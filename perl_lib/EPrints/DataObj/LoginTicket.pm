######################################################################
#
# EPrints::DataObj::LoginTicket
#
######################################################################
#
#
######################################################################

=pod

=for Pod2Wiki

=head1 NAME

B<EPrints::DataObj::LoginTicket> - User system login ticket.

=head1 DESCRIPTION

Login tickets are the database entries for a user's session cookies.

=head2 Configuration Settings

=over 4

=item user_cookie_timeout = undef

Set an expiry on the session cookies. This will cause the user's 
browser to delete the cookie after the given time. The time is 
specified according to L<CGI>'s cookie constructor. This allows 
settings like C<+1h> and C<+7d>.

=item user_inactivity_timeout = 86400 * 7

How long to wait in seconds before logging the user out after their 
last activity.

=item user_session_timeout = undef

How long in seconds the user can stay logged in before they must 
re-log in. Defaults to never - if you do specify this setting you 
probably want to reduce C<user_inactivity_timeout> to <1 hour.

=back

=head1 CORE METADATA FIELDS

=over 4

=item code (id)

The identifier used in the HTTP cookie for this login ticket's 
session.

=item securecode (id)

The identifier used in the HTTPS cookie for this login ticket's 
session.

=item ip (id)

The IP address of associated with this login ticket.

=item time (bigint)

The time in seconds since the start of epoch when this login 
ticket was created.

=item expires (bigint)

The time in seconds since the start of epoch when this login
ticket will expires.

=back

=head1 REFERENCES AND RELATED OBJECTS

=over 4

=item userid (itemref)

The ID of the user to whom this login ticket belongs.

=back

=head1 INSTANCE VARIABLES

See L<EPrints::DataObj|EPrints::DataObj#INSTANCE_VARIABLES>.

=head1 METHODS

=cut 

package EPrints::DataObj::LoginTicket;

@ISA = ( 'EPrints::DataObj' );

use EPrints;
use Digest::MD5;

use strict;

our $SESSION_KEY = "eprints_session";
our $SECURE_SESSION_KEY = "secure_eprints_session";
our $SESSION_TIMEOUT = 86400 * 7; # 7 days

######################################################################
=pod

=head2 Class Methods

=cut
######################################################################

######################################################################
=pod

=over 4

=item $fields = EPrints::DataObj::Access->get_system_field_info

Returns an array describing the system metadata of the loginticket
dataset.

=cut
######################################################################

sub get_system_field_info
{
	my( $class ) = @_;

	return
	( 
		{ name=>"code", type=>"id", required=>1 },

		{ name=>"securecode", type=>"id", required=>1 },

		{ name=>"userid", type=>"itemref", datasetid=>"user", required=>1 },

		{ name=>"ip", type=>"id", required=>1 },

		{ name=>"time", type=>"bigint", required=>1 },

		{ name=>"expires", type=>"bigint", required=>1 },
	);
}


######################################################################
=pod

=item $dataset = EPrints::DataObj::LoginTicket->get_dataset_id

Returns the ID of the L<EPrints::DataSet> object to which this record 
belongs.

=cut
######################################################################

sub get_dataset_id
{
	return "loginticket";
}


######################################################################
=pod

=item $defaults = EPrints::DataObj::LoginTicket->get_defaults( $session, $data, $dataset )

Returns default values for this data object based on the starting
C<$data>.

=cut
######################################################################

sub get_defaults
{
	my( $class, $repo, $data, $dataset ) = @_;

	$class->SUPER::get_defaults( $repo, $data, $dataset );

	$data->{code} = &_code();
	$data->{securecode} = &_code();
	if( !$repo->config( "ignore_login_ip" ) && !$repo->config( "securehost" ) )
	{
		$data->{ip} = $repo->remote_ip;
	}

	$data->{time} = time();
	my $timeout = $repo->config( "user_inactivity_timeout" );
	$timeout = $SESSION_TIMEOUT if !defined $timeout;
	$data->{expires} = time() + $timeout;

	return $data;
}

sub _code
{
	my $ctx = Digest::MD5->new;
	srand;
	$ctx->add( $$, time, rand() );
	return $ctx->hexdigest;
}

######################################################################
=pod

=item $loginticket = EPrints::DataObj::LoginTicket->new_from_request( $repo, $r )

Creates a new loginticket data object using the L<HTTP::Request> 
C<$r>.

Returns new loginticket data object if successful. Otherwise, returns
C<undef>.

=cut
######################################################################

sub new_from_request
{
	my( $class, $repo, $r ) = @_;

	my $dataset = $repo->dataset( $class->get_dataset_id );

	my $ip = $repo->remote_ip;

	my $ticket;

	if( $repo->get_secure )
	{
		my $securecode = EPrints::Apache::AnApache::cookie(
			$r,
			$class->secure_session_key($repo)
		);
		if (EPrints::Utils::is_set($securecode)) {
			$ticket = $dataset->search(filters => [
				{ meta_fields => [qw( securecode )], value => $securecode },
			])->item( 0 );
		}
	}
	elsif( !$repo->config( 'securehost' ) )
	{
		my $code = EPrints::Apache::AnApache::cookie(
			$r,
			$class->session_key($repo)
		);
		if (EPrints::Utils::is_set($code)) {
			$ticket = $dataset->search(filters => [
				{ meta_fields => [qw( code )], value => $code },
			])->item( 0 );
		}
	}

	my $timeout = $repo->config( "user_session_timeout" );

	if( 
		defined $ticket &&
		# maximum time in seconds someone can stay logged in
		(!defined $timeout || $ticket->value( "time" ) + $timeout >= time()) &&
		# maximum time in seconds between actions
		(!$ticket->is_set( "expires" ) || $ticket->value( "expires" ) >= time()) &&
		# same-origin IP
		(!$ticket->is_set( "ip" ) || $ticket->value( "ip" ) eq $ip)
	  )
	{
		return $ticket;
	}

	return undef;
}


