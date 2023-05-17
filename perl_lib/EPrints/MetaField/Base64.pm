######################################################################
#
# EPrints::MetaField::Base64
#
######################################################################
#
#
######################################################################

=pod

=for Pod2Wiki

=head1 NAME

B<EPrints::MetaField::Base64> - Base 64 encoded data

=head1 DESCRIPTION

Data encoded in base64.  This may be small files (e.g. kilobytes) 
better save in the database rather than to the filesystem.

=head1 INHERITANCE

 L<EPrints::MetaField>
   L<EPrints::MetaField::Id>
     L<EPrints::MetaField::Text>
       L<EPrints::MetaField::Longtext>
	       B<EPrints::MetaField::Base64>

=head1 PROPERTIES

I<To be written>

=head1 METHODS

=cut

package EPrints::MetaField::Base64;

use MIME::Base64;

use strict;
use base "EPrints::MetaField::Longtext";

######################################################################
=pod

=over 4

=item $value = $field->form_value( $session, $object, [$prefix] )

Base64 encode the CGI parameter submitted within the form for this 
particular field.  Assuming the from contained such an input field.

Returns a single scalar or array of base64 encoded values.

=cut
######################################################################

sub form_value 
{
  my ($self, $session, $object, $prefix) = @_;

  my $basename = $self->basename($prefix);

  my $value = $self->form_value_actual($session, $object, $basename);

  if(ref $value eq "ARRAY") 
  {
    foreach my $v (@{$value}) 
    {
      $v = MIME::Base64::encode_base64($v);
    }
  } 
  else 
  {
    $value = MIME::Base64::encode_base64($value);
  }

  return $value;
}


######################################################################
=pod

=over 4

=item $xml = $field->to_sax( $value, %opts )

Print the field and value(s) as an XML representation of a base64 
field.

=cut
######################################################################

sub to_sax
{
	my( $self, $value, %opts ) = @_;

	# MetaField::Compound relies on testing this specific attribute
	return if defined $self->{parent_name};

	return if !$opts{show_empty} && !EPrints::Utils::is_set( $value );

	my $handler = $opts{Handler};
	my $name = $self->name;

	my $enc_attr = {
		Prefix => '',
		LocalName => 'encoding',
		Name => 'encoding',
		NamespaceURI => '',
		Value => 'base64',
	};

	if( ref($value) eq "ARRAY" )
	{
		$handler->start_element( {
			Prefix => '',
			LocalName => $name,
			Name => $name,
			NamespaceURI => EPrints::Const::EP_NS_DATA,
			Attributes => {},
		});

		foreach my $v (@$value)
		{
			$handler->start_element( {
				Prefix => '',
				LocalName => "item",
				Name => "item",
				NamespaceURI => EPrints::Const::EP_NS_DATA,
				Attributes => {
					'{}encoding' => $enc_attr,
				},
			});
			$self->to_sax_basic( $v, %opts );
			$handler->end_element( {
				Prefix => '',
				LocalName => "item",
				Name => "item",
				NamespaceURI => EPrints::Const::EP_NS_DATA,
			});
		}
	}
	else
	{
		$handler->start_element( {
			Prefix => '',
			LocalName => $name,
			Name => $name,
			NamespaceURI => EPrints::Const::EP_NS_DATA,
			Attributes => {
				'{}encoding' => $enc_attr,
			},
		});

		$self->to_sax_basic( $value, %opts );
	}

	$handler->end_element( {
		Prefix => '',
		LocalName => $name,
		Name => $name,
		NamespaceURI => EPrints::Const::EP_NS_DATA,
	});
}

######################################################################
=pod

=over 4

=item $type = $field->get_xml_schema_type

Gets the XML schema type for this base64 field.

Returns a string containing the type, dataset ID and and name of this
field (e.g. C<base64_file_data>).

=cut
######################################################################


sub get_xml_schema_type
{
    my ( $self ) = @_;

    return $self->get_property( "type" ) . "_" . $self->{dataset}->confid . "_" . $self->get_name;
}

######################################################################
=pod

=over 4

=item $type = $field->render_xml_schema_type

Produces an XML fragment this base64 field.

Returns a DOM for the following:

 <xs:complexType name="base64_file_data">
   <xs:simpleContent>
     <xs:extension base="xs:base64Binary">
       <xs:attribute name="encoding">
         <xs:simpleType>
           <xs:restriction base="xs:string">
             <xs:enumeration value="base64" />
           </xs:restriction>
         </xs:simpleType>
       </xs:attribute>
     </xs:extension>
   </xs:simpleContent>
 </xs:complexType>

E.g., <data encoding="base64">...</data>

=cut
######################################################################

sub render_xml_schema_type
{
    my ( $self, $session ) = @_;

    my $type = $session->make_element( 'xs:complexType',
                                       name => $self->get_xml_schema_type );
    my $sc = $session->make_element( 'xs:simpleContent' );
    my $ext = $session->make_element( 'xs:extension', base => 'xs:base64Binary' );

    # encoding attribute
    my $encoding = $session->make_element( 'xs:attribute', name => 'encoding' );
    my $enc_type = $session->make_element( 'xs:simpleType' );
    my $enc_restr = $session->make_element( 'xs:restriction', base => 'xs:string' );
    my $enc_enum = $session->make_element( 'xs:enumeration', value => 'base64' );

    $enc_restr->appendChild( $enc_enum );
    $enc_type->appendChild( $enc_restr );
    $encoding->appendChild( $enc_type );
    $ext->appendChild( $encoding );
    $sc->appendChild( $ext );
    $type->appendChild( $sc );

    return $type;
}


1;

######################################################################
=pod

=back

=head1 COPYRIGHT

=begin COPYRIGHT

Copyright 2023 University of Southampton.
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
