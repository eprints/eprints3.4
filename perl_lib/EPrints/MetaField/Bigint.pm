######################################################################
#
# EPrints::MetaField::Bigint
#
######################################################################
#
#
######################################################################

=pod

=for Pod2Wiki

=head1 NAME

B<EPrints::MetaField::Bigint> - big integer

=head1 DESCRIPTION

Signed integer in the range -9223372036854775808 to 9223372036854775807.

=over 4

=cut

package EPrints::MetaField::Bigint;

use strict;
use warnings;

use EPrints::MetaField::Int;
our @ISA = qw( EPrints::MetaField::Int );

sub get_sql_type
{
	my( $self, $session ) = @_;

	return $session->get_database->get_column_type(
		$self->get_sql_name(),
		EPrints::Database::SQL_BIGINT,
		!$self->get_property( "allow_null" ),
		undef,
		undef,
		$self->get_sql_properties,
	);
}

sub get_property_defaults
{
    my( $self ) = @_;
    my %defaults = $self->SUPER::get_property_defaults;
    $defaults{digits} = 18;
    return %defaults;
}


######################################################################
1;

=head1 COPYRIGHT

=begin COPYRIGHT

Copyright 2023 University of Southampton.
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

