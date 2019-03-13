=head1 NAME

EPrints::Plugin::Screen::Search

=cut

package EPrints::Plugin::Screen::Search;

use EPrints::Plugin::Screen::AbstractSearch;
@ISA = ( 'EPrints::Plugin::Screen::AbstractSearch' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);
	
	$self->{appears} = [];
	push @{$self->{actions}}, "advanced", "savesearch";

	return $self;
}

sub datasets
{
	my( $self ) = @_;

	my $session = $self->{session};

	my @datasets;

	foreach my $datasetid ($session->get_dataset_ids)
	{
		local $self->{processor}->{dataset} = $session->dataset( $datasetid );
		next if !$self->can_be_viewed();
		push @datasets, $datasetid;
	}

	return @datasets;
}

sub search_dataset
{
	my( $self ) = @_;

	return $self->{processor}->{dataset};
}

sub allow_advanced { shift->can_be_viewed( @_ ) }
sub allow_export { shift->can_be_viewed( @_ ) }
sub allow_export_redir { shift->can_be_viewed( @_ ) }
sub allow_savesearch
{
	my( $self ) = @_;

	return 0 if !$self->can_be_viewed();

	my $user = $self->{session}->current_user;
	return defined $user && $user->allow( "create_saved_search" );
}
sub can_be_viewed
{
	my( $self ) = @_;

	# note this method is also used by $self->datasets()
	
	my $dataset = $self->{processor}->{dataset};
	return 0 if !defined $dataset;

	my $searchid = $self->{processor}->{searchid};

	if( $dataset->id eq "archive" )
	{
		return $self->allow( "eprint_search" );
	}
	elsif( defined($searchid) && (my $rc = $self->allow( $dataset->id . "/search/$searchid" )) )
	{
		return $rc;
	}
	{
		return $self->allow( $dataset->id . "/search" );
	}
}

sub get_controls_before
{
	my( $self ) = @_;

	my @controls = $self->get_basic_controls_before;

	my $cacheid = $self->{processor}->{results}->{cache_id};
	my $escexp = $self->{processor}->{search}->serialise;

	my $baseurl = URI->new( $self->{session}->get_uri );
	$baseurl->query_form(
		cache => $cacheid,
		exp => $escexp,
		screen => $self->{processor}->{screenid},
		dataset => $self->search_dataset->id,
		order => $self->{processor}->{search}->{custom_order},
	);

# Maybe add links to the pagination controls to switch between simple/advanced
#	if( $self->{processor}->{searchid} eq "simple" )
#	{
#		push @controls, {
#			url => "advanced",
#			label => $self->{session}->html_phrase( "lib/searchexpression:advanced_link" ),
#		};
#	}

	my $user = $self->{session}->current_user;
	if( defined $user && $user->allow( "create_saved_search" ) )
	{
		#my $cacheid = $self->{processor}->{results}->{cache_id};
		#my $exp = $self->{processor}->{search}->serialise;

		my $url = $baseurl->clone;
		$url->query_form(
			$url->query_form,
			_action_savesearch => 1
		);

		push @controls, {
			url => "$url",
			label => $self->{session}->html_phrase( "lib/searchexpression:savesearch" ),
		};
	}

	return @controls;
}

sub hidden_bits
{
	my( $self ) = @_;
	
	my %bits = $self->SUPER::hidden_bits;

	my @datasets = $self->datasets;

	# if there's more than 1 dataset, then the search form will render the list of "search-able" datasets - see render_dataset below
	if( scalar( @datasets ) < 2 )
	{
		$bits{dataset} = $self->{processor}->{dataset}->id;
	}

	return %bits;
}

