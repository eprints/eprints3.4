# <link> entries for machine-navigation
$c->add_trigger( EP_TRIGGER_DYNAMIC_TEMPLATE, sub {
	my %params = @_;

	my $repo = $params{repository};
	my $pins = $params{pins};
	my $xhtml = $repo->xhtml;

	my $head = $repo->xml->create_document_fragment;

	# Top
	$head->appendChild( $repo->xml->create_element( "link",
			rel => "Top",
			href => $repo->config( "frontpage" ),
		) );
	$head->appendChild( $repo->xml->create_text_node( "\n    " ) );

	# SWORD endpoints
	$head->appendChild( $repo->xml->create_element( "link",
			rel => "Sword",
			href => $repo->current_url( scheme => 'https', host => 1, path => "static", "sword-app/servicedocument" ),
		) );
	$head->appendChild( $repo->xml->create_text_node( "\n    " ) );
	$head->appendChild( $repo->xml->create_element( "link",
			rel => "SwordDeposit",
			href => $repo->current_url( scheme => 'https', host => 1, path => "static", "id/contents" ),
		) );
	$head->appendChild( $repo->xml->create_text_node( "\n    " ) );

	# Search
	$head->appendChild( $repo->xml->create_element( "link",
			rel => "Search",
			type => "text/html",
			href => $repo->current_url( scheme => 'http', host => 1, path => "cgi", "search" ),
		) );
	$head->appendChild( $repo->xml->create_text_node( "\n    " ) );

	# OpenSearch
	$head->appendChild( $repo->xml->create_element( "link",
			rel => "Search",
			type => "application/opensearchdescription+xml",
			href => $repo->current_url( scheme => 'http', host => 1, path => "cgi", "opensearchdescription" ),
            title=> $repo->phrase( 'archive_name' ),
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
});

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

