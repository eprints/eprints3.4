$c->{password_maxlength} = 200;

$c->add_trigger( EPrints::Const::EP_TRIGGER_VALIDATE_FIELD, sub
{
        my( %args ) = @_;
        my( $repo, $field, $user, $value, $problems ) = @args{qw( repository field dataobj value problems )};

	return unless $user->isa( "EPrints::DataObj::User" ) && $field->type eq "secret";

	my $password;
	foreach my $key ( keys %{ $repo->{query}->{param} } )
	{
		my $fieldname = $field->name;
		if ( $key =~ m/$fieldname$/ )
		{
			$password = $repo->{query}->{param}->{$key}->[0];
			last;
		}
	}
		
	if ( defined $password && defined $repo->config( "password_maxlength" ) && length( $password ) > $repo->config( "password_maxlength" ) )
        {
		my $fieldname = $repo->xml->create_element( "span", class=>"ep_problem_field:".$field->get_name );
	        $fieldname->appendChild( $field->render_name( $repo ) );
        	my $maxlength_el = $repo->make_text( $repo->config( "password_maxlength" ) );
                push @$problems, $repo->html_phrase( "validate:password_too_long",
                        fieldname => $fieldname,
                        maxlength => $maxlength_el,
                );
        }
}, priority => 1000 );

