#!/usr/bin/perl

use FindBin;
use lib "$FindBin::Bin/../perl_lib";

use EPrints;
use EPrints::Test::ModuleSize;

use strict;
use warnings;

my $repo = @ARGV ? EPrints->new->repository( $ARGV[0] ) : undef;

my $sizes = EPrints::Test::ModuleSize::scan();
foreach my $name (sort { $sizes->{$b} <=> $sizes->{$a} } keys %$sizes)
{
	print sprintf("%40s %s\n", $name, EPrints::Utils::human_filesize( $sizes->{$name} ));
}

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

