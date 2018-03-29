
# This is an example of a custom browse items renderer.

# Note: This function needs to return a UTF-8 encoded string NOT XHTML DOM.
# (this is to speed things up).

# To use this add render_fn=render_view_items_3col_boxes" to the options of a variation of a view.
# eg:
#		variations => [
#			"DEFAULT;render_fn=render_view_items_3col_boxes",
#		],

$c->{render_view_items_3col_boxes} = sub
{
	my( $repository, $item_list, $view_definition, $path_to_this_page, $filename ) = @_;

	my $xml = $repository->xml();

	my $table = $xml->create_element( "table" );
	my $columns = 3;
	my $tr = $xml->create_element( "tr" );
	$table->appendChild( $tr );
	my $cells = 0;
	foreach my $item ( @{$item_list} )
	{
		if( $cells > 0 && $cells % $columns == 0 )
		{
			$tr = $xml->create_element( "tr" );
			$table->appendChild( $tr );
		}

		my $link = $item->get_url;

		my $td = $xml->create_element( "td", style=>"vertical-align: top; padding: 1em; text-align: center; width: 200px;" );
		$tr->appendChild( $td );

		my $a1 = $repository->render_link( $link );
		my $piccy = $xml->create_element( "span", style=>"display: block; width: 200px; height: 150px; border: solid 1px #888; background-color: #ccf; padding: 0.25em" );
		$piccy->appendChild( $xml->create_text_node( "Imagine I'm a picture!" ));
		$a1->appendChild( $piccy );
		$td->appendChild( $a1 );

		$td->appendChild( $item->render_citation_link );

		$cells += 1;
	}

	return $xml->to_string( $table );
};


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

