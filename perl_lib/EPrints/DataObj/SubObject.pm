######################################################################
#
# EPrints::DataObj::SubObject
#
######################################################################
#
#
######################################################################


=pod

=for Pod2Wiki

=head1 NAME

B<EPrints::DataObj::SubObject> - virtual class to support sub-objects

=head1 DESCRIPTION

This virtual class provides some utility methods to objects that are 
sub-objects of other data objects.

It expects to find C<datasetid> and C<objectid> fields to identify 
the parent object.

=head1 CORE METADATA FIELDS

None.

=head1 REFERENCES AND RELATED OBJECTS

None.

=head1 INSTANCE VARIABLES

See L<EPrints::DataObj|EPrints::DataObj#INSTANCE_VARIABLES>.

=head1 METHODS

=cut

######################################################################

package EPrints::DataObj::SubObject;

@ISA = qw( EPrints::DataObj );

use strict;


######################################################################
=pod

=head2 Constructor Methods

=cut
######################################################################

######################################################################
=pod

=over 4

=item $dataobj = EPrints::DataObj::SubObject->new_from_data( $session, $data, [ $dataset ] )

Constructs and returns a new sub-object from the C<$data> provided.

Looks for a special C<_parent> element in C<$data> and uses it to set 
the parent object, if defined.

C<$dataset> is determined from the class if not provided.

=cut
######################################################################

sub new_from_data
{
	my( $class, $session, $data, $dataset ) = @_;

	my $parent = delete $data->{_parent};

	my $self = $class->SUPER::new_from_data( $session, $data, $dataset );

	if( defined $parent )
	{
		$self->set_parent( $parent );
	}

	return $self;
}


######################################################################
=pod

=item $dataobj = EPrints::DataObj::SubObject->create_from_data( $session, $data, [ $dataset ] )

Creates and returns a new sub-object from the C<$data> provided.

Looks for a special B<_parent> element in $data and uses it to create 
default values for B<datasetid> and B<objectid> if parent is available 
and those fields exist on the object.

C<$dataset> is determined from the class if not provided.

=cut
######################################################################

sub create_from_data
{
	my( $class, $session, $data, $dataset ) = @_;

	my $parent = $data->{_parent};
	if( defined( $parent ) )
	{
		if( $dataset->has_field( "datasetid" ) ) 
		{
			$data->{datasetid} = $parent->dataset->base_id;
		}
		if( $dataset->has_field( "objectid" ) )
		{
			$data->{objectid} = $parent->id;
		}
	}

	return $class->SUPER::create_from_data( $session, $data, $dataset );
}


######################################################################
=pod

=back

=head2 Object Methods

=cut
######################################################################

######################################################################
=pod

=over 4

=item $parent = $dataobj->get_parent( [ $datasetid, $objectid ] )

Gets and caches the parent data object. If C<$datasetid> and/or 
C<$objectid> are specified uses these values rather than the stored 
values.

Subsequent calls to C<get_parent> will return the cached object, 
regardless of C<$datasetid> and C<$objectid>.

Has alias:

 $dataobj->parent

=cut
######################################################################

sub parent { shift->get_parent( @_ ) }
sub get_parent
{
	my( $self, $datasetid, $objectid ) = @_;

	return $self->{_parent} if defined( $self->{_parent} );

	my $session = $self->get_session;

	$datasetid = $self->get_parent_dataset_id unless defined $datasetid;
	$objectid = $self->get_parent_id unless defined $objectid;

	my $ds = $session->dataset( $datasetid );

	my $parent = $ds->get_object( $session, $objectid );
	$self->set_parent( $parent );

	return $parent;
}


######################################################################
=pod

=item $parent = $dataobj->set_parent( $parent )

Sets C<_parent> attribute to the provide C<$parent> data object.

=cut
######################################################################

sub set_parent
{
	my( $self, $parent ) = @_;

	$self->{_parent} = $parent;
}


######################################################################
=pod

=item $id = $dataobj->get_parent_dataset_id

Returns the ID of the dataset two which the parent data object 
belongs.

=cut
######################################################################

sub get_parent_dataset_id
{
	my( $self ) = @_;

	return $self->get_value( "datasetid" );
}


######################################################################
=pod

=item $id = $dataobj->get_parent_id

Returns the ID of the parent data object.

=cut
######################################################################

sub get_parent_id
{
	my( $self ) = @_;

	return $self->get_value( "objectid" );
}


######################################################################
=pod

=item $r = $dataobj->permit( $priv, [ $user ] )

Checks parent data object for as well as this data object gives 
permission for C<$priv>. If C<$user> specified then permissions must
also be applicable to that user.

Returns C<true> if permitted, otherwise returns C<false>

=cut
######################################################################

sub permit
{
	my( $self, $priv, $user ) = @_;

	my $r = 0;

	$r |= $self->SUPER::permit( $priv, $user );

	my $parent = $self->parent;
	return $r if !defined $parent;

	my $privid = $self->{dataset}->base_id;
	return $r if $priv !~ s{^$privid/}{};

	# creating or destroying a sub-object is equivalent to editing its parent
	$priv = "edit" if $priv eq "create" || $priv eq "destroy";

	# eprint/view => eprint/archive/view
	my $dataset = $parent->get_dataset;
	$priv = $dataset->id ne $dataset->base_id ?
		join('/', $dataset->base_id, $dataset->id, $priv) :
		join('/', $dataset->base_id, $priv);

	$r |= $self->parent->permit( $priv, $user );
	return $r;
}


######################################################################
=pod

=item $dataobj->has_owner( $user )

Check whether the C<$user> provided is the owner of this sub-object,
which is determined by checking the owner of the parent data object.

Returns C<true> if parent data object exists and has C<$user> as the 
owner. Otherwise, returns C<false>.

=cut
######################################################################

sub has_owner
{
	my( $self, $user ) = @_;

	my $parent = $self->parent;
	return 0 if !defined $parent;

	return $parent->has_owner( $user );
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
