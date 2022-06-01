######################################################################
#
# EPrints::DataObj::MetaField
#
######################################################################
#
#
######################################################################

=pod

=for Pod2Wiki

=head1 NAME

B<EPrints::DataObj::MetaField> - metadata fields

=head1 DESCRIPTION

This is an internal class that should not be used outside 
L<EPrints::Database>.

=head1 CORE METADATA FIELDS

=over 4

=item metafieldid (counter)

The unique identifier for the metafield.

=item mfdatasetid (set)

The dataset two which this metafield belongs.

=item name (text)

The name of this metafield.

=item type (set)

The type of this metafield.

=item provenance (set)

The provenance of this metafield.

=item phrase_name (multilang, multiple)

The phrase name(s)(labels) potentially in multiple languages for 
this metafield.

=item phrase_help (multilang, multiple)

The phrase help text(s) potentially in multiple languages for
this metafield.

=item required (boolean)

Whether this metafield is required for the dataset.

=item multiple (boolean)

Whether this metafield can have multiple values for a data object.

=item allow_null (boolean)

Whether this metafield can have a null value.

=item export_as_xml (boolean)

Whether this metafield can be exported in XML.

=item volatile (boolean)

Whether this metafield stores a volatile data.

=item min_resolution (set)

The minimum time resolution (second, minute, hour, day, month or 
year) for this metafield if it is a timestamp/datestamp.

=item sql_index (boolean)

Whether an SQL index should be created for this metafield.

=item render_input (text)

A different or bespoke function to render the input field for
this metafield.

=item render_value (text)

A different or bespoke function to render the value for this 
metafield.

=item input_ordered (boolean)

Whether the input for this metafield is ordered.

=item maxlength (int)

The maximum length for this metafield if it is a text or
subclass of a text field.

=item browse_link (boolean)

The link to a browse view for this metafield if it is a subject
metafield.

=item top (text)

The top subject in the subject tree that should be used as 
options for this subject metafield.

=item datasetid (text)

The dataset ID for this metafield, if it is a search, subobject,
dataobjref, fields, itemref or file field.

=item set_name (text)

The name of the file that contains the options for this namedset
metafield.

=item options (text)

The commas separated list of options for this set metafield.

=item render_order (set)

The order to render a name if this metafield is for a name.

=item hide_honourific (boolean)

Whether to hide the honourfic sub-field if this is a name 
metafield.

=item hide_lineage (boolean)

Whether to hide the lineage sub-field if this is a name
metafield.

=item family_first (boolean)

Whether to render the family name sub-field before the given
name if this is a name metafield.

=item input_style (set)

A particular style for displaying the input form element for
this metafield.

=item input_rows (int)

The number of input rows for this metafield.

=item input_cols (int)

The number of input columns for this metafield.

=item input_boxes (int)

The number of input boxes for this metafield.

=item sql_counter (text)

The name to give to the sql counter for this counter 
metafield.  Typically the same as the metafield's name.

=item default_value (text)

The default value for this metafield.

=back

=head1 REFERENCES AND RELATED OBJECTS

=over 4

=item parent (itemref)

The parent metafield this metafield belongs to, if it is a sub-field.

=item fields (subobject, multiple)

Sub-fields of this metafield.

=back

=head1 INSTANCE VARIABLES

See L<EPrints::DataObj|EPrints::DataObj#INSTANCE_VARIABLES>.

=head1 METHODS

=cut

package EPrints::DataObj::MetaField;

@ISA = qw( EPrints::DataObj::SubObject );

use Data::Dumper;

use strict;


######################################################################
=pod

=head2 Utility Methods

=cut
######################################################################

######################################################################
=pod

=over 4

=item @ids = EPrints::DataObj::MetaField::dataset_ids( $repo )

Returns array of all dataset IDs for non-virtual datasets in C<$repo>.

=cut
######################################################################

sub dataset_ids
{
	my( $repo ) = @_;

	my @ids = sort $repo->get_dataset_ids;

	@ids = grep { !$repo->dataset( $_ )->is_virtual } @ids;

	return @ids;
}


######################################################################
=pod

=item $dataset_label = EPrints::DataObj::MetaField::render_dataset_id( $repo, $id )

Returns XHTML DOM rendering of phrase for dataset with C<$id>.

=cut
######################################################################

sub render_dataset_id
{
	my( $repo, $id ) = @_;

	return $repo->html_phrase( "datasetname_$id" );
}


######################################################################
=pod

