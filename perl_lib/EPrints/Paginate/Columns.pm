######################################################################
#
# EPrints::Paginate::Columns
#
######################################################################
#
#
######################################################################

=pod

=for Pod2Wiki

=head1 NAME

B<EPrints::Paginate::Columns> - Methods for rendering a paginated List as sortable columns

=head1 DESCRIPTION

=over 4

=cut

######################################################################
package EPrints::Paginate::Columns;

@ISA = ( 'EPrints::Paginate' );

use URI::Escape;
use strict;

sub paginate_list
{
	my( $class, $session, $basename, $list, %opts ) = @_;

	my %newopts = %opts;
	
	if( EPrints::Utils::is_set( $basename ) )
	{
		$basename .= '_';
	}
	else
	{
		$basename = '';
	}

	# Build base URL
	my $url = $session->get_uri . "?";
	my @param_list;
	if( defined $opts{params} )
	{
		my $params = $opts{params};
		foreach my $key ( keys %$params )
		{
			next if $key eq $basename."order";
			my $value = $params->{$key};
			push @param_list, "$key=$value" if defined $value;
		}
	}
	$url .= join "&", @param_list;

	my $offset = defined $opts{offset} ? $opts{offset} : ($session->param( $basename."offset" ) || 0);
	$offset += 0;
	$url .= "&".$basename."offset=$offset"; # $basename\_offset used by paginate_list

	# Sort param
	my $sort_order = $opts{custom_order};
	if( !defined $sort_order )
	{
		$sort_order = $session->param( $basename."order" );
	}
	if( !defined $sort_order ) 
	{
		foreach my $sort_col (@{$opts{columns}})
		{
			next if !defined $sort_col;
			my $field = $list->get_dataset->get_field( $sort_col );
			next if !defined $field;

			if( $field->should_reverse_order )
			{
				$sort_order = "-$sort_col";
			}	
			else	
			{
				$sort_order = "$sort_col";
			}	
			last;
		}
	}	
	if( EPrints::Utils::is_set( $sort_order ) )
	{
		$newopts{params}{ $basename."order" } = $sort_order;
		if( !$opts{custom_order} )
		{
			$list = $list->reorder( $sort_order );
		}
	}
	
	# URL for images
	my $imagesurl = $session->config( "rel_path" )."/style/images";

	# Container for list
	my $table = $session->make_element( "table", border=>0, cellpadding=>4, cellspacing=>0, class=>"ep_columns" );
	my $tr = $session->make_element( "tr", class=>"header_plain" );
	$table->appendChild( $tr );

	my $len = scalar(@{$opts{columns}});

	for(my $i = 0; $i<$len;++$i )
	{
		my $col = $opts{columns}->[$i];
		my $last = ($i == $len-1);
		# Column headings
		my $th = $session->make_element( "th", style=>"padding:0px", class=>"ep_columns_title".($last?" ep_columns_title_last":"") );
		if ( !defined $col )
		{
			my $span = $session->make_element( "span", style=>"padding: 4px" );
			$span->appendChild( $session->make_text( $session->html_phrase( "general:actions_column_name" ) ) );
			$th->appendChild( $span );
		}
		$tr->appendChild( $th );
		next if !defined $col;
	
		my $linkurl = "$url&${basename}order=$col";
		if( $col eq $sort_order )
		{
			$linkurl = "$url&${basename}order=-$col";
		}
		my $field = $list->get_dataset->get_field( $col );
		if( $field->should_reverse_order )
		{
			$linkurl = "$url&${basename}order=-$col";
			if( "-$col" eq $sort_order )
			{
				$linkurl = "$url&${basename}order=$col";
			}
		}
		my $itable = $session->make_element( "div", class=>"ep_columns_title_inner" );
		$th->appendChild( $itable );
		my $itr = $session->make_element( "div" );
		$itable->appendChild( $itr );
		my $itd1 = $session->make_element( "div" );
		$itr->appendChild( $itd1 );
		my $link = $session->make_element( "a", href=>$linkurl . "&link=name", style=>'display:block;padding:4px' );
		$link->appendChild( $list->get_dataset->get_field( $col )->render_name( $session ) );
		$itd1->appendChild( $link );

		# Sort controls

		if( $sort_order eq $col || $sort_order eq "-$col")
		{
			my $itd2 = $session->make_element( "div", class=>"ep_columns_title_inner_sort" );
			$itr->appendChild( $itd2 );
			my $link2 = $session->render_link( $linkurl . "&link=icon" );
			$itd2->appendChild( $link2 );
			if( $sort_order eq $col )
			{
				$link2->appendChild( $session->make_element(
					"img",
					alt=>"Up",
					src=> "$imagesurl/sorting_up_arrow.gif" ));
			}
			if( $sort_order eq "-$col" )
			{
				$link2->appendChild( $session->make_element(
					"img",
					alt=>"Down",
					src=> "$imagesurl/sorting_down_arrow.gif" ));
			}
		}
			
	}
	
	my $info = {
		row => 1,
		columns => $opts{columns},
	};
	$newopts{container} = $table unless defined $newopts{container};
	$newopts{render_result_params} = $info unless defined $newopts{render_result_params};
	$newopts{render_result} = sub {
		my( $session, $e, $info ) = @_;

		my $tr = $session->make_element( "tr" );
		my $first = 1;
		foreach my $column ( @{ $info->{columns} } )
		{
			my $td = $session->make_element( "td", class=>"ep_columns_cell".($first?" ep_columns_cell_first":"") );
			$first = 0;
			$tr->appendChild( $td );
			$td->appendChild( $e->render_value( $column ) );
		}
		return $tr;
	} unless defined $newopts{render_result};

	$newopts{render_no_results} = sub {
		my( $session, $info, $phrase ) = @_;
		my $tr = $session->make_element( "tr" );
		my $td = $session->make_element( "td", class=>"ep_columns_no_items", colspan => scalar @{ $opts{columns} } );
		$td->appendChild( $phrase ); 
		$tr->appendChild( $td );
		return $tr;
	} unless defined $newopts{render_no_results};
	
	return EPrints::Paginate->paginate_list( $session, $basename, $list, %newopts );
}

1;

######################################################################
=pod

=back

=cut


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

