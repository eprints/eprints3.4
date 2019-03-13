=head1 NAME

EPrints::Plugin::Screen::Admin::Reload

=cut

package EPrints::Plugin::Screen::Admin::Reload;

@ISA = ( 'EPrints::Plugin::Screen' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);
	
	$self->{actions} = [qw/ reload_config /]; 
		
	$self->{appears} = [
		{ 
			place => "admin_actions_config", 
			position => 1250, 
			action => "reload_config",
		},
	];

	return $self;
}

sub allow_reload_config
{
	my( $self ) = @_;

	return $self->allow( "config/reload" );
}

sub action_reload_config
{
	my( $self ) = @_;

	$self->{processor}->{screenid} = "Admin";

	my $session = $self->{session};

	my( $result, $msg ) = $session->get_repository->test_config;

	if( $result != 0 )
	{
		$self->{processor}->add_message( "error",
			$self->html_phrase( "reload_bad_config",
				output=>$self->{session}->make_text( $msg ) ) );
		return;
	}

	if( !$session->reload_config )
	{
		$self->{processor}->add_message( "error",
			$self->html_phrase( "reload_write_failed" ) );
		return;
	}

	$self->{processor}->add_message( "message",
		$self->html_phrase( "reloaded" ) );

	return 1; # useful for other Screen plugins calling us
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

