=head1 NAME

EPrints::Plugin::Screen::Request::Respond

=cut


package EPrints::Plugin::Screen::Request::Respond;

use EPrints::Plugin::Screen;

@ISA = ( 'EPrints::Plugin::Screen' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	$self->{actions} = [qw/ confirm /];

	return $self;
}

sub properties_from
{
	my( $self ) = @_;

	my $use_pin_security = $self->{session}->config( 'use_request_copy_pin_security' );

	if ( $use_pin_security )
	{
		$self->{processor}->{requestpin} = $self->{session}->param( "pin" );
		$self->{processor}->{request} = EPrints::DataObj::Request::request_with_pin( $self->{session}, $self->{processor}->{requestpin} );
	}

	if( !defined $self->{processor}->{request} )
	{
		# Use the previous, authenticated model. This also
		# provides a fall-back for requests with a requestid but
		# not a pin, which may occur during the changeover to the
		# pin-model.
		$self->{processor}->{requestid} = $self->{session}->param( "requestid" );
		$self->{processor}->{request} = new EPrints::DataObj::Request( $self->{session}, $self->{processor}->{requestid} );

		# Disable pin security for this response only
		$use_pin_security = 0;
	}	

	if( !defined $self->{processor}->{request} )
	{
		&_properties_error;
		return;
	}

	$self->{processor}->{document} = EPrints::DataObj::Document->new(
				$self->{session}, $self->{processor}->{request}->get_value( "docid" ) );

	$self->{processor}->{eprint} = EPrints::DataObj::EPrint->new(
				$self->{session}, $self->{processor}->{request}->get_value( "eprintid" ) );

	$self->{processor}->{contact} = EPrints::DataObj::User->new(
				$self->{session}, $self->{processor}->{request}->get_value( "userid" ) );

	# Need valid document, eprint and (when not using pin security) contact
	if( !defined $self->{processor}->{document} ||
		!defined $self->{processor}->{eprint} ||
		( !defined $self->{processor}->{contact} && !$use_pin_security ) )
	{
		&_properties_error;
		return;
	}

	$self->{processor}->{response_sent} = $self->{session}->param( "response_sent" );
	$self->{processor}->{actionid} = $self->{session}->param( "action" );

	$self->{processor}->{use_pin_security} = $use_pin_security;

	$self->SUPER::properties_from;

}

sub _properties_error
{
	my( $self ) = @_;
	
	$self->{processor}->{screenid} = "Error";
	$self->{processor}->add_message( "error", $self->{session}->html_phrase( "general:bad_param" ) );
}

sub can_be_viewed
{
	my( $self ) = @_;

	# If the pin security model is being used for this response,
	# anyone with the correct pin can access it.
	return 1 if $self->{processor}->{use_pin_security};

	# Only the contact user (ie. user listed as contact email at time of request) can process it
	return $self->{processor}->{contact}->get_id == $self->{processor}->{user}->get_id;
}

sub allow_confirm
{
	return 1;
}

