######################################################################
#
# EPrints::MetaField::Timestamp;
#
######################################################################
#
#
######################################################################

=pod

=head1 NAME

B<EPrints::MetaField::Timestamp> - a date/time

=head1 DESCRIPTION

A date/time that defaults to the current time in UTC.

=over 4

=cut


package EPrints::MetaField::Timestamp;

use strict;
use warnings;

use EPrints::MetaField::Time;
our @ISA = qw( EPrints::MetaField::Time );

sub get_default_value
{
	return EPrints::Time::get_iso_timestamp();
}

sub is_type
{
	my( $self, @types ) = @_;

	for(@types)
	{
		return 1 if $_ eq "time";
		return 1 if $_ eq "timestamp";
	}

	return 0;
}

######################################################################
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

