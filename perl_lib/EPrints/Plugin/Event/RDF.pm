=head1 NAME

EPrints::Plugin::Event::RDF

=cut

package EPrints::Plugin::Event::RDF;

use EPrints::Plugin::Event;

@ISA = qw( EPrints::Plugin::Event );

use strict;

sub clear_triples
{
	my( $self, $dataobj ) = @_;

	# clear
	my $uri = $dataobj->internal_uri;
	$uri =~ s/^\/id\//epid:/;
	
	my $list = $self->{session}->dataset( "triple" )->search( 
		filters => [
			{
				meta_fields => [qw/ primary_resource /],
				value => $uri,
			}
		],
	);

	$list->map( sub {
		my( $repository, $dataset, $dataobj ) = @_;
		$dataobj->remove;
	} );

	return;
}

sub update_triples
{
	my( $self, $dataobj ) = @_;

	$self->clear_triples( $dataobj );

	# modded
	my $graph = EPrints::RDFGraph->new( repository=>$self->{session} );
	$graph->add_dataobj_triples( $dataobj );

	my $namespaces = $self->{session}->get_conf( "rdf","xmlns");

	$graph->map( sub {
		my( $repository, $dataset, $triple ) = @_;
		my %data = %{$triple->get_data};
		$data{primary_resource}= '<'.$dataobj->uri.'>';
		uri_compress( \$data{primary_resource}, $namespaces );
		if( defined $data{secondary_resource} )
		{
			uri_compress( \$data{secondary_resource}, $namespaces );
		}
		uri_compress( \$data{subject}, $namespaces );
		uri_compress( \$data{predicate}, $namespaces );
		if( !$data{type} )
		{
			uri_compress( \$data{object}, $namespaces );
		}
		if( $data{type} )
		{
			uri_compress( \$data{type}, $namespaces );
		}
		delete $data{tripleid};
		$self->{session}->dataset( "triple" )->create_dataobj( \%data );
	});

	return;
}

sub uri_compress
{
	my( $str, $namespaces ) = @_;

	return if( substr( $$str, 0, 1 ) ne "<" );
	foreach my $short ( keys %{$namespaces} )
	{
		my $long = $namespaces->{$short};
		my $l = length( $long );
		if( substr( $$str, 1, $l ) eq $long )
		{
			$$str = $short.":".substr( $$str, 1+$l, length($$str)-$l-2);
			return;
		}
	}
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