sub action_confirm
{
	my( $self ) = @_;

	my $session = $self->{session};

	my $eprint = $self->{processor}->{eprint};
	my $doc = $self->{processor}->{document};

	my $email = $self->{processor}->{request}->get_value( "requester_email" );
	unless( EPrints::Utils::validate_email( $email ) )
	{
		$self->{processor}->add_message( "error", $self->{session}->html_phrase(
			"general:bad_email", email => $session->make_text( $email ) ) );
		return;		
	}

	my $action = $session->param("action");
	$action = "reject" if !defined $action || $action ne "accept";
	# Requested document has been made OA in the meantime
	$action = "oa" if $self->{processor}->{document}->is_public;

	my $subject = $session->phrase( 
		"request/response_email:subject", 
		eprint => $eprint->get_value( "title" ) );

	my $mail = $session->make_element( "mail" );
	my $reason = $session->param( "reason" );
	$mail->appendChild( $session->html_phrase(
		"request/response_email:body_$action",
		eprint => $eprint->render_citation_link,
		document => $doc->render_value( "main" ),
		reason => EPrints::Utils::is_set( $reason ) ? EPrints::Extras::render_paras( $self->{session}, "reason", $reason )
			: $session->html_phrase( "Plugin/Screen/EPrint/RequestRemoval:reason" ) ) );

	my $result;
	if( $action eq "accept")
	{
	
		# Make document OA if flag set
		if( defined $session->param( "oa" ) && $session->param( "oa" ) eq "on" )
		{
			$doc->set_value( "security", "public" );
			$doc->commit;
			$eprint->commit;
			$eprint->generate_static;
		}

		my $expiry = $session->config( "expiry_for_doc_request" );
		$expiry = 7 if( !defined $expiry || $expiry !~ /^\d+$/ );
		$expiry = time + $expiry*3600*24;

		$self->{processor}->{request}->set_value(
				       "expiry_date" ,
				       EPrints::Time::get_iso_timestamp( $expiry )
		);

		my $code = $self->{processor}->{request}->get_value( "code" );
		if ( !EPrints::Utils::is_set( $code ) )
		{
			my @a = ();
			srand;
			for(1..16) { push @a, sprintf( "%02X",int rand 256 ); }
			$code = join( "", @a );
			$self->{processor}->{request}->set_value( "code", "$code" );
			$self->{processor}->{request}->commit;
		}
		# Make HTTPS if available to allow SameSite for cookie to be set to None to avoid authentication popups when getting restricted document.	
		my $cgi_url = $session->config( "perl_url" )."/process_request?code=$code";
		my $link = $session->make_element( "a", href=>"$cgi_url" );
		$link->appendChild( $session->html_phrase( "request/response_email:download_label" ) );
		$mail->appendChild( $link );

		$mail->appendChild( $session->html_phrase( "request/response_email:warning_expiry",
					       expiry => $session->make_text( EPrints::Time::human_time( $expiry )  ) ) );


		$result = EPrints::Email::send_mail(
			session => $session,
			langid => $session->get_langid,
			to_email => $email,
			subject => $subject,
			message => $mail,
			sig => $session->html_phrase( "mail_sig" ),
		);
	}
	else
	{
		# Send rejection notice and expire request
		$result = EPrints::Email::send_mail(
			session => $session,
			langid => $session->get_langid,
			to_email => $email,
			subject => $subject,
			message => $mail,
			sig => $session->html_phrase( "mail_sig" ),
		);
		$self->{processor}->{request}->set_value( "expiry_date", EPrints::Time::get_iso_timestamp( time ) );
		$self->{processor}->{request}->commit;
	}
	
	# Log response event
	my $history_ds = $session->dataset( "history" );
	my $user = $self->{processor}->{contact};
	my $history_data = {
		datasetid=>"request",
		objectid=>$self->{processor}->{request}->get_id,
		action=> "$action\_request",
		details=>EPrints::Utils::is_set( $reason ) ? $reason : undef,
	};
	if ( defined $user )
	{
		$history_data->{userid} = $user->get_id;
		$history_data->{actor} = EPrints::Utils::tree_to_utf8( $user->render_description );
	}
	else
	{
		$history_data->{actor} = $self->{processor}->{request}->get_value( 'email' );
	}
	$history_ds->create_object( $session, $history_data );

	if( !$result )
	{
		$self->{processor}->add_message( "error", $self->{session}->html_phrase(
			"general:email_failed" ) );
		return;
	}

	$self->{processor}->add_message( "message", $self->{session}->html_phrase( "request/response:ack_page" ) );
	$self->{processor}->{response_sent} = 1;
}

sub redirect_to_me_url
{
	my( $self ) = @_;

	my $url = $self->SUPER::redirect_to_me_url;
	if( defined $self->{processor}->{requestid} )
	{
		$url.="&requestid=".$self->{processor}->{requestid};
	}
	if( defined $self->{processor}->{requestpin} )
	{
		$url.="&pin=".$self->{processor}->{requestpin};
	}
	if( defined $self->{processor}->{actionid} )
	{
		$url.="&action=".$self->{processor}->{actionid};
	}
	if( defined $self->{processor}->{response_sent} )
	{
		$url.="&response_sent=".$self->{processor}->{response_sent};
	}
	return $url;
}

