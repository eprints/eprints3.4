######################################################################
#
# EPrints::Bench
#
######################################################################
#
#
######################################################################

=pod

=for Pod2Wiki

=head1 NAME

B<EPrints::Bench> - Class for benchmarking EPrints.

=head1 DESCRIPTION

Tools for benchmarking performance of EPrints Repository software.

=head1 METHODS

=cut

package EPrints::Bench;

use Time::HiRes qw( gettimeofday );

our @ids = ();

our $totals = {};

our $starts = {};

######################################################################
=pod

=over 4

=item EPrints::Bench::clear()

Empties C<@ids> array and C<$totals> and C<$starts> hash references. 
(So a new set of benchmarking task can be undertaken).

=cut
######################################################################

sub clear
{
	@ids = ();
	$totals = {};
	$starts = {};
}

######################################################################
=pod

=item EPrints::Banch::hitime()

Returns an integer representing the number of microseconds since the 
start of the epoch.

=cut
######################################################################

sub hitime
{
	my( $s,$ms ) = gettimeofday();

	return $s*1000000+$ms;
}

######################################################################
=pod

=item EPrints::Bench::enter( $id )

Sets the (microseconds since start of epoch) start time for specified 
task with C<$id>.

=cut
######################################################################

sub enter
{
	my( $id ) = @_;

	if( defined $starts->{$id} )
	{
		die "Double entry in $id";
	}

	push @ids, $id;
	$starts->{$id} = hitime();
}

######################################################################
=pod

=item EPrints::Bench::leave( $id )

Sets the total time (in microseconds) for a specified task with C<$id>
based on the time since that set for same ID by 
L<EPrints::Bench::enter|EPrints::Bench#enter>.

=cut
######################################################################

sub leave
{
	my( $id ) = @_;

	if( !defined $starts->{$id} )
	{
		die "Leave without enter in $id";
	}

	$totals->{$id}+=hitime()-$starts->{$id};	
	delete $starts->{$id};
}

######################################################################
=pod

=item EPrints::Bench::totals()

Prints the individual microseconds for each task carried out since 
benchmarking was started or last cleared.

=cut
######################################################################

sub totals
{
	print STDERR "TOTALS\n";
	my %seen;
	foreach ( @ids )
	{
		next if $seen{$_};
		$seen{$_} = 1;
		print STDERR sprintf("%16d - %s\n", $totals->{$_} , $_);
	}
}
BEGIN {
	enter( "MAIN" );
}
END {
	totals();
}
1;

=back

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

