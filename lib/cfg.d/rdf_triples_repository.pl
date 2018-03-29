
# These triples will be supplied to describe your repository. These are given
# if someone queries /id/repository.

# By default it uses some information from the oai.pl configuration to save 
# having to define it twice.

$c->{rdf}->{xmlns}->{void} = "http://rdfs.org/ns/void#";

$c->add_trigger( EP_TRIGGER_REPOSITORY_RDF, sub {
	my( %o ) = @_;

	my $repository_uri = "<".$o{repository}->config( "base_url" )."/id/repository>";

	my @eprint_ids = sort @{$o{repository}->dataset("archive")->get_item_ids( $o{repository} )};

	my $oai_config = $o{repository}->config( "oai" );

	$o{graph}->add( 
		  subject => $repository_uri,
		predicate => "rdf:type",
		   object => "ep:Repository" );
	$o{graph}->add( 
		  subject => $repository_uri,
		predicate => "dct:title",
		   object => $o{repository}->phrase( "archive_name" ),
		     type => "xsd:string" );
	$o{graph}->add( 
		  subject => $repository_uri,
		predicate => "foaf:homepage",
		   object => "<".$o{repository}->config( "base_url" )."/>" );
	$o{graph}->add( 
		  subject => $repository_uri,
		predicate => "ep:OAIPMH2",
		   object => "<".$o{repository}->config( "base_url" )."/cgi/oai2>" );

	# maybe dct:rightsHolder, dct:publisher

	# voID

	$o{graph}->add( 
		  subject => $repository_uri,
		predicate => "rdf:type",
		   object => "void:Dataset" );
	if( @eprint_ids )
	{
		$o{graph}->add( 
		  	subject => $repository_uri,
			predicate => "void:exampleResource",
		   	object => "<".$o{repository}->config( "base_url" )."/id/eprint/".$eprint_ids[0].">" );
	}
	my $xmlns = $o{repository}->config( "rdf","xmlns" );
	foreach my $nsid ( keys %{$xmlns} )
	{
		$o{graph}->add( 
		  	subject => $repository_uri,
			predicate => "void:vocabulary",
		   	object => "<".$xmlns->{$nsid}.">" );
	}

	# Repository Description

	if( $oai_config->{content}->{text} )
	{
		$o{graph}->add( 
		  	subject => $repository_uri,
			predicate => "dct:description",
		   	object => $oai_config->{content}->{text},
			type => "xsd:string" );
	}
	if( $oai_config->{content}->{url} )
	{
		$o{graph}->add( 
		  	subject => $repository_uri,
			predicate => "dct:description",
		   	object => "<".$oai_config->{content}->{url}.">" );
	}

	# Rights
		
	if( $oai_config->{metadata_policy}->{text} )
	{
		$o{graph}->add( 
		  	subject => $repository_uri,
			predicate => "dc:rights",
		   	object => $oai_config->{metadata_policy}->{text},
			type => "xsd:string" );
	}
	if( $oai_config->{metadata_policy}->{url} )
	{
		$o{graph}->add( 
		  	subject => $repository_uri,
			predicate => "dct:rights",
		   	object => "<".$oai_config->{metadata_policy}->{url}.">" );
	}

	if( $oai_config->{data_policy}->{text} )
	{
		$o{graph}->add( 
		  	subject => $repository_uri,
			predicate => "dc:rights",
		   	object => $oai_config->{data_policy}->{text},
			type => "xsd:string" );
	}
	if( $oai_config->{data_policy}->{url} )
	{
		$o{graph}->add( 
		  	subject => $repository_uri,
			predicate => "dct:rights",
		   	object => "<".$oai_config->{data_policy}->{url}.">" );
	}

	if( $oai_config->{submission_policy}->{text} )
	{
		$o{graph}->add( 
		  	subject => $repository_uri,
			predicate => "dc:rights", # <<< not ideal
		   	object => $oai_config->{submission_policy}->{text},
			type => "xsd:string" );
	}
	if( $oai_config->{submission_policy}->{url} )
	{
		$o{graph}->add( 
		  	subject => $repository_uri,
			predicate => "dct:rights", # <<< not ideal
		   	object => "<".$oai_config->{submission_policy}->{url}.">" );
	}

	# Comments

	foreach my $comment ( @{ $oai_config->{comments} } )
	{
		$o{graph}->add( 
		  	subject => $repository_uri,
			predicate => "rdfs:comment",
		   	object => $comment,
			type => "xsd:string" );
	}

	foreach my $id ( sort @eprint_ids )
	{
		# Not loading the actual object as that would take a crazy-long time!
		$o{graph}->add( 
		  	subject => $repository_uri,
			predicate => "ep:hasEPrint",
		   	object => "<".$o{repository}->config( "base_url" )."/id/eprint/".$id.">" );
	}

	my $root_subject = $o{repository}->dataset("subject")->dataobj("ROOT");
	foreach my $top_subject ( $root_subject->get_children )
	{
		$o{graph}->add( 
		  	subject => $repository_uri,
			predicate => "ep:hasConceptScheme",
		   	object => "<".$top_subject->uri."#scheme>" );
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

