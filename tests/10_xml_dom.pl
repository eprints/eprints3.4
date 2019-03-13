use strict;
use Test::More;

BEGIN {
	eval "require XML::DOM";
	if( $@ )
	{
		plan skip_all => "XML::DOM missing";
	}
	else
	{
		plan tests => 12;
	}
}

use EPrints::SystemSettings;
$EPrints::SystemSettings::conf->{enable_gdome} = 0;
$EPrints::SystemSettings::conf->{enable_libxml} = 0;
use_ok( "EPrints" );
use_ok( "EPrints::Test" );
use_ok( "EPrints::Test::XML" );
$EPrints::XML::CLASS = $EPrints::XML::CLASS; # suppress used-only-once warning
BAIL_OUT( "Didn't load expected XML library" )
	if $EPrints::XML::CLASS ne "EPrints::XML::DOM";

my $repo = EPrints::Test::get_test_repository();

&EPrints::Test::XML::xml_tests( $repo );

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

