######################################################################
#
# EPrints::Box
#
######################################################################
#
#
######################################################################

=pod

=for Pod2Wiki

=head1 NAME

B<EPrints::Box> - Class to render cute little collapsable/expandable 
Web 2.0ish boxes.

=head1 DESCRIPTION

This just provides a function to render boxes in the EPrints style.

=head2 SYNOPSIS

	use EPrints;

	# an XHTML DOM box with a title and some content that starts rolled up.
	EPrints::Box(
		   handle => $handle,
		       id => "my_box",
		    title => $my_title_dom,
		  content => $my_content_dom,
		collapsed => 1,
	); 

=head1 METHODS

=cut

package EPrints::Box;

use strict;

######################################################################
=pod

=over 4

=item $box_xhtmldom = EPrints::Box::render( %options )

Render a collapsable/expandable box to which content can be added. The 
box is in keeping with the eprints style.

Required Options:

B<C<$options{handle}>> - Current C<$handle>.

B<C<$options{id}>> - ID attibute of the box. E.g. <div id="my_box">

B<C<$options{title}>> - XHTML DOM of the title of the box. N.B. The exact 
object will be used not a clone of the object.

B<C<$options{content}>> - XHTML DOM of the content of the box. N.B. The 
exact object will be used not a clone of the object.

Optional Options:

B<C<$options{collapsed}>> -Should the box start rolled up. Defaults to 
C<false>.

B<C<$options{content_style}>> - The CSS style to apply to the content box. 
E.g. C<overflow-y: auto; height: 300px;>

B<C<$options{show_icon_url}>> - The URL of the icon to use instead of the 
B<[+]>

B<C<$options{hide_icon_url}>> - The URL of the icon to use instead of the 
B<[-]>

=cut
######################################################################

sub EPrints::Box::render
{
	my( %options ) = @_;

	if( !defined $options{id} ) { EPrints::abort( "EPrints::Box::render called without a id. Bad bad bad." ); }
	if( !defined $options{title} ) { EPrints::abort( "EPrints::Box::render called without a title. Bad bad bad." ); }
	if( !defined $options{content} ) { EPrints::abort( "EPrints::Box::render called without a content. Bad bad bad." ); }
	if( !defined $options{session} ) { EPrints::abort( "EPrints::Box::render called without a session. Bad bad bad." ); }

	my $class = "";
	$class = $options{class} if defined $options{class};

	my $session = $options{session};
	my $imagesurl = $session->config( "rel_path" );
	if( !defined $options{show_icon_url} ) { $options{show_icon_url} = "$imagesurl/style/images/plus.png"; }
	if( !defined $options{hide_icon_url} ) { $options{hide_icon_url} = "$imagesurl/style/images/minus.png"; }

	my $id = $options{id};
		
	my $contentid = $id."_content";
	my $colbarid = $id."_colbar";
	my $barid = $id."_bar";

	my $div = $session->make_element( "div", class=>"ep_summary_box $class", id=>$id );

	# Title
	my $div_title = $session->make_element( "div", class=>"ep_summary_box_title" );
	$div->appendChild( $div_title );

	my $nojstitle = $session->make_element( "div", class=>"ep_no_js" );
	$nojstitle->appendChild( $session->clone_for_me( $options{title},1 ) );
	$div_title->appendChild( $nojstitle );

	my $collapse_bar = $session->make_element( "div", class=>"ep_only_js", id=>$colbarid );
	my $collapse_link = $session->make_element( "a", class=>"ep_box_collapse_link", onclick => "EPJS_blur(event); EPJS_toggleSlideScroll('${contentid}',true,'${id}');EPJS_toggle('${colbarid}',true);EPJS_toggle('${barid}',false);return false", href=>"#" );
	$collapse_link->appendChild( $session->make_element( "img", alt=>"-", src=>$options{hide_icon_url}, border=>0 ) );
	$collapse_link->appendChild( $session->make_text( " " ) );
	$collapse_link->appendChild( $session->clone_for_me( $options{title},1 ) );
	$collapse_bar->appendChild( $collapse_link );
	$div_title->appendChild( $collapse_bar );

	my $a = "true";
	my $b = "false";
	if( $options{collapsed} ) 
	{ 
		$b = "true";
		$a = "false";
	}
	my $uncollapse_bar = $session->make_element( "div", class=>"ep_only_js", id=>$barid );
	my $uncollapse_link = $session->make_element( "a", class=>"ep_box_collapse_link", onclick => "EPJS_blur(event); EPJS_toggleSlideScroll('${contentid}',false,'${id}');EPJS_toggle('${colbarid}',$a);EPJS_toggle('${barid}',$b);return false", href=>"#" );
	$uncollapse_link->appendChild( $session->make_element( "img", alt=>"+", src=>$options{show_icon_url}, border=>0 ) );
	$uncollapse_link->appendChild( $session->make_text( " " ) );
	$uncollapse_link->appendChild( $session->clone_for_me( $options{title},1 ) );
	$uncollapse_bar->appendChild( $uncollapse_link );
	$div_title->appendChild( $uncollapse_bar );
	
	# Body	
	my $div_body = $session->make_element( "div", class=>"ep_summary_box_body", id=>$contentid );
	my $div_body_inner = $session->make_element( "div", id=>$contentid."_inner", style=>$options{content_style} );
	$div_body->appendChild( $div_body_inner );
	$div->appendChild( $div_body );
	$div_body_inner->appendChild( $options{content} );

	if( $options{collapsed} ) 
	{ 
		$collapse_bar->setAttribute( "style", "display: none" ); 
		$div_body->setAttribute( "style", "display: none" ); 
	}
	else
	{
		$uncollapse_bar->setAttribute( "style", "display: none" ); 
	}
		
	return $div;
}

1;

=back

=head1 COPYRIGHT

=begin COPYRIGHT

Copyright 2022 University of Southampton.
EPrints 3.4 is supplied by EPrints Services.

http://www.eprints.org/eprints-3.4/

=end COPYRIGHT

=begin LICENSE

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

=end LICENSE

