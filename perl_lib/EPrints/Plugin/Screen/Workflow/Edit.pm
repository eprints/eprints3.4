=head1 NAME

EPrints::Plugin::Screen::Workflow::Edit

=cut

package EPrints::Plugin::Screen::Workflow::Edit;

use EPrints::Plugin::Screen::Workflow;

@ISA = ( 'EPrints::Plugin::Screen::Workflow' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	$self->{actions} = [qw/ stop save next prev /];

	$self->{icon} = "action_edit.png";

	$self->{appears} = [
		{
			place => "dataobj_actions",
			position => 250,
		},
		{
			place => "dataobj_view_actions",
			position => 250,
		},
	];

	$self->{staff} = 0;

	return $self;
}

sub can_be_viewed
{
	my( $self ) = @_;

	return 0 if !$self->has_workflow();

	return $self->allow( $self->{processor}->{dataset}->id."/edit" );
}

sub from
{
	my( $self ) = @_;

	if( defined $self->{processor}->{internal} )
	{
		if( my $component = $self->current_component )
		{
			$component->update_from_form( $self->{processor} );
		}
		else
		{
			$self->workflow->update_from_form( $self->{processor}, undef, 1 );
		}

		my $button_id = $self->{processor}->{internal};

		if(( $button_id !~ /_morespaces$/ ) &&
		   ( $button_id !~ /_up_[0-9]+$/ ) &&
		   ( $button_id !~ /_down_[0-9]+$/ ))
		{
			$self->workflow->{item}->commit;
		}

		$self->uncache_workflow;
		return;
	}

	my $action_id = $self->{processor}->{action};
	if( $action_id =~ m/^jump_(.*)$/ )
	{
		my $jump_to = $1;

		if( defined $self->{session}->param( "stage" ) )
		{
			$self->workflow->update_from_form( $self->{processor},$jump_to );
			$self->uncache_workflow;
		}

		$self->workflow->set_stage( $jump_to );

		# not checking that this succeeded. Maybe we should.
		return;
	}

	$self->EPrints::Plugin::Screen::from;
}

sub wishes_to_export
{
	my( $self ) = @_;

	return $self->current_component->wishes_to_export($self->{processor})
		if $self->current_component;

	return $self->SUPER::wishes_to_export;
}

sub export_mimetype
{
	my( $self ) = @_;

	return $self->current_component->export_mimetype($self->{processor})
		if $self->current_component;

	return $self->SUPER::export_mimetype;
}

sub export
{
	my( $self ) = @_;

	return $self->current_component->export($self->{processor})
		if $self->current_component;

	return $self->SUPER::export;
}

sub action_stop
{
	my( $self ) = @_;

	my $return_to = $self->repository->param('return_to');
        if ($return_to)
        {
                $self->{processor}->{screenid} = $return_to;
        }
        else
        {
		$self->{processor}->{screenid} = $self->view_screen;
	}
}	

sub action_save
{
	my( $self ) = @_;

	$self->workflow->update_from_form( $self->{processor} );
	$self->uncache_workflow;

	my $return_to = $self->repository->param('return_to');
	if ($return_to)
	{
		$self->{processor}->{screenid} = $return_to;
	}
	else
	{
		$self->{processor}->{screenid} = $self->view_screen;
	}
}


sub allow_prev
{
	my( $self ) = @_;

	return $self->can_be_viewed;
}
	
sub action_prev
{
	my( $self ) = @_;

	$self->workflow->update_from_form( $self->{processor}, $self->workflow->get_prev_stage_id );
	$self->uncache_workflow;

	$self->workflow->prev;
}

sub action_next
{
	my( $self ) = @_;

	my $from_ok = $self->workflow->update_from_form( $self->{processor} );
	$self->uncache_workflow;

	return unless $from_ok;

	if( !defined $self->workflow->get_next_stage_id )
	{
		return;
	}

	$self->workflow->next;
}

sub redirect_to_me_url
{
	my( $self ) = @_;

	return undef if $self->current_component;

	return $self->SUPER::redirect_to_me_url.$self->workflow->get_state_params( $self->{processor} );
}

sub render
{
	my( $self ) = @_;

	my $form = $self->render_form;

	if( my $component = $self->current_component )
	{
		$form->appendChild( $component->render );
		return $form;
	}

	if( scalar $self->workflow->get_stage_ids > 1 )
	{
		my $blister = $self->render_blister( $self->workflow->get_stage_id, 0 );
		my $toolbox = $self->{session}->render_toolbox( undef, $blister );
		$form->appendChild( $toolbox );
	}

	my $stage = $self->workflow->get_stage( $self->workflow->get_stage_id );
	my $action_buttons = $stage->action_buttons;

	if( $action_buttons eq "top" || $action_buttons eq "both" )
	{
		$form->appendChild( $self->render_buttons( "top" ) );
	}
	$form->appendChild( $self->workflow->render );
	if( $action_buttons eq "bottom" || $action_buttons eq "both" )
	{
		$form->appendChild( $self->render_buttons( "bottom" ) );
	}
	
	return $form;
}


sub render_buttons
{
	my( $self, $position ) = @_;

	my $class = "ep_form_button_bar";

	if( defined( $position ))
	{
		$class .= " ep_form_button_bar_$position";
	}

	my %buttons = ( _order=>[], _class=> $class );

	if( defined $self->workflow->get_prev_stage_id )
	{
		push @{$buttons{_order}}, "prev";
		$buttons{prev} = 
			$self->{session}->phrase( "lib/submissionform:action_prev" );
	}

	push @{$buttons{_order}}, "stop";
	$buttons{stop} = 
		$self->{session}->phrase( "lib/submissionform:action_stop" );

	push @{$buttons{_order}}, "save";
	$buttons{save} = 
		$self->{session}->phrase( "lib/submissionform:action_save" );

	if( defined $self->workflow->get_next_stage_id )
	{
		push @{$buttons{_order}}, "next";
		$buttons{next} = 
			$self->{session}->phrase( "lib/submissionform:action_next" );
	}

	return $self->{session}->render_action_buttons( %buttons );
}

sub hidden_bits
{
	my( $self ) = @_;

	return(
		$self->SUPER::hidden_bits,
		stage => $self->workflow->get_stage_id
	);
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

