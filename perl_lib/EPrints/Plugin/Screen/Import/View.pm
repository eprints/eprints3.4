=head1 NAME

EPrints::Plugin::Screen::Import::View

=cut

package EPrints::Plugin::Screen::Import::View;

@ISA = ( 'EPrints::Plugin::Screen::Workflow' );

use strict;

sub get_dataset_id { "import" }

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	$self->{icon} = "action_view.png";

	$self->{appears} = [
		{
			place => "import_item_actions",
			position => 200,
		},
	];

	$self->{actions} = [qw/ /];

	return $self;
}

sub render
{
	my( $self ) = @_;

	my $session = $self->{session};
	my $dataobj = $self->{processor}->{dataobj};

	my $page = $session->make_doc_fragment;

	my $ul = $session->make_element( "ul" );
	$page->appendChild( $ul );

	$dataobj->map(sub {
		my( undef, undef, $item ) = @_;

		my $li = $session->make_element( "li" );
		$ul->appendChild( $li );

		$li->appendChild( $item->render_citation_link() );
	});

	return $page;
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

