=head1 NAME

EPrints::Test::Repository

=cut

use Test::More tests => 4;

BEGIN { use_ok( "EPrints" ); }
BEGIN { use_ok( "EPrints::Test" ); }

{
package EPrints::Test::Repository;

our @ISA = qw( EPrints::Repository );

	sub _load_config
	{
		# reset mem usage ready for the first call to a _load method below
		EPrints::Test::human_mem_increase();

		return &EPrints::Repository::_load_config;
	}
	sub _load_workflows
	{
		Test::More::diag( "\t_load_config=" . EPrints::Test::human_mem_increase() );

		my $rc = &EPrints::Repository::_load_workflows;

		Test::More::diag( "\t_load_workflows=" . EPrints::Test::human_mem_increase() );

		return $rc;
	}
	sub _load_storage
	{
		my $rc = &EPrints::Repository::_load_storage;

		Test::More::diag( "\t_load_storage=" . EPrints::Test::human_mem_increase() );

		return $rc;
	}
	sub _load_namedsets
	{
		my $rc = &EPrints::Repository::_load_namedsets;

		Test::More::diag( "\t_load_namedsets=" . EPrints::Test::human_mem_increase() );

		return $rc;
	}
	sub _load_datasets
	{
		my $rc = &EPrints::Repository::_load_datasets;

		Test::More::diag( "\t_load_datasets=" . EPrints::Test::human_mem_increase() );

		return $rc;
	}
	sub _load_languages
	{
		my $rc = &EPrints::Repository::_load_languages;

		Test::More::diag( "\t_load_languages=" . EPrints::Test::human_mem_increase() );

		return $rc;
	}
	sub _load_templates
	{
		my $rc = &EPrints::Repository::_load_templates;

		Test::More::diag( "\t_load_templates=" . EPrints::Test::human_mem_increase() );

		return $rc;
	}
	sub _load_citation_specs
	{
		my $rc = &EPrints::Repository::_load_citation_specs;

		Test::More::diag( "\t_load_citation_specs=" . EPrints::Test::human_mem_increase() );

		return $rc;
	}
	sub _load_plugins
	{
		my $rc = &EPrints::Repository::_load_plugins;

		Test::More::diag( "\t_load_plugins=" . EPrints::Test::human_mem_increase() );

		return $rc;
	}
}

diag( "LOAD=".EPrints::Test::human_mem_increase() );
diag( "Repository-Specific Data" );
my $repository = EPrints::Test::Repository->new( EPrints::Test::get_test_id() );

EPrints::Test::mem_increase(0); # Reset
my $session = EPrints::Test::get_test_session();
diag( "Session=".EPrints::Test::human_mem_increase() );

ok(defined $repository, "test repository creation");
ok(defined $session, "test session creation");

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

