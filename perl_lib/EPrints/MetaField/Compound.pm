######################################################################
#
# EPrints::MetaField::Compound
#
######################################################################
#
#
######################################################################

=pod

=for Pod2Wiki

=head1 NAME

B<EPrints::MetaField::Compound> - Magic type of field which actually 
combines several other fields into a data structure.

=head1 DESCRIPTION

not done

=over 4

=cut

package EPrints::MetaField::Compound;

use EPrints::MetaField;
@ISA = qw( EPrints::MetaField );

use strict;

sub new
{
	my( $class, %properties ) = @_;

	$properties{fields_cache} = [];

	my $self = $class->SUPER::new( %properties );

	my %seen;
	foreach my $inner_field ( @{$properties{fields}}, $self->extra_subfields )
	{
		if( !EPrints::Utils::is_set( $inner_field->{sub_name} ) )
		{
			EPrints->abort( "Sub fields of ".$self->dataset->id.".".$self->name." need the sub_name property to be set." );
		}
		if( $seen{$inner_field->{sub_name}}++ )
		{
			EPrints->abort( $self->dataset->id.".".$self->name." already contains a sub-field called '$inner_field->{sub_name}'" );
		}
		my $field = EPrints::MetaField->new( 
			show_in_html => 0, # don't show the inner field separately
		# these properties can be overridden
			export_as_xml => $properties{ "export_as_xml" },
			import => $properties{ "import" },
		# inner field's properties
			%{$inner_field},
			name => join('_', $self->name, $inner_field->{sub_name}),
		# these properties must be the same as the compound
			parent => $self,
			parent_name => $self->get_name(),
			dataset => $self->get_dataset(), 
			provenance => $self->get_property( "provenance" ),
			multiple => $properties{ "multiple" },
			volatile => $properties{ "volatile" },
		);
		# avoid circular references if we can
		Scalar::Util::weaken( $field->{parent} )
			if defined &Scalar::Util::weaken;

		push @{$self->{fields_cache}}, $field;
	}

	return $self;
}

=item @epdata = $field->extra_subfields()

Returns a list of sub-field definitions that will be added to this compound field.

This method should be overridden by sub-classes.

=cut

sub extra_subfields
{
	my( $self ) = @_;

	return ();
}

#Edited by ADB under direction from TDB
#sub render_value
sub render_value_actual
{
	my( $self, $session, $value, $alllangs, $nolink, $object ) = @_;

	#if( defined $self->{render_value} )
	#{
	#	return $self->call_property( "render_value",
	#		$session, 
	#		$self, 
	#		$value, 
	#		$alllangs, 
	#		$nolink,
	#		$object );
	#}

	my $class = "ep_" . $self->{name};
	my $readonly = ( $self->{readonly} && $self->{readonly} eq "yes" ) ? 1 : undef;
	$class .= " ep_readonly" if $readonly;
	my $result;

	if( !EPrints::Utils::is_set( $self->get_property( "as_list"  ) ) || $self->get_property( "as_list" ) == 0 ) 
	{

		# View as table

		my $table = $session->make_element( "div", class=>"ep_compound $class" );

		my $tr = $session->make_element( "div", "class"=>"ep_compound_header_row" );
		$table->appendChild( $tr );
		my $f = $self->get_property( "fields_cache" );
		my $index = 0;
		foreach my $field_conf ( @{$f} )
		{
			my $fieldname = $field_conf->{name};
			(my $subfieldname = $fieldname) =~ s/^$self->{name}_//;
			if (
				   ( $self->get_property( "multiple" ) && exists @{$value}[0]->{$subfieldname} )
				|| ( !$self->get_property( "multiple" ) && exists $value->{$subfieldname} )
				|| !$field_conf->{render_quiet}
			)
			{
				my $field = $self->{dataset}->get_field( $fieldname );
				my $th = $session->make_element( "div", class=>"ep_compound_header_cell", "data-row-cell-index"=>$index );
				$tr->appendChild( $th );
				$th->appendChild( $field->render_name( $session ) );
			}
		}
	
		if( $self->get_property( "multiple" ) )
		{
			$index = 0;
			foreach my $row ( @{$value} )
			{
				$table->appendChild( $self->render_single_value_row( $session, $row, $alllangs, $nolink, $object, $index ) );
				$index++;
			}
		}
		else
		{
			$table->appendChild( $self->render_single_value_row( $session, $value, $alllangs, $nolink, $object, undef ) );
		}

		$result = $table;
	}
	else
	{
		# View as list

		my $list = $session->make_element( "div", class=>"ep_compound_list $class" );

		my @records = $self->get_property( "multiple" ) ? @{$value} : @{[$value]};

		foreach my $record ( @records )
		{
			my $table = $session->make_element( "div" );

			my $f = $self->get_property( "fields_cache" );

			foreach my $field_conf ( @{$f} )
			{
				my $tr = $session->make_element( "div" );

				my $fieldname = $field_conf->{name};
				my $field = $self->{dataset}->get_field( $fieldname );
				my $th = $session->make_element( "div" );

				$tr->appendChild( $th );
				$th->appendChild( $field->render_name( $session ) );

				my $alias = $field->property( "sub_name" );
				my $td = $session->make_element( "div", class=>"ep_compound_header_cell" );

				$tr->appendChild( $td );
				$td->appendChild( 
					$field->render_value_no_multiple( 
						$session, 
						$record->{$alias}, 
						$alllangs,
						$nolink,
						$object ) );

				$table->appendChild( $tr );
			}

			$list->appendChild( $table );
		}

		$result = $list;
	}

	return $result;
}