sub render
{
	my( $self ) = @_;

	my $session = $self->{session};

	my $page = $session->make_doc_fragment();
	return $page if $self->{processor}->{response_sent};

	my $email = $self->{processor}->{request}->get_value( "email" );

	my $action = $session->param("action");
	$action = "reject" if !defined $action || $action ne "accept";
	# Requested document has been made OA in the meantime
	$action = "oa" if $self->{processor}->{document}->is_public;

	my $requested = $self->{processor}->{request}->get_value( "datestamp" );

	# Requests expiry after 90 (or specified) number of days. Otherwise, they expiry after permitted access period or immediately if rejected.
	my $unresponded_expiry = $session->config( "expiry_for_unresponded_doc_request" );
	$unresponded_expiry = 90 if( !defined $unresponded_expiry || $unresponded_expiry !~ /^\d+$/ );
	$unresponded_expiry = EPrints::Time::datetime_local( split( /[- :]/, $requested ) ) + $unresponded_expiry*3600*24;
	my $expiry_date = $self->{processor}->{request}->get_value( "expiry_date" );
	my $expiry = $expiry_date ? EPrints::Time::datetime_local( split( /[- :]/, $expiry_date ) ) : 0;
	if ( time > $unresponded_expiry || ( $expiry && time > $expiry ) )
	{
		$page->appendChild( $session->html_phrase( 
			"request/respond_page:expired",
			action => $session->make_text( $action ),
			eprint => $self->{processor}->{eprint}->render_citation_link,
			document => $self->render_document,
		) );
		return $page;
	}

	if ( EPrints::Utils::is_set( $self->{processor}->{request}->get_value( "code" ) ) )
	{
		$page->appendChild( $session->html_phrase( 
			"request/respond_page:already_approved",
			action => $session->make_text( $action ),
			eprint => $self->{processor}->{eprint}->render_citation_link,
	        document => $self->render_document,
		) );
		return $page;
	}

	$page->appendChild( $session->html_phrase(
		"request/respond_page:$action",
		eprint => $self->{processor}->{eprint}->render_citation_link,
		document => $self->render_document,
	) );

	my $form =  $session->render_form( "post" );
	$page->appendChild( $form );
	
	if( $action eq "reject" )
	{
		my $textarea = $session->make_element( "textarea",
			name => "reason",
			rows => 5,
			cols => 60,
			wrap => "virtual",
		);
		$form->appendChild( $textarea );
	}

	# Only display the 'Make this document OA' form if the user
	# has privilege to edit this document
	if( !EPrints::Utils::is_set( $self->{processor}->{request}->get_value( "code" ) ) )
	{
		if( $action eq "accept"
			 && $self->allow( 'eprint/archive/edit', $self->{processor}->{eprint} ) )
		{
			my $p = $session->make_element( "p" );
			$form->appendChild( $p );
			unless ( $session->config( 'disable_make_open_access' ) )
			{
				my $label = $session->make_element( "label" );
				my $cb = $session->make_element( "input", type => "checkbox", name => "oa" );
				$label->appendChild( $cb );
				$label->appendChild( $session->make_text( " " ));
				$label->appendChild( $session->html_phrase(
					"request/respond_page:fieldname_oa" ) );
				$p->appendChild( $label );
			}
		}

		$form->appendChild( $session->render_hidden_field( "screen", $self->{processor}->{screenid} ) );
		$form->appendChild( $session->render_hidden_field( "requestid", $self->{processor}->{request}->get_id ) );
		$form->appendChild( $session->render_hidden_field( "pin", $self->{processor}->{requestpin} ) );
		$form->appendChild( $session->render_hidden_field( "action", $action ) );

		$form->appendChild( $session->make_element( "br" ) );
		$form->appendChild( $session->render_action_buttons( confirm => $session->phrase( "request/respond_page:action_respond" ) ) );
	}

	return $page;

}

sub render_document
{
	my( $self ) = @_;

	my $session = $self->{session};
	my $doc = $self->{processor}->{document};

	my( $doctable, $doctr, $doctd );
	$doctable = $session->make_element( "table" );
	$doctr = $session->make_element( "tr" );
	
	$doctd = $session->make_element( "td" );
	$doctr->appendChild( $doctd );
	$doctd->appendChild( $doc->render_icon_link );
	
	$doctd = $session->make_element( "td" );
	$doctr->appendChild( $doctd );
	$doctd->appendChild( $doc->render_citation_link() );
	my %files = $doc->files;
	if( defined $files{$doc->get_main} )
	{
		my $size = $files{$doc->get_main};
		$doctd->appendChild( $session->make_element( 'br' ) );
		$doctd->appendChild( $session->make_text( EPrints::Utils::human_filesize($size) ));
	}

	$doctable->appendChild( $doctr );

	return $doctable;
}

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

