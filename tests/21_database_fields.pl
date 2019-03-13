use strict;
use Test::More tests => 17;

BEGIN { use_ok( "EPrints" ); }
BEGIN { use_ok( "EPrints::Test" ); }

my $session = EPrints::Test::get_test_session( 0 );
ok(defined $session, 'opened an EPrints::Session object (noisy, no_check_db)');

# a dataset that won't mind being broken
my $dataset = $session->dataset( "upload_progress" );

my $db = $session->get_db;

my $field;

# singular add/remove
$field = EPrints::MetaField->new(
	dataset => $dataset,
	type => "text",
	name => "unit_tests",
	sql_index => 1,
);
ok( $db->add_field( $dataset, $field ), "add field" );
ok( $db->has_column( $dataset->get_sql_table_name, $field->get_sql_name ), "expected column name" );
ok( $db->remove_field( $dataset, $field ), "remove field" );

# single rename
$field = EPrints::MetaField->new(
	dataset => $dataset,
	type => "text",
	name => "unit_tests",
);
ok( $db->add_field( $dataset, $field ), "add field" );
$field->set_property( name => "unit_tests2" );
ok( $db->rename_field( $dataset, $field, "unit_tests" ), "rename field" );
ok( $db->has_column( $dataset->get_sql_table_name, $field->get_sql_name ), "expected column name" );
ok( $db->remove_field( $dataset, $field ), "remove field" );

# multiple add/remove
$field = EPrints::MetaField->new(
	dataset => $dataset,
	type => "text",
	name => "unit_tests",
	multiple => 1,
);
ok( $db->add_field( $dataset, $field ), "add multiple field" );
ok( $db->has_table( $dataset->get_sql_sub_table_name( $field ) ), "expected table name" );
ok( $db->remove_field( $dataset, $field ), "remove multiple field" );

# multiple rename
$field = EPrints::MetaField->new(
	dataset => $dataset,
	type => "text",
	name => "unit_tests",
	multiple => 1,
);
ok( $db->add_field( $dataset, $field ), "add multiple field" );
$field->set_property( name => "unit_tests2" );
ok( $db->rename_field( $dataset, $field, "unit_tests" ), "rename multiple field" );
ok( $db->has_table( $dataset->get_sql_sub_table_name( $field ) ), "expected table name" );
ok( $db->remove_field( $dataset, $field ), "remove multiple field" );

$session->terminate;

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

