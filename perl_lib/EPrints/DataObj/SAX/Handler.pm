######################################################################
#
# EPrints::DataObj::SAX::Handler
#
######################################################################
#
#
######################################################################

=pod

=for Pod2Wiki

=head1 NAME

B<EPrints::DataObj::SAX::Handler> - SAX handler for EPrints data 
objects.

=head1 DESCRIPTION

This class provides a SAX handler for parsing EPrints data objects.

=head1 METHODS

=cut

package EPrints::DataObj::SAX::Handler;


######################################################################
=pod

=head2 Constructor Methods

=cut
######################################################################

######################################################################
=pod

=over 4

=item EPrints::DataObj::SAX::Handler->new

Create new SAX Handler.

=cut
######################################################################

sub new
{
    my( $class, @self ) = @_;

    return bless \@self, $class;
}

sub AUTOLOAD {}


######################################################################
=pod

=back

=head2 Object Methods

=back
######################################################################

######################################################################
=pod

=over 4

=item $sax_handler->start_element( $data )

Use C<$data> to start a new element.

=cut
######################################################################

sub start_element
{
    my( $self, $data ) = @_;
    $self->[0]->start_element( $data, @$self[1..$#$self] );
}

######################################################################
=pod

=item $sax_handler->end_element( $data )

Use C<$data> to end an element.

=cut
######################################################################

sub end_element
{
    my( $self, $data ) = @_;
    $self->[0]->end_element( $data, @$self[1..$#$self] );
}


######################################################################
=pod

=item $sax_handler->characters( $data )

Use C<$data> to add characters to element.

=cut
######################################################################

sub characters
{
    my( $self, $data ) = @_;
    $self->[0]->characters( $data, @$self[1..$#$self] );
}

1;

######################################################################
=pod

=back

=head1 COPYRIGHT

=begin COPYRIGHT

Copyright 2022 University of Southampton.
EPrints 3.4 is supplied by EPrints Services.

http://www.eprints.org/eprints-3.4/

=end COPYRIGHT

=begin LICENSE

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

=end LICENSE
