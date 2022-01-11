######################################################################
#
# EPrints::DataObj::RichDataObj
#
######################################################################
#
#
######################################################################


=pod

=for Pod2Wiki

=head1 NAME

B<EPrints::DataObj::RichDataObj> - A richer version of a data object

=head1 DESCRIPTION

UNDER DEVELOPMENT

Designed to extend L<EPrints::DataObj> in a number of generically 
useful ways, (e.g. add revision history). B<Not currently used by any
data object classes>.

Not designed to be instantiated directly.

=head1 CORE METADATA FIELDS

None.

=head1 REFERENCES AND RELATED OBJECTS

None.

=head1 INSTANCE VARIABLES

See L<EPrints::DataObj|EPrints::DataObj#INSTANCE_VARIABLES>.

=head1 METHODS

=cut
######################################################################

package EPrints::DataObj::RichDataObj;

use EPrints;
use EPrints::DataObj;

@ISA = ( 'EPrints::DataObj' );

use strict;


######################################################################
=pod

=head2 Class Methods

=cut
######################################################################

######################################################################
=pod

=over 4 

=item $dataset = EPrints::DataObj::RichDataObj->get_dataset_id

Returns the ID of the L<EPrints::DataSet> object to which this record
belongs.

=cut
######################################################################

sub get_dataset_id { "rich" }


######################################################################
=pod

=item $indexable = EPrints::DataObj::RichDataObj->indexable

Always returns C<true>, as a rich data objects.

=cut
######################################################################

sub indexable { return 1; }


######################################################################
=pod

=item $indexable = EPrints::DataObj::RichDataObj->get_system_field_info

Returns an array describing the system metadata of the rich data 
object dataset.

In fact, there are no fields for the rich data object dataset, as it 
is an abstract dataset.

=cut
######################################################################

sub get_system_field_info
{
  my( $class ) = @_;

  return
  (
  );
}


######################################################################
=pod

=item $richdataobj = EPrints::DataObj::RichDataObj->create_obj( $session, $data )

Creates and returns rich data object based on data C<$data>.

=cut
######################################################################

sub create_obj
{
  my( $class, $session, $data ) = @_;

  my $obj = $class->create_from_data( $session, $data );

  return $obj;
}


######################################################################
=pod

=item EPrints::DataObj::RichDataObj->delete_obj( $session )

Deletes rich data object.

=cut
######################################################################

sub delete_obj
{
  my( $self, $session ) = @_;

  $self->delete;
}


######################################################################
=cut

=back

=head2 Object Methods

=cut
######################################################################

######################################################################
=pod

=over 4

=item $path = $richdataobj->local_path

Returns local path for rich data object.

Needed as well as l<EPrints::DataObj#local_path>.

=cut
######################################################################

sub local_path
{
  my( $self ) = @_;

  my $datasetid = $self->dataset->base_id;
  my $objectid = $self->id;
  my $lp = $self->{session}->get_repository->get_conf("archiveroot" )."/history/".$datasetid."/".$objectid;
  print STDERR "(EPrints::DataObj::RichDataObj::local_path) $datasetid/$objectid local_path = '$lp'\n";

  return $lp;
}


######################################################################
=pod

=item $richdataobj->commit( [ $force ] )

Commit handler to maintain the C<rev_number>.

Set C<$force> to C<true> toforce commit, even if there is no changes.

=cut
######################################################################

sub commit
{
  my( $self, $force ) = @_;

  $self->update_triggers();
        
  if( !defined $self->{changed} || scalar( keys %{$self->{changed}} ) == 0 )
  {
    return 1 unless $force; # don't do anything if there isn't anything to do
  }
  if( $self->{non_volatile_change} )
  {
    $self->set_value( "rev_number", ($self->get_value( "rev_number" )||0) + 1 );    
  }

  return $self->SUPER::commit( $force );
}


######################################################################
=pod

=item $richdataobj->get_control_url

Returns the control URL for this rich data object.

=cut
######################################################################

sub get_control_url
{
  my( $self ) = @_;

  my $i = $self->get_dataset_id;
  return $self->{session}->get_repository->get_conf( "perl_url" )."/users/home?screen=Workflow::View&dataset=${i}&dataobj=".$self->get_value( "${i}id" );
}

######################################################################
=pod

=back

=head2 Utility Methods

=cut
######################################################################

######################################################################
=pod

=over 4

=item EPrints::DataObj::RichDataObj::history_update_trigger( $session, $obj )

Utility method for updating the revision history on the rich data 
object.

=cut
######################################################################

sub history_update_trigger
{
  my( $session, $obj ) = @_;

  my $datasetid = $obj->dataset->base_id;
  return unless defined $session->config( "history_enable", $datasetid );

  my %opts; # fake it for now
  my $action = exists $opts{action} ? $opts{action} : "modify";
  my $details = exists $opts{details} ? $opts{details} : join('|', sort keys %{$obj->{changed}}),

  my $user = exists $opts{user} ? $opts{user} : $session->current_user;
  $user = $obj if $obj->dataset->base_id eq "user"; # this is the user dataset

  my $userid = defined $user ? $user->id : undef;
  my $rev_number = $obj->value( "rev_number" ) || 0;

  my $event = $session->dataset( "history" )->create_dataobj(
  {
    _parent=>$obj,
    userid=>$userid,
    datasetid=>$datasetid,
    objectid=>$obj->id,
    revision=>$rev_number,
    action=>$action,
    details=>$details,
  });

  $event->set_dataobj_xml( $obj ); # what is this?
};

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

