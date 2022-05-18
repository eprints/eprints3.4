=head1 NAME

EPrints::Plugin::Screen::EPMC::Cfgd - Package manager controller for cfg.d

=head1 DESCRIPTION

This is a utility EPMC that will point the user at the first configuration file included in the package.

=cut

package EPrints::Plugin::Screen::EPMC::Cfgd;

use EPrints::Plugin::Screen::EPMC;

@ISA = ( 'EPrints::Plugin::Screen::EPMC' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new( %params );

	push @{$self->{actions}}, "configure";

	return $self;
}

sub allow_configure { shift->can_be_viewed( @_ ) }

sub action_configure
{
	my( $self ) = @_;

	my $epm = $self->{processor}->{dataobj};
	my $epmid = $epm->id;

	foreach my $file ($epm->installed_files)
	{
		my $filename = $file->value( "filename" );
		next if $filename !~ m#^epm/$epmid/cfg/cfg\.d/(.*)#;
		my $url = $self->{repository}->current_url( host => 1 );
		$url->query_form(
			screen => "Admin::Config::View::Perl",
			configfile => "cfg.d/$1",
		);
		$self->{repository}->redirect( $url );
		exit( 0 );
	}

	$self->{processor}->{screenid} = "Admin::EPM";

	$self->{processor}->add_message( "error", $self->html_phrase( "missing" ) );
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

