######################################################################
#
# EPrints::DataObj::Triple
#
######################################################################
#
#
######################################################################


=head1 NAME

B<EPrints::DataObj::Triple> - RDF Triple

=head1 DESCRIPTION

Inherits from L<EPrints::DataObj>.

=head1 CORE FIELDS

=over 4

=item tripleid

Unique id for the triple.

=item primary_resource

The local URI of the EPrint that this data comes from.

=item secondary_resource

The URI of the other resource, if any, this data belongs to. Eg. the event/ext-foo

=item subject, predicate, object, type, lang

The parts of the triple.

=back

=head1 METHODS

=over 4

=cut

package EPrints::DataObj::Triple;

@ISA = ( 'EPrints::DataObj' );

use EPrints;

use strict;

=item $thing = EPrints::DataObj::Triple->get_system_field_info

Core fields contained in a Web access.

=cut

sub get_system_field_info
{
	my( $class ) = @_;

	return
	( 
		{ name=>"tripleid", type=>"counter", required=>1, can_clone=>0,
			sql_counter=>"tripleid" },

		{ name=>"primary_resource", type=>"id", required=>1, text_index=>0, sql_index=>1 },
		{ name=>"secondary_resource", type=>"id", required=>0, text_index=>0, sql_index=>1 },

		{ name=>"subject",   type=>"longtext", required=>1, text_index=>0, },
		{ name=>"predicate", type=>"longtext", required=>1, text_index=>0, },
		{ name=>"object",    type=>"longtext", required=>1, text_index=>0, },
		{ name=>"type",      type=>"longtext", required=>1, text_index=>0, },
		{ name=>"lang",      type=>"longtext", required=>1, text_index=>0, },
	);
}

######################################################################

=back

=head2 Class Methods

=over 4

=cut

######################################################################

######################################################################
=pod

=item $dataset = EPrints::DataObj::Triple->get_dataset_id

Returns the id of the L<EPrints::DataSet> object to which this record belongs.

=cut
######################################################################

sub get_dataset_id
{
	return "triple";
}

######################################################################

=head2 Object Methods

=cut

######################################################################

=item $dataobj->get_referent_id()

Return the fully qualified referent id.

=cut


1;

__END__

=back

=head1 SEE ALSO

L<EPrints::DataObj> and L<EPrints::DataSet>.

=cut


=head1 COPYRIGHT

=for COPYRIGHT BEGIN

Copyright 2018 University of Southampton.
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

