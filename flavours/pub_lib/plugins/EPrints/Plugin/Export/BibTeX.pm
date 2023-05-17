=head1 NAME

EPrints::Plugin::Export::BibTeX

=cut

=pod

=head1 FILE FORMAT

See L<EPrints::Plugin::Import::BibTeX>

=cut

package EPrints::Plugin::Export::BibTeX;

use Encode;
use EPrints::Plugin::Export;

@ISA = ( "EPrints::Plugin::Export" );

use strict;

sub new
{
	my( $class, %params ) = @_;

	# Test if TeX::Encode present before allowing advertising export format.
	eval "use TeX::Encode";
	$params{advertise} = 0 if $@;

	my $self = $class->SUPER::new(%params);

	$self->{name} = "BibTeX";
	$self->{accept} = [ 'list/eprint', 'dataobj/eprint' ];
	$self->{visible} = "all";
	$self->{suffix} = ".bib";
	$self->{mimetype} = "text/plain; charset=utf-8";
	unshift @{$self->{produce}}, "application/x-bibtex";

	return $self;
}

######################################################################

=pod

=item $string = make_bibtex_string( $name )

Return a string containing the name described in the hash reference
$name for BibTeX

The keys of the hash are one or more of given, family, honourific and
lineage. The values are utf-8 strings.

The result will be in the most robust format "family, lineage, honourific given";
cf. https://tex.stackexchange.com/questions/557/how-should-i-type-author-names-in-a-bib-file
=cut

######################################################################

sub make_bibtex_string
{
	my( $name ) = @_;

	return "make_bibtex_string expected hash reference" unless ref($name) eq "HASH";

	my $tmp = "";
	my $tail = "";
	if( defined $name->{honourific} && $name->{honourific} ne "" )
	{
		$tmp = $name->{honourific};
		$tmp =~ s/(.+?),/$1\{,\}/g;  # enclose any comma in curly braces
		$tmp =~ s/\band\b/\{and\}/g;  # enclose any single 'and' in curly braces
		$tail = $tmp." ";
	}
	if( defined $name->{given} )
	{
		$tmp = $name->{given};
		$tmp =~ s/(.+?),/$1\{,\}/g;  # enclose any comma in curly braces
		$tmp =~ s/\band\b/\{and\}/g;  # enclose any single 'and' in curly braces
		$tmp =~ s/\.([A-Z])/. $1/g;  # separate sloughed initials
		$tmp =~ s/^[\s]*$/\{\}/g;  # replace empty 'given' token
	}
	else
	{
		$tmp = "{}";  # ensure 'given' token
	}
	$tail .= $tmp;
	
	$tmp = "{}";
	my $lineage = "";
	if( defined $name->{family} )
	{
		$lineage = $tmp = $name->{family};
		$tmp =~ s/(.+?)((,| )\s*[IVX]+\.?)*((,| )\s*[jJsS](un|en)?(io)?r\.?)*((,| )\s*[IVX]+\.?)*$/$1/g;  # remove contained lineage
		$lineage =~ s/\Q${tmp}\E,?\s*(.*)$/$1/g;  # save contained lineage, but pay attention to metacharacters
		$tmp =~ s/(.+?),/$1\{,\}/g;  # enclose any comma in curly braces
		$tmp =~ s/\band\b/\{and\}/g;  # enclose any single 'and' in curly braces
	}
	$tmp =~ s/^[\s]*$/\{\}/g;  # ensure 'last' token
	my $head = $tmp;
	$head .= ", ".$lineage if $lineage ne "";

	if( defined $name->{lineage} && $name->{lineage} ne "" )
	{
		$tmp = $name->{lineage};
		$tmp =~ s/(.+?),/$1\{,\}/g;  # enclose any comma in curly braces
		$tmp =~ s/\band\b/\{and\}/g;  # enclose any single 'and' in curly braces
		$head .= ", " if $lineage eq "";
		$head .= " ".$tmp;
	}
	return $head.", ".$tail;
}

