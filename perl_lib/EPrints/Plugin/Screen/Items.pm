=head1 NAME

EPrints::Plugin::Screen::Items

=cut


package EPrints::Plugin::Screen::Items;

use EPrints::Plugin::Screen::Listing;

@ISA = ( 'EPrints::Plugin::Screen::Listing' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	$self->{appears} = [
		{
			place => "key_tools",
			position => 125,
		}
	];

	$self->{actions} = [qw/ col_left col_right remove_col add_col /];

	return $self;
}

sub properties_from
{
	my( $self ) = @_;

	my $processor = $self->{processor};
	my $session = $self->{session};

	$processor->{dataset} = $session->dataset( "eprint" );

	$self->SUPER::properties_from();
}

sub can_be_viewed
{
	my( $self ) = @_;

	return $self->allow( "items" );
}

sub allow_col_left { return $_[0]->can_be_viewed; }
sub allow_col_right { return $_[0]->can_be_viewed; }
sub allow_remove_col { return $_[0]->can_be_viewed; }
sub allow_add_col { return $_[0]->can_be_viewed; }

sub action_col_left
{
	my( $self ) = @_;

	my $col_id = $self->{session}->param( "colid" );
	my $v = $self->{session}->current_user->get_value( "items_fields" );

	my @newlist = @$v;
	my $a = $newlist[$col_id];
	my $b = $newlist[$col_id-1];
	$newlist[$col_id] = $b;
	$newlist[$col_id-1] = $a;

	$self->{session}->current_user->set_value( "items_fields", \@newlist );
	$self->{session}->current_user->commit();
}

sub action_col_right
{
	my( $self ) = @_;

	my $col_id = $self->{session}->param( "colid" );
	my $v = $self->{session}->current_user->get_value( "items_fields" );

	my @newlist = @$v;
	my $a = $newlist[$col_id];
	my $b = $newlist[$col_id+1];
	$newlist[$col_id] = $b;
	$newlist[$col_id+1] = $a;
	
	$self->{session}->current_user->set_value( "items_fields", \@newlist );
	$self->{session}->current_user->commit();
}
sub action_add_col
{
	my( $self ) = @_;

	my $col = $self->{session}->param( "col" );
	my $v = $self->{session}->current_user->get_value( "items_fields" );

	my @newlist = @$v;
	push @newlist, $col;	
	
	$self->{session}->current_user->set_value( "items_fields", \@newlist );
	$self->{session}->current_user->commit();
}
sub action_remove_col
{
	my( $self ) = @_;

	my $col_id = $self->{session}->param( "colid" );
	my $v = $self->{session}->current_user->get_value( "items_fields" );

	my @newlist = @$v;
	splice( @newlist, $col_id, 1 );
	
	$self->{session}->current_user->set_value( "items_fields", \@newlist );
	$self->{session}->current_user->commit();
}

