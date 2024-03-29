package EPrints::Plugin::Screen::HistorySingleItem;

our @ISA = ( 'EPrints::Plugin::Screen' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	$self->{datasetid} = undef; # define in subclasses
	$self->{title_phrase} = __PACKAGE__ . ":title";
	$self->{expensive} = 1;
	$self->{appears} = [
		{
			place => "dataobj_view_tabs",
			position => 600,
		}
	];

	return $self;
}

sub can_be_viewed
{
	my( $self ) = @_;

	return 0 unless defined $self->{datasetid};
	return 0 unless defined $self->repository->config( "history_enable", $self->{datasetid} );
	return $self->{datasetid} eq $self->repository->param( "dataset" )  && $self->allow( $self->{datasetid} . "/history" );
}

sub render_tab_title
{
	my( $self ) = @_;

	return $self->repository->html_phrase( $self->{title_phrase} );
}

sub render
{
	my( $self, $basename ) = @_;
	my $repo = $self->repository;

	my $objectid = $repo->param( "dataobj" );

	my @filters = (
		{ meta_fields => [qw( datasetid )], value => $self->{datasetid}, },
		{ meta_fields => [qw( objectid )], value => $objectid, },
	);

	my $list = $repo->dataset( "history" )->search(
		filters => \@filters,
		custom_order=>"-historyid",
		# limit => 10,
	);

	return EPrints::Paginate->paginate_list(
		$repo,
		$basename,
		$list,
		params => {
			$self->{processor}->{screen}->hidden_bits,
		},
		container => $repo->make_element( "div" ),
		render_result => sub {
			my( undef, $item ) = @_;

			$item->set_parent( $list );
			return $item->render;
		},
	);
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

