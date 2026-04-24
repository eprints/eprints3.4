=head1 NAME

EPrints::Plugin::Screen::Admin::IndexerControl

=cut

package EPrints::Plugin::Screen::Admin::IndexerControl;

@ISA = ( 'EPrints::Plugin::Screen' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);
	
	$self->{actions} = [qw/ start_indexer force_start_indexer stop_indexer retry_tasks clear_tasks /];

	$self->{appears} = [
		{ 
			place => "admin_actions_system",
			action => "start_indexer",
			position => 1100, 
		},
		{ 
			place => "admin_actions_system",
			action => "force_start_indexer",
			position => 1101,
		},
		{ 
			place => "admin_actions_system",
			action => "stop_indexer",
			position => 1100, 
		},
		{
			place => "admin_actions_system",
			action => "retry_tasks",
			position => 1105,
		},
		{
			place => "admin_actions_system",
			action => "clear_tasks",
			position => 1106,
		},
	];

	$self->{daemon} = EPrints::Index::Daemon->new(
		session => $self->{session},
		Handler => $self->{processor},
		logfile => EPrints::Index::logfile(),
		noise => ($self->{session}->{noise}||1),
	);

	return $self;
}

sub get_daemon
{
	my( $self ) = @_;
	return $self->{daemon};
}

sub about_to_render
{
	my( $self ) = @_;
	$self->{processor}->{screenid} = "Admin";
}

sub allow_stop_indexer
{
	my( $self ) = @_;

	return 0 if( !$self->get_daemon->is_running || $self->get_daemon->has_stalled );
	return $self->allow( "indexer/stop" );
}

sub action_stop_indexer
{
	my( $self ) = @_;

	my $result = $self->get_daemon->stop( $self->{session} );

	if( $result == 1 )
	{
		$self->{processor}->add_message( 
			"message", 
			$self->html_phrase( "indexer_stopped" ) 
		);
	}
	else
	{
		$self->{processor}->add_message( 
			"error", 
			$self->html_phrase( "cant_stop_indexer", 
				logpath => $self->{session}->make_text( EPrints::Index::logfile() ) 
			)
		);
	}
}

sub allow_start_indexer
{
	my( $self ) = @_;

	return 0 if( $self->get_daemon->is_running() );

	return $self->allow( "indexer/start" );
}

sub action_start_indexer
{
	my( $self ) = @_;

	my $result = $self->get_daemon->start( $self->{session} );

	if( $result == 1 )
	{
		$self->{processor}->add_message( 
			"message", 
			$self->html_phrase( "indexer_started" ) 
		);
	}
	else
	{
		$self->{processor}->add_message( 
			"error", 
			$self->html_phrase( "cant_start_indexer", 
				logpath => $self->{session}->make_text( EPrints::Index::logfile() ) 
			)
		);
	}
}

sub allow_force_start_indexer
{
	my( $self ) = @_;
	return 0 if( !$self->get_daemon->is_running() );
	return $self->allow( "indexer/force_start" );
}

sub action_force_start_indexer
{
	my( $self ) = @_;

	$self->get_daemon->stop(); # give the indexer a chance to stop
	$self->get_daemon->cleanup(); # remove pid/tick file
	my $result = $self->get_daemon->start( $self->{session} );

	if( $result == 1 )
	{
		$self->{processor}->add_message( 
			"message", 
			$self->html_phrase( "indexer_started" ) 
		);
	}
	else
	{
		$self->{processor}->add_message( 
			"error", 
			$self->html_phrase( "cant_start_indexer", 
				logpath => $self->{session}->make_text( EPrints::Index::logfile() )
			)
		);
	}
}

sub allow_retry_tasks
{
	my( $self ) = @_;
	return $self->allow( "indexer/retry_tasks" );
}

sub action_retry_tasks
{
	my( $self ) = @_;

	my $abortive_tasks = $self->_get_abortive_tasks;
	$abortive_tasks->map( sub {
		my ( $session, undef, $task ) = @_;

		$task->set_value( 'status', 'waiting' );
		$task->commit;
	} );
}

sub allow_clear_tasks
{
	my( $self ) = @_;
	return $self->allow( "indexer/clear_tasks" );
}

sub action_clear_tasks
{
	my( $self ) = @_;

	my $abortive_tasks = $self->_get_abortive_tasks;
	$abortive_tasks->map( sub {
		my ( $session, undef, $task ) = @_;

		$task->delete;
	} );
}

sub _get_abortive_tasks
{
	my( $self ) = @_;

	my $session = $self->{session};
	my $event_queue = $session->dataset( 'event_queue' );

	my $failed_ids = $event_queue->search(
		filters => [
			{
				meta_fields => [ 'status' ],
				value => 'failed',
			}
		]
	)->ids;

	# Time it would take for standard dequeue of 10 tasks to timeout. Anything older in progress must have gone stale.
	my $stale_seconds =  $session->config( 'indexer_daemon', 'timeout' ) * 10;
	my $stale_time = time() - $stale_seconds;
	my $datetime_less_than_stale_seconds = '-' . EPrints::Time::iso_datetime( time() - $stale_seconds );
	my $stale_ids = $event_queue->search(
		filters => [
			{
				meta_fields => [ 'status' ],
				value => 'inprogress',
			},
			{
				meta_fields => [ 'start_time' ],
				value => $datetime_less_than_stale_seconds,
				match => "EQ",
			},
		]
	)->ids;

	my $ids = [ @$failed_ids, @$stale_ids ];
	return $event_queue->list( $ids );
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

