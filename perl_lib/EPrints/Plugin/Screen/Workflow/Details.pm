=head1 NAME

EPrints::Plugin::Screen::Workflow::Details

=cut

package EPrints::Plugin::Screen::Workflow::Details;

@ISA = ( 'EPrints::Plugin::Screen::Workflow' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	$self->{appears} = [
		{
			place => "dataobj_view_tabs",
			position => 100,
		},
	];

	my $session = $self->{session};
	if( $session && $session->get_online )
	{
		$self->{title} = $session->make_element( "span" );
		$self->{title}->appendChild( $self->SUPER::render_tab_title );
	}

	return $self;
}

sub properties_from
{
	my( $self ) = @_;

	$self->SUPER::properties_from;

}

sub can_be_viewed
{
	my( $self ) = @_;
		
	return $self->allow( $self->{processor}->{dataset}->id."/details" );
}

sub _find_stage
{
	my( $self, $name ) = @_;

	return undef if !$self->{processor}->{can_be_edited};

	return undef if !$self->has_workflow();

	my $workflow = $self->workflow;

	return $workflow->{field_stages}->{$name};
}

sub _render_name_maybe_with_link
{
	my( $self, $field ) = @_;

	my $dataset = $self->{processor}->{dataset};
	my $dataobj = $self->{processor}->{dataobj};

	my $name = $field->get_name;
	my $stage = $self->_find_stage( $name );

	my $r_name = $field->render_name( $self->{session} );
	return $r_name if !defined $stage;

	my $url = URI->new( $self->{session}->current_url );
	$url->query_form(
		screen => $self->edit_screen,
		dataset => $dataset->id,
		dataobj => $dataobj->id,
		stage => $stage
	);
	$url->fragment( $name );
	my $link = $self->{session}->render_link( $url );
	$link->appendChild( $r_name );

	return $link;
}

sub DESTROY
{
	my( $self ) = @_;

	if( $self->{title} )
	{
		$self->{session}->xml->dispose( $self->{title} );
	}
}

sub render_tab_title
{
	my( $self ) = @_;

	# Return a clone otherwise the DESTROY above will double-dispose of this
	# element when it is disposed by whatever called us
	return $self->{session}->xml->clone( $self->{title} );
}

