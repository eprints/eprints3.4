#!/usr/bin/perl

use Test::More tests => 3;

use strict;
use warnings;

BEGIN { use_ok( "EPrints" ); }
BEGIN { use_ok( "EPrints::Test" ); }

my $repoid = EPrints::Test::get_test_id();
my $ep = EPrints->new();
my $repo = $ep->repository( $repoid );

my $searchexp = EPrints::Search->new(
	session => $repo,
	dataset => $repo->dataset( "subject" ),
	allow_blank => 1
);

my @subjects = $searchexp->perform_search->get_records();

BAIL_OUT("No subjects loaded") if !@subjects;

my $childless;
for(@subjects)
{
	$childless = $_, last if !($_->get_children);
}

$repo->cache_subjects;

my $cached = EPrints::DataObj::Subject->new( $repo, $childless->get_id );

#3451
ok(!$cached->get_children, "can call get_children on childless subject")

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

