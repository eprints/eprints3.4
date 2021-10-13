=head1 NAME

EPrints::Plugin::Screen::Admin::TestEmail

=cut

package EPrints::Plugin::Screen::Admin::TestEmail;

use EPrints::Plugin::Screen::Admin;

@ISA = ( 'EPrints::Plugin::Screen' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);
	
	$self->{actions} = [qw/ test_email /]; 
		
	$self->{appears} = [
		{ 
			place => "admin_actions_system", 
			position => 1500, 
		},
	];

	return $self;
}

sub can_be_viewed
{
	my( $self ) = @_;

	return $self->allow( "config/test_email" );
}

sub allow_test_email
{
	my( $self ) = @_;

	return $self->can_be_viewed;
}

sub action_test_email
{
        my( $self ) = @_;

        my $session = $self->{session};

        my @emails = split(/[, \s\/]+/ ,$session->param( "requester_email" ) );

        unless( @emails )
        {
                $self->{processor}->add_message( "error", $self->html_phrase( "no_email" ) );
                return;
        }

        my $mail = $session->make_element( "mail" );
        $mail->appendChild( $self->html_phrase( "test_mail" ));

        for my $email (@emails) {
                my $rc = EPrints::Email::send_mail(
                        session => $session,
                        langid => $session->get_langid,
                        to_email => $email,
                        subject => $self->phrase( "test_mail_subject" ),
                        message => $mail,
                        sig => $session->html_phrase( "mail_sig" )
                );

                if( !$rc )
                {
                        $self->{processor}->add_message( "error",
                                $self->html_phrase( "mail_failed",
                                        requester => $session->make_text( $email )
                                 ) );
                }
                else
                {
                        $self->{processor}->add_message( "message",
                                $self->html_phrase( "mail_sent",
                                        requester => $session->make_text( $email )
                                ) );
                }

        }
}

sub render
{
	my( $self ) = @_;

	my $session = $self->{session};

	my( $html , $table , $p , $span );
	
	$html = $session->make_doc_fragment;

	my $form = $session->render_input_form(
		fields => [
			$session->dataset( "request" )->get_field( "requester_email" ),
		],
		show_names => 1,
		show_help => 1,
		buttons => { test_email => $self->phrase( "send" ) },
	);

	$html->appendChild( $form );
	$form->appendChild( $session->render_hidden_field( "screen", $self->{processor}->{screenid} ) );

	return $html;
}


1;

=head1 COPYRIGHT

=for COPYRIGHT BEGIN

Copyright 2021 University of Southampton.
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

