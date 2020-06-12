######################################################################
#
# EPrints::MetaField::Userid;
#
######################################################################
#
#
######################################################################

=pod

=head1 NAME

B<EPrints::MetaField::Userid> - a unique ID that represent a user within EPrints

=head1 DESCRIPTION

This MetaField allows the ID of the user (i.e. the auto-increment userid field) to be 
stored in the database but rendered/ordered based on the name for this user.

=over 4

=cut

package EPrints::MetaField::Userid;

use EPrints::MetaField::Id;

@ISA = qw( EPrints::MetaField::Id );

use strict;

sub get_value_label
{
        my( $self, $repo, $value ) = @_;

        my $user = EPrints::DataObj::User->new( $repo, $value );

        if( defined $user )
        {
                return $repo->make_text( $user->render_citation( "userid_field" ) );
        }

        return $self->SUPER::get_value_label( $repo, $value );
}

sub ordervalue_basic
{
        my( $self, $value, $repo, $langid ) = @_;

        my $user = EPrints::DataObj::User->new( $repo, $value );

        if( defined $user )
        {
                return $user->dataset->field( "name" )->ordervalue_basic( $user->value( "name" ), $repo, $langid );
        }

        return $self->SUPER::ordervalue_basic( $value, $repo, $langid );
}

sub render_single_value
{
        shift->get_value_label( @_ );
}

1;

=head1 COPYRIGHT

=for COPYRIGHT BEGIN

Copyright 2020 University of Southampton.
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

