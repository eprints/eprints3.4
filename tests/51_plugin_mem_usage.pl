=head1 NAME

EPrints::Test::PluginFactory

=cut

use Test::More tests => 3;

BEGIN { use_ok( "EPrints" ); }
BEGIN { use_ok( "EPrints::Test" ); }

our %PLUGIN_MEM_USAGE;

{
package EPrints::Test::PluginFactory;

our @ISA = qw( EPrints::PluginFactory );

	sub _load_plugin
	{
		my( $self, $data, $repository, $fn, $class ) = @_;

		EPrints::Test::mem_increase(0); # Reset

		my $rc = $self->SUPER::_load_plugin( @_[1..$#_] );

		$PLUGIN_MEM_USAGE{$class} = EPrints::Test::mem_increase();

		return $rc;
	}
}
{
package EPrints::Test::Repository;

our @ISA = qw( EPrints::Repository );

	sub _load_plugins
	{
		my( $self ) = @_;

		$self->{plugins} = EPrints::Test::PluginFactory->new( $self );

		return defined $self->{plugins};
	}
}

my $repository = EPrints::Test::Repository->new( EPrints::Test::get_test_id() );

ok(defined $repository, "test repository creation");

my %usage = %PLUGIN_MEM_USAGE;

my $show = $ENV{PLUGIN_MEM_USAGE} || 5;

diag( "\nPlugin Memory Usage" );
foreach my $class (sort { $usage{$b} <=> $usage{$a} } keys %usage)
{
	diag( "$class=".EPrints::Utils::human_filesize( $usage{$class} ) );
	last unless --$show;
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

