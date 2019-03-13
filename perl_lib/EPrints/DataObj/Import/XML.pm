=head1 NAME

EPrints::DataObj::Import::XML

=cut

######################################################################
#
# EPrints::DataObj::Import::XML
#
######################################################################
#
#
######################################################################

package EPrints::DataObj::Import::XML;

# This is a utility module for importing existing eprints from an XML file

use EPrints;

use strict;

use EPrints::Plugin::Import::XML;

our @ISA = qw( EPrints::Plugin::Import::XML );

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new( %params );

	$self->{import} = $params{import};
	$self->{id} = "Import::XML"; # hack to make phrases work

	return $self;
}

sub epdata_to_dataobj
{
	my( $self, $dataset, $epdata ) = @_;

	my $dataobj = $self->{import}->epdata_to_dataobj( $dataset, $epdata );

	$self->handler->parsed( $epdata ); # TODO: parse-only import?
	$self->handler->object( $dataset, $dataobj );

	return $dataobj;
}

# suppress warnings, in particular that various imported fields don't exist
# in our repository
sub warning {}

1;

__END__


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

