=head1 NAME

EPrints::Plugin::Screen::Admin::Config::Edit::XPage

=cut

package EPrints::Plugin::Screen::Admin::Config::Edit::XPage;

use EPrints::Plugin::Screen::Admin::Config::Edit::XML;

@ISA = ( 'EPrints::Plugin::Screen::Admin::Config::Edit::XML' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);
	
	$self->{appears} = [
# See cfg.d/dynamic_template.pl
#		{
#			place => "key_tools",
#			position => 1250,
#			action => "edit",
#		},
	];

	push @{$self->{actions}}, qw( edit );

	return $self;
}

sub can_be_viewed
{
	my( $self ) = @_;

	return $self->allow( "config/edit/static" );
}

sub allow_edit
{
	my( $self ) = @_;

	$self->{processor}->{conffile} ||= $self->{session}->get_static_page_conf_file;

	return defined $self->{processor}->{conffile};
}
sub action_edit {} # dummy action for key_tools

sub render_action_link
{
	my( $self, %opts ) = @_;

	my $conffile = $self->{processor}->{conffile};

	my $uri = URI->new( $self->{session}->current_url( path => 'cgi' , "users/home" ) );
	$uri->query_form(
		screen => substr($self->{id},8),
		configfile => $conffile,
	);

	$opts{class} = "ep_tm_key_tools_item_link" if not defined $opts{class};
	my $link = $self->{session}->render_link( $uri, undef, %opts );
	$link->appendChild( $self->{session}->html_phrase( "lib/session:edit_page" ) );

	return $link;
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

