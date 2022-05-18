package EPrints::Plugin::Screen::HistoryMultiItem;

# only works for items associated with the current user

our @ISA = ( 'EPrints::Plugin::Screen' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	$self->{datasetid} = undef; # define in subclasses
	$self->{datasetid_sub} = undef; # optionally define in subclasses
	$self->{title_phrase} = __PACKAGE__ . ":title";
	$self->{expensive} = 1;
	$self->{appears} = [
		{
			place => "dataobj_user_view_tabs",
			position => 600,
		}
	];

	return $self;
}

sub can_be_viewed
{
	my( $self ) = @_;

	# should perhaps be locked down further for security reasons
	return 0 unless defined $self->{datasetid};
	return 0 unless defined $self->repository->config( "history_enable", $self->{datasetid} );
	return 0 if $self->get_history->count == 0;

	return
		$self->allow( $self->{datasetid} . "/history" ) && 
		(
			$self->{datasetid} eq $self->repository->param( "dataset" ) ||
			$self->{datasetid_sub} eq $self->repository->param( "dataset" )
		);
}

sub render_tab_title
{
	my( $self ) = @_;

	return $self->repository->html_phrase( $self->{title_phrase} );
}

sub get_history
{
	my( $self ) = @_;

	my $user = $self->{processor}->{dataobj};
	$user = $self->{processor}->{user} if !defined $user;

	my $cache_id = "history_".$self->{datasetid}."_".$user->id;

	if( !defined $self->{processor}->{$cache_id} )
	{
		my $ds = $self->{session}->get_repository->get_dataset( "history" );
		my $searchexp = EPrints::Search->new(
			session=>$self->{session},
			dataset=>$ds,
			custom_order=>"-timestamp/-historyid" );
		
		$searchexp->add_field(
			$ds->get_field( "userid" ),
			$user->id );
		$searchexp->add_field(
			$ds->get_field( "datasetid" ),
			$self->{datasetid} );
		
		$self->{processor}->{$cache_id} = $searchexp->perform_search;
	}

	return $self->{processor}->{$cache_id};
}

sub render
{
	my( $self ) = @_;

	my $list = $self->get_history;
	my $cacheid = $list->{cache_id};

	my $container = $self->{session}->make_element( 
				"div", 
				class=>"ep_paginate_list" );

	# a tab's screen is the parent screen
	my %params = (
		$self->hidden_bits,
		screen => $self->{processor}->{screenid},
		view => $self->get_subtype,
	);

	my %opts =
	(
		params => \%params,
		render_result => sub { return $self->render_result_row( @_ ); },
		render_result_params => $self,
		page_size => 50,
		container => $container,
	);

	return EPrints::Paginate->paginate_list( 
			$self->{session}, 
			"_history", 
			$list,
			%opts );
}	

sub render_result_row
{
	my( $self, $session, $result, $searchexp, $n ) = @_;

	my $div = $session->make_element( "div", class=>"ep_search_result" );
	$div->appendChild( $result->render_citation( "default" ) );
	return $div;
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

