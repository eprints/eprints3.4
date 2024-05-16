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
