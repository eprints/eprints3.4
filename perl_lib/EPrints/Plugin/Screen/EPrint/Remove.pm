=head1 NAME

EPrints::Plugin::Screen::EPrint::Remove

=cut

package EPrints::Plugin::Screen::EPrint::Remove;

our @ISA = ( 'EPrints::Plugin::Screen::EPrint' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	$self->{icon} = "action_remove.png";

	$self->{appears} = [
		{
			place => "eprint_actions",
			position => 1600,
		},
		{
			place => "eprint_item_actions",
			position => 100,
		},
		{
			place => "eprint_actions_bar_archive",
			position => 1000,
		},
	];
	
	$self->{actions} = [qw/ remove cancel /];

	return $self;
}

sub obtain_lock
{
	my( $self ) = @_;

	return $self->could_obtain_eprint_lock;
}


sub can_be_viewed
{
	my( $self ) = @_;

	return 0 unless $self->could_obtain_eprint_lock;

	# Do not allow items that are or have once been in the live archive be removed unless the user has an extra special permission.
	return 0 if $self->{processor}->{eprint}->is_set( 'datestamp' ) && !$self->allow( "eprint/remove_once_archived" );

	return $self->allow( "eprint/remove" );
}

sub render
{
	my( $self ) = @_;

	my $div = $self->{session}->make_element( "div", class=>"ep_block" );

	if( $self->{processor}->{eprint}->is_set( "datestamp" ) )
        {
                $div->appendChild(
                        $self->{session}->html_phrase(
                                "cgi/users/edit_eprint:remove_once_archived" ) );
        }

	$div->appendChild( $self->html_phrase("sure_delete",
		title=>$self->{processor}->{eprint}->render_description() ) );

	my %buttons = (
		cancel => $self->{session}->phrase(
				"lib/submissionform:action_cancel" ),
		remove => $self->{session}->phrase(
				"lib/submissionform:action_remove" ),
		_order => [ "remove", "cancel" ]
	);

	my $form= $self->render_form;
	$form->appendChild( 
		$self->{session}->render_action_buttons( 
			%buttons ) );
	$div->appendChild( $form );

	return( $div );
}	

sub allow_remove
{
	my( $self ) = @_;

	return $self->can_be_viewed;
}

sub allow_cancel
{
	my( $self ) = @_;

	return 1;
}

sub action_cancel
{
	my( $self ) = @_;

	$self->{processor}->{screenid} = "EPrint::View";
}

sub action_remove
{
	my( $self ) = @_;

	$self->{processor}->{screenid} = "Items";

	if( !$self->{processor}->{eprint}->remove )
	{
		my $db_error = $self->{session}->get_database->error;
		$self->{session}->get_repository->log( "DB error removing EPrint ".$self->{processor}->{eprint}->get_value( "eprintid" ).": $db_error" );
		$self->{processor}->add_message( "message", $self->html_phrase( "item_not_removed" ) );
		$self->{processor}->{screenid} = "FirstTool";
		return;
	}

	$self->{processor}->add_message( "message", $self->html_phrase( "item_removed" ) );
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

