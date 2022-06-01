=head1 NAME

EPrints::Plugin::Screen::EPMC::Theme - update static files on enable/disable

=head1 DESCRIPTION

This EPM controller will update static files whenever the EPM is enabled/disabled.

=cut

package EPrints::Plugin::Screen::EPMC::Theme;

use EPrints::Plugin::Screen::EPMC;

@ISA = ( 'EPrints::Plugin::Screen::EPMC' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new( %params );

	return $self;
}

sub action_enable
{
	my( $self ) = @_;

	$self->SUPER::action_enable;
	
	$self->_static;
}

sub action_disable
{
	my( $self ) = @_;

	$self->SUPER::action_disable;
	
	$self->_static;
}

sub _static
{
	my( $self ) = @_;

	my $epm = $self->{processor}->{dataobj};

	my $path = $self->{repository}->config( "archiveroot" )."/html";

	FILE: foreach my $file ($epm->installed_files)
	{
		my $filename;
		foreach my $dir ("static/", qr#themes/[^/]+/static/#)
		{
			$filename = $1, last if $file->value( "filename" ) =~ /^$dir(.+)/;
		}
		next FILE if !defined $filename;
		foreach my $langid (@{$self->{repository}->config( "languages" )})
		{
			my $filepath = "$path/$langid/$filename";
			if( -f $filepath ) {
				unlink($filepath);
			}
			if( $filename =~ m#^javascript/auto/# ) {
				unlink("$path/$langid/javascript/auto.js");
				unlink("$path/$langid/javascript/secure_auto.js");
			}
			elsif( $filename =~ m#^style/auto/# ) {
				unlink("$path/$langid/style/auto.css");
			}
			elsif( $filename =~ m/^(.+)\.xpage$/ ) {
				for(qw( html head page title title.textonly ))
				{
					unlink("$path/$langid/$1.$_");
				}
			}
		}
	}
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

