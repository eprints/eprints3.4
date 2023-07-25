######################################################################
#
# EPrints::MetaField::Recaptcha3;
#
######################################################################
#
#
######################################################################

=pod

=head1 NAME

B<EPrints::MetaField::Recaptcha3> - a Captcha using Google ReCAPTCHA v3.

=head1 DESCRIPTION

Please refer to the notes in [EPRINTS_ROOT]/archives/[ARCHIVEID]/cfg/cfg.d/recaptcha3.pl.

If this files does not exist, copy [EPRINTS_ROOT]/lib/defaultcfg/cfg.d/recaptcha3.pl.example
to the path above and edit it.

This field uses version 3 of Google "reCAPTCHA" service:

https://developers.google.com/recaptcha/docs/v3

and renders a Captcha (a test that humans can easily pass, but robots shouldn't be able to).

=over 4

=cut

package EPrints::MetaField::Recaptcha3;

use EPrints::MetaField::Id;
@ISA = qw( EPrints::MetaField::Id );

use strict;
use JSON;

sub is_virtual { 1 }

sub get_property_defaults
{
        my( $self ) = @_;
        my %defaults = $self->SUPER::get_property_defaults;
        $defaults{action} = "request";

        return %defaults;
}

sub render_input_field_actual
{
	my( $self, $session, $value, $dataset, $staff, $hidden_fields, $obj, $basename ) = @_;

	my $public_key = $session->config( "recaptcha3", "public_key" );

	if( !defined $public_key )
	{
		return $session->render_message( "error", $session->make_text( "public_key not set" ) );
	}

	my $frag = $session->make_doc_fragment;

	my $url = URI->new( "https://www.google.com/recaptcha/api.js?render=" . $public_key );

	$frag->appendChild( $session->make_javascript( undef,
		src => $url,
		async => 'async',
		defer => 'defer'
	) );

	$frag->appendChild( $session->make_element( "input",
		type => "hidden",
		id => "g-recaptcha-response",
		name => "g-recaptcha-response",
	) );

	$frag->appendChild( $session->make_element( "input",
		type => "hidden",
		name => "_action_" . $self->get_property( "action" ),
		value => "1",
	) ); 

	$frag->appendChild( $session->make_javascript( <<EOJ ) );
	function sleep(ms) {
	    return new Promise(resolve => setTimeout(resolve, ms));
	}
	document.addEventListener("DOMContentLoaded", function(){
		document.querySelector('.ep_form_action_button').addEventListener('click', e => {
			e.preventDefault();
			grecaptcha.ready(function() {
				grecaptcha.execute('$public_key', {action: 'submit'}).then(function(token) {
					document.getElementById('g-recaptcha-response').value = token;
					e.target.form.submit();
				});
			});
		});
	});
EOJ

	 return $frag;
}

sub form_value_actual
{
	my( $self, $repo, $object, $basename ) = @_;

	my $private_key = $repo->config( "recaptcha3", "private_key" );
	my $timeout = $repo->config( "recaptcha3", "timeout" ) || 5;
	my $min_score = $repo->config( "recaptcha3", "min_score" ) || 0.5;

	if( !defined $private_key )
	{
		$repo->log( "recaptcha private_key not set" );
		return undef;
	}

	my $response = $repo->param( "g-recaptcha-response" );
	if( !EPrints::Utils::is_set( $response ) )
	{
		if ( my $ignore_countries = $repo->config( "recaptcha3", "ignore_countries" ) )
                {
                        # if possible, use the GeoIP data file shipped with EPrints
                        my $dat_file = $repo->config( "lib_path" ).'/geoip/GeoIP.dat';

                        # alternatively use the global one
                        $dat_file = 1 if( !-e $dat_file );

                        #Test Geo::IP first - it's faster!
                        my $geoip;
                        foreach my $pkg ( 'Geo::IP', 'Geo::IP::PurePerl' )
                        {
                                if( EPrints::Utils::require_if_exists( $pkg ) )
                                {
                                        $geoip = $pkg->new( $dat_file );
                                        last if( defined $geoip );
                                }
                        }
                        if ( defined $geoip )
                        {
                                my $code = $geoip->country_code_by_addr( $repo->remote_ip ); 
                                if ( grep { $_ eq $code } @{ $ignore_countries } )
                                {
                                        $repo->log( "NOTICE: No ReCAPTCHA used for IP address ".$repo->remote_ip." from $code." );
                                        return undef;
                                }
                        }
                }
		return "invalid-captcha-sol";
	}

	my $url = URI->new( "https://www.google.com/recaptcha/api/siteverify" );

	my $ua = LWP::UserAgent->new();
	$ua->env_proxy;
	$ua->timeout( $timeout ); #LWP default timeout is 180 seconds. 

	my $r = $ua->post( $url, [
		secret => $private_key,
		response => $response
	]);

	# the request returned a response - but we have to check whether the human (or otherwise)
	# passed the Captcha 
	if( $r->is_success )
	{
		my $hash = decode_json( $r->content );

		#use Data::Dumper;
		#print STDERR "recaptcha3 response: ".Dumper( $hash );

		if( !$hash->{success} )
		{
			my $recaptcha_error = 'unknown-error';
			my $codes = $hash->{'error-codes'};
			if( $codes && scalar @{$codes} )
			{
				$recaptcha_error = join '+', @{$codes};
			}
			return $recaptcha_error;
		}
		elsif ( $hash->{score} < $min_score )
		{
			return 'score-too-low';
		}
		return undef; #success!
	}

	# error talking to recaptcha, so lets continue to avoid blocking the user
	# in case of network problems
	$repo->log( "Error contacting recaptcha: ".$r->code." ".$r->message );

	return undef;
}

sub validate
{
	my( $self, $session, $value, $object ) = @_;

	#print STDERR "validate value: $value\n";
	
	my @probs;

	if( $value )
	{
		push @probs, $session->html_phrase( "validate:recaptcha_mismatch" );
	}

	return @probs;
}

######################################################################
1;

=head1 COPYRIGHT

=for COPYRIGHT BEGIN

Copyright 2022 University of Southampton.
EPrints 3.4 is supplied by EPrints Services.

http://www.eprints.org/eprints-3.4/

=for COPYRIGHT END

=for LICENSE BEGIN

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

=for LICENSE END
