# core system head parts - auto.css, auto.js and dynamic settings
$c->add_trigger( EP_TRIGGER_DYNAMIC_TEMPLATE, sub {
	my %params = @_;

	my $repo = $params{repository};
	my $pins = $params{pins};
	my $xhtml = $repo->xhtml;

	my $head = $repo->xml->create_document_fragment;

	# dynamic CSS/JS settings
	$head->appendChild( $repo->make_javascript(sprintf(<<'EOJ',
var eprints_http_root = %s;
var eprints_http_cgiroot = %s;
var eprints_oai_archive_id = %s;
var eprints_logged_in = %s;
EOJ
			(map { EPrints::Utils::js_string( $_ ) }
				$repo->current_url( host => 1, path => 'static' ),
				$repo->current_url( host => 1, path => 'cgi' ),
				EPrints::OpenArchives::archive_id( $repo ) ),
			defined $repo->current_user ? 'true' : 'false',
		)) );
	$head->appendChild( $repo->xml->create_text_node( "\n    " ) );
	my $style = $head->appendChild( $repo->xml->create_element( "style",
			type => "text/css",
		) );
	$style->appendChild( $repo->xml->create_text_node(
		(defined $repo->current_user ? '.ep_not_logged_in' : '.ep_logged_in') .
		' { display: none }'
	) );
	$head->appendChild( $repo->xml->create_text_node( "\n    " ) );
	$head->appendChild( $repo->xml->create_element( "link",
			rel => "stylesheet",
			type => "text/css",
			href => $repo->current_url( path => "static", "style/auto-".EPrints->human_version.".css" ),
		) );
	$head->appendChild( $repo->xml->create_text_node( "\n    " ) );
	$head->appendChild( $repo->make_javascript( undef,
		src => $repo->current_url( path => "static", "javascript/auto-".EPrints->human_version.".js" ),
	) );
	$head->appendChild( $repo->xml->create_text_node( "\n    " ) );

	# IE 6 fix
	$head->appendChild( $repo->xml->create_comment( sprintf('[if lte IE 6]>
        <link rel="stylesheet" type="text/css" href="%s" />
   <![endif]',
			$repo->current_url( path => "static", "style/ie6.css" ),
		) ) );
	$head->appendChild( $repo->xml->create_text_node( "\n    " ) );

	# meta-generator
	$head->appendChild( $repo->xml->create_element( "meta",
		name => "Generator",
		content => "EPrints ".EPrints->human_version,
	) );
	$head->appendChild( $repo->xml->create_text_node( "\n    " ) );

	# meta-content-type
	$head->appendChild( $repo->xml->create_element( "meta",
		'http-equiv' => "Content-Type",
		content => "text/html; charset=UTF-8",
	) );
	$head->appendChild( $repo->xml->create_text_node( "\n    " ) );

	# meta-content-language
	$head->appendChild( $repo->xml->create_element( "meta",
		'http-equiv' => "Content-Language",
		content => $repo->get_langid
	) );
	$head->appendChild( $repo->xml->create_text_node( "\n    " ) );

	if( defined $pins->{'utf-8.head'} )
	{
		$pins->{'utf-8.head'} .= $xhtml->to_xhtml( $head );
	}
	if( defined $pins->{head} )
	{
		$head->appendChild( $pins->{head} );
		$pins->{head} = $head;
	}
	else
	{
		$pins->{head} = $head;
	}

	return;
}, priority => 1000);

=head1 COPYRIGHT

=for COPYRIGHT BEGIN

Copyright 2018 University of Southampton.
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

