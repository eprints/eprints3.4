package EPrints::DataObj::RichDataObj;

# designed to extend DataObj in a number of generically useful ways
# eg add revision history

# not designed to be instantiated directly

use EPrints;
use EPrints::DataObj;

@ISA = ( 'EPrints::DataObj' );

use strict;

sub get_dataset_id { "rich" }

sub indexable { return 1; }

sub get_system_field_info
{
  my( $class ) = @_;

  return
  (
  );
}

sub create_obj
{
  my( $class, $session, $data ) = @_;

  my $obj = $class->create_from_data( $session, $data );

  return $obj;
}

sub delete_obj
{
  my( $self, $session ) = @_;

  $self->delete;
}

# needed as well as the version in DataObj
sub local_path
{
  my( $self ) = @_;

  my $datasetid = $self->dataset->base_id;
  my $objectid = $self->id;
  my $lp = $self->{session}->get_repository->get_conf("archiveroot" )."/history/".$datasetid."/".$objectid;
  print STDERR "(EPrints::DataObj::RichDataObj::local_path) $datasetid/$objectid local_path = '$lp'\n";

  return $lp;
}

# commit handler to maintain the rev_number - can this not be handled higher up?
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

sub get_control_url
{
  my( $self ) = @_;

  my $i = $self->get_dataset_id;
  my $conf_name = ( $self->{session}->get_repository->get_conf( "securehost" ) ? "https_cgiurl" : "http_cgiurl" );
  return $self->{session}->get_repository->get_conf( $conf_name )."/users/home?screen=Workflow::View&dataset=${i}&dataobj=".$self->get_value( "${i}id" );
}

# utility routine for updating the revision history on a dataobj

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

=head1 COPYRIGHT

=for COPYRIGHT BEGIN

Copyright 2021 University of Southampton.
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

