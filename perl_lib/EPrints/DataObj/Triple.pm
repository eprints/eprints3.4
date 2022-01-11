######################################################################
#
# EPrints::DataObj::Triple
#
######################################################################
#
#
######################################################################


=pod

=for Pod2Wiki

=head1 NAME

B<EPrints::DataObj::Triple> - RDF Triple

=head1 DESCRIPTION

Provides a subject-predicate-object representation of a piece of 
metadata.

=head1 CORE METADATA FIELDS

=over 4

=item tripleid (counter)

Unique ID for the triple.

=item primary_resource (id)

The local URI of the data object from which this data comes.

=item secondary_resource (id)

The URI of the other resource, if any, to which this triple refers.
E.g. the event/ext-foo

=item subject (longtext)

The subject part of the triple.

=item predicate (longtext)

The predicate part of the triple.

=item object (longtext)

The object part of the triple.

=item type (longtext)

The XSD datatype for the object if it is not a value rather than a
resource.

=item lang (longtext)

The XSD language for the object if it is not a value rather than a
resource.

=back

=head1 REFERENCES AND RELATED OBJECTS

None.

=head1 INSTANCE VARIABLES

See L<EPrints::DataObj|EPrints::DataObj#INSTANCE_VARIABLES>.

=head1 METHODS

=cut
######################################################################

package EPrints::DataObj::Triple;

@ISA = ( 'EPrints::DataObj' );

use EPrints;

use strict;


######################################################################
=pod

=head2 Class Methods

=cut
######################################################################

######################################################################
=pod

=over 4

=item $thing = EPrints::DataObj::Triple->get_system_field_info

Core fields contained in a Web access.

=cut
######################################################################

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
=pod

=item $dataset = EPrints::DataObj::Triple->get_dataset_id

Returns the ID of the L<EPrints::DataSet> object to which this record 
belongs.

=cut
######################################################################

sub get_dataset_id
{
	return "triple";
}


1;


######################################################################
=pod

=back

=head1 SEE ALSO

L<EPrints::DataObj> and L<EPrints::DataSet>.

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

