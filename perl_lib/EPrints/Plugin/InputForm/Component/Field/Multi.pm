=head1 NAME

EPrints::Plugin::InputForm::Component::Field::Multi

=cut

package EPrints::Plugin::InputForm::Component::Field::Multi;

use EPrints::Plugin::InputForm::Component::Field;

@ISA = ( "EPrints::Plugin::InputForm::Component::Field" );

use strict;

sub new
{
	my( $class, %opts ) = @_;

	my $self = $class->SUPER::new( %opts );

	$self->{name} = "Multi";
	$self->{visible} = "all";

	return $self;
}

sub wishes_to_export
{
	my( $self ) = @_;

	return $self->{session}->param( $self->{prefix} . "_export" );
}

sub export
{
	my( $self ) = @_;

	my $frag = $self->render_content;

	print $self->{session}->xhtml->to_xhtml( $frag );
	$self->{session}->xml->dispose( $frag );
}

sub update_from_form
{
	my( $self, $processor ) = @_;

	foreach my $field ( @{$self->{config}->{fields}} )
	{
		my $value = $field->form_value( $self->{session}, $self->{dataobj}, $self->{prefix} );
		$self->{dataobj}->set_value( $field->{name}, $value );
	}

	return;
}

sub validate
{
	my( $self ) = @_;

	my @problems;
	
	foreach my $field ( @{$self->{config}->{fields}} )
	{
		my $for_archive = defined($field->{required}) &&
			$field->{required} eq "for_archive";

		# cjg bug - not handling for_archive here.
		if( $field->{required} && !$self->{dataobj}->is_set( $field->{name} ) )
		{
			my $fieldname = $self->{session}->make_element( "span", class=>"ep_problem_field:".$field->{name} );
			$fieldname->appendChild( $field->render_name( $self->{session} ) );
			my $problem = $self->{session}->html_phrase(
				"lib/eprint:not_done_field" ,
				fieldname=>$fieldname );
			push @problems, $problem;
		}
		
		push @problems, $self->{dataobj}->validate_field( $field->{name} );
	}
	
	return @problems;
}

sub parse_config
{
	my( $self, $config_dom ) = @_;
	
	$self->{config}->{fields} = [];
	$self->{config}->{title} = $self->{session}->make_doc_fragment;

	foreach my $node ( $config_dom->getChildNodes )
	{
		if( $node->nodeName eq "field" ) 
		{
			my $field = $self->xml_to_metafield( $node );
			return if !defined $field;
			$self->{config}->{field}->{required} = 1 if $field->get_property( "required" );
			if ($self->{workflow}->{processor}->{required_fields_only}) {
				if ($field->get_property( "required" ) ) {
					push @{$self->{config}->{fields}}, $field;
				}
			} else {
				push @{$self->{config}->{fields}}, $field;
			}
			$self->{config}->{help_fields}->{$field->name} = $self->xml_to_help( $node );
		}

		if( $node->nodeName eq "title" ) 
		{
			$self->{config}->{title} = EPrints::XML::contents_of( $node );
		}

		if( $node->nodeName eq "help" ) 
		{
			my $phrase_ref = $node->getAttribute( "ref" );
			$self->{config}->{help} = $self->{session}->make_element( "div", class=>"ep_sr_help_chunk" );
			if( EPrints::Utils::is_set( $phrase_ref ) )
			{
				$self->{config}->{help}->appendChild( $self->{session}->html_phrase( $phrase_ref ) );
			}
			else
			{
				$self->{config}->{help} = EPrints::XML::contents_of( $node );
			}
		}
	}
	
	if( @{$self->{config}->{fields}} == 0 )
	{
		EPrints::abort( "Multifield with no fields defined. Config was:\n".EPrints::XML::to_string( $config_dom ) );
	}
}

sub has_help
{
	my( $self ) = @_;

	return defined $self->{config}->{help};
}

