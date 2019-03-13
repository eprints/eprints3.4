=head1 NAME

EPrints::XML::SAX::PrettyPrint

=cut

package EPrints::XML::SAX::PrettyPrint;

use strict;

our $AUTOLOAD;

sub new
{
	my( $class, %self ) = @_;

	$self{depth} = 0;

	return bless \%self, $class;
}

sub AUTOLOAD
{
	$AUTOLOAD =~ s/^.*:://;
	return if $AUTOLOAD =~ /^[A-Z]/;
	shift->{Handler}->$AUTOLOAD( @_ );
}

sub start_element
{
	my( $self, $data ) = @_;

	$self->{Handler}->characters({
		Data => "\n" . (" " x ($self->{depth} * 2))
	});

	$self->{depth}++;

	$self->{Handler}->start_element( $data );
}

sub characters
{
	my( $self, $data ) = @_;

	$self->{leaf} = 1;

	$self->{Handler}->characters( $data );
}

sub end_element
{
	my( $self, $data ) = @_;

	$self->{depth}--;

	if( !$self->{leaf} )
	{
		$self->{Handler}->characters({
			Data => "\n" . (" " x ($self->{depth} * 2))
		});
	}
	$self->{leaf} = 0;

	$self->{Handler}->end_element( $data );
}

sub end_document
{
	my( $self, $data ) = @_;

	$self->{Handler}->characters({
		Data => "\n"
	});

	$self->{Handler}->end_document( $data );
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

