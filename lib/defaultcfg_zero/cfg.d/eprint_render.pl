
$c->{summary_page_metadata} = [qw/
	commentary
	subjects
	sword_depositor
	userid
	datestamp
	lastmod
/];

# IMPORTANT NOTE ABOUT SUMMARY PAGES
#
# While you can completely customise them using the perl subroutine
# below, it's easier to edit them via citation/eprint/summary_page.xml


######################################################################
=pod

=over

=item $xhtmlfragment = eprint_render( $eprint, $repository, $preview )

This subroutine takes an eprint object and renders the XHTML view
of this eprint for public viewing.

Takes two arguments: the L<$eprint|EPrints::DataObj::EPrint> to render
and the current L<$repository|EPrints::Session>.

Returns a list of ( C<$page>, C<$title>[, C<$links>[, C<$template>]] )
where C<$page>, C<$title> and C<$links> are XHTML DOM objects and
C<$template> is a string containing the name of the template to use
for this page.

If $preview is true then this is only being shown as a preview. The C<$template> isn't honoured in this situation.
(This is used to stop the "edit eprint" link appearing when it makes
no sense.)

=back

=cut

######################################################################

$c->{eprint_render} = sub
{
	my( $eprint, $repository, $preview ) = @_;

	my $succeeds_field = $repository->dataset( "eprint" )->field( "succeeds" );
	my $commentary_field = $repository->dataset( "eprint" )->field( "commentary" );

	my $flags = { 
		has_multiple_versions => $eprint->in_thread( $succeeds_field ),
		in_commentary_thread => $eprint->in_thread( $commentary_field ),
		preview => $preview,
	};
	my %fragments = ();

	# Put in a message describing how this document has other versions
	# in the repository if appropriate
	if( $flags->{has_multiple_versions} )
	{
		my $latest = $eprint->last_in_thread( $succeeds_field );
		if( $latest->value( "eprintid" ) == $eprint->value( "eprintid" ) )
		{
			$flags->{latest_version} = 1;
			$fragments{multi_info} = $repository->html_phrase( "page:latest_version" );
		}
		else
		{
			$fragments{multi_info} = $repository->render_message(
				"warning",
				$repository->html_phrase( 
					"page:not_latest_version",
					link => $repository->render_link( $latest->get_url() ) ) );
		}
	}		


	# Now show the version and commentary response threads
	if( $flags->{has_multiple_versions} )
	{
		$fragments{version_tree} = $eprint->render_version_thread( $succeeds_field );
	}
	
	if( $flags->{in_commentary_thread} )
	{
		$fragments{commentary_tree} = $eprint->render_version_thread( $commentary_field );
	}


	foreach my $key ( keys %fragments ) { $fragments{$key} = [ $fragments{$key}, "XHTML" ]; }
	
	my $page = $eprint->render_citation( "summary_page", %fragments, flags=>$flags );

	my $title = $eprint->render_citation("brief");

	my $links = $repository->xml()->create_document_fragment();
	if( !$preview )
	{
		$links->appendChild( $repository->plugin( "Export::Simple" )->dataobj_to_html_header( $eprint ) );
	}

	#to define a specific template to render the abstract with, you can do something like:
	# my $template;
	# if( $eprint->value( "type" ) eq "article" ){
	# 	$template = "article_template";
	# }
	# return ( $page, $title, $links, $template );
	return( $page, $title, $links );
};



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

