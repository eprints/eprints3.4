=head1 NAME

EPrints::Plugin::Screen::SetLang

=cut

package EPrints::Plugin::Screen::SetLang;

use EPrints::Plugin::Screen;
@ISA = qw( EPrints::Plugin::Screen );

use strict;

sub from
{
	my( $self ) = @_;

	my $session = $self->{session};

	my $langid = $session->param( "lang" );
	$langid = "" if !defined $langid;

	my $cookie = $session->{query}->cookie(
		-name    => "eprints_lang",
		-path    => "/",
		-expires => 0,
		-value   => $langid,
		-expires => ($langid ? "+10y" : "+0s"), # really long time
		-domain  => $session->config("cookie_domain") );
	$session->{request}->err_headers_out->add('Set-Cookie' => $cookie);

	my $referrer = $session->param( "referrer" );
        $referrer = EPrints::Apache::AnApache::header_in( $session->get_request, 'Referer' ) unless( EPrints::Utils::is_set( $referrer ) );
	$referrer = $session->config( "home_page" ) unless( EPrints::Utils::is_set( $referrer ) );

	$self->{processor}->{redirect} = $referrer;
}

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
	my $scripturl = URI->new( $session->current_url( path => "cgi", "set_lang" ), 'http' );
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

1;

=head1 COPYRIGHT

=for COPYRIGHT BEGIN

Copyright 2019 University of Southampton.
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

