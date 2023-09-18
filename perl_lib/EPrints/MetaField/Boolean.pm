######################################################################
#
# EPrints::MetaField::Boolean
#
######################################################################
#
#
######################################################################

=pod

=for Pod2Wiki

=head1 NAME

B<EPrints::MetaField::Boolean> - no description

=head1 DESCRIPTION

not done

=over 4

=cut

package EPrints::MetaField::Boolean;

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

	# Could be a 'SET' on MySQL/Postgres
	return $session->get_database->get_column_type(
		$self->get_sql_name(),
		EPrints::Database::SQL_VARCHAR,
		!$self->get_property( "allow_null" ),
		5, # 'TRUE' or 'FALSE'
		undef,
		$self->get_sql_properties,
	);
}

sub get_index_codes
{
	my( $self, $session, $value ) = @_;

	return( [], [], [] );
}


sub render_single_value
{
	my( $self, $session, $value ) = @_;

	return $session->html_phrase(
		"lib/metafield:".($value eq "TRUE"?"true":"false") );
}


sub get_basic_input_elements
{
	my( $self, $session, $value, $basename, $staff, $obj, $one_field_component ) = @_;

	my @classes;
	push @classes, join('_', 'ep', $self->{dataset}->base_id, $self->name);
	push @classes, join('_', 'eptype', $self->{dataset}->base_id, $self->type);
	push @classes, join('_', 'eptype', $self->{dataset}->base_id, $self->type, $self->{input_style}) if $self->{input_style};

	my $readonly = ( $self->{readonly} && $self->{readonly} eq "yes" ) ? 1 : undef;
	push @classes, "ep_readonly" if $readonly;
	my $onclick = ( $readonly ) ? "return false;" : "return true;";

	if( $self->{input_style} eq "menu" )
	{
		my @values = qw/ TRUE FALSE /;
		my %labels = (
			TRUE=> $session->phrase( $self->{confid}."_fieldopt_".$self->{name}."_TRUE" ),
			FALSE=> $session->phrase( $self->{confid}."_fieldopt_".$self->{name}."_FALSE" ),
		);
		my $height = 2;
		if( !$self->get_property( "required" ) )
		{
			push @values, "";
			$labels{""} = $self->unspecified_phrase( $session );
			$height++;
		}
		if( $self->get_property( "input_rows" ) )
		{
			$height = $self->get_property( "input_rows" );
		}

		my %settings = (
			height=>$height,
			values=>\@values,
			labels=>\%labels,
			name=>$basename,
			default=>$value,
			class=>join(" ", @classes),
			onclick=>$onclick,
			'aria-labelledby' => $self->get_labelledby( $basename ),
			'aria-describedby' => $self->get_describedby( $basename, $one_field_component ),
		);
		return [[{ el=>$session->render_option_list( %settings ) }]];
	}

	if( $self->{input_style} eq "radio" )
	{
		# render as radio buttons

		my $f = $session->make_element( "dl", class=>"ep_option_list ep_boolean_list" );
		
		my $inputs = {};
		$inputs->{true} = $session->render_noenter_input_field(
			type => "radio",
			checked=>( defined $value && $value eq 
					"TRUE" ? "checked" : undef ),
			name => $basename,
			id => $basename . "_true",
			readonly => $readonly,
			onclick => $onclick,
			class => join(" ", @classes),
			title => $session->html_phrase( $self->{confid} . "_radio_" . $self->{name} . "_true" ),
			value => "TRUE",
			'aria-labelledby' => $basename . "_true_label" );
		$inputs->{false} = $session->render_noenter_input_field(
			type => "radio",
			checked=>( defined $value && $value eq 
					"FALSE" ? "checked" : undef ),
			name => $basename,
			id => $basename . "_false",
			readonly => $readonly,
			onclick => $onclick,
			class => join(" ", @classes),
			title => $session->html_phrase( $self->{confid} . "_radio_" . $self->{name} . "_false" ),
			value => "FALSE",
			'aria-labelledby' => $basename . "_false_label" );
		if( !$self->get_property( "required" ) )
                {
                        $inputs->{unspecified} = $session->render_noenter_input_field(
                                type => "radio",
                                checked=>( !EPrints::Utils::is_set($value) ? "checked" : undef ),
				name => $basename,
                                id => $basename . "_unspecified",
                                class => join(" ", @classes),
                                title => $self->unspecified_phrase( $session ),
                                onclick => $onclick,
                                value => "",
				'aria-labelledby' => $basename . "_unspecified_label" )
		}

		my @options = qw/ true false /;
		@options = reverse( @options ) if $self->{false_first};
		push @options, "unspecified" if defined $inputs->{unspecified};
            
		foreach my $option ( @options )
		{
			my $dt = $session->make_element( "dt" );
			$dt->appendChild( $inputs->{$option} );
			$f->appendChild( $dt );
			my $dd = $session->make_element( "dd", id => $basename . "_" . $option . "_label" );
			$dd->appendChild( $session->html_phrase( $self->{confid} . "_radio_" . $self->{name} . "_" . $option ) ) unless $option eq "unspecified";
			$dd->appendChild( $self->unspecified_phrase( $session ) ) if $option eq "unspecified";
			$f->appendChild( $dd );
		}
		
		return [[{ el=>$f }]];
	}
			
	# render as checkbox (ugly)
	return [[{ el=>$session->render_noenter_input_field(
				type => "checkbox",
				checked => ( defined $value && $value eq "TRUE" ) ? "checked" : undef,
				name => $basename,
				class => join(" ", @classes),
				onclick => $onclick,
				value => "TRUE",  
				'aria-labelledby' => $self->get_labelledby( $basename ),
				'aria-describedby' => $self->get_describedby( $basename, $one_field_component ) ) }]];
}