=item $options = EPrints::DataObj::MetaField::options_fromform( $value )

Returns an array reference of options from the comma-separated 
C<$value> provided.

=cut
######################################################################

sub options_fromform
{
	my( $value ) = @_;

	return [grep { length($_) } split /\s*,\s*/, $value];
}


######################################################################
=pod

=item $options_str = EPrints::DataObj::MetaField::options_toform( $value )

Returns a comma-separated string of options from the array reference
C<$value> provided.

=cut
######################################################################

sub options_toform
{
	my( $value ) = @_;

	return join ',', @{ref($value) eq "ARRAY" ? $value : []};
}


######################################################################
=pod

=item $boolean = EPrints::DataObj::MetaField::boolean_fromform( $value )

Returns C<true> or C<false>, (literally C<1> or C<0>) depending on the
C<$value> representation of a boolean in a form. 

=cut
######################################################################

sub boolean_fromform
{
	my( $value ) = @_;

	return undef if !defined $value;

	return defined $value && $value eq "TRUE" ? 1 : 0;
}


######################################################################
=pod

=item $boolean_str = EPrints::DataObj::MetaField::boolean_toform( $value )

Returns a string representation of a boolean (C<"TRUE">, C<"FALSE"> or
C<undef>) depending on the to form C<$value> provided.

=cut
######################################################################

sub boolean_toform
{
	my( $value ) = @_;

	return undef if !defined $value;

	return $value ? "TRUE" : "FALSE";
}

sub _get_sub_field_types
{
	my @types = &_get_field_types;

	@types = grep { $_ ne "compound" and $_ ne "multilang" } @types;

	return @types;
}

sub _get_field_types
{
	my @types;

	return qw(
			arclanguage
			bigint
			boolean
			compound
			counter
			date
			email
			float
			int
			itemref
			longtext
			multilang
			name
			namedset
			pagerange
			search
			secret
			set
			subject
			text
			time
			timestamp
			url
	);
}


######################################################################
=back

=head2 Constructor Methods

=cut
######################################################################

######################################################################
=pod

=over 4

=item $metafield = EPrints::DataObj::MetaField->new_from_field( $repo, $field, [ $dataset ] )

Returns a new metafield data object based on C<$field>.

C<$dataset> is determined from dataset ID of class (i.e. C<metafield>)
if unset.

=cut
######################################################################

