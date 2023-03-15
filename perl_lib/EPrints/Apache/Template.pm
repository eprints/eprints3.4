######################################################################
#
# EPrints::Apache::Template
#
######################################################################
#
#
######################################################################

=pod

=for Pod2Wiki

=head1 NAME

B<EPrints::Apache::Template> - Template Applying Module

=head1 DESCRIPTION

When HTML pages are served by EPrints they are processed through a 
template written in XML. Most repositories will have two templates - 
F<default.xml> for HTTP and F<secure.xml> for HTTPS.

Templates are parsed at B<server start-up> and any included phrases 
are replaced at that point. Because templates persist over the 
lifetime of a server you do not typically perform any logic within 
the template itself, instead use a pin generated via L</Custom Pins>.

The page content is added to the template via C<<epc:pins>>.

=head2 Synopsis

	<?xml version="1.0" standalone="no"?>
	<!DOCTYPE html SYSTEM "entities.dtd">
	<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epc="http://eprints.org/ep3/control">
	  <head>
		  <title><epc:pin ref="title" textonly="yes"/> - <epc:phrase ref="archive_name"/></title>
    ...

=head2 Custom Pins

In F<cfg.d/dynamic_template.pl>:

	$c->{dynamic_template}->{function} = sub {
		my( $repo, $parts ) = @_;

		$parts->{mypin} = $repo->xml->create_text_node( "Hello, World!" );
	};

In F<archives/[archiveid]/cfg/templates/default.xml> (copy from 
F<lib/templates/default.xml> if not already exists):

	<epc:pin ref="mypin" />

Or, for just the text content of a pin:

	<epc:pin ref="mypin" textonly="yes" />

=head2 Default Pins

=over 4

=item title

The title of the page.

=item page

The page content.

=item login_status_header

HTML C<<head>> includes for the login status of the user - currently 
just some JavaScript variables.

=item head

Page-specific HTML C<<head>> contents.

=item pagetop

(Unused?)

=item login_status

A menu containing L<EPrints::Plugin::Screen>s that appear in C<key_tools>. 
The content from each plugin's C<render_action_link> is rendered as a HTML 
C<<ul>> list.

Historically this was the login/logout links plus C<key_tools> but since 
3.3 login/logout are Screen plugins as well.

=item languages

The C<render_action_link> from L<EPrints::Plugin::Screen::SetLang>.

=back

=head1 METHODS

=cut

package EPrints::Apache::Template;

use EPrints::Apache::AnApache; # exports apache constants

use strict;

######################################################################
=pod

=over 4

=item $rc = EPrints::Apache::Template::handler( $r )

Handler for applying site layout templates.

=cut
######################################################################

sub handler
{
	my( $r ) = @_;

	my $filename = $r->filename;

	return DECLINED unless( $filename =~ s/\.html$// );

	return DECLINED unless( -r $filename.".page" );

	my $repo = EPrints->new->current_repository;

	my $parts;
	foreach my $part ( "title", "title.textonly", "page", "head", "template" )
	{
		if( !-e $filename.".".$part )
		{
			$parts->{"utf-8.".$part} = "";
		}
		elsif( open( CACHE, $filename.".".$part ) ) 
		{
			binmode(CACHE,":utf8");
			$parts->{"utf-8.".$part} = join("",<CACHE>);
			close CACHE;
		}
		else
		{
			$parts->{"utf-8.".$part} = "";
			$repo->log( "Could not read ".$filename.".".$part.": $!" );
		}
	}

	local $repo->{preparing_static_page} = 1;

	$parts->{login_status} = EPrints::ScreenProcessor->new(
		session => $repo,
	)->render_toolbar;
	
	my $template = delete $parts->{"utf-8.template"};
	chomp $template;
	$template = 'default' if $template eq "";

	my $page_id = $r->uri;
	$page_id =~ s![^/]*$!!;
	if ( $page_id ne $r->uri )
	{
		$page_id .= ( $r->uri =~ m!/index\..*$! ) ? "index" : "page";	
	}
	$page_id =~ s!/[0-9]+/?$!/abstract!;
	$page_id =~ s!/$!!;
	$page_id =~ s!/!_!g;
	$page_id = "static$page_id";

	my $page = $repo->prepare_page( 
		$parts,
		page_id=>$page_id,
		template=>$template
	);
	$page->send;

	return OK;
}

1;

######################################################################
=pod

=back

=head1 SEE ALSO

The directories scanned for template sources are in 
L<EPrints::Repository/template_dirs>.

=head1 COPYRIGHT

=begin COPYRIGHT

Copyright 2023 University of Southampton.
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

