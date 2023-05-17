######################################################################
#
# EPrints::DataObj::EventQueue
#
######################################################################
#
#
######################################################################


=pod

=for Pod2Wiki

=head1 NAME

B<EPrints::DataObj::EventQueue> - Scheduler/indexer event queue.

=head1 DESCRIPTION

Individual tasks for the EPrints event queue that can then be actioned
by the EPrints indexer in the background.

=head1 CORE METADATA FIELDS

=over 4

=item eventqueueid (uuid)

Either a UUID or a hash of the event (if created with 
L</create_unique>).

=item cleanup (boolean)

If set to C<true> removes this event once it has finished. Defaults to 
C<true>.

=item priority (int)

The priority for this event.

=item start_time (time)

The event should not be executed before this time.

=item end_time (time)

The event was last touched at this time.

=item status (set)

The status of this event. Can be C<waiting>, C<staged>, C<inprogress>, C<success>
or C<failed>. Defaults to C<waiting>.

=item description (longtext)

A human-readable description of this event (or error).

=item pluginid (id)

The L<EPrints::Plugin::Event> plugin id to call to execute this event.

=item action (id)

The name of the action to execute on the plugin (i.e. method name).

=item params (storable)

Parameters to pass to the action (a text serialisation).

=back

=head1 REFERENCES AND RELATED OBJECTS

=over 4

=item userid (itemref)

The user (if any) that was responsible for creating this event.

=head1 INSTANCE VARIABLES

See L<EPrints::DataObj|EPrints::DataObj#INSTANCE_VARIABLES>.

=back

=head1 METHODS

=cut

package EPrints::DataObj::EventQueue;

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

=item $event = EPrints::DataObj::EventQueue->create_unique( $session, $data, [ $dataset ] )

Returns a unique event queue task using the C<$data> provided. Setting
the C<eventqueueid> to a MD5 hash of the C<pluginid>, C<action> and
(if given) C<params>.

Returns C<undef> if such an event already exists.

If C<$dataset> is not provided generate from dataset ID of the class.

=cut
######################################################################

sub create_unique
{
    my( $class, $session, $data, $dataset ) = @_;

    $dataset ||= $session->dataset( $class->get_dataset_id );

    my $md5 = Digest::MD5->new;
    $md5->add( $data->{pluginid} );
    $md5->add( $data->{action} );
    $md5->add( EPrints::MetaField::Storable->freeze( $session, $data->{params} ) )
        if EPrints::Utils::is_set( $data->{params} );
    $data->{eventqueueid} = $md5->hexdigest;

    # No need to create a new event queue task if one already exists with the same params but if failed set to waiting.
    my $task = $dataset->dataobj( $data->{eventqueueid} );
    if ( defined $task )
    {
        if ( $task->get_value( "status" ) eq "failed" )
        {
            $task->set_value( "status", "waiting" );
            $task->commit;
            $session->log( "[".EPrints::Time::get_iso_timestamp()."] Resetting failed event ".$data->{eventqueueid}." to waiting." );
        }
        return $task;
    }

    # Some event queue plugins create 'staged' tasks that are logged by the indexer but executed by an external script, (e.g. video transcoding).
    my $plugin = $session->plugin( $data->{pluginid} );
    if ( defined $plugin )
    {
        if ( $plugin->{staged} || ( $plugin->can( 'is_staged_task' ) && $plugin->is_staged_task( $data ) ) )
        {
            $data->{status} = "staged";
            $data->{cleanup} = "FALSE";
        }
    }

    return $class->create_from_data( $session, $data, $dataset );
}


######################################################################
=pod

=item $event = EPrints::DataObj::EventQueue->new_from_hash( $session, $data, [ $dataset ] )

Returns the event that corresponds to the MD5 hash of the C<$data>
provided, (C<pluginid>, C<action> and C<params>).  Returns C<undef>
if no event queue task exists with a matching MD5 hash.

If C<$dataset> is not provided generate from dataset ID of the class.

=cut
######################################################################