sub render_content
{
	my( $self, $surround ) = @_;

	my $frag = $self->{session}->make_doc_fragment;

	my $table = $self->{session}->make_element( "div", class => "ep_multi" );
	$frag->appendChild( $table );

	my $first = 1;
	foreach my $field ( @{$self->{config}->{fields}} )
	{
		my %parts;
		$parts{class} = "";
		$parts{class} = "ep_first" if $first;
		$first = 0;

		$parts{label} = $field->render_name( $self->{session} );

		if( $field->{required} ) # moj: Handle for_archive
		{
                        my $required = $self->{session}->make_element( "img",
                                src => $self->{session}->html_phrase( "sys:ep_form_required_src" ),
                                class => "ep_required",
                                alt => $self->{session}->html_phrase( "sys:ep_form_required_alt" ));
                        $required->appendChild( $self->{session}->make_text( " " ) );
                        $required->appendChild( $parts{label} );
                        $parts{label} = $required;
		}

		# customisation for type specific help on the eprint workflow
		# phrase IDs should be (e.g. eprint_fieldhelp_title.article)
	        if( $self->{dataobj}->exists_and_set('type') )
	        {
	                my $phrase_id = 'eprint_fieldhelp_' . $field->{name} . '.' . $self->{dataobj}->get_value('type');
	                if( $self->{session}->get_lang->has_phrase( $phrase_id ) )
	                {
	                        $parts{help} = $self->{session}->html_phrase($phrase_id);
	                }
	        }
		$parts{help} = $field->render_help( $self->{session} ) unless $parts{help};

		# Get the field and its value/default
		my $value;
		if( $self->{dataobj} )
		{
			$value = $self->{dataobj}->get_value( $field->{name} );
		}
		else
		{
			$value = $self->{default};
		}
		$parts{field} = $field->render_input_field( 
			$self->{session}, 
			$value, 
			undef,
			0,
			undef,
			$self->{dataobj},
			$self->{prefix},
			
		  );

		@parts{qw( no_help no_toggle )} = @$self{qw( no_help no_toggle )};

		if( !defined $parts{no_toggle} ) #no_toggle hasn't been set for all fields in the component
		{
			#so set it to the current fields setting only
			$parts{no_toggle} = $self->{config}->{help_fields}->{$field->name};
		}

		# Allow for individual field setting of show_help
		$parts{no_toggle} = 1 if $field->{show_help} eq "always";
                $parts{no_toggle} = 0 if $field->{show_help} eq "toggle";
                $parts{no_help} = 1 if $field->{show_help} eq "never";

		$parts{prefix} = $self->{prefix} . "_" . $field->get_name;
		$parts{help_prefix} = $self->{prefix}."_help_".$field->get_name;

		

		$table->appendChild( $self->{session}->render_row_with_help( %parts ) );
	}

	$frag->appendChild( $self->{session}->make_javascript( <<EOJ ) );
new Component_Field ('$self->{prefix}');
EOJ

	return $frag;
}


sub render_help
{
	my( $self, $surround ) = @_;
	return $self->{config}->{help};
}

sub render_title
{
	my( $self, $surround ) = @_;

	# nb. That this must clone the title as the title may be used 
	# more than once.
	return $self->{session}->clone_for_me( $self->{config}->{title}, 1 );
}


sub could_collapse
{
	my( $self ) = @_;

	foreach my $field ( @{$self->{config}->{fields}} )
	{
		my $set = $self->{dataobj}->is_set( $field->{name} );
		return 0 if( $set );
	}
	
	return 1;
}

sub get_fields_handled
{
	my( $self ) = @_;

	my @names = ();
	foreach my $field ( @{$self->{config}->{fields}} )
	{
		push @names, $field->{name};
	}
	return @names;
}

sub get_state_params
{
	my( $self ) = @_;

	my $params = "";
	foreach my $field ( @{$self->{config}->{fields}} )
	{
		$params .= $field->get_state_params( $self->{session}, $self->{prefix} );
	}
	return $params;
}

sub get_state_fragment
{
	my( $self, $processor ) = @_;

	foreach my $field ( @{$self->{config}->{fields}} )
	{
		return $self->{prefix} if $field->has_internal_action( $self->{prefix} );
	}

	return "";
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

