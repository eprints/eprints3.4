#!/usr/bin/perl

use Test::More tests => 9;

use strict;
use warnings;

BEGIN { use_ok( "EPrints" ); }
BEGIN { use_ok( "EPrints::Test" ); }

my $repoid = EPrints::Test::get_test_id();

my $ep = EPrints->new();
isa_ok( $ep, "EPrints", "EPrints->new()" );
if( !defined $ep ) { BAIL_OUT( "Could not obtain the EPrints System object" ); }

my $repo = $ep->repository( $repoid );
isa_ok( $repo, "EPrints::Repository", "Get a repository object ($repoid)" );
if( !defined $repo ) { BAIL_OUT( "Could not obtain the Repository object" ); }

# render tests

my $xhtml;

$xhtml = EPrints::Time::render_date( $repo, '2010' );
is($xhtml->toString, '2010', 'render_date(YYYY)');

$xhtml = EPrints::Time::render_date( $repo, '2010-06-02' );
is($xhtml->toString, '2 June 2010', 'render_date(YYYY-MM-DD)');

$xhtml = EPrints::Time::render_short_date( $repo, '2010-06-02' );
is($xhtml->toString, '02 Jun 2010', 'render_date(YYYY-MM-DD)');

# misc

my $dt;
my @t;

@t = EPrints::Time::utc_datetime();
is($t[0], (gmtime())[5]+1900, 'utc_datetime() year');

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

