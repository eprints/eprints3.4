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
	$links->appendChild( $plugin->{session}->make_comment( " PRISM meta tags " ) );
	$links->appendChild( $plugin->{session}->make_text( "\n" ) );

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
	# 4.2.59 prism:publicationDate
	push @tags, [ 'prism.publicationDate', $publication_date ] if defined $publication_date;
	# 4.2.17 prism:dateReceived
	push @tags, [ 'prism.dateReceived', parse_date( $eprint->get_value( 'datestamp' ) ) ] if $eprint->exists_and_set( 'datestamp' );
	# 4.2.43 prism:modificationDate
	push @tags, [ 'prism.modificationDate', parse_date( $eprint->get_value( 'lastmod' ) ) ] if $eprint->exists_and_set( 'lastmod' );

	# 4.2.54 prism:pageRange
	push @tags, simple_value( $eprint, 'pagerange' => 'pageRange' );
	my( $starting_page, $ending_page ) = EPrints::Plugin::Export::HighwirePress::split_pagerange( $eprint );
	# 4.2.70 prism:startingPage
	push @tags, [ 'prism.startingPage', $starting_page ] if defined $starting_page;
	# 4.2.23 prism:endingPage
	push @tags, [ 'prism.endingPage', $ending_page ] if defined $ending_page;
	# 4.2.52 prism:pageCount
	push @tags, simple_value( $eprint, 'pages' => 'pageCount' );

	# 4.2.20 prism:doi
	if( $eprint->exists_and_set( 'ids' ) ) {
		for my $id ( @{$eprint->get_value( 'ids' )} ) {
			if( defined $id->{id} && defined $id->{id_type} ) {
				push @tags, [ 'prism.doi', $id->{id} ] if $id->{id_type} eq 'doi';
			}
		}
	}
	# 4.2.31 prism:isbn
	push @tags, simple_value( $eprint, 'isbn' );
	# 4.2.33 prism:issn
	push @tags, simple_value( $eprint, 'issn' );

	# 4.2.61 prism:publicationName
	push @tags, simple_value( $eprint, 'publication' => 'publicationName' );
	# 4.2.88 prism:volume
	push @tags, simple_value( $eprint, 'volume' );
	# 4.2.45 prism:number
	push @tags, simple_value( $eprint, 'number' );

	# 4.2.7 prism:bookEdition
	push @tags, simple_value( $eprint, 'edition' => 'bookEdition' );
	# 4.2.68 prism:seriesTitle
	push @tags, simple_value( $eprint, 'series' => 'seriesTitle' );

	# 4.2.24 prism:event
	push @tags, simple_value( $eprint, 'event_title' => 'event' );
	# 4.2.41 prism:link
	push @tags, simple_value( $eprint, 'official_url' => 'link' );

	if( $eprint->exists_and_set( 'keywords' ) ) {
		my $keywords = $eprint->get_value( 'keywords' );
		# There should be zero or more instances of 'prism:keyword' so we split
		# our keywords on newlines, commas and semicolons
		for my $keyword (split /[\n,;]/, $keywords) {
			# Trim leading and trailing spaces
			$keyword =~ s/^\s+|\s+$//g;
			# 4.2.39 prism:keyword
			push @tags, [ 'prism.keyword', $keyword ];
		}
	}
	if( $eprint->exists_and_set( 'subjects' ) ) {
		for my $subject (@{$eprint->get_value( 'subjects' )}) {
			my $subject_obj = EPrints::DataObj::Subject->new( $plugin->{repository}, $subject );
			my $subject_name = $subject_obj->render_description();

			push @tags, [ 'prism.keyword', $subject_name ];
		}
	}

	return \@tags;
}

=over 4

=item [$name, $value] | ([$name, $value], ...) = simple_value( $eprint, $data_name, $tag_name )

Returns the value (or values if it is multiple) associated with the given
C<$eprint> at C<$data_name>. This is designed to then be pushed straight to
C<@tags>, associating 'prism.$tag_name' with the read value(s).

=cut
sub simple_value
{
	my( $eprint, $data_name, $tag_name ) = @_;
	$tag_name = $data_name unless defined $tag_name;

	if( $eprint->exists_and_set( $data_name ) ) {
		my $value = $eprint->get_value( $data_name );
		if( ref( $value ) eq 'ARRAY' ) {
			return map { [ 'prism.'.$tag_name, $_ ] } @{$value};
		} else {
			return [ 'prism.'.$tag_name, $value ];
		}
	} else {
		return ();
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

=item $parsed_date = Prism::parse_date( $date )

Takes datetimes in EPrints format (%Y-%m-%d %H:%M:%S) and outputs them as
ISO-8601 datetimestamps.

=cut
sub parse_date
{
	my( $date ) = @_;

	my $parsed_date;
	if( defined $date && $date =~ m/^(\d+(?:-\d+(?:-\d+)?)?)(?: (\d+:\d+:\d+))?/ ) {
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

