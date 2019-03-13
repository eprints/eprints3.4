#!/usr/bin/perl

use Test::More tests => 3;

BEGIN { use_ok( "EPrints" ); }
BEGIN { use_ok( "EPrints::Test" ); }

unless(eval "use Test::Memory::Cycle; 1")
{
	BAIL_OUT "Install Test::Memory::Cycle";
}

my $repoid = EPrints::Test::get_test_id();

my $eprints;
my $repository;

# we load twice to check that reloading a repository won't cause cycles to
# appear
for(0..1)
{
	undef $eprints;
	undef $repository;
	$eprints = EPrints->new;

	$repository = $eprints->repository( $repoid );
}

# do a load_config() to check that doesn't cause issues
$repository->load_config();

memory_cycle_ok( $repository, "Reference cycles after load_config" );

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

