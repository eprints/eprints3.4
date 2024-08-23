######################################################################
#
# EPrints::Signposting
#
######################################################################
#
#
######################################################################

=pod

=for Pod2Wiki

=head1 NAME

B<EPrints::Signposting> - Signposting functionality as described by https://signposting.org/

=head1 SYNOPSIS
	
=head1 DESCRIPTION

=head1 METHODS

=over 4

=cut

package EPrints::Signposting;

use strict;

sub signposting
{
	my ( $repository, $r, $eprint ) = @_;

    my @links;

    # citation
    push @links, EPrints::Signposting::link_header( $eprint->uri, "cite-as" );

    # exports
    my @plugins = $repository->get_plugins(
        type => "Export",
        can_accept => "dataobj/eprint",
        is_visible => "all",
        signposting => 1,
    );
    foreach my $plugin ( @plugins )
    {
        push @links, EPrints::Signposting::link_header( $plugin->dataobj_export_url( $eprint ), "describedby", $plugin->{mimetype} );
    }       

    # and add to the response header    
    EPrints::Apache::AnApache::header_out( $r, "Link", join( ", ", @links ) );
}   

sub link_header
{
    my( $value, $rel, $type ) = @_;

    my $link_header = "<$value>; rel=\"$rel\""; 

    $link_header .= "; type=\"$type\"" if( defined $type );

    return $link_header;
}

1;


=head1 COPYRIGHT

=for COPYRIGHT BEGIN

Copyright 2024 University of London

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

