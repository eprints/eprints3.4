######################################################################
#
# EPrints::MetaField::Idci;
#
######################################################################
#
#
######################################################################

=pod

=head1 NAME

B<EPrints::MetaField::Idci> - a case-insensitive identifier string

=head1 DESCRIPTION

Use Idci fields whenever you are storing textual data that needs to be matched exactly but case insensivity is required (e.g. usernames and email addresses).

Characters that are not valid XML 1.0 code-points will be replaced with the Unicode replacement character.

=over 4

=cut

package EPrints::MetaField::Idci;

use EPrints::MetaField::Id;

@ISA = qw( EPrints::MetaField::Id );

use strict;

sub get_search_conditions
{
        my( $self, $session, $dataset, $search_value, $match, $merge,
                $search_mode ) = @_;

        if( $match eq "SET" )
        {
                return EPrints::Search::Condition->new(
                                "is_not_null",
                                $dataset,
                                $self );
        }

        if( $match eq "EX" )
        {
                if( !EPrints::Utils::is_set( $search_value ) )
                {
                        return EPrints::Search::Condition->new(
                                        'is_null',
                                        $dataset,
                                        $self );
                }

                return EPrints::Search::Condition->new(
                                'like',
                                $dataset,
                                $self,
                                $search_value );
        }

        return $self->get_search_conditions_not_ex(
                        $session,
                        $dataset,
                        $search_value,
                        $match,
                        $merge,
                        $search_mode );
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