sub new_from_field
{
	my( $class, $repo, $field, $dataset ) = @_;

	my $epdata = {};

	$dataset ||= $repo->dataset( $class->get_dataset_id );

	for($dataset->fields)
	{
		next if $_->is_virtual;
		next if !exists $field->{$_->name};
		$epdata->{$_->name} = EPrints::Utils::clone( $field->{$_->name} );
	}

	if( $epdata->{type} eq "set" )
	{
		$epdata->{options} = join ',', @{
			ref($epdata->{options}) eq 'ARRAY' ? $epdata->{options} : []
		};
	}

	$epdata->{mfdatasetid} = $field->dataset->id;

	my $self = $class->new_from_data( $repo, $epdata, $dataset );

	my @fields;
	for(@{$field->{fields_cache}})
	{
		push @fields, $class->new_from_field( $repo, $_, $dataset );
	}
	$self->set_value( "fields", \@fields ) if scalar @fields;

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

=over 4

=item $thing = EPrints::DataObj::MetaField->get_system_field_info

Returns an array describing the system metadata fields of the
metafield dataset.

=cut
######################################################################

sub get_system_field_info
{
    my( $class ) = @_;

    return
    (
        { name=>"metafieldid", type=>"counter", sql_counter => "metafieldid", },

        { name=>"mfdatasetid", type=>"set", required=>1, input_rows=>1,
            options => [],
            input_tags => \&dataset_ids,
            render_option => \&render_dataset_id,
        },

        { name=>"parent", type=>"itemref", datasetid=>"metafield", },

        { name=>"fields", type=>"subobject", datasetid=>"metafield", multiple=>1, dataobj_fieldname=>"parent", dataset_fieldname=>"" },

        { name=>"name", type=>"text", required=>1, input_cols=>10 },

        { name=>"type", type=>"set", required=>1,
            input_style => "long",
            options => [&_get_field_types],
        },

        { name=>"provenance", type=>"set", required=>1,
            options => [qw( core config user )],
        },

        &_get_property_fields,

        { name=>"phrase_name", type=>"multilang", multiple=> 1, required=>0,
            fields => [
                { sub_name=>"text", type=>"text", }
        ]},

        { name=>"phrase_help", type=>"multilang", multiple => 1, required=>0,
            fields => [
                { sub_name=>"text", type=>"longtext", }
        ]},
    );
}

sub _get_property_sub_fields
{
    return
        map { $_->{sub_name} = delete $_->{name}; $_ }
        grep { $_->{name} ne "multiple" }
        &_get_property_fields;
}

sub _get_property_fields
{
    return (
        { name=>"required", type=>"boolean", fromform=>\&boolean_fromform, toform=>\&boolean_toform, input_style => "menu", },
        { name=>"multiple", type=>"boolean", fromform=>\&boolean_fromform, toform=>\&boolean_toform, input_style => "menu", },
        { name=>"allow_null", type=>"boolean", fromform=>\&boolean_fromform, toform=>\&boolean_toform, input_style => "menu", },
        { name=>"export_as_xml", type=>"boolean", fromform=>\&boolean_fromform, toform=>\&boolean_toform, input_style => "menu", },
        { name=>"volatile", type=>"boolean", fromform=>\&boolean_fromform, toform=>\&boolean_toform, input_style => "menu", },

        { name=>"min_resolution", type=>"set",
            options => [qw( year month day hour minute second )],
        },

        { name=>"sql_index", type=>"boolean", fromform=>\&boolean_fromform, toform=>\&boolean_toform, input_style => "menu", },

        { name=>"render_input", type=>"text" },
        { name=>"render_value", type=>"text" },

        { name=>"input_ordered", type=>"boolean", fromform=>\&boolean_fromform, toform=>\&boolean_toform, input_style => "menu", },

        { name=>"maxlength", type=>"int", input_cols => 5, },

        { name=>"browse_link", type=>"text", input_cols=>10, },
        { name=>"top", type=>"text", input_cols=>10, },

        { name=>"datasetid", type=>"text", input_cols=>10, },

        { name=>"set_name", type=>"text", input_cols=>10, },
        { name=>"options", type=>"text", },
        { name=>"render_order", type=>"set", input_rows=>1,
            options => [qw( fg gf )]
        },
        { name=>"hide_honourific", type=>"boolean", fromform=>\&boolean_fromform, toform=>\&boolean_toform, input_style => "menu", input_rows=>1, },
        { name=>"hide_lineage", type=>"boolean", fromform=>\&boolean_fromform, toform=>\&boolean_toform, input_style => "menu", input_rows=>1, },
        { name=>"family_first", type=>"boolean", fromform=>\&boolean_fromform, toform=>\&boolean_toform, input_style => "menu", input_rows=>1, },

        { name=>"input_style", type=>"set",
            options => [qw( menu radio long medium short )],
        },
        { name=>"input_rows", type=>"int", input_cols=>3, },
        { name=>"input_cols", type=>"int", input_cols=>3, },
        { name=>"input_boxes", type=>"int", input_cols=>3, },

        { name=>"sql_counter", type=>"text", sql_index=>0 },
        { name=>"default_value", type=>"text", sql_index=>0 },
    );
}

######################################################################
=pod

=item $dataset = EPrints::DataObj::MetaField->get_dataset_id

Returns the ID of the L<EPrints::DataSet> object to which this record 
belongs.

=cut
######################################################################

sub get_dataset_id
{
	return "metafield";
}


######################################################################
=pod

=item $dataset = EPrints::DataObj::MetaField->get_parent_dataset_id

Returns the ID of the L<EPrints::DataSet> object to which this 
record's parent belongs.

=cut
######################################################################

sub get_parent_dataset_id { "metafield" }


######################################################################
=pod

=item $defaults = EPrints::DataObj::MetaField->get_defaults( $repo, $data, [ $dataset ] )

Returns default values for this object based on the starting C<$data>.

Get C<$dataset> from class if not defined.

=cut
######################################################################

sub get_defaults
{
	my( $class, $repo, $data, $dataset ) = @_;
	
	$class->SUPER::get_defaults( $repo, $data, $dataset );

	$data->{"type"} = "text";

	# This is set by DataSet for core and config fields
	$data->{"provenance"} = "user";

	return $data;
}


######################################################################
=pod

=back

=head2 Object Methods

=cut
######################################################################

######################################################################
=pod

=over 4

=item $defaults = $metafield->get_property_defaults( $repo, $type )

Gets the property defaults for metafield C<$type>.

=cut
######################################################################

sub get_property_defaults
{
    my( $self, $type ) = @_;

    my $repo = $self->{session};

    my $field_defaults = $repo->get_field_defaults( $type );
    return $field_defaults if defined $field_defaults;

    my $class = $type;
    $class =~ s/[^a-zA-Z0-9_]//g; # don't let badness into eval()
    $class = "EPrints::MetaField::\u$class";
    eval "use $class;";
    if( $@ )
    {
        return undef;
    }

    my $prototype = bless {
            repository => $repo
        }, $class;

    return { $prototype->get_property_defaults };
}


######################################################################
=pod

=item $str = $metafield->dump

Dump the fields configuration as used in C<cfg.d>.

=cut
######################################################################

sub dump
{
    my( $self ) = @_;

    my $dd = Data::Dumper->new( [$self->perl_struct] );
    $dd->Terse( 1 );
    $dd->Sortkeys( 1 );

    return "\t" . $dd->Dump;
}


######################################################################
=pod

=item $parent = $metafield->get_parent_id

Returns the parent ID for this metafield.

Alias for:

 $metafield->value( "parent" );

=cut
######################################################################

sub get_parent_id { shift->value( "parent" ) }


######################################################################
=pod

=item $ok = $metafield->remove

Remove the field and any sub-fields from the database.

=cut
######################################################################

sub remove
{
	my( $self ) = @_;

	# avoid infinite loops
	if( !$self->is_set( "parent" ) )
	{
		my $sub_fields = $self->value( "fields" );
		$_->remove for @$sub_fields;
	}

	return $self->SUPER::remove;
}


######################################################################
=pod

=item $path = $metafield->config_path

Returns the root directory of the repository configuration path.

=cut
######################################################################

sub config_path
{
	my( $self ) = @_;

	return $self->{session}->config( "config_path" );
}


######################################################################
=pod

=item $filename = $metafield->config_filename( $dataset )

Returns the location of the cfg.d config file for the provided
C<$dataset>.

=cut
######################################################################

sub config_filename
{
	my( $self, $dataset ) = @_;

	return $self->config_path . "/cfg.d/zz_webcfg_" . $dataset->base_id . "_fields.pl";
}


######################################################################
=pod

=item $filename = $metafield->phrases_filename( $langid )

Returns the location of the XML phrases file for provided C<$lang>.

=cut
######################################################################

sub phrases_filename
{
	my( $self, $langid ) = @_;

	return $self->config_path."/lang/$langid/phrases/zz_webcfg.xml";
}


######################################################################
=pod

=item $filename = $metafield->workflow_filename( $dataset )

Returns the location of the workflow file for the provided 
C<$dataset>.

=cut
######################################################################

sub workflow_filename
{
	my( $self, $dataset ) = @_;

	return $self->config_path . "/workflows/".$dataset->base_id."/default.xml";
}


######################################################################
=pod

=item $ok = $metafield->add_to_phrases

Adds the phrases defined by this metafield to the system.

=cut
######################################################################

sub add_to_phrases
{
	my( $self, $prefix ) = @_;

	my $repo = $self->{session};
	my $xml = $repo->xml;

	my $ok = 1;

	my $name = $self->value( "name" );
	my $dataset = $repo->dataset( $self->value( "mfdatasetid" ) );

	if( !defined $prefix )
	{
		foreach my $sub_field (@{$self->value( "fields" )})
		{
			$sub_field->add_to_phrases( $name );
		}
	}

	my %phrases;

	foreach my $type (qw( name help ))
	{
		my $values = $self->value( "phrase_$type" );
		foreach my $phrase (@$values)
		{
			$phrase = EPrints::Utils::clone( $phrase );
			$phrase->{lang} ||= "en";
			my $name = join('_', $dataset->base_id, "field$type", $self->value( "name" ) );
			$phrases{$phrase->{lang}}->{$name} = $phrase->{text};
		}
	}

	# Add default phrases for sub-fields/options
	foreach my $field_data ($self->{data},@{$self->{data}->{fields}||[]})
	{
		my $type = $field_data->{"type"};
		my $field_name = $name;
		if( exists($field_data->{"sub_name"}) )
		{
			$field_name .= "_" . $field_data->{"sub_name"};
			foreach my $langid (keys %phrases)
			{
				my $phraseid = join('_', $dataset->base_id, "fieldname", $field_name );
				my $phrase = _opt_to_phrase($field_name);
				$phrases{$langid}->{$phraseid} = $phrase;
			}
		}
		if( $type eq "set" && defined $field_data->{options} )
		{
			for(split /\s*,\s*/, $field_data->{options})
			{
				my $phraseid = join('_', $dataset->base_id, "fieldopt", $field_name, $_ );
				my $phrase = _opt_to_phrase($_);
				foreach my $langid (keys %phrases)
				{
					$phrases{$langid}->{$phraseid} = $phrase;
				}
			}
		}
	}

	foreach my $langid (keys %phrases)
	{
		my $file_name = $self->phrases_filename( $langid );
		my $doc;
		if( !-e $file_name )
		{
			$doc = $self->_phrases_empty();
		}
		else
		{
			$doc = $repo->xml->parse_file( $file_name );
		}
		my $xml = EPrints::XML->new( $repo, doc => $doc );
		my $phrases = $doc->documentElement;

		while(my( $name, $text ) = each %{$phrases{$langid}})
		{
			my $phrase = $xml->create_element( "epp:phrase", id => $name );
			my $html = eval { $xml->parse_xml_string( $text ) };
			if( defined $html )
			{
				$phrase->appendChild( $xml->clone( $html->documentElement ) );
				$xml->dispose( $html );
			}
			else
			{
				$phrase->appendChild( $xml->create_text_node( $text ) );
			}
			my $old_phrase;
			foreach my $node ($phrases->childNodes)
			{
				if( $node->localName eq "phrase" &&
					$node->hasAttribute("id") &&
					$node->getAttribute("id") eq $name )
				{
					$old_phrase = $node;
					last;
				}
			}
			if( defined $old_phrase )
			{
				$phrases->replaceChild( $phrase, $old_phrase );
			}
			else
			{
				$phrases->appendChild( $xml->create_text_node( "\n\t" ) );
				$phrases->appendChild( $phrase );
			}
		}

		if( open(my $fh, ">", $file_name) )
		{
			binmode($fh, ":utf8");
			print $fh $xml->to_string( $doc );
			close($fh);
		}
		else
		{
			$repo->get_repository->log( "Failed to open $file_name for writing: $!" );
			$ok = 0;
		}

		$xml->dispose( $doc );
	}

	return $ok;
}


######################################################################
=item $ok = $metafield->add_to_dataset

Add this metafield to the dataset specified by its C<mfdatasetid> 
value.

Returns boolean dependent on success adding to the dataset.

=cut
######################################################################

sub add_to_dataset
{
	my( $self ) = @_;

	my $repo = $self->{session};
	my $dataset = $repo->dataset( $self->value( "mfdatasetid" ) );

	return 1 if $dataset->has_field( $self->value( "name" ) );

	my $field = $self->make_field_object();
	$dataset->register_field( $field );

	return $self->_update_cfg_d( $repo, $dataset );
}


######################################################################
=pod

=item $ok = $metafield->remove_from_dataset

Remove this metafield from the dataset specified by its C<mfdatasetid>
value.

Returns boolean dependent on success removing from the dataset.

=cut
######################################################################

sub remove_from_dataset
{
	my( $self ) = @_;

	my $repo = $self->{session};
	my $dataset = $repo->dataset( $self->value( "mfdatasetid" ) );

	my $field = $dataset->field( $self->value( "name" ) );
	return 1 if !defined $field;

	$dataset->unregister_field( $field );

	return $self->_update_cfg_d( $repo, $dataset );
}


######################################################################
=pod

=item $ok = $metafield->add_to_database

Add this metafield to the database.

Returns boolean dependent on success adding to the database.

=cut
######################################################################

sub add_to_database
{
	my( $self ) = @_;

	my $repo = $self->{session};
	my $dataset = $repo->dataset( $self->value( "mfdatasetid" ) );

	my $field = $dataset->field( $self->value( "name" ) );

	return $repo->get_database->add_field( $dataset, $field );
}


######################################################################
=pod

=item $ok = $metafield->remove_from_database

Remove this field from the database.

Returns boolean dependent on success removing from the database.

=cut
######################################################################

sub remove_from_database
{
	my( $self ) = @_;

	my $repo = $self->{session};
	my $dataset = $repo->dataset( $self->value( "mfdatasetid" ) );

	my $field = $dataset->field( $self->value( "name" ) );
	return 1 if !defined $field;

	return $repo->get_database->remove_field( $dataset, $field );
}


######################################################################
=pod

=item $ok = $metafield->add_to_workflow

Add this metafield to the workflow in the C<Misc.> section.

Returns boolean dependent on success adding to the workflow.

=cut
######################################################################

sub add_to_workflow
{
	my( $self ) = @_;

	my $repo = $self->{session};

	my $ok = 1;

	my $dataset = $repo->dataset( $self->value( "mfdatasetid" ) );

	my $file_name = $self->workflow_filename( $dataset );
	return $ok if !-e $file_name;

	my $doc = $repo->xml->parse_file( $file_name );

	my $xml = EPrints::XML->new( $repo, doc => $doc );
	my $workflow = $doc->documentElement;

	# return if this field is already referred to in the workflow
	foreach my $field ($workflow->getElementsByTagName( "field" ) )
	{
		if( $field->getAttribute( "ref" ) eq $self->get_value( "name" ) )
		{
			return $ok;
		}
	}

	my( $flow ) = $workflow->getElementsByTagName( "flow" );

	my $stage_ref;
	for($flow->childNodes)
	{
		if( $_->nodeName eq "stage" &&
			$_->hasAttribute( "ref" ) &&
			$_->getAttribute( "ref" ) eq "local"
		)
		{
			$stage_ref = $_;
			last;
		}
	}
	if( !defined( $stage_ref ) )
	{
		$stage_ref = $xml->create_element( "stage",
			ref => "local"
		);
		$flow->appendChild( $stage_ref );
		$flow->appendChild( $xml->create_text_node( "\n\t" ) );
	}

	my $stage;
	for($workflow->childNodes)
	{
		if( $_->nodeName eq "stage" &&
			$_->hasAttribute( "name" ) &&
			$_->getAttribute( "name" ) eq "local"
		)
		{
			$stage = $_;
			last;
		}
	}

	if( !defined( $stage ) )
	{
		$stage = $xml->create_element( "stage",
			name => "local"
		);
		$stage->appendChild( $xml->create_text_node( "\n\t" ) );
		$workflow->appendChild( $xml->create_text_node( "\t" ) );
		$workflow->appendChild( $stage );
		$workflow->appendChild( $xml->create_text_node( "\n\n" ) );
	}

	my $component = $xml->create_element( "component" );
	my $field = $xml->create_element( "field",
		ref => $self->value( "name" )
	);
	$stage->appendChild( $xml->create_text_node( "\t" ) );
	$stage->appendChild( $component );
	$stage->appendChild( $xml->create_text_node( "\n\t" ) );
	$component->appendChild( $field );

	if( open(my $fh, ">", $file_name) )
	{
		binmode($fh, ":utf8");
		print $fh $xml->to_string($doc);
		close($fh);
	}
	else
	{
		$repo->get_repository->log( "Failed to open $file_name for writing: $!" );
		$ok = 0;
	}

	return $ok;
}


######################################################################
=pod

=item $ok = $metafield->remove_from_workflow

Remove all occurrences of this field from the workflow. Will remove 
the C<local> stage if it is empty.

Returns boolean dependent on success removing from the workflow.

=cut
######################################################################

sub remove_from_workflow
{
	my( $self ) = @_;

	my $repo = $self->{session};

	my $ok = 1;

	my $dataset = $repo->dataset( $self->value( "mfdatasetid" ) );
	my $name = $self->value( "name" );

	my $file_name = $self->workflow_filename( $dataset );
	return $ok if !-e $file_name;

	my $doc = $repo->xml->parse_file( $file_name );

	my $workflow = $doc->documentElement;

	my( $flow ) = $workflow->getElementsByTagName( "flow" );

	# find and remove all occurrences of the $name field
	foreach my $field ($workflow->getElementsByTagName( "field" ))
	{
		if(
			$field->hasAttribute( "ref" ) and
			$field->getAttribute( "ref" ) eq $name
		)
		{
			my $component = $field->parentNode;
			$component->removeChild( $field );
			# remove the component as well if it doesn't contain any other
			# fields
			if( $component->getElementsByTagName( "field" )->length == 0 )
			{
				$component->parentNode->removeChild( $component );
			}
		}
	}

	my $remove_local = 0;

	# if the "local" stage contains no components or fields, remove it
	foreach my $stage ($workflow->getElementsByTagName( "stage" ))
	{
		if(
			$stage->hasAttribute( "name" ) and
			$stage->getAttribute( "name" ) eq "local"
		)
		{
			if( $stage->getElementsByTagName( "component" )->length == 0 and
				$stage->getElementsByTagName( "field" )->length == 0
			)
			{
				$workflow->removeChild( $stage );
				$remove_local = 1;
			}
			last;
		}
	}

	# remove the reference to the local stage if we deleted it
	if( $remove_local )
	{
		foreach my $stage ( $flow->getElementsByTagName( "stage" ) )
		{
			if(
				$stage->hasAttribute( "ref" ) and
				$stage->getAttribute( "ref" ) eq "local"
			)
			{
				$flow->removeChild( $stage );
				last;
			}
		}
	}

	open(my $fh, ">", $file_name) or EPrints::abort "Failed to open $file_name for writing: $!";
	binmode($fh, ":utf8");
	print $fh $repo->xml->to_string( $doc );
	close($fh);

	$repo->xml->dispose( $doc );

	return $ok;
}


######################################################################
=pod

=item $data = $metafield->perl_struct( $prefix )

Returns the Perl data structure representation of this field, as you 
would find defined in the configuration or L<EPrints::DataObj> 
classes.

If C<$prefix> is defined returns the Perl data structure for the 
fields property, where C<$prefix> is the fieldname of the parent 
field.

=cut
######################################################################

sub perl_struct
{
	my( $self, $prefix ) = @_;

	my $dataset = $self->{dataset};
EPrints->abort( $self ) if !$dataset;

	my $data = {};

	foreach my $field ($dataset->fields)
	{
		next if defined $field->get_property( "sub_name" );
		next if $field->is_virtual;
		next if
			$field->name eq "metafieldid" or
			$field->name eq "mfdatasetid" or
			$field->name eq "parent" or
			$field->name eq "phrase_name" or
			$field->name eq "phrase_help"
			;
		my $value = $field->get_value( $self );
		if( EPrints::Utils::is_set( $value ) )
		{
			$data->{$field->name} = $value;
		}
	}

	my $sub_fields = $self->value( "fields" );
	foreach my $sub_field (@$sub_fields)
	{
		$data->{fields} = [] if !defined $data->{fields};
		push @{$data->{fields}}, $sub_field->perl_struct( $self->value( "name" ) );
	}

	# Fix for document.main (options => [])
	if( $data->{type} eq "set" )
	{
		if( !defined $data->{options} )
		{
			$data->{options} = [];
		}
		else
		{
			$data->{options} = [split /\s*,\s*/, $data->{options}];
		}
	}

	if( defined $prefix )
	{
		$data->{sub_name} = delete $data->{name};
		$data->{sub_name} =~ s/^${prefix}_//;
	}

	return $data;
}

# The initial phrases file (sorry, English only)
sub _phrases_empty
{
	my( $self ) = @_;

	my $repo = $self->{session};

	my $doc = $repo->get_lang->create_phrase_doc( $repo );
	my $phrases = $doc->documentElement;

	my $phrase = $doc->createElement( "epp:phrase" );
	$phrase->setAttribute( id=>"metapage_title_local" );
	$phrase->appendChild( $doc->createTextNode( "Misc." ) );

	$phrases->appendChild( $phrase );

	return $doc;
}

# convert an option to a phrase - this is just for convenience
sub _opt_to_phrase
{
	my( $name ) = @_;

	$name =~ s/_/ /g;
	$name =~ s/\b(\w)/\u$1/g;

	return $name;
}


######################################################################
=pod

=item $field = $metafield->make_field_object

Makes and returns a new field object based on this metafield.

=cut
######################################################################

sub make_field_object
{
	my( $self ) = @_;

	my $repo = $self->{session};

	my $dataset = $repo->dataset( $self->value( "mfdatasetid" ) );

	my $fielddata = $self->perl_struct();

	return undef if !EPrints::Utils::is_set( $fielddata->{name} );
	return undef if !EPrints::Utils::is_set( $fielddata->{type} );

	$fielddata->{provenance} = "user"; # always user

	my $field = EPrints::MetaField->new( 
		repository => $repo,
		dataset => $dataset, 
		%{$fielddata} );	

	return $field;
}

######################################################################
=pod

=item $ok = $metafield->add_to_repository

Adds this field to the repository.

Returns boolean dependent on success adding to the repository.

=cut
######################################################################

sub add_to_repository
{
	my( $self ) = @_;

	return 1 if $self->value( "provenance" ) ne "user"; # ?!

	my $rc = 1;

	$rc &&= $self->add_to_dataset();
	$rc &&= $self->add_to_database();
	$rc &&= $self->add_to_workflow();
	$rc &&= $self->add_to_phrases();

	return $rc;
}


######################################################################
=pod

=item $ok = $mf->remove_from_repository

Remove this field from the repository.

Returns boolean dependent on success removing from the repository.

=cut
######################################################################

sub remove_from_repository
{
	my( $self ) = @_;

	return 1 if $self->value( "provenance" ) ne "user"; # ?!

	my $rc = 1;

	$rc &&= $self->remove_from_workflow();
	$rc &&= $self->remove_from_database();
	$rc &&= $self->remove_from_dataset();
	# don't bother removing phrases

	return $rc;
}


######################################################################
=pod

=item $problems = $metafield->validate( $repository )

Returns any problems associated with this metafield as an array 
reference.

=cut
######################################################################

sub validate
{
	my( $self, $repository ) = @_;

	my @problems;

	my $epdata = $self->perl_struct();
	push @problems, $self->_validate_epdata( $epdata );

	for(@{$self->value("fields")})
	{
		push @problems, @{$_->validate( $repository )};
	}

	return \@problems;
}

sub _validate_epdata
{
	my( $self, $epdata ) = @_;

	my $repo = $self->get_session;

	my @problems;

	if( !defined $epdata->{"type"} )
	{
		push @problems, $repo->html_phrase(
				"validate:missing_type",
			);
		return @problems;
	}

	my $field_defaults = $self->get_property_defaults( $epdata->{type} );

	if( !defined $field_defaults )
	{
		push @problems, $repo->html_phrase(
				"validate:bad_type",
				type => $repo->make_text( $epdata->{type} ),
			);
		return @problems;
	}

	foreach my $property (keys %$field_defaults)
	{
		# fields_cache only exists when the field is added to the system
		next if $property eq "fields_cache";

		if( $field_defaults->{$property} eq $EPrints::MetaField::REQUIRED && !EPrints::Utils::is_set( $epdata->{$property} ) )
		{
			push @problems, $repo->html_phrase(
					"validate:missing_property",
					property => $repo->make_text( $property )
				);
		}
	}

	if( $epdata->{"type"} eq "itemref" )
	{
		my $datasetid = $epdata->{"datasetid"};
		$datasetid = "" unless defined $datasetid;

		unless( $repo->dataset( $datasetid ) )
		{
			push @problems, $repo->html_phrase(
					"validate:unknown_datasetid",
					datasetid => $repo->make_text( $datasetid ),
				);
		}
	}

	return @problems;
}


######################################################################
=pod

=item $xhtml = $metafield->render_citation( [ $type, %params ] )

Returns a XHTML DOM rendering of the metafield using citation 
C<$type> (of C<default> if not provided) an specified C<%params>.

=cut
######################################################################

sub render_citation
{
	my( $self, $type, %params ) = @_;

	if( defined $type && $type eq "default" )
	{
		my $xml = $self->{session}->xml;

		my $pre = $xml->create_element( "pre" );
		$pre->appendChild( $xml->create_text_node( $self->dump ) );

		return $pre;
	}

	return $self->SUPER::render_citation( $type, %params );
}

sub _update_cfg_d
{
    my( $self, $repo, $dataset ) = @_;

    my @data;

    foreach my $field ($dataset->fields)
    {
        next if $field->property( "sub_name" );
        next if $field->property( "provenance" ) ne "user";
        my $mf = EPrints::DataObj::MetaField->new_from_field(
            $repo,
            $field,
            $self->{dataset}
        );
        push @data, $mf->perl_struct;
    }

    my $fn = $self->config_filename( $dataset );

    if( !scalar @data )
    {
        return scalar unlink( $fn );
    }

    open(my $fh, ">", $fn) or EPrints->abort( "Error opening $fn: $!" );

    my $var = '$c->{fields}->{' . $dataset->base_id . '}';

    print $fh "# This file is automatically generated\n\n";
    print $fh "$var = [] if !defined $var;\n";
    print $fh "push \@{$var}, \n\t";
    for(@data)
    {
        my $dd = Data::Dumper->new( [$_] );
        $dd->Terse( 1 );
        $dd->Sortkeys( 1 );

        print $fh $dd->Dump() . ",";
    }
    print $fh ";\n";

    close($fh);
}


1;

######################################################################
=pod

=back

=head1 SEE ALSO

L<EPrints::DataObj> and L<EPrints::DataSet>.

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
