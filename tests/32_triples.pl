#!/usr/bin/perl

use Test::More;

use strict;
use warnings;

use EPrints;
use EPrints::Test;
use EPrints::Test::RepositoryLog;

my $repoid = EPrints::Test::get_test_id();

my $ep = EPrints->new();
if( !defined $ep ) { BAIL_OUT( "Could not obtain the EPrints System object" ); }

my $repo = $ep->repository( $repoid );
if( !defined $repo ) { BAIL_OUT( "Could not obtain the Repository object" ); }

my $dataset = $repo->dataset( "triple" );
if( !defined $dataset ) { BAIL_OUT( "Could not obtain the triple dataset" ); }

plan tests => 4;

{
	my $graph = EPrints::RDFGraph->new( repository=>$repo );
	ok( defined $graph, "Created a graph" );

	ok( $graph->count == 0, "Empty graph has zero size" );

	$graph->add( 
		subject => '<aaa>', 
		predicate => '<bbb>',
		object => "<ccc>" );

	ok( $graph->count == 1, "Graph has size of 1 after adding an item." );

	my $plugin = $repo->plugin( "Export::RDFNT" );
	my $nt = $plugin->output_graph( $graph );

	ok( $nt eq "<aaa> <bbb> <ccc> .\n", "Output graph" );
}

# done

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

