

# These triples will be supplied in any serialisation of RDF your repository
# produces, use it to describe rights information etc.

$c->add_trigger( EP_TRIGGER_BOILERPLATE_RDF, sub {
	my( %o ) = @_;

	my $license_uri = $o{repository}->config( "rdf", "license" );
	if( defined $license_uri )
	{
		$o{graph}->add( 
		  	subject => "<>",
			predicate => "cc:license",
		   	object => "<$license_uri>" );
	}
	else
	{
		$o{graph}->add( 
		  	subject => "<>",
			predicate => "rdfs:comment",
		   	object => "The repository administrator has not yet configured an RDF license.",
		     	type => "xsd:string" );
	}	
	
	my $attributionName = $o{repository}->config( "rdf", "attributionName" );
	if( defined $license_uri )
	{
		$o{graph}->add( 
		  	  subject => "<>",
			predicate => "cc:attributionName",
		   	   object => $attributionName,
			     type => "xsd:string" );
	}

	my $attributionURL = $o{repository}->config( "rdf", "attributionURL" );
	if( defined $attributionURL )
	{
		$o{graph}->add( 
		  	subject => "<>",
			predicate => "cc:attributionURL",
		   	object => "<$attributionURL>" );
	}

	# [ "<>", "dc:creator", $o{repository}->phrase( "archive_name" ), "literal" ];
	# [ "<>", "dct:rightsHolder", $o{repository}->phrase( "archive_name" ), "literal" ];
} );



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

