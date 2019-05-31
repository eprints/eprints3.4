######################################################################
#
# EPrints::DataObj::Citation
#
######################################################################
#
#
######################################################################


=pod

=head1 NAME

B<EPrints::DataObj::Citation> - An citation for a DataObj.

=head1 DESCRIPTION

This class describes a single item in the citation dataset. A citation
object describes a formatted citation for a single item in another
dataset.

=head1 METADATA

=over 4

=item citationid (int)

The unique numerical ID of this citation event. 

=item datasetid (text)

The name of the dataset to which the item that has a citation belongs. "eprint"
is used for eprints, rather than the inbox, buffer etc.

=item objectid (int)

The numerical ID of the object in the dataset. 

=item style (text)

The style of citation for a particular item.  Each DataObj may have nany different 
citation styles and defined in citations/<DataObject>

=item citation_text (text)

The actually text generated for the citation by render_citation.

=item timestamp (time)

The moment at which this citation was generated.

=back

=head1 METHODS

=over 4

=cut

package EPrints::DataObj::Citation;

@ISA = ( 'EPrints::DataObj::SubObject' );

use EPrints;

use strict;

######################################################################
=pod

=item $field_info = EPrints::DataObj::Citation->get_system_field_info

Return the metadata field configuration for this object.

=cut
######################################################################

sub get_system_field_info
{
	my( $class ) = @_;

	return 
	( 
		{ name=>"citationid", type=>"counter", required=>1, can_clone=>0,
			sql_counter=>"citationid" }, 

		{ name=>"datasetid", type=>"id", text_index=>0, }, 

		{ name=>"objectid", type=>"int", }, 

		{ name=>"style", type=>"text", sql_index => 1 },
 
                { name=>"citation_text", type=>"longtext", text_index=>0, },

		{ name=>"timestamp", type=>"timestamp", }, 

	);
}



######################################################################
=pod

=item $dataset = EPrints::DataObj::Citation->get_dataset_id

Returns the id of the L<EPrints::DataSet> object to which this record belongs.

=cut
######################################################################

sub get_dataset_id
{
	return "citation";
}



######################################################################
=pod

=item $citation->commit 

Commit the formatted text generated for a citation

=cut
######################################################################

sub commit 
{
	my( $self, $force ) = @_;

	my $rv = $self->SUPER::commit( $force );

        return $rv;	
}


######################################################################
# =pod
# 
# =item EPrints::DataObj::Citation::create( $session, $data );
# 
# Create a new citation  object from this data. Unlike other create
# methods this one does not return the new object as it's never 
# needed, and would increase the load of modifying items.
# 
# Also, this does not queue the fields for indexing.
# 
# =cut
######################################################################

sub create
{
	my( $session, $data ) = @_;

	return EPrints::DataObj::Citation->create_from_data( 
		$session, 
		$data,
		$session->dataset( "citation" ) );
}

######################################################################
=pod

=item $defaults = EPrints::DataObj::Citation->get_defaults( $session, $data )

Return default values for this object based on the starting data.

=cut
######################################################################

sub get_defaults
{
	my( $class, $session, $data, $dataset ) = @_;
	
	$class->SUPER::get_defaults( $session, $data, $dataset );

	return $data;
}

######################################################################
#
# $xhtml = $citation->render_citation( $style, $url )
#
# This overrides the normal citation as a citation cannot have its
# own citation.
#
######################################################################

sub render_citation
{
	return undef;
}

######################################################################
=pod

=item $xhtml = $citation->render

A citation cannot have a rendering of itself.

=cut
######################################################################

sub render
{
	my( $self ) = @_;
	
	return undef;
}

######################################################################
=pod

=item $object = $citation->get_dataobj

Returns the object to which this citation relates.

=cut
######################################################################

sub get_dataobj
{
	my( $self ) = @_;

	return unless( $self->is_set( "datasetid" ) );
	my $ds = $self->{session}->get_repository->get_dataset( $self->get_value( "datasetid" ) );
	return $ds->get_object( $self->{session}, $self->get_value( "objectid" ) );
}

######################################################################
1;
######################################################################
=pod

=back

=cut


=head1 COPYRIGHT

=for COPYRIGHT BEGIN

Copyright 2019 University of Southampton.
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

