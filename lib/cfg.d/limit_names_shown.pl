# For instructions on how to use see https://wiki.eprints.org/w/Limiting_names_shown
$c->{limit_names_shown} = sub
{
        my( $session, $field, $value, $alllangs, $nolink, $object ) = @_;

        $session = $object->repository unless $session->can("make_doc_fragment");

        #get parent field values                
        my $parent_name = $field->{parent_name};
	my $actual_name = $field->{name};
        if ( $field->{name} =~ /_limited/ )
        {
                $actual_name =~ s/_limited.*$//;
                $parent_name = $field->{name};
                $parent_name =~ s/_name_limited.*$//;
                $value = $object->get_value( $actual_name );
        }

	my $id = $object->id;

        my $pvals = $object->get_value( $parent_name );

        return $field->render_value_actual($session, $value, $alllangs, $nolink, $object ) if scalar( @$value ) != scalar( @$pvals );

        #construct the HTML
        my $html = $session->make_doc_fragment();
        my $n = scalar(@$value);

        # render_limit property to limit number of names displayed before using et al.
        my $limit = $field->{render_limit} ? $field->{render_limit} : 99999; # Assume there will never be 100,000 or more names

        my $db = $session->get_database();
        my $user_ds = $session->get_repository->dataset( "user" );

	my $init_names = $session->make_doc_fragment;
        my $rest_names = $session->make_doc_fragment;
        my $init_names_span = $session->make_element( "span", "id" => $actual_name . "_".$id."_init" );
        my $rest_names_span = $session->make_element( "span", "id" => $actual_name . "_".$id."_rest" );

	my $join_phrase = "lib/metafield:join_name";
	my $join_last_phrase = $session->get_lang->has_phrase( "lib/metafield:join_name.last", $session ) ? "lib/metafield:join_name.last" : $join_phrase; 

	# Add names to appropriate HTML document fragment depending on whether they are within limit
        for( my $i=0; $i<$n; ++$i )
        {
                my $sv = $value->[$i];
                my $pv = $pvals->[$i]; # parent value
                my $name = EPrints::Utils::make_name_string( $sv );

		my $person_name_span = $session->make_element( "span", class => "person_name" );
                $person_name_span->appendChild( $session->make_text( $name ) );

                if( $i < $limit )
                {	
			$init_names->appendChild( $person_name_span );
			if ( $i == $limit-1 )
			{
				$rest_names->appendChild( $session->html_phrase( $join_phrase ) ) if ($i < $n-2);
                        	$rest_names->appendChild( $session->html_phrase( $join_last_phrase ) ) if ($i == $n-2);
			}	
			else
			{
				$init_names->appendChild( $session->html_phrase( $join_phrase ) ) if ($i < $n-2);
                        	$init_names->appendChild( $session->html_phrase( $join_last_phrase ) ) if ($i == $n-2);
			}
                }
		else 
		{
			$rest_names->appendChild( $person_name_span );
 			$rest_names->appendChild( $session->html_phrase( $join_phrase ) ) if ($i < $n-2);
                        $rest_names->appendChild( $session->html_phrase( $join_last_phrase ) ) if ($i == $n-2);
		}
        }

	# Add names within limit to be rendered
	$init_names_span->appendChild( $init_names );
	$html->appendChild( $init_names_span );
	
	# If over limited number of names render the rest.
	if ( $rest_names->hasChildNodes )
	{
		# Render dynamically to allow expanding of the rest of the names
		if ( defined $field->{render_dynamic} && $field->{render_dynamic} == 1 )
		{
			my $show = $session->html_phrase("limit_names_shown");
			my $hide = "";
			$hide = $session->html_phrase( "limit_names_shown_hide" ) if ( $session->get_lang->has_phrase( "limit_names_shown_hide", $session ) );
			my $et_al_link = $session->make_element( "button", "id" => $actual_name."_".$id."_et_al", "aria-expanded" => "false", "aria-controls" => $actual_name . "_".$id."_rest", "aria-label" => $session->html_phrase("limit_names_shown_label", "field" => $session->html_phrase( $field->{confid}."_fieldname_".$parent_name )), "type" => "button", "style" => "margin-left: 0.5em; display: none;", "onclick" => "EPJS_limit_names_shown( '${actual_name}_${id}_et_al', '${actual_name}_${id}_rest', '$show', '$hide' );" );
			my $et_al_span = $session->make_element( "span", "aria-hidden" => "false" );
			$et_al_link->appendChild( $show );
			$rest_names_span->appendChild( $rest_names );
			$html->appendChild( $rest_names_span );
			$html->appendChild($et_al_link);
			my $script = $session->make_element( "script" );		
			$script->appendChild( $session->make_text( "EPJS_limit_names_shown_load( '${actual_name}_${id}_et_al', '${actual_name}_${id}_rest' );" ) );
			$html->appendChild( $script );
		}
		else {
			$html->appendChild( $session->make_text( " " ) );
           	$html->appendChild( $session->make_text( $session->html_phrase("limit_names_shown") ) );
		}
	}

        return $html;
};

