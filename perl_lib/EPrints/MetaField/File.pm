######################################################################
#
# EPrints::MetaField::File;
#
######################################################################
#
#
######################################################################

=pod

=head1 NAME

B<EPrints::MetaField::File> - File in the file system.

=head1 DESCRIPTION

This is an abstract field which represents a directory in the 
filesystem. It is mostly used by the import and export systems.

For example: Documents have files.

=over 4

=cut

package EPrints::MetaField::File;

use strict;
use warnings;

BEGIN
{
	our( @ISA );

	@ISA = qw( EPrints::MetaField );
}

use EPrints::MetaField;

sub get_sql_type
{
	my( $self, $session ) = @_;

	return undef;
}

# This type of field is virtual.
sub is_virtual
{
	my( $self ) = @_;

	return 1;
}

sub get_property_defaults
{
	my( $self ) = @_;

	my %defaults = $self->SUPER::get_property_defaults;
	$defaults{show_in_fieldlist} = 0;
	#$defaults{datasetid} = $EPrints::MetaField::REQUIRED; 

	return %defaults;
}

sub render_xml_schema
{
	my( $self, $session ) = @_;

	my $element = $session->make_element( "xs:element", name => $self->get_name );

	if( $self->get_property( "multiple" ) )
	{
		my $complexType = $session->make_element( "xs:complexType" );
		$element->appendChild( $complexType );
		my $sequence = $session->make_element( "xs:sequence" );
		$complexType->appendChild( $sequence );
		my $item = $session->make_element( "xs:element", name => "file", maxOccurs => "unbounded", type => $self->get_xml_schema_type() );
		$sequence->appendChild( $item );
	}
	else
	{
		$element->setAttribute( type => $self->get_xml_schema_type() );
	}

	return $element;
}

sub render_xml_schema_type
{
	my( $self, $session ) = @_;

	my $type = $session->make_element( "xs:complexType", name => $self->get_xml_schema_type );

	my $all = $session->make_element( "xs:all", minOccurs => "0" );
	$type->appendChild( $all );
	foreach my $part ( qw/ filename filesize url / )
	{
		my $element = $session->make_element( "xs:element", name => $part, type => "xs:string" );
		$all->appendChild( $element );
	}
	{
		my $element = $session->make_element( "xs:element", name => "data" );
		$all->appendChild( $element );
		my $complexType = $session->make_element( "xs:complexType" );
		$element->appendChild( $complexType );
		my $simpleContent = $session->make_element( "xs:simpleContent" );
		$complexType->appendChild( $simpleContent );
		my $extension = $session->make_element( "xs:extension", base => "xs:base64Binary" );
		$simpleContent->appendChild( $extension );
		my $attribute = $session->make_element( "xs:attribute", name => "href", type => "xs:anyURI" );
		$extension->appendChild( $attribute );
	}

	return $type;
}

######################################################################
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