sub new_from_hash
{
    my( $class, $session, $data, $dataset ) = @_;

    $dataset ||= $session->dataset( $class->get_dataset_id );

    my $md5 = Digest::MD5->new;
    $md5->add( $data->{pluginid} );
    $md5->add( $data->{action} );
    $md5->add( EPrints::MetaField::Storable->freeze( $session, $data->{params} ) )
        if EPrints::Utils::is_set( $data->{params} );
    my $eventqueueid = $md5->hexdigest;

    return $dataset->dataobj( $eventqueueid );
}

######################################################################
=pod

=back

=head2 Class Methods

=cut
######################################################################

######################################################################
=pod

=over 4

=item $metadata = EPrints::DataObj::EPrint->get_system_field_info

Returns an array describing the system metadata of the event queue 
dataset.

=cut
######################################################################

sub get_system_field_info
{
	return (
		{ name=>"eventqueueid", type=>"uuid", required=>1, },
		{ name=>"cleanup", type=>"boolean", default_value=>"TRUE", },
		{ name=>"priority", type=>"int", },
		{ name=>"start_time", type=>"timestamp", required=>1, },
		{ name=>"end_time", type=>"time", },
		{ name=>"status", type=>"set", options=>[qw( waiting staged inprogress success failed )], default_value=>"waiting", },
		{ name=>"userid", type=>"itemref", datasetid=>"user", },
		{ name=>"description", type=>"longtext", },
		{ name=>"pluginid", type=>"id", required=>1, },
		{ name=>"action", type=>"id", required=>1, },
		{ name=>"params", type=>"storable", },
	);
}


######################################################################
=pod

=item $dataset = EPrints::DataObj::EPrint->get_dataset_id

Returns the ID of the L<EPrints::DataSet> object to which this record
belongs.

=cut
######################################################################

sub get_dataset_id { "event_queue" }



######################################################################
=pod

=back

=head2 Object Methods

=cut
######################################################################

######################################################################
=pod

=over 4

=item $ok = $event->execute()

Execute the action this event queue task describes.

The response from the L<EPrints::Plugin::Event> plugin action is 
treated as follows:

 undef - equivalent to HTTP_OK
 HTTP_OK - action succeeded, event is removed if cleanup is TRUE
 HTTP_RESET_CONTENT - action succeeded, event is set 'waiting'
 HTTP_NOT_FOUND - action failed, event is removed if cleanup is TRUE
 HTTP_LOCKED - action failed, event is re-scheduled for 10 minutes time
 HTTP_INTERNAL_SERVER_ERROR - action failed, event is 'failed' and kept

=cut
######################################################################

sub execute
{
	my( $self ) = @_;

	# commenced at
	$self->set_value( "end_time", EPrints::Time::get_iso_timestamp() );
	$self->commit();

	my $rc = $self->_execute();

	# completed at
	$self->set_value( "end_time", EPrints::Time::get_iso_timestamp() );

	if( $rc == EPrints::Const::HTTP_LOCKED )
	{
		my $start_time = $self->value( "start_time" );
		if( defined $start_time )
		{
			$start_time = EPrints::Time::datetime_utc(
				EPrints::Time::split_value( $start_time )
			);
		}
		$start_time = time() if !defined $start_time;
		$start_time += 10 * 60; # try again in 10 minutes time
		$self->set_value( "start_time",
			EPrints::Time::iso_datetime( $start_time )
		);
		$self->set_value( "status", "waiting" );
		$self->commit;
	}
	elsif( $rc == EPrints::Const::HTTP_RESET_CONTENT )
	{
		$self->set_value( "status", "waiting" );
		$self->commit;
	}
	elsif( $rc == EPrints::Const::HTTP_INTERNAL_SERVER_ERROR )
	{
		$self->set_value( "status", "failed" );
		$self->commit();
	}
	# OK or NOT_FOUND, which is ok
	else
	{
		if(
			$rc != EPrints::Const::HTTP_OK &&
			$rc != EPrints::Const::HTTP_NOT_FOUND
		  )
		{
			$self->message( "warning", $self->{session}->xml->create_text_node( "Unrecognised result code (check your action return): $rc" ) );
		}
		if( !$self->is_set( "cleanup" ) || $self->value( "cleanup" ) eq "TRUE" )
		{
			$self->remove();
		}
		else
		{
			if( $rc == EPrints::Const::HTTP_OK )
			{
				$self->set_value( "status", "success" );
			}
			else # NOT_FOUND
			{
				$self->set_value( "status", "failed" );
			}
			$self->commit;
		}
	}

	return $rc;
}

