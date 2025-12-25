=head1 NAME

EPrints::Plugin::Export::HighwirePress

=cut

package EPrints::Plugin::Export::HighwirePress;

@ISA = ( "EPrints::Plugin::Export::TextFile" );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new( %params );

	$self->{name} = "Highwire Press";
	$self->{accept} = [ 'list/eprint', 'dataobj/eprint' ];
	$self->{visible} = 0;

	return $self;
}

sub dataobj_to_html_header
{
	my( $plugin, $dataobj ) = @_;

	my $links = $plugin->{session}->make_doc_fragment;
	$links->appendChild( $plugin->{session}->make_comment( " Highwire Press meta tags " ) );
	$links->appendChild( $plugin->{session}->make_text( "\n" ) );

	my $tags = $plugin->convert_dataobj( $dataobj, "no_cache" => 1 );
	for my $tag (@{$tags})
	{
		$links->appendChild( $plugin->{session}->make_element(
			"meta",
			name => $tag->[0],
			content => $tag->[1]
		) );
		$links->appendChild( $plugin->{session}->make_text( "\n" ));
	}
	return $links;
}

sub output_dataobj
{
	my( $plugin, $dataobj ) = @_;

	my $data = $plugin->convert_dataobj( $dataobj );

	my $r = "";
	foreach( @{$data} )
	{
		next unless defined( $_->[1] );
		my $v = $_->[1];
		$v=~s/[\r\n]/ /g;
		$r.=$_->[0].": $v\n";
	}
	$r.="\n";
	return $r;
}

sub convert_dataobj
{
	my( $plugin, $eprint, %params ) = @_;

	my $dataset = $eprint->{dataset};

	my @tags = ();

	# Based on https://scholar.google.co.uk/intl/en/scholar/inclusion.html#indexing
	# as of 2025-08-05 (https://web.archive.org/web/20250606022732/https://scholar.google.co.uk/intl/en/scholar/inclusion.html#indexing)

	# A. The title tag 'citation_title' containing the title of the paper
	push @tags, simple_value( $eprint, 'title' );

	# B. Separate 'citation_author' tags for each paper author
	if( $eprint->exists_and_set( 'creators_name' ) ) {
		for my $creator (@{$eprint->get_value( 'creators_name' )}) {
			push @tags, [ 'citation_author', EPrints::Utils::make_name_string( $creator ) ] if defined $creator;
		}
	}

	# C. The publication date tag 'citation_publication_date' containing the date of publication
	#
	# This is not the date it was entered into the repo, which is instead stored in 'citation_online_date'
	my $publication_date = $plugin->get_earliest_date( $eprint, 'published', 'published_online' );
	push @tags, [ 'citation_publication_date', $publication_date ] if defined $publication_date;
	my $online_date = parse_date( $eprint->get_value( 'datestamp' ) ) if $eprint->exists_and_set( 'datestamp' );
	push @tags, [ 'citation_online_date', $online_date ] if defined $online_date;

	# D. For journal and conference papers provide the remaining data in
	#    'citation_journal_title', 'citation_conference_title', 'citation_issn', 'citation_isbn',
	#    'citation_volume', 'citation_issue', 'citation_firstpage' and 'citation_lastpage'
	push @tags, simple_value( $eprint, 'publication' => 'journal_title' );
	push @tags, simple_value( $eprint, 'event_title' => 'conference_title' );
	push @tags, simple_value( $eprint, 'issn' );
	push @tags, simple_value( $eprint, 'isbn' );
	push @tags, simple_value( $eprint, 'volume' );
	push @tags, simple_value( $eprint, 'number' => 'issue' );
	my( $firstpage, $lastpage ) = split_pagerange( $eprint );
	push @tags, [ 'citation_firstpage', $firstpage ] if defined $firstpage;
	push @tags, [ 'citation_lastpage', $lastpage ] if defined $lastpage;

	# E. For theses, dissertations and technical reports provide the remaining
	#    data in 'citation_dissertation_institution', 'citation_technical_report_institution' and
	#    'citation_technical_report_number'
	if( $eprint->get_value( 'type' ) eq 'thesis' ) {
		push @tags, simple_value( $eprint, 'institution' => 'dissertation_institution' );
	} else { # 'monograph'
		push @tags, simple_value( $eprint, 'institution' => 'technical_report_institution' );
		# TODO: Do we have anything for 'citation_technical_report_number'
	}

	# H. If you have the full text in a separate file please specify the locations
	#    of all full text versions using 'citation_pdf_url'
	for my $document ( $eprint->get_all_documents() ) {
		push @tags, [ 'citation_pdf_url', $document->get_url() ];
	}

	# Suggested by https://www.zotero.org/support/dev/exposing_metadata
	# Google Scholar does not recommend using these if already using citation_publication_date and/or citation_online_date
	#push @tags, [ 'citation_date', $publication_date || $online_date ] if defined $publication_date || $online_date;
	#push @tags, [ 'citation_cover_date', $publication_date ] if defined $publication_date;
	push @tags, simple_value( $eprint, 'book_title' );
	push @tags, simple_value( $eprint, 'series' => 'series_title' );
	push @tags, simple_value( $eprint, 'publisher' );
	if( $eprint->exists_and_set( 'ids' ) ) {
		for my $id ( @{$eprint->get_value( 'ids' )} ) {
			if( defined $id->{id} && defined $id->{id_type} ) {
				push @tags, [ 'citation_doi', $id->{id} ] if $id->{id_type} eq 'doi';
				push @tags, [ 'citation_pmid', $id->{id} ] if $id->{id_type} eq 'pmid';
			}
		}
	}
	push @tags, simple_value( $eprint, 'abstract' );
	my @documents = $eprint->get_all_documents();
	if( scalar @documents && $documents[0]->exists_and_set( 'language' ) ) {
		push @tags, [ 'citation_language', $documents[0]->get_value( 'language' ) ];
	}
	if( $eprint->exists_and_set( 'editors_name' ) ) {
		for my $editor (@{$eprint->get_value( 'editors_name' )}) {
			push @tags, [ 'citation_editor', EPrints::Utils::make_name_string( $editor ) ] if defined $editor;
		}
	}

	my $keywords = '';
	if( $eprint->exists_and_set( 'keywords' ) ) {
		# Keywords should be separated by semicolons according to Zotero so
		# this converts newlines and commas into semicolons (with consistent
		# spacing)
		for my $keyword (split /[\n,;]/, $eprint->get_value( 'keywords' )) {
			# Trim leading and trailing spaces
			$keyword =~ s/^\s+|\s+$//g;
			$keywords .= '; ' if $keywords ne '';
			$keywords .= $keyword;
		}
	}
	if( $eprint->exists_and_set( 'subjects' ) ) {
		for my $subject (@{$eprint->get_value( 'subjects' )}) {
			my $subject_obj = EPrints::DataObj::Subject->new( $plugin->{repository}, $subject );
			my $subject_name = $subject_obj->render_description();

			$keywords .= '; ' if $keywords ne '';
			$keywords .= $subject_name;
		}
	}
	push @tags, [ 'citation_keywords', $keywords ] if $keywords ne '';

	push @tags, simple_value( $eprint, 'article_number' => 'journal_article' );

	return \@tags;
}

