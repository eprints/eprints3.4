=head1 NAME

EPrints::Plugin::Export::ListUserEmails

=cut

package EPrints::Plugin::Export::ListUserEmails;

use EPrints::Plugin::Export;

@ISA = ( "EPrints::Plugin::Export" );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new( %params );

	$self->{name} = "List of Email Addresses";
	$self->{accept} = [ 'dataobj/user', 'list/user' ];
	$self->{visible} = "staff";
	$self->{suffix} = "text";
	$self->{mimetype} = "text/plain";

	return $self;
}


sub output_dataobj
{
	my( $plugin, $dataobj ) = @_;

	return "" if $dataobj->is_set( "pin" );
	return "" if !$dataobj->is_set( "email" );

	my $email = $dataobj->get_value( "email" );

	return "$email\n";
}


1;

=head1 COPYRIGHT

=for COPYRIGHT BEGIN

Copyright 2018 University of Southampton.
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

