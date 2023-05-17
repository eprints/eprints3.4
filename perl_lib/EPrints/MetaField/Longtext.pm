######################################################################
#
# EPrints::MetaField::Longtext
#
######################################################################
#
#
######################################################################

=pod

=for Pod2Wiki

=head1 NAME

B<EPrints::MetaField::Longtext> - no description

=head1 DESCRIPTION

not done

=over 4

=cut

package EPrints::MetaField::Longtext;

use strict;
use warnings;

BEGIN
{
	our( @ISA );

	@ISA = qw( EPrints::MetaField::Text );
}

use EPrints::MetaField::Text;

sub get_sql_type
{
	my( $self, $session ) = @_;

	return $session->get_database->get_column_type(
		$self->get_sql_name(),
		EPrints::Database::SQL_CLOB,
		!$self->get_property( "allow_null" ),
		undef,
		undef,
		$self->get_sql_properties,
	);
}

sub render_single_value
{
	my( $self, $session, $value ) = @_;
	
#	my @paras = split( /\r\n\r\n|\r\r|\n\n/ , $value );
#
#	my $frag = $session->make_doc_fragment();
#	foreach( @paras )
#	{
#		my $p = $session->make_element( "p" );
#		$p->appendChild( $session->make_text( $_ ) );
#		$frag->appendChild( $p );
#	}
#	return $frag;

	return $session->make_text( $value );
}

sub get_basic_input_elements
{
	my( $self, $session, $value, $basename, $staff, $obj, $one_field_component ) = @_;
	my @classes = defined $self->{dataset} ?
		( join('_', 'ep', $self->dataset->base_id, $self->name),
		join('_', 'eptype', $self->dataset->base_id, $self->type) ) :
		();

	my $readonly = ( $self->{readonly} && $self->{readonly} eq "yes" ) ? 1 : undef;
	push @classes, "ep_readonly" if $readonly;

	my %attributes = ( 
		name => $basename,
                id => $basename,
                class => join(' ', @classes),
                rows => $self->{input_rows},
                cols => $self->{input_cols},
                readonly => $readonly,
                wrap => "virtual",
                'aria-labelledby' => $self->get_labelledby( $basename ),
	);
	my $describedby = $self->get_describedby( $basename, $one_field_component );
	$attributes{'aria-describedby'} = $describedby if EPrints::Utils::is_set( $describedby ); 
	my $textarea = $session->make_element( "textarea", %attributes );
	$textarea->appendChild( $session->make_text( $value ) );

	return [ [ { el=>$textarea } ] ];
}


sub form_value_basic
{
	my( $self, $session, $basename ) = @_;

	# this version is just like that for Basic except it
	# does not remove line breaks.
	
	my $value = $session->param( $basename );

	return undef if( !defined($value) or $value eq "" );

	# replace UTF8-MB4 characters with a �
	$value=~s/[^\N{U+0000}-\N{U+FFFF}]/\N{REPLACEMENT CHARACTER}/g;
	
	return $value;
}

sub is_browsable
{
	return( 1 );
}

sub get_property_defaults
{
	my( $self ) = @_;
	my %defaults = $self->SUPER::get_property_defaults;
	$defaults{input_rows} = $EPrints::MetaField::FROM_CONFIG;
	$defaults{maxlength} = 65535;
	$defaults{sql_index} = 0;

	return %defaults;
}

sub get_xml_schema_type
{
	return "xs:string";
}

sub render_xml_schema_type
{
	my( $self, $session ) = @_;

	return $session->make_doc_fragment;
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