sub render_single_value_row
{
	my( $self, $session, $value, $alllangs, $nolink, $object, $index ) = @_;

	my $tr;
	if ( defined $index )
	{
		$tr = $session->make_element( "div", "class"=>"ep_compound_data_row", "data-row-index"=>$index );
	}
	else
	{
		$tr = $session->make_element( "div", "class"=>"ep_compound_data_row" );
	}

	my $i = 0;
	foreach my $field (@{$self->{fields_cache}})
	{
		my $alias = $field->property( "sub_name" );
		if ( exists $value->{$alias} || !$field->property( "render_quiet" ) )
                {
			my $td = $session->make_element( "div", "class"=>"ep_compound_data_row_cell", "data-row-cell-index"=>$i );
			$tr->appendChild( $td );
			$td->appendChild( 
				$field->render_value_no_multiple( 
					$session, 
					$value->{$alias}, 
					$alllangs,
					$nolink,
					$object ) );
			$i++;
		}
	}

	return $tr;
}

sub render_single_value
{
	my( $self, $session, $value, $object ) = @_;

	my $table = $session->make_element( "div", class=>"ep_compound_single" );
	$table->appendChild( $self->render_single_value_row( $session, $value, $object, undef ) );
	return $table;
}

sub to_sax_basic
{
	my( $self, $value, %opts ) = @_;

	return if !EPrints::Utils::is_set( $value );

	foreach my $field (@{$self->{fields_cache}})
	{
		next if !$field->property( "export_as_xml" ) && !$opts{revision_generation};

		my $alias = $field->property( "sub_name" );
		my $v = $value->{$alias};
		# cause the sub-field to behave like it's a normal field
		local $field->{multiple} = 0;
		local $field->{parent_name};
		local $field->{name} = $field->{sub_name};
		$field->to_sax( $v, %opts );
	}
}

sub empty_value
{
	return {};
}

sub start_element
{
	my( $self, $data, $epdata, $state ) = @_;

	++$state->{depth};

	# if we're inside a sub-field just call it
	if( defined(my $field = $state->{handler}) )
	{
		$field->start_element( $data, $epdata, $state->{$field} );
	}
	# or initialise all fields at <creators>
	elsif( $state->{depth} == 1 )
	{
		foreach my $field (@{$self->property( "fields_cache" )})
		{
			local $data->{LocalName} = $field->property( "sub_name" );
			$state->{$field} = {%$state,
				depth => 0,
			};
			$field->start_element( $data, $epdata, $state->{$field} );
		}
	}
	# add a new empty value for each sub-field at <item>
	elsif( $state->{depth} == 2 && $self->property( "multiple" ) )
	{
		foreach my $field (@{$self->property( "fields_cache" )})
		{
			$field->start_element( $data, $epdata, $state->{$field} );
		}
	}
	# otherwise we must be starting a new sub-field value
	else
	{
		foreach my $field (@{$self->property( "fields_cache" )})
		{
			if( $field->property( "sub_name" ) eq $data->{LocalName} )
			{
				$state->{handler} = $field;
				last;
			}
		}
	}
}