sub get_filters
{
	my( $self ) = @_;

	my $pref = $self->{id}."/eprint_status";
	my $user = $self->{session}->current_user;
	my @f = @{$user->preference( $pref ) || []};
	if( !scalar @f )
	{
		# sf2 - 2010-08-04 - define local filters
		my $lf = $self->{session}->config( "items_filters" );
		@f = ( defined $lf ) ? @$lf : ( inbox=>1, buffer=>1, archive=>1, deletion=>1 );
	}

	foreach my $i (0..$#f)
	{
		next if $i % 2;
		my $filter = $f[$i];
		my $v = $self->{session}->param( "set_show_$filter" );
		if( defined $v )
		{
			$f[$i+1] = $v;
			$user->set_preference( $pref, \@f );
			$user->commit;
			last;
		}
	}	

	my @l = map { $f[$_] } grep { $_ % 2 == 0 && $f[$_+1] } 0..$#f;

	return (
		{ meta_fields => [qw( eprint_status )], value => "@l", match => "EQ", merge => "ANY" },
	);
}

sub render_title
{
	my( $self ) = @_;

	return $self->EPrints::Plugin::Screen::render_title();
}

sub perform_search
{
	my( $self ) = @_;

	my $processor = $self->{processor};
	my $search = $processor->{search};
	my $session = $self->{session};

	# Make sure you have the search order now as reorder expensive when many items
	my $sort_order = $search->{order};
	$sort_order = $session->param( "_buffer_order" ) unless $sort_order;
	unless ( $sort_order )
	{
		my $ds = $session->dataset( 'eprint' );
		my $columns = $self->get_sort_columns( $session, $ds );
		foreach my $sort_col ( @$columns )
		{
			next if !defined $sort_col;
			my $field = $ds->get_field( $sort_col );
			next if !defined $field;
			$sort_order = $field->should_reverse_order ? "-$sort_col" : $sort_col;
			last;
		}
	}
 	$self->{sort_order} = $sort_order;

	my $list = $self->{session}->current_user->owned_eprints_list( %$search,
		custom_order => $sort_order,
	);

	return $list;
}

sub render
{
	my( $self ) = @_;

	my $repo = $self->{session};
	my $user = $repo->current_user;
	my $chunk = $repo->make_doc_fragment;
	my $imagesurl = $repo->current_url( path => "static", "style/images" );

	### Get the items owned by the current user
	my $list = $self->perform_search;

	my $has_eprints = $list->count > 0 || $user->owned_eprints_list()->count > 0;

	if( $repo->get_lang->has_phrase( $self->html_phrase_id( "intro" ), $repo ) )
	{
		my $intro_div_outer = $repo->make_element( "div", class => "ep_toolbox" );
		my $intro_div = $repo->make_element( "div", class => "ep_toolbox_content" );
		$intro_div->appendChild( $self->html_phrase( "intro" ) );
		$intro_div_outer->appendChild( $intro_div );
		$chunk->appendChild( $intro_div_outer );
	}

	{
		my $phraseid = $has_eprints ? "Plugin/Screen/Items:help" : "Plugin/Screen/Items:help_no_items";
		my %options;
		if( $repo->get_lang->has_phrase( $phraseid, $repo ) )
		{
			$options{session} = $repo;
			$options{id} = "ep_review_instructions";
			$options{title} = $self->html_phrase( "help_title" );
			$options{content} = $repo->html_phrase( $phraseid );
			$options{collapsed} = 1;
			$options{show_icon_url} = "$imagesurl/help.gif";
			my $box = $repo->make_element( "div", style=>"text-align: left" );
			$box->appendChild( EPrints::Box::render( %options ) );
			$chunk->appendChild( $box );
		}
	}

	$chunk->appendChild( $self->render_action_list_bar( "item_tools" ) );

	my $import_screen = $repo->plugin( "Screen::Import" );
	$chunk->appendChild( $import_screen->render_import_bar() ) if( defined $import_screen );

	if( $has_eprints )
	{
		$chunk->appendChild( $self->render_items( $list ) );
	}

	return $chunk;
}

sub render_items
{
	my( $self, $list ) = @_;

	my $session = $self->{session};
	my $user = $session->current_user;
	my $chunk = $session->make_doc_fragment;
	my $imagesurl = $session->current_url( path => "static", "style/images" );
	my $ds = $session->dataset( "eprint" );

	my $pref = $self->{id}."/eprint_status";
	my %filters = @{$session->current_user->preference( $pref ) || [
		inbox=>1, buffer=>1, archive=>1, deletion=>1
	]};

	my $filter_div = $session->make_element( "div", class=>"ep_items_filters" );
	# EPrints Services/tmb 2011-02-15 add opportunity to bypass hardcoded order
	my @order = @{ $session->config( 'items_filters_order' ) || [] };
	@order = qw/ inbox buffer archive deletion / unless( scalar(@order) );
	# EPrints Services/tmb end
	foreach my $f ( @order )
	{
		my $url = URI->new( $session->current_url() );
		my %q = $self->hidden_bits;
		$q{"set_show_$f"} = !$filters{$f};
		$url->query_form( %q );
		my $link = $session->render_link( $url );
		# http://servicesjira.eprints.org:8080/browse/RCA-175
		$link->setAttribute( 'class', "ep_items_filters_$f" );
		if( $filters{$f} )
		{
			$link->appendChild( $session->make_element(
				"img",
				src=> "$imagesurl/checkbox_tick.png",
				alt=>"Showing" ) );
		}
		else
		{
			$link->appendChild( $session->make_element(
				"img",
				src=> "$imagesurl/checkbox_empty.png",
				alt=>"Not showing" ) );
		}
		$link->appendChild( $session->make_text( " " ) );
		$link->appendChild( $session->html_phrase( "eprint_fieldopt_eprint_status_$f" ) );
		$filter_div->appendChild( $link );
		#$filter_div->appendChild( $session->make_text( ". " ) );
	}

	my $columns = $self->get_sort_columns( $session, $ds );
	my $len = scalar @{$columns};

	my $final_row = undef;
	if( $len > 1 )
	{	
		$final_row = $session->make_element( "tr" );
		my $imagesurl = $session->config( "rel_path" )."/style/images";
		for(my $i=0; $i<$len;++$i )
		{
			my $col = $columns->[$i];
			# Column headings
			my $td = $session->make_element( "td", class=>"ep_columns_alter" );
			$final_row->appendChild( $td );
	
			my $acts_table = $session->make_element( "div", class=>"ep_columns_alter_inner" );
			my $acts_row = $session->make_element( "div" );
			my $acts_td1 = $session->make_element( "div" );
			my $acts_td2 = $session->make_element( "div" );
			my $acts_td3 = $session->make_element( "div" );
			$acts_table->appendChild( $acts_row );
			$acts_row->appendChild( $acts_td1 );
			$acts_row->appendChild( $acts_td2 );
			$acts_row->appendChild( $acts_td3 );
			$td->appendChild( $acts_table );

			if( $i!=0 )
			{
				my $form_l = $session->render_form( "post" );
				$form_l->appendChild( 
					$session->render_hidden_field( "screen", "Items", "screen_" . $i . "_left" ) );
				$form_l->appendChild( 
					$session->render_hidden_field( "colid", $i, "colid_" . $i . "_left" ) );
				$form_l->appendChild( $session->make_element( 
					"input",
					type=>"image",
					value=>"Move Left",
					title=>"Move Left",
					src => "$imagesurl/left.png",
					alt => "<",
					name => "_action_col_left" ) );
				$acts_td1->appendChild( $form_l );
			}
			else
			{
				$acts_td1->appendChild( $session->make_element("img",src=>"$imagesurl/noicon.png",alt=>"") );
			}

			my $msg = $self->phrase( "remove_column_confirm" );
			my $form_rm = $session->render_form( "post" );
			$form_rm->appendChild( 
				$session->render_hidden_field( "screen", "Items", "screen_". $i . "_remove" ) );
			$form_rm->appendChild( 
				$session->render_hidden_field( "colid", $i, "colid_". $i . "_remove" ) );
			$form_rm->appendChild( $session->make_element( 
				"input",
				type=>"image",
				value=>"Remove Column",
				title=>"Remove Column",
				src => "$imagesurl/delete.png",
				alt => "X",
				onclick => "if( window.event ) { window.event.cancelBubble = true; } return confirm( ".EPrints::Utils::js_string($msg).");",
				name => "_action_remove_col" ) );
			$acts_td2->appendChild( $form_rm );

			if( $i!=$len-1 )
			{
				my $form_r = $session->render_form( "post" );
				$form_r->appendChild( 
					$session->render_hidden_field( "screen", "Items", "screen_" . $i . "_right" ) );
				$form_r->appendChild( 
					$session->render_hidden_field( "colid", $i, "colid_". $i . "_right" ) );
				$form_r->appendChild( $session->make_element( 
					"input",
					type=>"image",
					value=>"Move Right",
					title=>"Move Right",
					src => "$imagesurl/right.png",
					alt => ">",
					name => "_action_col_right" ) );
				$acts_td3->appendChild( $form_r );
			}
			else
			{
				$acts_td3->appendChild( $session->make_element("img",src=>"$imagesurl/noicon.png",alt=>"")  );
			}
		}
		my $td = $session->make_element( "td", class=>"ep_columns_alter ep_columns_alter_last" );
		$final_row->appendChild( $td );
	}

	# Paginate list
	my %opts = (
		params => {
			screen => "Items",
		},
		columns => [@{$columns}, undef ],
  		custom_order => $self->{sort_order}, # Prevents a potentially very expensive reorder
		above_results => $filter_div,
		render_result => sub {
			my( $session, $e, $info ) = @_;

			my $class = "row_".($info->{row}%2?"b":"a");
			if( $e->is_locked )
			{
				$class .= " ep_columns_row_locked";
				my $my_lock = ( $e->get_value( "edit_lock_user" ) == $session->current_user->get_id );
				if( $my_lock )
				{
					$class .= " ep_columns_row_locked_mine";
				}
				else
				{
					$class .= " ep_columns_row_locked_other";
				}
			}

			my $tr = $session->make_element( "tr", class=>$class );

			my $status = $e->get_value( "eprint_status" );

			my $first = 1;
			for( @$columns )
			{
				my $td = $session->make_element( "td", class=>"ep_columns_cell ep_columns_cell_$status".($first?" ep_columns_cell_first":"")." ep_columns_cell_$_"  );
				$first = 0;
				$tr->appendChild( $td );
				$td->appendChild( $e->render_value( $_ ) );
			}

			$self->{processor}->{eprint} = $e;
			$self->{processor}->{eprintid} = $e->get_id;
			my $td = $session->make_element( "td", class=>"ep_columns_cell ep_columns_cell_last", align=>"left" );
			$tr->appendChild( $td );
			$td->appendChild( 
				$self->render_action_list_icons( "eprint_item_actions", { 'eprintid' => $self->{processor}->{eprintid} } ) );
			delete $self->{processor}->{eprint};

			++$info->{row};

			return $tr;
		},
		rows_after => $final_row,
	);

	$chunk->appendChild( EPrints::Paginate::Columns->paginate_list( $session, "_buffer", $list, %opts ) );

	# Add form
	my $div = $session->make_element( "div", class=>"ep_columns_add" );
	my $form_add = $session->render_form( "post" );
	$form_add->appendChild( $session->render_hidden_field( "screen", "Items", "screen_add_column" ) );

	my $colcurr = {};
	foreach( @$columns ) { $colcurr->{$_} = 1; }
	my $fieldnames = {};
        foreach my $field ( $ds->get_fields )
        {
                next unless $field->get_property( "show_in_fieldlist" );
		next if $colcurr->{$field->get_name};
		my $name = EPrints::Utils::tree_to_utf8( $field->render_name( $session ) );
		my $parent = $field->get_property( "parent_name" );
		if( defined $parent ) 
		{
			my $pfield = $ds->get_field( $parent );
			$name = EPrints::Utils::tree_to_utf8( $pfield->render_name( $session )).": $name";
		}
		$fieldnames->{$field->get_name} = $name;
        }

	my @tags = sort { $fieldnames->{$a} cmp $fieldnames->{$b} } keys %$fieldnames;

	my $label = $session->make_element( "label" );
	$label->appendChild( $session->make_text( $self->phrase( "add_label" ) . " " ) );

	$label->appendChild( $session->render_option_list( 
		name => 'col',
		height => 1,
		multiple => 0,
		'values' => \@tags,
		labels => $fieldnames ) );

	$form_add->appendChild( $label );
		
	$form_add->appendChild( 
			$session->render_button(
				class=>"ep_form_action_button",
				role=>"button",
				name=>"_action_add_col", 
				value => $self->phrase( "add" ) ) );
	$div->appendChild( $form_add );
	$chunk->appendChild( $div );
	# End of Add form

	return $chunk;
}

sub get_sort_columns 
{
	my ( $self, $session, $ds ) = @_;

	my $columns = $session->current_user->get_value( "items_fields" );
	@$columns = grep { $ds->has_field( $_ ) } @$columns;
	if( !EPrints::Utils::is_set( $columns ) )
	{
		$columns = [ "eprintid","type","eprint_status","lastmod" ];
		$session->current_user->set_value( "items_fields", $columns );
		$session->current_user->commit;
	}
	return $columns;
}

1;


=head1 COPYRIGHT

=for COPYRIGHT BEGIN

Copyright 2024 University of Southampton.
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

