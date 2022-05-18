=head1 NAME

EPrints::Plugin::Export::XML

=cut

package EPrints::Plugin::Export::StaffXML;

use EPrints::Plugin::Export::XML;

@ISA = ( "EPrints::Plugin::Export::XML" );

use strict;

sub new
{
	my( $class, %opts ) = @_;

	my( $self ) = $class->SUPER::new( %opts );

	$self->{name} = "EP3 XML (Staff)";

	# this module outputs fields that have export_as_xml 
	# set to 0, which should not appear in public export.
	$self->{visible} = "staff";
	
	$self->{qs} = 0.4;

	return $self;
}

sub output_dataobj
{
	my( $self, $dataobj, %opts ) = @_;

	return $self->SUPER::output_dataobj( $dataobj, %opts, revision_generation => 1 );
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

