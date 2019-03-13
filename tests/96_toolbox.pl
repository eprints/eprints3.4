#!/usr/bin/perl

use Test::More tests => 9;

use strict;
use warnings;

BEGIN { use_ok( "EPrints" ); }
BEGIN { use_ok( "EPrints::Test" ); }
BEGIN { use_ok( "EPrints::Toolbox" ); }

my $repoid = EPrints::Test::get_test_id();

my $ep = EPrints->new();
isa_ok( $ep, "EPrints", "EPrints->new()" );
if( !defined $ep ) { BAIL_OUT( "Could not obtain the EPrints System object" ); }

my $repo = $ep->repository( $repoid );
isa_ok( $repo, "EPrints::Repository", "Get a repository object ($repoid)" );
if( !defined $repo ) { BAIL_OUT( "Could not obtain the Repository object" ); }

my $document = EPrints::Test::get_test_dataobj( $repo->dataset( "document" ) );

my $filename = "test_$$.txt";
my $data = "Hello, World!\n";

my @results;

@results = EPrints::Toolbox::tool_addFile(
	session => $repo,
	document => $document,
	filename => $filename,
	data_fn => sub { $data }, );
ok( $results[0] eq "0", "tool_addFile" );

@results = EPrints::Toolbox::tool_getFile(
	session => $repo,
	document => $document,
	filename => $filename, );
is( $results[1], $data, "tool_getFile" );

@results = EPrints::Toolbox::tool_removeFile(
	session => $repo,
	document => $document,
	filename => $filename, );
ok( $results[0] eq "0", "tool_delFile" );

ok(1);

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

