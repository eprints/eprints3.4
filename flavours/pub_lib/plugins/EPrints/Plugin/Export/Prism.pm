=head1 NAME

EPrints::Plugin::Export::Prism

=cut

package EPrints::Plugin::Export::Prism;

@ISA = ( "EPrints::Plugin::Export::TextFile" );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new( %params );

	$self->{name} = "PRISM";
	$self->{accept} = [ 'list/eprint', 'dataobj/eprint' ];
	$self->{visible} = 0;

	return $self;
}

sub dataobj_to_html_header
{
	my( $plugin, $dataobj ) = @_;

	my $links = $plugin->{session}->make_doc_fragment;

	$links->appendChild( $plugin->{session}->make_element(
		"link",
		rel => "schema.prism",
		href => "https://www.w3.org/submissions/2020/SUBM-prism-20200910/" ) );
	$links->appendChild( $plugin->{session}->make_text( "\n" ));
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

	# Based on 'PRISM Basic Metadata Specification 4.2'
	# (https://www.w3.org/submissions/2020/SUBM-prism-20200910/prism-basic.html#_Toc46322886)

	my $publication_date = $plugin->get_earliest_date( $eprint, 'published', 'published_online' );
	# 4.2.14 prism:coverDate
	push @tags, [ 'prism.coverDate', $publication_date ] if defined $publication_date;
	# 4.2.59 prism:publicationDate
	push @tags, [ 'prism.publicationDate', $publication_date ] if defined $publication_date;
	# 4.2.17 prism:dateReceived
	push @tags, [ 'prism.dateReceived', parse_date( $eprint->get_value( 'datestamp' ) ) ] if $eprint->exists_and_set( 'datestamp' );
	# 4.2.43 prism:modificationDate
	push @tags, [ 'prism.modificationDate', parse_date( $eprint->get_value( 'lastmod' ) ) ] if $eprint->exists_and_set( 'lastmod' );

	# 4.2.54 prism:pageRange
	push @tags, [ 'prism.pageRange', $eprint->get_value( 'pagerange' ) ] if $eprint->exists_and_set( 'pagerange' );
	my( $starting_page, $ending_page ) = EPrints::Plugin::Export::HighwirePress::split_pagerange( $eprint );
	# 4.2.70 prism:startingPage
	push @tags, [ 'prism.startingPage', $starting_page ] if defined $starting_page;
	# 4.2.23 prism:endingPage
	push @tags, [ 'prism.endingPage', $ending_page ] if defined $ending_page;
	# 4.2.52 prism:pageCount
	push @tags, [ 'prism.pageCount', $eprint->get_value( 'pages' ) ] if $eprint->exists_and_set( 'pages' );

	# 4.2.20 prism:doi
	if( $eprint->exists_and_set( 'ids' ) ) {
		for my $id ( @{$eprint->get_value( 'ids' )} ) {
			push @tags, [ 'prism.doi', $id->{id} ] if $id->{id_type} eq 'doi';
		}
	}
	# 4.2.31 prism:isbn
	push @tags, [ 'prism.isbn', $eprint->get_value( 'isbn' ) ] if $eprint->exists_and_set( 'isbn' );
	# 4.2.33 prism:issn
	push @tags, [ 'prism.issn', $eprint->get_value( 'issn' ) ] if $eprint->exists_and_set( 'issn' );

	# 4.2.61 prism:publicationName
	push @tags, [ 'prism.publicationName', $eprint->get_value( 'publication' ) ] if $eprint->exists_and_set( 'publication' );
	# 4.2.88 prism:volume
	push @tags, [ 'prism.volume', $eprint->get_value( 'volume' ) ] if $eprint->exists_and_set( 'volume' );
	# 4.2.45 prism:number
	push @tags, [ 'prism.number', $eprint->get_value( 'number' ) ] if $eprint->exists_and_set( 'number' );

	# 4.2.7 prism:bookEdition
	push @tags, [ 'prism.bookEdition', $eprint->get_value( 'edition' ) ] if $eprint->exists_and_set( 'edition' );	
	# 4.2.68 prism:seriesTitle
	push @tags, [ 'prism.seriesTitle', $eprint->get_value( 'series' ) ] if $eprint->exists_and_set( 'series' );

	# 4.2.24 prism:event
	push @tags, [ 'prism.event', $eprint->get_value( 'event_title' ) ] if $eprint->exists_and_set( 'event_title' );
	# 4.2.39 prism:keyword
	push @tags, [ 'prism.keyword', $eprint->get_value( 'keywords' ) ] if $eprint->exists_and_set( 'keywords' );
	# 4.2.41 prism:link
	push @tags, [ 'prism.link', $eprint->get_value( 'official_url' ) ] if $eprint->exists_and_set( 'official_url' );

	return \@tags;
}

=over 4

=item $parsed_date = $plugin->get_earliest_date( $eprint, [ $date_type, ... ] )

Returns the earliest date with an appropriate C<$date_type> from the given
C<$eprint>.

=cut
sub get_earliest_date
{
	my( $plugin, $eprint, @types ) = @_;

	my $early_date;
	for my $type (@types) {
		if( $eprint->exists_and_set( 'date_type' ) and $eprint->get_value( 'date_type' ) eq $type ) {
			$early_date = parse_date( $eprint->get_value( 'date' ) );
		}
	}
	return $early_date unless $eprint->exists_and_set( 'dates' );

	for my $date (@{$eprint->get_value( 'dates' )}) {
		for my $type (@types) {
			if( defined $date->{date_type} && $date->{date_type} eq $type ) {
				my $parsed_date = parse_date( $date->{date} );
				if( !defined $early_date || $early_date gt $parsed_date ) {
					$early_date = $parsed_date;
				}
			}
		}
	}

	return $early_date;
}

=item $parsed_date = Prism::parse_date( $date )

Takes datetimes in EPrints format (%Y-%m-%d %H:%M:%S) and outputs them as
ISO-8601 datetimestamps.

=cut
sub parse_date
{
	my( $date ) = @_;

	my $parsed_date;
	if( $date =~ m/^(\d+(?:-\d+(?:-\d+)?)?)(?: (\d+:\d+:\d+))/ ) {
		$parsed_date = $1;
		$parsed_date .= "T$2" if defined $2;
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

