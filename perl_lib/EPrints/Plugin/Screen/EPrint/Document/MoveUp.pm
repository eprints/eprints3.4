=head1 NAME

EPrints::Plugin::Screen::EPrint::Document::MoveUp

=cut

package EPrints::Plugin::Screen::EPrint::Document::MoveUp;

our @ISA = ( 'EPrints::Plugin::Screen::EPrint::Document' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	$self->{icon} = "action_up.png";

	$self->{appears} = [
		{
			place => "document_item_actions",
			position => 1000,
		},
	];
	
	$self->{actions} = [qw//];

	$self->{ajax} = "automatic";

	return $self;
}

sub from
{
	my( $self ) = @_;

	my $eprint = $self->{processor}->{eprint};
	my $doc = $self->{processor}->{document};
	my @docs = $eprint->get_all_documents;

	if( $doc )
	{
		my $i;
		for($i = 0; $i < @docs; ++$i)
		{
			last if $doc->id == $docs[$i]->id;
		}
		if( $i == 0 )
		{
			my $t = $docs[$#docs]->value( "placement" );
			for($i = $#docs; $i > 0; --$i)
			{
				$docs[$i]->set_value( "placement",
					$docs[$i-1]->value( "placement" ) );
			}
			$docs[0]->set_value( "placement", $t );
			$_->commit for @docs;
			return;
		}
		my( $left, $right ) = @docs[($i-1)%@docs, $i];
		my $t = $left->value( "placement" );
		$left->set_value( "placement", $right->value( "placement" ) );
		$right->set_value( "placement", $t );
		$left->commit;
		$right->commit;
		push @{$self->{processor}->{docids}},
			$left->id,
			$right->id;
	}

	$self->{processor}->{redirect} = $self->{processor}->{return_to};
}

1;

=head1 COPYRIGHT

=for COPYRIGHT BEGIN

Copyright 2018 University of Southampton.
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