sub _execute
{
	my( $self ) = @_;

	my $session = $self->{session};
	my $xml = $session->xml;

	my $plugin = $session->plugin( $self->value( "pluginid" ),
		event => $self,
	);
	if( !defined $plugin )
	{
		# no such plugin
		$self->message( "error", $xml->create_text_node( $self->value( "pluginid" )." not available" ) );
		return EPrints::Const::HTTP_INTERNAL_SERVER_ERROR;
	}

	my $action = $self->value( "action" );
	if( !$plugin->can( $action ) )
	{
		$self->message( "error", $xml->create_text_node( "'$action' not available on ".ref($plugin) ) );
		return EPrints::Const::HTTP_INTERNAL_SERVER_ERROR;
	}

	my $params = $self->value( "params" );
	if( !defined $params )
	{
		$params = [];
	}
	my @params = @$params;

	# expand any object identifiers
	foreach my $param (@params)
	{
		if( defined($param) && $param =~ m# ^/id/([^/]+)/(.+)$ #x )
		{
			my $dataset = $session->dataset( $1 );
			if( !defined $dataset )
			{
				$self->message( "error", $xml->create_text_node( "Bad parameters: No such dataset '$1'" ) );
				return EPrints::Const::HTTP_NOT_FOUND;
			}
			$param = $dataset->dataobj( $2 );
			if( !defined $param )
			{
				$self->message( "error", $xml->create_text_node( "Bad parameters: No such item '$2' in dataset '$1'" ) );
				return EPrints::Const::HTTP_NOT_FOUND;
			}
			my $locked = 0;
			if( $param->isa( "EPrints::DataObj::EPrint" ) )
			{
				$locked = 1 if( $param->is_locked() );
			}
			if( $param->isa( "EPrints::DataObj::Document" ) )
			{
				my $eprint = $param->get_parent;
				$locked = 1 if( $eprint && $eprint->is_locked() );
			}
			if( $locked )
			{
				$self->message( "warning", $xml->create_text_node( $param->get_dataset->base_id.".".$param->id." is locked" ) );
				return EPrints::Const::HTTP_LOCKED;
			}
		}
	}

	my $rc = eval { $plugin->$action( @params ) };
	if( $@ )
	{
		my $error_message = $@;
		$self->message( "error", $xml->create_text_node( "Error during execution: $error_message" ) );
		$self->set_value( "description", $error_message );
		return EPrints::Const::HTTP_INTERNAL_SERVER_ERROR;
	}

	return defined($rc) ? $rc : EPrints::Const::HTTP_OK;
}

######################################################################
=pod

=item $event->message( $type, $message )

Utility method to log the C<$message> for this event.

C<$type> is required by this method but not currently used.

=cut
######################################################################

sub message
{
	my( $self, $type, $message ) = @_;

	my $msg = "";
	$msg = sprintf( "[%s] %s::%s: %s",
		$self->id,
		$self->value( "pluginid" ),
		$self->value( "action" ),
		$self->{session}->xhtml->to_text_dump( $message ) );
	$self->{session}->xml->dispose( $message );

	$self->{session}->log( $msg );
}

1;

######################################################################
=pod

=back

=head1 SEE ALSO

L<EPrints::DataObj> and L<EPrints::DataSet>.

=head1 COPYRIGHT

=begin COPYRIGHT

Copyright 2023 University of Southampton.
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

