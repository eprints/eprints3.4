=head1 NAME

EPrints::Plugin::Screen::EPrint::ReleaseLock

=cut

package EPrints::Plugin::Screen::EPrint::ReleaseLock;

our @ISA = ( 'EPrints::Plugin::Screen::EPrint' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	$self->{appears} = [
		{
			place => "eprint_actions",
			action => "release",
			position => 3100,
		},
		{
			place => "lock_tools",
			action => "release",
			position => 100,
		},
	];
	
	$self->{actions} = [qw/ release /];

	return $self;
}

sub can_be_viewed
{
	my( $self ) = @_;

	my $eprint = $self->{processor}->{eprint};
	return 0 if !defined $eprint;
	return 0 if !$eprint->is_locked();
	return 15 if( $eprint->get_value( "edit_lock_user" ) == $self->{session}->current_user->get_id );

	return 0;
}

sub allow_release
{
	my( $self ) = @_;

	return $self->can_be_viewed;
}

sub action_release
{
	my( $self ) = @_;

	$self->{processor}->{screenid} = "EPrint::View";
	
	$self->{processor}->{eprint}->set_value( "edit_lock_until", 0 );
	$self->{processor}->{eprint}->commit;

	$self->{processor}->add_message( "message", $self->html_phrase( "item_released" ) );
}


1;

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

