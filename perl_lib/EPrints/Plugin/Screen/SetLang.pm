######################################################################
#
# EPrints::Plugin::Screen::SetLang
#
######################################################################
#
#
######################################################################

=pod

=for Pod2Wiki

=head1 NAME

B<EPrints::Plugin::Screen::SetLang> - Screen plugin for setting a
cookie for the language to use on repository web pages.

=head1 DESCRIPTION

This plugin allows a cookie called C<eprints_lang> to set that
specifies the language that be used for the current visitor to the
repository.

This takes the value of the C<lang> attribute from the HTTP GET of
the request (C</cgi/set_lang>) to set the cookie.

Once the language is set the user is returned the page
they original came from, which now should display in their preferred
language.

=head1 METHODS

=cut

package EPrints::Plugin::Screen::SetLang;

use EPrints::Plugin::Screen;
@ISA = qw( EPrints::Plugin::Screen );

use strict;

######################################################################
=pod

=over 4

=item EPrints::Plugin::Screen::SetLang->from

Creates the C<eprints_lang> cookie using the value of C<lang> attribute
from the HTTP GET of the request (C</cgi/set_lang>).

Once the cookie is set the client is redirected back to their original
page (specified by the C<Referrer> header of the request or the
repository homepage.

=cut
######################################################################


sub from
{
	my( $self ) = @_;

	my $session = $self->{session};

	my $langid = $session->param( "lang" );
	$langid = "" if !defined $langid;

	my $samesite = "Strict";
	my $secure = 0;
	my $httponly = 1;
	if ( $session->is_secure eq "on" )
	{
		$secure = 1;
		$httponly = 0;
	}
	my $cookie = $session->{query}->cookie(
		-name     => "eprints_lang",
		-path     => "/",
		-samesite => $samesite,
		-secure   => $secure,
		-httponly => $httponly,
		-expires  => 0,
		-value    => $langid,
		-expires  => ($langid ? "+10y" : "+0s"), # really long time
		-domain   => $session->config("cookie_domain") );
	$session->{request}->err_headers_out->add('Set-Cookie' => $cookie);

	my $referrer = $session->param( "referrer" );
        $referrer = EPrints::Apache::AnApache::header_in( $session->get_request, 'Referer' ) unless( EPrints::Utils::is_set( $referrer ) );
	if (defined $referrer)
	{
			my $referrer_uri = URI->new($referrer);
			my $repository_uri = URI->new($session->config('base_url'));

			if (defined $referrer_uri->host && $referrer_uri->host ne $repository_uri->host)
			{
				$referrer = undef;
			} elsif (defined $referrer_uri->scheme && defined $referrer_uri->host && $referrer_uri->scheme . "://" . $referrer_uri->host ne $session->config('base_url')) {
				# Verify against javascript: or data: injection
				$referrer = undef;
			}
	}
	$referrer = $session->config( "frontpage" ) unless( EPrints::Utils::is_set( $referrer ) );

	$self->{processor}->{redirect} = $referrer;
}

######################################################################
=pod

=over 4

=item EPrints::Plugin::Screen::SetLang->render_action_link

Returns a XHTML DOM fragment for a link or links to alternative
languages that could be used on the repository, (including a link to
clear the currently selected language). Once one of these links is
clicked, the C<eprints_lang> cookie will be updated appropriately.

=cut
######################################################################

sub render_action_link
{
	my( $self ) = @_;

	my $session = $self->{session};

	my $xml = $session->xml;
	my $f = $xml->create_document_fragment;

	my $languages = $session->config( "languages" );

	if( @$languages == 1 )
	{
		return $f;
	}

	my $imagesurl = $session->config( "rel_path" )."/images/flags";
	my $scheme = EPrints::Utils::is_set( $session->config( "securehost" ) ) ? "https" : "http";
	my $scripturl = URI->new( $session->current_url( path => "cgi", "set_lang" ), $scheme );
	my $curl = "";
	if( $session->get_online )
	{
		$curl = $session->current_url( host => 1, query => 1 );
	}

	my $div = $xml->create_element( "div", id => "ep_tm_languages" );
	$f->appendChild( $div );

	foreach my $langid (@$languages)
	{
		next if $langid eq $session->get_lang->get_id;
		$scripturl->query_form(
			lang => $langid,
			referrer => $curl
		);
		my $clangid = $session->get_lang()->get_id;
		$session->change_lang( $langid );
		my $title = $session->phrase( "languages_typename_$langid" );
		$session->change_lang( $clangid );
		my $link = $xml->create_element( "a",
			href => "$scripturl",
			title => $title,
		);
		my $img = $xml->create_element( "img",
			src => "$imagesurl/$langid.png",
			align => "top",
			border => 0,
			alt => $title,
		);
		$link->appendChild( $img );
		$div->appendChild( $link );
	}

	$scripturl->query_form( referrer => $curl );

	my $title = $session->phrase( "cgi/set_lang:clear_cookie" );
	my $link = $xml->create_element( "a",
		href => "$scripturl",
		title => $title,
	);
	my $img = $xml->create_element( "img",
		src => "$imagesurl/aero.png",
		align => "top",
		border => 0,
		alt => $title,
	);
	$link->appendChild( $img );
	$div->appendChild( $link );

	return $div;
}

######################################################################
=pod

=over 4

=item EPrints::Plugin::Screen::SetLang->render

Returns an XHTML DOM object that is a rendering of screen.  As the
client should be always be redirected from this page, once the
C<eprints_lang> cookie is updated, it just contain as message saying
the redirect failed.

=cut
######################################################################

sub render
{
        my( $self ) = @_;

        my $chunk = $self->{session}->make_doc_fragment;
	$chunk->appendChild( $self->html_phrase( "no_redirect" ) );

        return $chunk;
}


1;

=head1 COPYRIGHT

=begin COPYRIGHT

Copyright 2024 University of Southampton.
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

