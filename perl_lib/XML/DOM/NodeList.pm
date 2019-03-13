=head1 NAME

XML::DOM::NodeList

=cut

######################################################################
package XML::DOM::NodeList;
######################################################################

use vars qw ( $EMPTY );

# Empty NodeList
$EMPTY = new XML::DOM::NodeList;

sub new 
{
    bless [], $_[0];
}

sub item 
{
    $_[0]->[$_[1]];
}

sub getLength 
{
    int (@{$_[0]});
}

#------------------------------------------------------------
# Extra method implementations

sub dispose
{
    my $self = shift;
    for my $kid (@{$self})
    {
	$kid->dispose;
    }
}

sub setOwnerDocument
{
    my ($self, $doc) = @_;
    for my $kid (@{$self})
    { 
	$kid->setOwnerDocument ($doc);
    }
}

1; # package return code

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