sub render_result_row
{
	my( $self, $session, $result, $searchexp, $n ) = @_;

	my $staff = $self->{processor}->{sconf}->{staff};
	my $citation = $self->{processor}->{sconf}->{citation};

	#if we have a template, add it on the end of the item's url
	my %params;
	if( defined $self->{processor}->{sconf}->{template} )
	{
		$params{url} = $result->url . "?template=" . $self->{processor}->{sconf}->{template};
        }

	$params{n} = [$n,"INTEGER"];

	if( $staff )
	{
		return $result->render_citation_link_staff( $citation, 
			%params );
	}
	else
	{
		return $result->render_citation_link( $citation,
			%params );
	}
}

sub export_url
{
	my( $self, $format ) = @_;

	my $plugin = $self->{session}->plugin( "Export::".$format );
	if( !defined $plugin )
	{
		EPrints::abort( "No such plugin: $format\n" );	
	}

	my $url = URI->new( $self->{session}->current_url() . "/export_" . $self->{session}->get_repository->get_id . "_" . $format . $plugin->param( "suffix" ) );

	$url->query_form(
		$self->hidden_bits,
		_action_export => 1,
		output => $format,
		exp => $self->{processor}->{search}->serialise,
		n => scalar($self->{session}->param( "n" )),
	);

	return $url;
}

sub action_advanced
{
	my( $self ) = @_;

	my $adv_url;
	my $datasetid = $self->{session}->param( "dataset" );
	$datasetid = "archive" if !defined $datasetid; # something odd happened
	if( $datasetid eq "archive" )
	{
		$adv_url = $self->{session}->current_url( path => "cgi", "search/advanced" );
	}
	else
	{
		$adv_url = $self->{session}->current_url( path => "cgi", "search/$datasetid/advanced" );
	}

	$self->{processor}->{redirect} = $adv_url;
}

sub action_savesearch
{
	my( $self ) = @_;

	my $ds = $self->{session}->dataset( "saved_search" );

	my $searchexp = $self->{processor}->{search};
	$searchexp->{searchid} = $self->{processor}->{searchid};

	my $name = $searchexp->render_conditions_description;
	my $userid = $self->{session}->current_user->id;

	my $spec = $searchexp->freeze;
	my $results = $ds->search(
		filters => [
			{ meta_fields => [qw( userid )], value => $userid, },
			{ meta_fields => [qw( spec )], value => $spec, match => "EX" },
	]);
	my $savedsearch = $results->item( 0 );

	my $screen;

	if( defined $savedsearch )
	{
		$screen = "View";
	}
	else
	{
		$screen = "Edit";
		$savedsearch = $ds->create_dataobj( { 
			userid => $self->{session}->current_user->id,
			name => $self->{session}->xml->text_contents_of( $name ),
			spec => $searchexp->freeze
		} );
	}

	$self->{session}->xml->dispose( $name );

	my $url = URI->new( $self->{session}->config( "userhome" ) );
	$url->query_form(
		screen => "Workflow::$screen",
		dataset => "saved_search",
		dataobj => $savedsearch->id,
	);
	$self->{session}->redirect( $url );
	exit;
}

sub render_search_form
{
	my( $self ) = @_;

	if( $self->{processor}->{searchid} eq "simple" && @{$self->{processor}->{sconf}->{search_fields}} == 1 )
	{
		return $self->render_simple_form;
	}
	else
	{
		return $self->SUPER::render_search_form;
	}
}

sub render_preamble
{
	my( $self ) = @_;

	my $pphrase = $self->{processor}->{sconf}->{"preamble_phrase"};

	return $self->{session}->make_doc_fragment if !defined $pphrase;

	return $self->{session}->html_phrase( $pphrase );
}

