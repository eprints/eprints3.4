# rewrite the page for ?edit_phrases=yes
$c->add_trigger( EP_TRIGGER_DYNAMIC_TEMPLATE, sub {
	my %params = @_;

	my $repo = $params{repository};
	my $pins = $params{pins};
	my $xhtml = $repo->xhtml;
	my $user = $repo->current_user;

	return if
		!$repo->get_online ||
		!defined $user ||
		!$user->allow( "config/edit/phrase" ) ||
		!$repo->param( "edit_phrases" ) ||
		$repo->param( "edit_phrases" ) ne "yes";

	my $phrase_screen = $repo->plugin( "Screen::Admin::Phrases",
			phrase_ids => [ sort keys %{$repo->{used_phrases}} ]
		);

	my $url = $repo->current_url( query => 1 );
	# strip "edit_phrases" from the query list
	my @query = $url->query_form;
	foreach my $i (reverse 0..$#query)
	{
		next if $i % 2;
		splice(@query, $i, 2)
			if $query[$i] eq "edit_phrases" && $query[$i+1] eq "yes";
	}
	$url->query_form( @query );

	$pins->{page} = $repo->xml->create_document_fragment;
	my $div = $repo->xml->create_element( "div", style=>"margin-bottom: 1em" );
	$pins->{page}->appendChild( $div );
	$div->appendChild( $repo->html_phrase( "lib/session:phrase_edit_back",
		link => $repo->render_link( $url ),
		page_title => $repo->clone_for_me( $pins->{title}, 1 ) ) );
	$pins->{page}->appendChild( $phrase_screen->render );
	$pins->{title} = $repo->html_phrase( "lib/session:phrase_edit_title",
		page_title => $pins->{title} );

	return;
});

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

