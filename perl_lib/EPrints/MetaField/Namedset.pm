######################################################################
#
# EPrints::MetaField::Namedset;
#
######################################################################
#
#
######################################################################

=pod

=head1 NAME

B<EPrints::MetaField::Namedset> - no description

=head1 DESCRIPTION

not done

=over 4

=cut

# set_name

package EPrints::MetaField::Namedset;

use strict;
use warnings;

BEGIN
{
	our( @ISA );

	@ISA = qw( EPrints::MetaField::Set );
}

use EPrints::MetaField::Set;

sub tags
{
	my( $self ) = @_;

	if( defined $self->{options} )
	{
		return @{$self->{options}};
	}
	return $self->{repository}->get_types( $self->{set_name} );
}

sub get_unsorted_values
{
	my( $self, $session, $dataset, %opts ) = @_;

	if( defined $self->{options} )
	{
		return @{$self->{options}};
	}
	my @types = $self->{repository}->get_types( $self->{set_name} );

	return @types;
}

sub render_option
{
	my( $self, $session, $value ) = @_;

	if( !defined $value )
	{
		return $self->SUPER::render_option( $session, $value );
	}

        if( defined $self->get_property("render_option") )
        {
                return $self->call_property( "render_option", $session, $value );
        }

	return $session->render_type_name( $self->{set_name}, $value );
}

sub get_property_defaults
{
	my( $self ) = @_;
	my %defaults = $self->SUPER::get_property_defaults;
	$defaults{set_name} = $EPrints::MetaField::REQUIRED;
	$defaults{options} = $EPrints::MetaField::UNDEF;
	return %defaults;
}

sub get_search_group { return 'set'; }

=item $ov = $field->ordervalue_basic( $value, $session, $langid )

Return $value as an order value that will be cmp().

For Namedset this returns the values in the order they are given in the named set.

=cut

sub ordervalue_basic
{
	my( $self, $value, $session, $langid ) = @_;

	my @types = $self->tags( $session );
	foreach my $i (0..$#types)
	{
		return sprintf("%06d", $i)
			if $types[$i] eq $value;
	}

	# this will always come after any known values
	return $value;
}


######################################################################
1;

=head1 COPYRIGHT

=for COPYRIGHT BEGIN

Copyright 2022 University of Southampton.
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

