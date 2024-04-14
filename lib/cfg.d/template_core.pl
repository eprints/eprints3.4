# core system head parts - auto.css, auto.js and dynamic settings
$c->add_trigger( EP_TRIGGER_DYNAMIC_TEMPLATE, sub {
	my %params = @_;

	my $repo = $params{repository};
	my $pins = $params{pins};
	my $xhtml = $repo->xhtml;
	my $lang = $repo->get_langid;

	EPrints::Update::Static::update_auto_js( $repo, $repo->config( "htdocs_path" )."/$lang/", [$repo->get_static_dirs( $lang )] );
	my $auto_js = $repo->config( "htdocs_path" )."/$lang/javascript/auto.js";
	my $auto_js_timestamp = (stat($auto_js))[9];
	
	EPrints::Update::Static::update_auto_css( $repo, $repo->config( "htdocs_path" )."/$lang/", [$repo->get_static_dirs( $lang )] );
	my $auto_css = $repo->config( "htdocs_path" )."/$lang/style/auto.css";
	my $auto_css_timestamp = (stat($auto_css))[9];

	my $head = $repo->xml->create_document_fragment;

	# dynamic CSS/JS settings
	$head->appendChild( $repo->make_javascript(sprintf(<<'EOJ',
var eprints_http_root = %s;
var eprints_http_cgiroot = %s;
var eprints_oai_archive_id = %s;
var eprints_logged_in = %s;
var eprints_logged_in_userid = %s; 
var eprints_logged_in_username = %s; 
var eprints_logged_in_usertype = %s; 
var eprints_lang_id = %s;
EOJ
			(map { EPrints::Utils::js_string( $_ ) }
				$repo->current_url( host => 1, path => 'static' ),
				$repo->current_url( host => 1, path => 'cgi' ),
				EPrints::OpenArchives::archive_id( $repo ) ),
			defined $repo->current_user ? 'true' : 'false',
			defined $repo->current_user ? $repo->current_user->get_id : 0,
			defined $repo->current_user ? '"' . $repo->current_user->get_value("username") . '"' : '""',
			defined $repo->current_user ? '"' . $repo->current_user->get_value("usertype") . '"' : '""', # is this safe to share?
			defined $repo->{request} ? '"' . $repo->get_session_language( $repo->{request} ) . '"' : '""',
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
			href => $repo->current_url( path => "static", "style/auto-".EPrints->human_version.".css" ) . "?".$auto_css_timestamp
		) );
	$head->appendChild( $repo->xml->create_text_node( "\n    " ) );
	$head->appendChild( $repo->make_javascript( undef,
		src => $repo->current_url( path => "static", "javascript/auto-".EPrints->human_version.".js" ) . "?".$auto_js_timestamp
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

