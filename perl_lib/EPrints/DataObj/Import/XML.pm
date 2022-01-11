######################################################################
#
# EPrints::DataObj::Import::XML
#
######################################################################
#
#
######################################################################

=pod

=for Pod2Wiki

=head1 NAME

B<EPrints::DataObj::Import::XML> - XML import.

=head1 DESCRIPTION

This is a utility module for importing existing eprints from an XML 
file. It inherits from L<EPrints::Plugin::Import::XML>.

=head1 METHODS

=cut
######################################################################

package EPrints::DataObj::Import::XML;

use EPrints;

use strict;

use EPrints::Plugin::Import::XML;

our @ISA = qw( EPrints::Plugin::Import::XML );


######################################################################
=pod

=head2 Constructor Methods

=cut
######################################################################

######################################################################
=pod

=over 4

=item $xml_import = EPrints::DataObj::Import::XML->new( %params )

Create a new XML import data object using the C<%params> provided.

=cut
######################################################################

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new( %params );

	$self->{import} = $params{import};
	$self->{id} = "Import::XML"; # hack to make phrases work

	return $self;
}


######################################################################
=pod

=back

=head2 Class Methods

=cut
######################################################################

######################################################################
=pod

=item EPrints::DataObj::Import::XML->warn

Suppress warnings, in particular that various imported fields do not
exist in our repository.

=cut
######################################################################

sub warning {}


######################################################################
=pod

=back

=head2 Object Methods

=cut
######################################################################

######################################################################
=pod

=over 4

=item $dataobj = $xml_import->epdata_to_dataobj( $dataset, $epdata )

Create new data object for C<$dataset> parsing the XML data in 
C<$epdata>.

Returns the newly create data object.

=cut
######################################################################

sub epdata_to_dataobj
{
	my( $self, $dataset, $epdata ) = @_;

	my $dataobj = $self->{import}->epdata_to_dataobj( $dataset, $epdata );

	$self->handler->parsed( $epdata ); # TODO: parse-only import?
	$self->handler->object( $dataset, $dataobj );

	return $dataobj;
}


1;

######################################################################
=pod

=back

=head1 SEE ALSO

L<EPrints::Plugin::Import::XML>.

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