sub end_element
{
	my( $self, $data, $epdata, $state ) = @_;

	# finish all fields
	if( $state->{depth} == 1 )
	{
		my $value = $epdata->{$self->name} = $self->property( "multiple" ) ? [] : $self->empty_value;

		foreach my $field (@{$self->property( "fields_cache" )})
		{
			local $data->{LocalName} = $field->property( "sub_name" );
			$field->end_element( $data, $epdata, $state->{$field} );

			my $v = delete $epdata->{$field->name};
			if( ref($value) eq "ARRAY" )
			{
				foreach my $i (0..$#$v)
				{
					$value->[$i]->{$field->property( "sub_name" )} = $v->[$i];
				}
			}
			else
			{
				$value->{$field->property( "sub_name" )} = $v;
			}

			delete $state->{$field};
		}
	}
	# end a new <item> for every field
	elsif( $state->{depth} == 2 && $self->property( "multiple" ) )
	{
		foreach my $field (@{$self->property( "fields_cache" )})
		{
			$field->end_element( $data, $epdata, $state->{$field} );
		}
	}
	# end of a sub-field's content
	elsif( $state->{depth} == 2 || ($state->{depth} == 3 && $self->property( "multiple" )) )
	{
		delete $state->{handler};
	}
	# otherwise call the sub-field
	elsif( defined(my $field = $state->{handler}) )
	{
		$field->end_element( $data, $epdata, $state->{$field} );
	}

	--$state->{depth};
}

sub characters
{
	my( $self, $data, $epdata, $state ) = @_;

	if( defined(my $field = $state->{handler}) )
	{
		$field->characters( $data, $epdata, $state->{$field} );
	}
}

# This type of field is virtual.
sub is_virtual
{
	my( $self ) = @_;

	return 1;
}

sub get_sql_type
{
	my( $self, $session ) = @_;

	return undef;
}

# UNUSED
sub get_alias_to_fieldname
{
	my( $self ) = @_;

	my %addr = ();

	my $f = $self->get_property( "fields_cache" );
	foreach my $sub_field ( @{$f} )
	{
		$addr{$sub_field->{sub_name}} = $sub_field->{name};
	}

	return %addr;
}

# UNUSED
sub get_fieldname_to_alias
{
	my( $self ) = @_;

	return reverse $self->get_alias_to_fieldname;
}

# Get the value of this field from the object. In this case this
# is quite complicated.
sub get_value
{
	my( $self, $object ) = @_;

	my $value;

	if( $self->property( "multiple" ) )
	{
		$value = [];
		foreach my $field (@{$self->{fields_cache}})
		{
			my $alias = $field->property( "sub_name" );
			my $v = $field->get_value( $object );
			foreach my $i (0..$#$v)
			{
				$value->[$i]->{$alias} = $v->[$i];
			}
		}
	}
	else
	{
		$value = {};
		foreach my $field (@{$self->{fields_cache}})
		{
			my $alias = $field->property( "sub_name" );
			$value->{$alias} = $field->get_value( $object );
		}
	}

	return $value;
}


sub set_value
{
	my( $self, $object, $value ) = @_;

	if( $self->get_property( "multiple" ) )
	{
		foreach my $field (@{$self->{fields_cache}})
		{
			my $alias = $field->property( "sub_name" );
			$field->set_value( $object, [
				map { $_->{$alias} } @$value
			] );
		}
	}
	else
	{
		foreach my $field (@{$self->{fields_cache}})
		{
			my $alias = $field->property( "sub_name" );
			$field->set_value( $object, $value->{$alias} );
		}
	}
}

sub get_input_col_titles
{
	my( $self, $session, $staff ) = @_;

	my @r  = ();
	my $f = $self->get_property( "fields_cache" );
	foreach my $field ( @{$f} )
	{
		my $fieldname = $field->get_name;
		my $sub_r = $field->get_input_col_titles( $session, $staff, 1 );

		if( !defined $sub_r )
		{
			$sub_r = [ $field->render_name( $session ) ];
		}

		push @r, @{$sub_r};
	}
	
	return \@r;
}

# assumes all basic input elements are 1 high, x wide.
sub get_basic_input_elements
{
	my( $self, $session, $value, $basename, $staff, $object, $one_field_component ) = @_;

	my $readonly = ( $self->{readonly} && ( $self->{readonly} eq "1" || $self->{readonly} eq "yes" ) ) ? 1 : 0;
	my $grid_row = [];

	foreach my $field (@{$self->{fields_cache}})
	{
		$field->{readonly} = $readonly unless defined $field->{readonly};
		my $alias = $field->property( "sub_name" );
		my $field_value = $value->{$alias} if EPrints::Utils::is_set( $value->{$alias} );
		$field_value ||= EPrints::Utils::is_set( $field->{default_value} ) ? $field->{default_value} : undef;
		my $part_grid = $field->get_basic_input_elements( 
					$session, 
					$field_value,
					$basename."_".$alias,
					$staff, 
					$object,
					$one_field_component );
		my $top_row = $part_grid->[0];
		push @{$grid_row}, @{$top_row};
	}

	return [ $grid_row ];
}

sub get_basic_input_ids
{
	my( $self, $session, $basename, $staff, $obj ) = @_;

	my @ids = ();

	foreach my $field (@{$self->{fields_cache}})
	{
		my $alias = $field->property( "sub_name" );
		push @ids, $field->get_basic_input_ids( 
					$session, 
					$basename."_".$alias, 
					$staff, 
					$obj,
					1 );
	}

	return( @ids );
}


sub form_value_basic
{
	my( $self, $session, $basename, $object ) = @_;
	
	my $value = {};

	foreach my $field (@{$self->{fields_cache}})
	{
		my $alias = $field->property( "sub_name" );
		my $v = $field->form_value_basic( $session, $basename."_".$alias, $object );
		$value->{$alias} = $v;
	}

	return undef if( !EPrints::Utils::is_set( $value ) );

	return $value;
}

sub validate
{
	my( $self, $session, $value, $object ) = @_;

	my $f = $self->get_property( "fields_cache" );
	my @problems;
	foreach my $field_conf ( @{$f} )
	{
		push @problems, $object->validate_field( $field_conf->{name} );
	}
	return @problems;
}

sub is_browsable
{
	return( 0 );
}


# don't index
sub get_index_codes
{
	my( $self, $session, $value ) = @_;

	return( [], [], [] );
}

sub get_property_defaults
{
	my( $self ) = @_;
	my %defaults = $self->SUPER::get_property_defaults;
	$defaults{fields} = $EPrints::MetaField::REQUIRED;
	$defaults{fields_cache} = $EPrints::MetaField::REQUIRED;
	$defaults{show_in_fieldlist} = 0;
	return %defaults;
}

sub get_xml_schema_type
{
	my( $self ) = @_;

	return $self->get_xml_schema_field_type;
}

sub render_xml_schema_type
{
	my( $self, $session ) = @_;

	my $type = $session->make_element( "xs:complexType", name => $self->get_xml_schema_type );

	my $all = $session->make_element( "xs:all" );
	$type->appendChild( $all );
	foreach my $field (@{$self->{fields_cache}})
	{
		my $name = $field->{sub_name};
		my $element = $session->make_element( "xs:element", name => $name, type => $field->get_xml_schema_type(), minOccurs => 0 );
		$all->appendChild( $element );
	}

	return $type;
}

sub get_search_conditions
{
	my( $self, $session, $dataset, $search_value, $match, $merge,
		$search_mode ) = @_;

	if( $match eq "EX" )
	{
		if( ref($search_value) ne "HASH" )
		{
			$search_value = $self->get_value_from_id( $session, $search_value );
		}
		return EPrints::Search::Condition->new(
			'=',
			$dataset,
			$self,
			$search_value
		);
	}

	return shift->get_search_conditions_not_ex( @_ );
}

sub get_search_conditions_not_ex
{
	my( $self, $session, $dataset, $search_value, $match, $merge,
		$search_mode ) = @_;

	EPrints::abort( "Unsupported attempt to search compound field on ".$session->get_id . "." . $self->{dataset}->confid . "." . $self->get_name );
}

# don't know how to turn a compound into a order value
sub ordervalue_single
{
	my( $self, $value, $session, $langid, $dataset ) = @_;

	return "";
}

sub get_value_from_id
{
	my( $self, $session, $id ) = @_;

	return {} if $id eq "NULL";

	my $value = {};

	my @parts = 
		map { URI::Escape::uri_unescape($_) }
		split /:/, $id, scalar(@{$self->property( "fields_cache" )});

	foreach my $field (@{$self->property( "fields_cache" )})
	{
		my $v = $field->get_value_from_id( $session, shift @parts );
		$value->{$field->property( "sub_name" )} = $v;
	}

	return $value;
}

sub get_id_from_value
{
	my( $self, $session, $value ) = @_;

	return "NULL" if !defined $value;

	my @parts;
	foreach my $field (@{$self->property( "fields_cache" )})
	{
		push @parts, $field->get_id_from_value(
			$session,
			$value->{$field->property( "sub_name" )}
		);
	}

	return join(":",
		map { URI::Escape::uri_escape($_, ":%") }
		@parts);
}

######################################################################

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