=over 4

=item [$name, $value] | ([$name, $value], ...) = simple_value( $eprint, $data_name, $tag_name )

Returns the value (or values if it is multiple) associated with the given
C<$eprint> at C<$data_name>. This is designed to then be pushed straight to
C<@tags>, associating 'citation_$tag_name' with the read value(s).

=cut
sub simple_value
{
	my( $eprint, $data_name, $tag_name ) = @_;
	$tag_name = $data_name unless defined $tag_name;

	if( $eprint->exists_and_set( $data_name ) ) {
		my $value = $eprint->get_value( $data_name );
		if( ref( $value ) eq 'ARRAY' ) {
			return map { [ 'citation_'.$tag_name, $_ ] } @{$value};
		} else {
			return [ 'citation_'.$tag_name, $value ];
		}
	} else {
		return ();
	}
}

=item ( $from, $to ) = HighwirePress::split_pagerange( $eprint )

Splits the pagerange from the given C<$eprint> into its first page and last
page as done by C<EPrints::MetaField::Pagerange::render_single_value>. If
either of these values cannot be gleaned from this eprint they will return
C<undef>.

=cut
sub split_pagerange
{
	my( $eprint ) = @_;

	return( undef, undef ) unless $eprint->exists_and_set( 'pagerange' );
	my $range = $eprint->get_value( 'pagerange' );

	# Based on `EPrints::MetaField::Pagerange::render_single_value`
	if( $range =~ /^([1-9]\d*)$/ ) {
		return( $1, undef );
	} elsif( my( $from, $to ) = $range =~ m/^([^-]+)-(.+)$/ ) {
		# If there are multiple '-' we assume that the one which defines the
		# range is in the middle of the string and split on that one.
		my $count = $range =~ tr/-//;
		if( $count > 1 ) {
			my $middle = int( ($count - 1) / 2 );
			# Capture `$middle` instances of '<text>-' followed by '<text>' as
			# the first group, with everything after the following hyphen in
			# the second group.
			( $from, $to ) = $range =~ m/^((?:[^-]+-){$middle}[^-]+)-(.+)$/;
		}

		return( $from, $to );
	} else {
		return( undef, undef );
	}
}

=item $parsed_date = $plugin->get_earliest_date( $eprint, [ $date_type, ... ] )

Returns the earliest date with an appropriate C<$date_type> from the given
C<$eprint>.

=cut
sub get_earliest_date
{
	my( $plugin, $eprint, @types ) = @_;

	my $early_date;
	for my $type (@types) {
		if( $eprint->exists_and_set( 'date' ) && $eprint->exists_and_set( 'date_type' ) && $eprint->get_value( 'date_type' ) eq $type ) {
			$early_date = parse_date( $eprint->get_value( 'date' ) );
		}
	}
	# Assume that if there is no date_type field then date is a publication date.
	if( $eprint->exists_and_set( 'date' ) && ( ! $eprint->{dataset}->has_field( 'date_type' ) || ! $eprint->get_value( 'date_type' ) ) )
	{
		$early_date = parse_date( $eprint->get_value( 'date' ) );
	}
	return $early_date unless $eprint->exists_and_set( 'dates' );

	for my $date (@{$eprint->get_value( 'dates' )}) {
		for my $type (@types) {
			if( defined $date->{date_type} && $date->{date_type} eq $type ) {
				my $parsed_date = parse_date( $date->{date} );
				if( defined $parsed_date && ( !defined $early_date || $early_date gt $parsed_date ) ) {
					$early_date = $parsed_date;
				}
			}
		}
	}

	return $early_date;
}

=item $parsed_date = HighwirePress::parse_date( $date )

Takes datetimes in EPrints format (%Y-%m-%d %H:%M:%S) and outputs them as
Google Scholar expects (%Y/%m/%d).

=cut
sub parse_date
{
	my( $date ) = @_;

	my $parsed_date;
	if( defined $date && $date =~ m/^(\d+)(?:-(\d+)(?:-(\d+))?)?/ ) {
		$parsed_date = $1;
		$parsed_date .= "/$2" if defined $2;
		$parsed_date .= "/$3" if defined $3;
	}
	return $parsed_date;
}


1;

=back

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

