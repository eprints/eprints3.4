=head1 NAME

EPrints::Plugin::Screen::Admin::RegenCitations

=cut

package EPrints::Plugin::Screen::Admin::RegenCitations;

@ISA = ( 'EPrints::Plugin::Screen' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);
	
	$self->{actions} = [qw/ regen_citations /]; 
		
	$self->{appears} = [
		{ 
			place => "admin_actions_system", 
			position => 1265, 
			action => "regen_citations",
		},
	];

	return $self;
}

sub allow_regen_citations
{
	my( $self ) = @_;

	return 0 unless defined $self->{session}->config( "citation_caching", "enabled" ) && $self->{session}->config( "citation_caching", "enabled" );

	return $self->allow( "config/regen_citations" );
}

sub action_regen_citations
{
	my( $self ) = @_;

	my $session = $self->{session};
	
	unless( $session->expire_citations() )
	{
		$self->{processor}->add_message( "error",
			$self->html_phrase( "failed" ) );
		$self->{processor}->{screenid} = "Admin";
		return;
	}
	
	$self->{processor}->add_message( "message",
		$self->html_phrase( "ok" ) );
	$self->{processor}->{screenid} = "Admin";
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