######################################################################
=pod

=item EPrints::DataObj::LoginTicket->expire_all( $repo )

Expire all login tickets. Effectively logging out all users currently
logged in.

=cut
######################################################################

sub expire_all
{
	my( $class, $repo ) = @_;

	my $dataset = $repo->dataset( $class->get_dataset_id );

	$dataset->search(filters => [
		{ meta_fields => [qw( expires )], value => "..".time() },
	])->map(sub {
		$_[2]->remove;
	});
}


######################################################################
=pod

=item EPrints::DataObj::LoginTicket->session_key( $repo )

Get the key to use for the session cookies.

In the following circumstance:

	example.org
	custom.example.org

Where both hosts use the same cookie key the cookie from example.org 
will collide with the cookie from custom.example.org. To avoid this 
the full hostname is embedded in the cookie key.

=cut
######################################################################

sub session_key
{
	my ($class, $repo) = @_;

	my $host = $repo->config('host');
	$host ||= $repo->config('securehost');
	return join ':', $SESSION_KEY, $host;
}


######################################################################
=pod

=item EPrints::DataObj::LoginTicket->secure_session_key($repo)

See L</session_key>.

=cut
######################################################################

sub secure_session_key
{
	my ($class, $repo) = @_;

	return join ':', $SECURE_SESSION_KEY, $repo->config('securehost');
}


######################################################################
=back

=head2 Object Methods

=cut
######################################################################

######################################################################
=pod

=over 4

=item $cookie = $loginticket->generate_cookie( %opts )

Returns the HTTP (non-secure) session cookie. Uses C<%opts> to add any
additional attributes to the cookie.

=cut
######################################################################

sub generate_cookie
{
	my( $self, %opts ) = @_;

	my $repo = $self->{session};

	my $domain = $repo->config( "host" );
	$domain ||= $repo->config( "securehost" );
	return $repo->query->cookie(
		-name    => $self->session_key($repo),
		-path    => ($repo->config( "rel_path" ) || '/'),
		-value   => $self->value( "code" ),
		-domain  => $domain,
		-samesite => 'Strict',
		-expires => $repo->config( "user_cookie_timeout" ),
		%opts,
	);			
}


######################################################################
=pod

=item $cookie = $ticket->generate_secure_cookie( %opts )

Returns the HTTPS session cookie. Uses C<%opts> to add any additional 
attributes to the cookie.

=cut
######################################################################

sub generate_secure_cookie
{
	my( $self, %opts ) = @_;

	my $repo = $self->{session};

	return $repo->query->cookie(
		-name    => $self->secure_session_key($repo),
		-path    => ($repo->config( "https_root" ) || '/'),
		-value   => $self->value( "securecode" ),
		-domain  => $repo->config( "securehost" ),
		-secure  => 1,
		-samesite => 'Strict',
		-expires => $repo->config( "user_cookie_timeout" ),
		%opts,
	);			
}


######################################################################
=pod

=item $ticket->set_cookies

Set the session cookies for this loginticket data object.

=cut
######################################################################

sub set_cookies
{
	my( $self ) = @_;

	my $repo = $self->{session};

	if( $repo->config( "securehost" ) )
	{
		$repo->get_request->err_headers_out->add(
			'Set-Cookie' => $self->generate_secure_cookie
		);
	}
	else
	{
		$repo->get_request->err_headers_out->add(
			'Set-Cookie' => $self->generate_cookie
		);
	}
}

######################################################################
=pod

=item $ticket->update

Update the loginticket data object by extending the expiry time.

The expiry time is extended C<user_inactivity_timeout> or 7 days.

=cut
######################################################################

sub update
{
	my( $self ) = @_;

	my $timeout = $self->{session}->config( "user_inactivity_timeout" );
	$timeout = $SESSION_TIMEOUT if !defined $timeout;

	$self->set_value( "expires", time() + $timeout );
	$self->commit;
}

1;


######################################################################
=pod

=back

=head1 SEE ALSO

L<EPrints::DataObj> and L<EPrints::DataSet>.

=head1 COPYRIGHT

=begin COPYRIGHT

Copyright 2023 University of Southampton.
EPrints 3.4 is supplied by EPrints Services.

http://www.eprints.org/eprints-3.4/

=end COPYRIGHT

=begin LICENSE

This file is part of EPrints 3.4 L<http://www.eprints.org/>.

EPrints 3.4 and this file are released under the terms of the
GNU Lesser General Public License version 3 as published by
the Free Software Foundation unless otherwise stated.

EPrints 3.4 is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with EPrints 3.4.
If not, see L<http://www.gnu.org/licenses/>.

=end LICENSE
