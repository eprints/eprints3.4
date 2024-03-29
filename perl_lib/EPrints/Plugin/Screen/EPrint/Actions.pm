=head1 NAME

EPrints::Plugin::Screen::EPrint::Actions

=cut

package EPrints::Plugin::Screen::EPrint::Actions;

our @ISA = ( 'EPrints::Plugin::Screen::EPrint' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	$self->{appears} = [
		{
			place => "eprint_view_tabs",
			position => 300,
		}
	];

	return $self;
}

sub can_be_viewed
{
	my( $self ) = @_;

	return 0 unless
		scalar $self->action_list( "eprint_actions" )
		|| scalar $self->action_list( "eprint_editor_actions" );

	return $self->who_filter;
}

sub render
{
	my( $self ) = @_;

	my $session = $self->{session};

	my $user = $session->current_user;
	my $staff = $user->get_type eq "editor" || $user->get_type eq "admin";

	my $frag = $session->make_doc_fragment;
	my $table = $session->make_element( "table" );
	$frag->appendChild( $table );
	my( $contents, $tr, $th, $td );

	$contents = $self->render_action_list( "eprint_actions", ['eprintid'] );

	if( $contents->hasChildNodes )
	{
		$tr = $table->appendChild( $session->make_element( "tr" ) );
		$td = $tr->appendChild( $session->make_element( "td" ) );
		$td->appendChild( $contents );
	}

	$contents = $self->render_action_list( "eprint_editor_actions", ['eprintid'] );

	if( $contents->hasChildNodes )
	{
		$tr = $table->appendChild( $session->make_element( "tr" ) );
		$th = $tr->appendChild( $session->make_element( "th", class => "ep_title_row", role => "banner" ) );
		$th->appendChild( $session->html_phrase( "Plugin/Screen/EPrint/Actions/Editor:title" ) );

		$tr = $table->appendChild( $session->make_element( "tr" ) );
		$td = $tr->appendChild( $session->make_element( "td" ) );
		$td->appendChild( $contents );
	}

	$contents = $self->{processor}->{eprint}->render_export_bar( $staff );

	if( $contents->hasChildNodes )
	{
		$tr = $table->appendChild( $session->make_element( "tr" ) );
		$th = $tr->appendChild( $session->make_element( "th", class => "ep_title_row", role => "banner" ) );
		$th->appendChild( $session->html_phrase( "Plugin/Screen/EPrint/Export:title" ) );

		$tr = $table->appendChild( $session->make_element( "tr" ) );
		$td = $tr->appendChild( $session->make_element( "td" ) );
		$td->appendChild(
			$session->make_element( "div", class => "ep_block" )
		)->appendChild(
			$contents
		);
	}

	return $frag;
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