sub convert_dataobj
{
	my( $plugin, $dataobj ) = @_;

	my $data = ();

	# Key
	$data->{key} = $plugin->{session}->get_repository->get_id . $dataobj->get_id;

	# Entry Type
	my $type = $dataobj->get_type;
	$data->{type} = "misc";
	$data->{type} = "article" if $type eq "article";
	$data->{type} = "book" if $type eq "book";
	$data->{type} = "incollection" if $type eq "book_section";
	$data->{type} = "inproceedings" if $type eq "conference_item";
	if( $type eq "monograph" )
	{
		if( $dataobj->exists_and_set( "monograph_type" ) &&
			( $dataobj->get_value( "monograph_type" ) eq "manual" ||
			$dataobj->get_value( "monograph_type" ) eq "documentation" ) )
		{
			$data->{type} = "manual";
		}
		else
		{
			$data->{type} = "techreport";
		}
	}
	if( $type eq "thesis")
	{
		if( $dataobj->exists_and_set( "thesis_type" ) && $dataobj->get_value( "thesis_type" ) eq "masters" )
		{
			$data->{type} = "mastersthesis";
		}
		else
		{
			$data->{type} = "phdthesis";	
		}
	}
	if( $dataobj->exists_and_set( "ispublished" ) )
	{
		my $publication_status_type_override = $plugin->{session}->config( 'export', 'publication_status_type_override' );
		$publication_status_type_override = 1 unless EPrints::Utils::is_set( $publication_status_type_override );
		$data->{type} = "unpublished" if $dataobj->get_value( "ispublished" ) eq "unpub" && ( $data->{type} eq "misc" || $publication_status_type_override );
		$data->{bibtex}->{note} = $plugin->{session}->phrase( "eprint_fieldopt_ispublished_".$dataobj->get_value( "ispublished" ) ) if $dataobj->get_value( "ispublished" ) ne "pub";
	}

	# address
	$data->{bibtex}->{address} = $dataobj->get_value( "place_of_pub" ) if $dataobj->exists_and_set( "place_of_pub" );

	# author
	if( $dataobj->exists_and_set( "creators" ) )
	{
		my $names = $dataobj->get_value( "creators" );	
		$data->{additional}->{author} = join( " and ", map { make_bibtex_string( $_->{name} ) } @$names );
	}
	
	# booktitle
	$data->{bibtex}->{booktitle} = $dataobj->get_value( "event_title" ) if $dataobj->exists_and_set( "event_title" );
	$data->{bibtex}->{booktitle} = $dataobj->get_value( "book_title" ) if $dataobj->exists_and_set( "book_title" );

	# editor
	if( $dataobj->exists_and_set( "editors" ) )
	{
		my $names = $dataobj->get_value( "editors" );	
		$data->{bibtex}->{editor} = join( " and ", map { EPrints::Utils::make_name_string( $_->{name}, 1 ) } @$names );
	}

	# institution
	if( $type eq "monograph" && $data->{type} ne "manual" )
	{
		$data->{bibtex}->{institution} = $dataobj->get_value( "institution" ) if $dataobj->exists_and_set( "institution" );
	}

	# journal
	$data->{bibtex}->{journal} = $dataobj->get_value( "publication" ) if $dataobj->exists_and_set( "publication" );

	# month
	if ($dataobj->exists_and_set( "date" )) {
		if( $dataobj->get_value( "date" ) =~ /^[0-9]{4}-([0-9]{2})/ ) {
			$data->{bibtex}->{month} = EPrints::Time::get_month_label( $plugin->{session}, $1 );
		}
	}

	# note	
        if( $dataobj->exists_and_set( "note" ) )
        {
                if( $data->{bibtex}->{note} )
                {
                        $data->{bibtex}->{note} .= "\n\n".$dataobj->get_value( "note" );
                }
                else
                {
                        $data->{bibtex}->{note} = $dataobj->get_value( "note" );
                }
	}

	# number
	if( $type eq "monograph" )
	{
		$data->{bibtex}->{number} = $dataobj->get_value( "id_number" ) if $dataobj->exists_and_set( "id_number" );
	}
	else
	{
		$data->{bibtex}->{number} = $dataobj->get_value( "number" ) if $dataobj->exists_and_set( "number" );
		$data->{bibtex}->{doi} = $dataobj->get_value( "id_number" ) if $dataobj->exists_and_set( "id_number" ) && $dataobj->get_value( "id_number" ) =~ m/(doi|10\.)/;
	}

	# organization
	if( $data->{type} eq "manual" )
	{
		$data->{bibtex}->{organization} = $dataobj->get_value( "institution" ) if $dataobj->exists_and_set( "institution" );
	}

	# pages
	if( $dataobj->exists_and_set( "pagerange" ) )
	{	
		$data->{bibtex}->{pages} = $dataobj->get_value( "pagerange" );
		$data->{bibtex}->{pages} =~ s/-/--/;
	}

	# publisher
	$data->{bibtex}->{publisher} = $dataobj->get_value( "publisher" ) if $dataobj->exists_and_set( "publisher" );

	# school
	if( $type eq "thesis" )
	{
		$data->{bibtex}->{school} = $dataobj->get_value( "institution" ) if $dataobj->exists_and_set( "institution" );
	}

	# series
	$data->{bibtex}->{series} = $dataobj->get_value( "series" ) if $dataobj->exists_and_set( "series" );

	# title
	$data->{bibtex}->{title} = $dataobj->get_value( "title" ) if $dataobj->exists_and_set( "title" );

	# type
	if( $type eq "monograph" && $dataobj->exists_and_set( "monograph_type" ) )
	{
		$data->{bibtex}->{type} = EPrints::Utils::tree_to_utf8( $dataobj->render_value( "monograph_type" ) );
	}

	# volume
	$data->{bibtex}->{volume} = $dataobj->get_value( "volume" ) if $dataobj->exists_and_set( "volume" );

	# year
	if ($dataobj->exists_and_set( "date" )) {
		$dataobj->get_value( "date" ) =~ /^([0-9]{4})/;
		$data->{bibtex}->{year} = $1 if $1;
	}

	# Not part of BibTeX
	$data->{additional}->{abstract} = $dataobj->get_value( "abstract" ) if $dataobj->exists_and_set( "abstract" );
	$data->{additional}->{url} = $dataobj->get_url; 
	$data->{additional}->{url} = $dataobj->get_value( "official_url" ) if $dataobj->exists_and_set( "official_url" );

	$data->{additional}->{keywords} = $dataobj->get_value( "keywords" ) if $dataobj->exists_and_set( "keywords" );

	$data->{additional}->{issn} = $dataobj->get_value( "issn" ) if $dataobj->exists_and_set( "issn" );
	$data->{additional}->{isbn} = $dataobj->get_value( "isbn" ) if $dataobj->exists_and_set( "isbn" );

	return $data;
}

