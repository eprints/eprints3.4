######################################################################
#
# EPrints::Search::Condition::NameMatch
#
######################################################################
#
#
######################################################################

=pod

=head1 NAME

B<EPrints::Search::Condition::Like> - "Like" search condition

=head1 DESCRIPTION

Matches items that are the same ignoring case

=cut

package EPrints::Search::Condition::Like;

use EPrints::Search::Condition::Comparison;

@ISA = qw( EPrints::Search::Condition::Comparison );

use strict;

sub new
{
        my( $class, @params ) = @_;

        my $self = {};
        $self->{op} = "like";
        $self->{dataset} = shift @params;
        $self->{field} = shift @params;
        $self->{params} = \@params;

        return bless $self, $class;
}


sub logic
{
        my( $self, %opts ) = @_;

        my $prefix = $opts{prefix};
        $prefix = "" if !defined $prefix;

        my $db = $opts{session}->get_database;
        my $table = $prefix . $self->table;
        my $sql_name = $self->{field}->get_sql_name;

        return sprintf( "%s ".$db->sql_LIKE." '%s'",
                $db->quote_identifier( $table, $sql_name ),
                EPrints::Database::prep_like_value( $self->{params}->[0] ) );
}

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

