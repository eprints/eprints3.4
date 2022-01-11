######################################################################
#
# EPrints::System::freebsd
#
######################################################################
#
#
######################################################################


=pod

=for Pod2Wiki

=head1 NAME

B<EPrints::System::freebsd> - Wrappers for FreeBSD system calls.

=head1 DESCRIPTPION

This class provides FreeBSD-specific system calls required by EPrints.

This class inherits from L<EPrints::System>.

=head1 INSTANCE VARIABLES

See L<EPrints::System|EPrints::System#INSTANCE_VARIABLES>.

=head1 METHODS

None, as L<EPrints::System> methods were built around a FreeBSD-based
system.

=cut
######################################################################

package EPrints::System::freebsd;

@ISA = qw( EPrints::System );

use strict;

1;

######################################################################
=pod

=head1 SEE ALSO

L<EPrints::System>

=head1 COPYRIGHT

=begin COPYRIGHT

Copyright 2022 University of Southampton.
EPrints 3.4 is supplied by EPrints Services.

http://www.eprints.org/eprints-3.4/

=end COPYRIGHT

=begin LICENSE

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

=end LICENSE