sub output_dataobj
{
	my( $plugin, $dataobj ) = @_;

	my $data = $plugin->convert_dataobj( $dataobj );

	my @list = ();
	foreach my $k ( keys %{$data->{bibtex}} )
	{
		push @list, sprintf( "%16s = {%s}", $k, encode( 'bibtex', fix_special_chars( $data->{bibtex}->{$k} ) ) );
	}
	foreach my $k ( keys %{$data->{additional}} )
	{
		my $value = $data->{additional}->{$k};
		if( $k eq "url" )
		{
			$value = TeX::Encode::BibTeX->encode_url( $value );
		}
		else
		{
			$value =  encode( 'bibtex', fix_special_chars( $value ) );
		}
		$value =~ s/\\\{\\\}/\{\}/g if( $k eq "author" );  # 'decode' deliberately inserted code
		$value =~ s/\\\{,\\\}/\{,\}/g if( $k eq "author" );
		$value =~ s/\\\{and\\\}/\{and\}/g if( $k eq "author" );

		push @list, sprintf( "%16s = {%s}", $k, $value );
	}

	my $out = '@' . $data->{type} . "{" . $data->{key} . ",\n";
	$out .= join( ",\n", @list ) . "\n";
	$out .= "}\n\n";

	return $out;
}

$EPrints::Plugin::Export::BibTeX::SPECIAL_CHAR_MAPPING = {
		'0x00ae' => '(R)', # registered
		'0x00a1' => '!', # inverted exclaimation mark
		'0x00a2' => 'c', # cent
 		'0x00a5' => 'Y', # Yen
		'0x00aa' => 'a', # feminine ordinal
 		'0x00b0' => 'o', # degree
                '0x00b2' => '2', # squared
                '0x00b3' => '3', # cubed
                '0x00b5' => 'u', # micro
		'0x00b7' => '.', # middle dot
		'0x00b9' => '1', # superscript 1
                '0x00bc' => '1/4', # quarter
                '0x00bd' => '1/2', # half
                '0x00be' => '3/4', # three-quarters
                '0x00bf' => '?', # inverted question mark
		'0x00f7' => '/', # divide
		'0x2010' => '-', # hyphen
                '0x2011' => '-', # non-breaking hyphen
                '0x2012' => '-', # figure dash
                '0x2013' => '-', # en dash
                '0x2014' => '-', # em dash
                '0x2015' => '--', # horizontal bar
		'0x2018' => "'", # left single quote mark
                '0x2019' => "'", # right single quote mark
		'0x201a' => "'", # low single quote mark
		'0x201c' => '"', # left double quote mark
		'0x201d' => '"', # right double quote mark
		'0x201e' => '"', # low double quote mark
		'0x2122' => 'TM', # trademark	
};

sub fix_special_chars 
{
	my( $utext ) = @_;

	$utext = join("", map { 
		my $char = $_;
		$char =~ s/(.)/sprintf '0x%04x', ord $1/seg;
		exists $EPrints::Plugin::Export::BibTeX::SPECIAL_CHAR_MAPPING->{$char} ? 
		$EPrints::Plugin::Export::BibTeX::SPECIAL_CHAR_MAPPING->{$char} : 
		$_;
	} split(//, $utext));
	return $utext;
}

1;

=head1 COPYRIGHT

=for COPYRIGHT BEGIN

Copyright 2023 University of Southampton.
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
