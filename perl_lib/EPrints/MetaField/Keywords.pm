######################################################################
#
# EPrints::MetaField::Keywords;
#
######################################################################
#
#
######################################################################

=pod

=head1 NAME

B<EPrints::MetaField::Keywords> - no description

=head1 DESCRIPTION

not done

=over 4

=cut

package EPrints::MetaField::Keywords;

use strict;
use warnings;

BEGIN
{
	our( @ISA );

	@ISA = qw( EPrints::MetaField::Id );
}

use EPrints::MetaField::Id;

sub get_sql_type
{
        my( $self, $session ) = @_;

        return $session->get_database->get_column_type(
                $self->get_sql_name(),
                EPrints::Database::SQL_CLOB,
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
        $defaults{match} = "EQ";
	$defaults{input_rows} = $EPrints::MetaField::FROM_CONFIG;
        $defaults{maxlength} = 2**31 - 1;
	$defaults{sql_index} = 0;
	$defaults{separator} = ",";
        return %defaults;
}

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

        if( $match eq "EQ" )
        {
                if( !EPrints::Utils::is_set( $search_value ) )
                {
                        return EPrints::Search::Condition->new(
                                        'is_null',
                                        $dataset,
                                        $self );
                }

                return EPrints::Search::Condition->new(
                                'like_list',
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

sub render_search_description
{
        my( $self, $session, $sfname, $value, $merge, $match ) = @_;

        my( $phraseid );
        if( $match eq "EQ" || $match eq "EX" )
        {
                $phraseid = "lib/searchfield:desc_has";
        }
        elsif( $merge eq "ANY" ) # match = "IN"
        {
                $phraseid = "lib/searchfield:desc_any_in";
        }
        else
        {
                $phraseid = "lib/searchfield:desc_all_in";
        }

        my $valuedesc = $self->render_search_value(
                $session,
                $value,
                $merge,
                $match );

        return $session->html_phrase(
                $phraseid,
                name => $sfname,
                value => $valuedesc );
}


sub split_search_value
{
        my( $self, $session, $value ) = @_;

        return split /$self->{separator}\s*/, $value;
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