sub render_simple_form
{
	my( $self ) = @_;

	my $session = $self->{session};
	my $xhtml = $session->xhtml;
	my $xml = $session->xml;
	my $input;

	my $div = $xml->create_element( "div", class => "ep_block" );

	my $form = $self->{session}->render_form( "get" );
	$div->appendChild( $form );

	# avoid adding "dataset", which is selectable here
	$form->appendChild( $self->SUPER::render_hidden_bits );

	# maintain the order if it was specified (might break if dataset is
	# changed)
	$input = $xhtml->hidden_field( "order", $session->param( "order" ) );
	$form->appendChild( $input );

	$form->appendChild( $self->render_preamble );

	$form->appendChild( $self->{processor}->{search}->render_simple_fields );

	$input = $xml->create_element( "input",
		type => "submit",
		name => "_action_search",
		value => $self->{session}->phrase( "lib/searchexpression:action_search" ),
		class => "ep_form_action_button",
	);
	$form->appendChild( $input );

	$input = $xml->create_element( "input",
		type => "submit",
		name => "_action_advanced",
		value => $self->{session}->phrase( "lib/searchexpression:advanced_link" ),
		class => "ep_form_action_button ep_form_search_advanced_link",
	);
	$form->appendChild( $input );

	$form->appendChild( $xml->create_element( "br" ) );

	$form->appendChild( $self->render_dataset );

	return( $div );
}

sub render_dataset
{
	my( $self ) = @_;

	my $session = $self->{session};
	my $xhtml = $session->xhtml;
	my $xml = $session->xml;

	my $frag = $xml->create_document_fragment;

	my @datasetids = $self->datasets;

	return $frag if @datasetids <= 1;

	foreach my $datasetid (sort @datasetids)
	{
		my $input = $xml->create_element( "input",
			name => "dataset",
			type => "radio",
			value => $datasetid );
		if( $datasetid eq $self->{processor}->{dataset}->id )
		{
			$input->setAttribute( checked => "yes" );
		}
		my $label = $xml->create_element( "label" );
		$frag->appendChild( $label );
		$label->appendChild( $input );
		$label->appendChild( $session->html_phrase( "datasetname_$datasetid" ) );
	}

	return $frag;
}

sub properties_from
{
	my( $self ) = @_;

	$self->SUPER::properties_from();

	my $processor = $self->{processor};
	my $repo = $self->{session};

	my $dataset = $processor->{dataset};
	my $searchid = $processor->{searchid};

	return if !defined $dataset;
	return if !defined $searchid;

	# get the dataset's search configuration
	my $sconf = $dataset->search_config( $searchid );
	$sconf = $self->default_search_config if !%$sconf;

	$processor->{sconf} = $sconf;
	$processor->{template} = $sconf->{template};
}

sub default_search_config
{
	my( $self ) = @_;

	my $processor = $self->{processor};
	my $repo = $self->{session};

	my $sconf = undef;

	#we haven't found an sconf in the config...
	#so try to derive an sconf from the searchid...
	my $searchid = $processor->{searchid};
	if( $searchid =~ /^([a-zA-z]+)_(\d+)_([a-zA-Z]+)/)
        {
		#get the sconf from the dataobj (this is probably an ingredients/eprints_list list)
		my $ds = $repo->dataset( $1 );
		if( defined $ds )
                {
                        my $dataobj = $ds->dataobj( $2 );
                        $sconf = $dataobj->get_sconf( $repo, $3 ) if defined $dataobj && $dataobj->can( "get_sconf" );
                }

	}
	return $sconf;
}

