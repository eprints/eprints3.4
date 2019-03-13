package EPrints::Test::ModuleSize;

=head1 NAME

EPrints::Test::ModuleSize - calculate the footprint of a module

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use Devel::Size;

use strict;

sub scan
{
	return _scan( "EPrints", {} );
}

sub _scan
{
	my( $name, $sizes ) = @_;

	no strict 'refs';
	while(my( $k, $v ) = each %{"${name}::"})
	{
		# class
		if( $k =~ s/::$// )
		{
			next if $k eq "SUPER";
			_scan( $name . "::" . $k, $sizes);
		}
		# glob
		else
		{
			$sizes->{$name} += Devel::Size::size( $v );
		}
	}

	return $sizes;
}

1;

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

