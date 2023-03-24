=head1 NAME

EPrints::Plugin::Screen::EPrint::UploadMethod::URL

=cut

package EPrints::Plugin::Screen::EPrint::UploadMethod::URL;

use EPrints::Plugin::Screen::EPrint::UploadMethod::File;

@ISA = qw( EPrints::Plugin::Screen::EPrint::UploadMethod::File );

use strict;

sub new
{
	my( $class, %opts ) = @_;

	my $self = $class->SUPER::new( %opts );

	$self->{actions} = [qw( add_format )];
	$self->{appears} = [
		{ place => "upload_methods", position => 300 },
	];

	return $self;
}

sub allow_add_format { shift->can_be_viewed }

sub action_add_format
{
	my( $self ) = @_;

	my $session = $self->{session};
	my $processor = $self->{processor};
	my $ffname = join('_', $self->{prefix}, "url");
	my $eprint = $processor->{eprint};

	my $url = Encode::decode_utf8( $session->param( $ffname ) );

	my $document = $eprint->create_subdataobj( "documents", {
		format => "other",
	});
	if( !defined $document )
	{
		$processor->add_message( "error", $self->{session}->html_phrase( "Plugin/InputForm/Component/Upload:create_failed" ) );
		return;
	}
	my $success = $document->upload_url( $url );
	if( !$success )
	{
		$document->remove();
		$processor->add_message( "error", $self->{session}->html_phrase( "Plugin/InputForm/Component/Upload:upload_failed" ) );
		return;
	}

	$document->commit;

	$processor->{notes}->{upload_plugin}->{to_unroll}->{$document->get_id} = 1;
}


sub render
{
	my( $self ) = @_;

	my $f = $self->{session}->make_doc_fragment;

	my $ffname = join('_', $self->{prefix}, "url");
	my $label = $self->{session}->make_element( "label", for => $ffname );
	$label->appendChild( $self->{session}->html_phrase( "Plugin/InputForm/Component/Upload:new_from_url" ) );
	$f->appendChild( $label );

	my $file_button = $self->{session}->make_element( "input",
		name => $ffname,
		size => "30",
		id => $ffname,
		class => "ep_upload_url_input"
		);
	my $add_format_button = $self->{session}->render_button(
		value => $self->{session}->phrase( "Plugin/InputForm/Component/Upload:add_format" ), 
		class => "ep_form_internal_button",
		name => "_internal_".$self->{prefix}."_add_format" );
	$f->appendChild( $file_button );
	$f->appendChild( $self->{session}->make_text( " " ) );
	$f->appendChild( $add_format_button );
	
	return $f; 
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