sub from
{
	my( $self ) = @_;

	my $session = $self->{session};
	my $processor = $self->{processor};
	my $sconf = $processor->{sconf};

	# This rather oddly now checks for the special case of one parameter, but
	# that parameter being a screenid, in which case the search effectively has
	# no parameters and should not default to action = 'search'.
	# maybe this can be removed later, but for a minor release this seems safest.
	if( !EPrints::Utils::is_set( $self->{processor}->{action} ) )
	{
		my %params = map { $_ => 1 } $self->{session}->param();
		foreach my $param (keys %{{$self->hidden_bits}}) {
			delete $params{$param};
		}
		if( EPrints::Utils::is_set( $self->{session}->param( "output" ) ) )
		{
			$self->{processor}->{action} = "export";
		}
		elsif( scalar keys %params )
		{
			$self->{processor}->{action} = "search";
		}
		else
		{
			$self->{processor}->{action} = "";
		}
	}

	my $satisfy_all = $self->{session}->param( "satisfyall" );
	$satisfy_all = !defined $satisfy_all || $satisfy_all eq "ALL";

	my $searchexp = $processor->{search};
	if( !defined $searchexp )
	{
		my $format = $processor->{searchid} . "/" . $processor->{dataset}->base_id;
		if( !defined $sconf )
		{
			EPrints->abort( "No available configuration for search type $format" );
		}
		$searchexp = $session->plugin( "Search" )->plugins(
			{
				session => $session,
				dataset => $self->search_dataset,
				keep_cache => 1,
				satisfy_all => $satisfy_all,
				%{$sconf},
				filters => [
					$self->search_filters,
					@{$sconf->{filters} || []},
				],
			},
			type => "Search",
			can_search => $format,
		);
		if( !defined $searchexp )
		{
			EPrints->abort( "No available search plugin for $format" );
		}
		$processor->{search} = $searchexp;
	}

	if( $searchexp->is_blank && $self->{processor}->{action} ne "newsearch" )
	{
		my $ok = 0;
		if( my $id = $session->param( "cache" ) )
		{
			$ok = $searchexp->from_cache( $id );
		}
		if( !$ok && (my $exp = $session->param( "exp" )) )
		{
			# cache expired
			$ok = $searchexp->from_string( $exp );
		}
		if( !$ok )
		{
			for( $searchexp->from_form )
			{
				$self->{processor}->add_message( "warning", $_ );
			}
		}
	}

	$sconf->{order_methods} = {} if !defined $sconf->{order_methods};
	if( $searchexp->param( "result_order" ) )
	{
		$sconf->{order_methods}->{"byrelevance"} = "";
	}

	# have we been asked to reorder?
	if( defined( my $order_opt = $self->{session}->param( "order" ) ) )
	{
		my $allowed_order = 0;
		foreach my $custom_order ( values %{$sconf->{order_methods}} )
		{
			$allowed_order = 1 if $order_opt eq $custom_order;
		}

		my $custom_order;
		if( $allowed_order )
		{
			$custom_order = $order_opt;
		}
		elsif( defined $sconf->{default_order} )
		{
			$custom_order = $sconf->{order_methods}->{$sconf->{default_order}};
		}
		else
		{
			$custom_order = "";
		}

		$searchexp->{custom_order} = $custom_order;
	}
	# use default order
	else
	{
		$searchexp->{custom_order} = $sconf->{order_methods}->{$sconf->{default_order}};
	}

	# feeds are always limited and ordered by -datestamp
	if( $self->{processor}->{action} eq "export" )
	{
		my $output = $self->{session}->param( "output" );
		my $export_plugin = $self->{session}->plugin( "Export::$output" );
		if( !defined($self->{session}->param( "order" )) && defined($export_plugin) && $export_plugin->is_feed )
		{
			# borrow the max from latest_tool (which we're replicating anyway)
			my $limit = $self->{session}->config(
				"latest_tool_modes", "default", "max"
			);
			$limit = 20 if !$limit;
			my $n = $self->{session}->param( "n" );
			if( $n && $n > 0 && $n < $limit)
			{
				$limit = $n;
			}
			$searchexp->{limit} = $limit;
			$searchexp->{custom_order} = "-datestamp";
		}
	}

	# do actions
	$self->EPrints::Plugin::Screen::from;

	if( $searchexp->is_blank && $self->{processor}->{action} ne "export" )
	{
		if( $self->{processor}->{action} eq "search" )
		{
			$self->{processor}->add_message( "warning",
				$self->{session}->html_phrase( 
					"lib/searchexpression:least_one" ) );
		}
		$self->{processor}->{search_subscreen} = "form";
	}
}

1;

=head1 COPYRIGHT

=for COPYRIGHT BEGIN

Copyright 2019 University of Southampton.
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

