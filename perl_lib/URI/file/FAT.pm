=head1 NAME

URI::file::FAT

=cut

package URI::file::FAT;

require URI::file::Win32;
@ISA=qw(URI::file::Win32);

sub fix_path
{
    shift; # class
    for (@_) {
	# turn it into 8.3 names
	my @p = map uc, split(/\./, $_, -1);
	return if @p > 2;     # more than 1 dot is not allowed
	@p = ("") unless @p;  # split bug? (returns nothing when splitting "")
	$_ = substr($p[0], 0, 8);
        if (@p > 1) {
	    my $ext = substr($p[1], 0, 3);
	    $_ .= ".$ext" if length $ext;
	}
    }
    1;  # ok
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

