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

B<EPrints::Search::Condition::LikeList> - "like_list" search condition

=head1 DESCRIPTION

Matches items that are in a list (e.g. a set of comma separated keywords) whilst ignoring case

=cut

package EPrints::Search::Condition::LikeList;

use EPrints::Search::Condition::Comparison;

@ISA = qw( EPrints::Search::Condition::Comparison );

use strict;

sub new
{
        my( $class, @params ) = @_;

        my $self = {};
        $self->{op} = "like_list";
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
	my $sep = $self->{field}->{separator};

	my $identifier = $db->quote_identifier( $table, $sql_name );
	my $value = EPrints::Database::prep_like_value( $self->{params}->[0] );

	return sprintf( _make_REPLACE( $sep ) . $db->sql_LIKE." '%%%s%s%s%%' OR " . _make_REPLACE( $sep ) . $db->sql_LIKE." '%s%s%%' OR " . _make_REPLACE( $sep ) . $db->sql_LIKE." '%%%s%s' OR " . _make_REPLACE( $sep ) . $db->sql_LIKE." '%s'",
                $identifier, $sep, $value, $sep,
		$identifier, $value, $sep, 
		$identifier, $sep, $value,
		$identifier, $value,
	);
}

sub _make_REPLACE 
{
	my( $separator ) = @_;	
	return " REPLACE(%s, '".$separator." ', '$separator') ";
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

