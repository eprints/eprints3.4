######################################################################
#
# EPrints::MetaField::Itemref
#
######################################################################
#
#
######################################################################

=pod

=for Pod2Wiki

=head1 NAME

B<EPrints::MetaField::Itemref> - Reference to an object with an "int" type of ID field.

=head1 DESCRIPTION

not done

=over 4

=cut

package EPrints::MetaField::Itemref;

use EPrints::MetaField::Int;
@ISA = qw( EPrints::MetaField::Int );

use strict;

sub new
{
        my( $self, %params ) = @_;

	$params{regexp} = '' if defined $params{fromform} && ! defined $params{regexp};

       	return  $self->SUPER::new( %params );
}

sub get_property_defaults
{
	my( $self ) = @_;
	my %defaults = $self->SUPER::get_property_defaults;
	$defaults{datasetid} = $EPrints::MetaField::REQUIRED;
	$defaults{get_item} = $EPrints::MetaField::UNDEF;
	$defaults{render_item} = $EPrints::MetaField::UNDEF;
	return %defaults;
}

sub get_input_col_titles
{
	my ( $self, $session, $staff, $from_compound ) = @_;
	if ( !$from_compound )
	{
		return;
	}

	my @r;
	push @r, $self->render_name($session);
	push @r, $session->make_doc_fragment();
	return \@r;
}

sub get_basic_input_elements
{
	my( $self, $session, $value, $basename, $staff, $obj, $one_field_component ) = @_;

	my $ex = $self->SUPER::get_basic_input_elements( $session, $value, $basename, $staff, $obj, $one_field_component );

	my $desc = $self->render_single_value( $session, $value );

	push @{$ex->[0]}, {el=>$desc, style=>"padding: 0 0.5em 0 0.5em;"};

	return $ex;
}

sub get_basic_input_ids
{
	my ( $self, $session, $basename, $staff, $obj, $from_compound ) = @_;
	my @r;
	push @r, $basename;
	if ($from_compound)
	{
		push @r, $basename . '_citation';
	}
	return @r;
}

sub render_single_value
{
	my( $self, $session, $value ) = @_;

	if( !defined $value )
	{
		return $session->make_doc_fragment;
	}

	my $object = $self->get_item( $session, $value );

	if( defined $object )
	{
		return $self->call_property( "render_item", $value, $session ) if $self->get_property("render_item");
		return $object->render_citation_link;
	}

	my $ds = $session->dataset( $self->get_property('datasetid') );

	return $session->html_phrase( 
		"lib/metafield/itemref:not_found",
			id=>$session->make_text($value),
			objtype=>$session->html_phrase( "datasetname_".$ds->base_id));
}

sub get_value_label
{
        my( $self, $session, $value, %opts ) = @_;

	my $item = $self->get_item( $session, $value );
	
        if( !EPrints::Utils::is_set( $item ) && $opts{fallback_phrase} )
        {
                return $session->html_phrase( $opts{fallback_phrase} );
        }
        return $self->render_single_value( $session, $value );
}

sub get_item
{
	my( $self, $session, $value ) = @_;

	if( defined $self->{get_item} )
        {
                return $self->call_property( "get_item", $value, $session );
        }

	my $ds = $session->dataset( $self->get_property('datasetid') );

	return $ds->dataobj( $value );
}


sub get_input_elements
{   
	my( $self, $session, $value, $staff, $obj, $basename, $one_field_component ) = @_;

	my $input = $self->SUPER::get_input_elements( $session, $value, $staff, $obj, $basename, $one_field_component );

	my $buttons = $session->make_doc_fragment;
	$buttons->appendChild( 
		$session->render_internal_buttons( 
			$self->{name}."_null" => $session->phrase(
				"lib/metafield/itemref:lookup" )));

	push @{ $input->[0] }, {el=>$buttons};

	return $input;
}




######################################################################
1;

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

