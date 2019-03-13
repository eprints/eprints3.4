use strict;
use Test::More tests => 6;

BEGIN { use_ok( "EPrints" ); }
BEGIN { use_ok( "EPrints::Test" ); }

my $session = EPrints::Test::get_test_session();
my $repository = $session->get_repository;

my $field = EPrints::MetaField->new(
	repository => $repository,
	name => "test",
	type => "text",
	);

my $value = chr(0x169) . " X '\"&++";

is( $field->get_id_from_value( $session, undef ), "NULL", "undef->NULL" );
is( $field->get_value_from_id( $session, "NULL" ), undef, "NULL->''" );

my $id = $field->get_id_from_value( $session, $value );
is( $field->get_value_from_id( $session, $id ), $value, "value->id->value" );

$field = EPrints::MetaField->new(
	repository => $repository,
	name => "test",
	type => "name",
	);

my $name = {
	family => "XxXx '+:^%".chr(0x169),
	given => "XxXx '+:^%".chr(0x169),
	honourific => "DR.",
};

$id = $field->get_id_from_value( $session, $name );
is_deeply( $field->get_value_from_id( $session, $id ), $name, "name->id->name" );


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