sub form_value_basic
{
	my( $self, $session, $basename ) = @_;
	
	my $form_val = $session->param( $basename );
	if( 
		$self->{input_style} eq "radio" || 
		$self->{input_style} eq "menu" )
	{
		return if( !defined $form_val );
		return "TRUE" if( $form_val eq "TRUE" );
		return "FALSE" if( $form_val eq "FALSE" );
		return;
	}

	# checkbox can't be NULL.
	return "TRUE" if defined $form_val;
	return "FALSE";
}

sub get_unsorted_values
{
	my( $self, $session, $dataset, %opts ) = @_;

	return [ "TRUE", "FALSE" ];
}


sub render_search_input
{
	my( $self, $session, $searchfield ) = @_;
	
	# Boolean: Popup menu

	my @bool_tags = ( "EITHER", "TRUE", "FALSE" );
	my %bool_labels = ( 
"EITHER" => $session->phrase( "lib/searchfield:bool_nopref" ),
"TRUE"   => $session->phrase( "lib/searchfield:bool_yes" ),
"FALSE"  => $session->phrase( "lib/searchfield:bool_no" ) );

	my $value = $searchfield->get_value;	
	return $session->render_option_list(
		name => $searchfield->get_form_prefix,
		values => \@bool_tags,
		default => ( defined $value ? $value : $bool_tags[0] ),
		labels => \%bool_labels,
		'aria-labelledby' => $searchfield->get_form_prefix . "_label" );
}

sub from_search_form
{
	my( $self, $session, $basename ) = @_;

	my $val = $session->param( $basename );

	return unless defined $val;

	return( "FALSE" ) if( $val eq "FALSE" );
	return( "TRUE" ) if( $val eq "TRUE" );
	return;
}

sub render_search_description
{
	my( $self, $session, $sfname, $value, $merge, $match ) = @_;

	if( $value eq "TRUE" )
	{
		return $session->html_phrase(
			"lib/searchfield:desc_true",
			name => $sfname );
	}

	return $session->html_phrase(
		"lib/searchfield:desc_false",
		name => $sfname );
}


sub get_search_conditions_not_ex
{
	my( $self, $session, $dataset, $search_value, $match, $merge,
		$search_mode ) = @_;
	
	return EPrints::Search::Condition->new( 
		'=', 
		$dataset,
		$self, 
		$search_value );
}

sub get_property_defaults
{
	my( $self ) = @_;
	my %defaults = $self->SUPER::get_property_defaults;
	$defaults{input_style} = 0;
	$defaults{input_rows} = $EPrints::MetaField::FROM_CONFIG;
	$defaults{false_first} = 0;
	return %defaults;
}

sub render_xml_schema_type
{
	my( $self, $session ) = @_;

	my $type = $session->make_element( "xs:simpleType", name => $self->get_xml_schema_type );

	my $restriction = $session->make_element( "xs:restriction", base => "xs:string" );
	$type->appendChild( $restriction );
	foreach my $value (@{$self->get_unsorted_values})
	{
		my $enumeration = $session->make_element( "xs:enumeration", value => $value );
		$restriction->appendChild( $enumeration );
	}

	return $type;
}

sub unspecified_phrase
{
	my( $self, $session ) = @_;

	return $session->html_phrase( $self->{confid} . "_radio_" . $self->{name} . "_unspecified" ) if $session->get_lang->has_phrase( $self->{confid} . "_radio_" . $self->{name} . "_unspecified" );
	return $session->html_phrase( $self->{confid} . "_fieldopt_" . $self->{name} . "_unspecified" ) if $session->get_lang->has_phrase( $self->{confid} . "_radio_" . $self->{name} . "_unspecified" );
        return $session->html_phrase( $self->{confid} . "_radio_" . $self->{name} . "_" ) if $session->get_lang->has_phrase( $self->{confid} . "_radio_" . $self->{name} . "_" );
        return $session->html_phrase( $self->{confid} . "_fieldopt_" . $self->{name} . "_" ) if $session->get_lang->has_phrase( $self->{confid} . "_radio_" . $self->{name} . "_" );
        return $session->html_phrase( "lib/metafield:unspecified_selection" );
}

sub is_set 
{
	my ( $self, $value )  = @_;
		
	if ( defined $value && $value eq "FALSE" )
	{
		return $self->property( "input_style" ) eq "radio" || $self->property( "input_style" ) eq "menu";
	}
	return EPrints::Utils::is_set( $value );
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

=begin LICENSE

