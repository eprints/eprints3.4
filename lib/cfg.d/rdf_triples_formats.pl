
$c->add_dataset_trigger( "eprint", EP_TRIGGER_RDF, sub {
	my( %o ) = @_;
	my $eprint = $o{"dataobj"};
	my $eprint_uri = "<".$eprint->uri.">";
	my $eprint_url = "<".$eprint->url.">";

	my $repo = $o{repository};
	my $xml = $repo->xml;

	my $title = $xml->to_string( $eprint->render_citation( 'brief' ));

	$o{graph}->add( 
		  subject => $eprint_uri,
		predicate => "rdfs:seeAlso",
  		   object => $eprint_url );
	$o{graph}->add( 
		  subject => $eprint_url,
		predicate => "dc:title",
  		   object => "HTML Summary of #".$eprint->id." $title",
		     type => "literal" );
	$o{graph}->add( 
		  subject => $eprint_url,
		predicate => "dc:format",
		   object => "text/html",
		     type => "literal" );
	$o{graph}->add( 
		  subject => $eprint_url,
		predicate => "foaf:primaryTopic",
  		   object => $eprint_uri );

	return; 
	# the below bit is disabled as it creates a whole heap of junk data

	my @plugins = $repo->plugin_list( 
					type=>"Export",
					can_accept=>"dataobj/eprint",
					is_advertised=>1,
					is_visible=>"all" );
	foreach my $plugin_id ( @plugins ) 
	{
		my $plugin = $repo->plugin( $plugin_id );
		my $url = "<".$plugin->dataobj_export_url( $eprint ).">";

		$o{graph}->add( 
			  subject => $eprint_uri,
			predicate => "rdfs:seeAlso",
  			   object => $url );
		$o{graph}->add( 
			  subject => $url,
			predicate => "dc:title",
  			   object => $xml->to_string( $plugin->render_name )." of #".$eprint->id." $title",
			     type => "literal" );
		$o{graph}->add( 
			  subject => $url,
			predicate => "dc:format",
			   object => $plugin->param("mimetype"),
			     type => "literal" );
		$o{graph}->add( 
			  subject => $url,
			predicate => "foaf:primaryTopic",
  			   object => $eprint_uri );
	}

} );


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