sub render
{
	my( $self ) = @_;

	my $dataobj = $self->{processor}->{dataobj};
	my $session = $self->{session};
	my $workflow = $self->workflow;

	my $page = $session->make_doc_fragment;

	my $has_problems = 0;

	#$self->{edit_ok} = $self->could_obtain_eprint_lock; # hmm
	my $plugin = $session->plugin( "Screen::" . $self->edit_screen,
		processor => $self->{processor}
	);
	my $edit_ok = $plugin->can_be_viewed;

	my %stages;
	foreach my $stage ("", keys %{$workflow->{stages}})
	{
		$stages{$stage} = {
			count => 0,
			rows => [],
			unspec => $session->make_doc_fragment,
		};
	}

	my @fields = $dataobj->dataset->fields;
	foreach my $field ( @fields )
	{
		next unless( $field->get_property( "show_in_html" ) );

		my $name = $field->get_name();

		my $stage = $self->_find_stage( $name );
		$stage = "" if !defined $stage;

		my $rows = $stages{$stage}->{rows};
		my $unspec = $stages{$stage}->{unspec};
		$stages{$stage}->{count}++;

		my $r_name = $self->_render_name_maybe_with_link( $field );

		if( $dataobj->is_set( $name ) )
		{
			if( $field->isa( "EPrints::MetaField::Subobject" ) )
			{
				push @$rows, $session->render_row(
					$r_name,
					$dataobj->render_value( $field->get_name(), 1 ) );
			}
			else
			{
				push @$rows, $session->render_row(
					$r_name,
					$dataobj->render_value( $field->get_name(), 1 ) );
			}
		}
		else
		{
			if( $unspec->hasChildNodes )
			{
				$unspec->appendChild( $session->make_text( ", " ) );
			}
			$unspec->appendChild( $r_name );
		}
	}

	my $table = $session->make_element( "table",
			border => "0",
			cellpadding => "3",
			class => "ep_view_details_table" );
	$page->appendChild( $table );

	foreach my $stage_id ($self->workflow->get_stage_ids, "")
	{
		my $unspec = $stages{$stage_id}->{unspec};
		next if $stages{$stage_id}->{count} == 0;

		my $stage = $self->workflow->get_stage( $stage_id );

		my( $tr, $th, $td );

		my $rows = $stages{$stage_id}->{rows};

		my $url = URI->new( $session->current_url );
		$url->query_form(
			screen => $self->edit_screen,
			dataobj => $dataobj->id,
			stage => $stage_id
		);

		$tr = $session->make_element( "tr" );
		$table->appendChild( $tr );
		$th = $session->make_element( "th", colspan => 2, class => "ep_title_row", "role" => "banner" );

		$tr->appendChild( $th );

		if( !defined $stage )
		{
			$th->appendChild( $self->html_phrase( "other" ) );
		}
		else
		{
			my $title = $stage->render_title();
			my $table_inner = $session->make_element( "div", class=>"ep_title_row_inner" );
			my $tr_inner = $session->make_element( "div" );
			my $td_inner_1 = $session->make_element( "div", class=>"ep_title" );
			$th->appendChild( $table_inner );
			$table_inner->appendChild( $tr_inner );
			$tr_inner->appendChild( $td_inner_1 );
			$td_inner_1->appendChild( $title );
			if( $edit_ok )
			{
				my $td_inner_2  = $session->make_element( "div" );
				$tr_inner->appendChild( $td_inner_2 );
				$td_inner_2->appendChild( $self->render_edit_button( $stage ) );
			}
		}

		if( defined $stage )
		{
			$tr = $session->make_element( "tr" );
			$table->appendChild( $tr );
			$td = $session->make_element( "td", colspan => 2 );
			$tr->appendChild( $td );
			$td->appendChild( $self->render_stage_warnings( $stage ) );
			$has_problems = 1 if $td->hasChildNodes;
		}

		foreach $tr (@$rows)
		{
			$table->appendChild( $tr );
		}

		if( $stage ne "" && $unspec->hasChildNodes )
		{
			$table->appendChild( $session->render_row(
				$session->html_phrase( "lib/dataobj:unspecified" ),
				$unspec ) );
		}

		$tr = $session->make_element( "tr" );
		$table->appendChild( $tr );
		$td = $session->make_element( "td", colspan => 2, style=>'height: 1em' );
		$tr->appendChild( $td );
	}

	if( $has_problems )
	{
		my $span = $self->{title};
		$span->setAttribute( style => "padding-left: 20px; background: url('".$session->current_url( path => "static", "style/images/warning-icon.png" )."') no-repeat;" );
	}

	return $page;
}

sub render_edit_button
{
	my( $self, $stage ) = @_;

	my $session = $self->{session};

	my $div = $session->make_element( "div" );

	my $button = $self->render_action_button({
		screen => $session->plugin( "Screen::".$self->edit_screen,
			processor => $self->{processor},
		),
		screen_id => "Screen::".$self->edit_screen,
		hidden => {
			dataset => $self->{processor}->{dataset}->id,
			dataobj => $self->{processor}->{dataobj}->id,
			stage => $stage->get_name,
		},
	});
	$div->appendChild( $button );

	return $div;
}

sub render_stage_warnings
{
	my( $self, $stage ) = @_;

	my $session = $self->{session};

	my @problems = $stage->validate( $self->{processor} );

	return $session->make_doc_fragment if !scalar @problems;
 
	my $ul = $session->make_element( "ul" );
	foreach my $problem ( @problems )
	{
		my $li = $session->make_element( "li" );
		$li->appendChild( $problem );
		$ul->appendChild( $li );
	}
	$self->workflow->link_problem_xhtml( $ul, $self->edit_screen, $stage );

	return $session->render_message( "warning", $ul );
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

