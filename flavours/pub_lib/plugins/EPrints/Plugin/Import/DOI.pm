=head1 NAME

EPrints::Plugin::Import::DOI

=cut

package EPrints::Plugin::Import::DOI;

# 10.1002/asi.20373

use strict;

use EPrints::Plugin::Import::TextFile;
use URI;

our @ISA = qw/ EPrints::Plugin::Import::TextFile /;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new( %params );

	$self->{name} = "DOI (via CrossRef)";
	$self->{visible} = "all";
	$self->{produce} = [ 'dataobj/eprint', 'list/eprint' ];
	$self->{screen} = "Import::DOI";

	# http://www.crossref.org/openurl - original url, valid up to feb 2017
	# https://doi.crossref.org/openurl - current preferred url, but below code does not support https
	$self->{ base_url } = "https://doi.crossref.org/openurl";

	return $self;
}

sub screen
{
	my( $self, %params ) = @_;

	return $self->{repository}->plugin( "Screen::Import::DOI", %params );
}

sub input_text_fh
{
	my( $plugin, %opts ) = @_;

	my @ids;

	my $pid = $plugin->param( "pid" );
	my $session = $plugin->{repository};
	my $use_prefix = $plugin->param( "use_prefix" ) || 1;
	my $doi_field = $plugin->param( "doi_field" ) || 'id_number';

	unless( $pid )
	{
		$plugin->error( 'You need to configure your pid by setting the `pid\' variable in cfg.d/plugins.pl (see http://www.crossref.org/openurl): $c->{plugins}->{"Import::DOI"}->{params}->{pid} = "ourl_username:password";' );
		return undef;
	}

	my $fh = $opts{fh};
	while( my $doi = <$fh> )
	{
		$doi =~ s/^\s+//;
		$doi =~ s/\s+$//;

		next unless length($doi);
		my $obj = EPrints::DOI->parse( $doi );
		if( $obj )
		{
			$doi = $obj->to_string( noprefix => !$use_prefix );
		}

		#some doi's in the repository may have the "doi:" prefix and others may not, so we need to check both cases - rwf1v07:27/01/2016
		my $doi2 = $doi;
		$doi =~ s/^(doi:)?//i;
		$doi2 =~ s/^(doi:)?/doi:/i;

		# START check and exclude DOI from fetch if DOI already exists in the 'archive' dataset - Alan Stiles, Open University, 20140408
		my $duplicates = $session->dataset( 'archive' )->search(
						filters =>
						[
							{ meta_fields => [$doi_field], value => "$doi $doi2", match => "EQ", merge => "ANY" }, #check for both "doi:" prefixed values and ones which aren't prefixed - rwf1v07:27/01/2016
						]
		);
		if ( $duplicates->count() > 0 )
		{
			$plugin->handler->message( "warning", $plugin->html_phrase( "duplicate_doi",
				doi => $plugin->{session}->make_text( $doi ),
				msg => $duplicates->item( 0 )->render_citation_link(),
			));
			next;
		}
		# END check and exclude DOI from fetch if DOI already exists in the 'archive' dataset - Alan Stiles, Open University, 20140408
	
		my %params = (
			pid => $pid,
			noredirect => "true",
			id => $doi,
		format => "unixref",
		);

		my $url = URI->new( $plugin->{ base_url } );
		$url->query_form( %params );

		my $dom_doc;
		my $dom_crossref;
		eval {
			$dom_doc = EPrints::XML::parse_url( $url );
			$dom_crossref = ($dom_doc->findnodes( "doi_records/doi_record/crossref" ))[0];
		};

		if( $@ || !defined $dom_crossref)
		{
			$plugin->handler->message( "warning", $plugin->html_phrase( "invalid_doi",
				doi => $plugin->{session}->make_text( $doi ),
				status => $plugin->{session}->make_text( "No or unrecognised response" )
			));
			next;
		}

		my $dom_item = ($dom_doc->findnodes( "doi_records/doi_record/crossref/*" ))[0];

		if( $dom_item->nodeName eq 'error' )
		{
			$plugin->handler->message( "warning", $plugin->html_phrase( "invalid_doi",
				doi => $plugin->{session}->make_text( $doi ),
				status => $plugin->{session}->make_text( "error with DOI" )
			));
			next;
		}
	my $data = { doi => $doi };
	if ( $dom_item->nodeName eq 'conference' )
	{
		$data->{type} = 'conference_item';	
	}
	elsif ( $dom_item->nodeName eq 'book' )
	{
		$data->{type} = 'book';
	}
	else
	{
		$data->{type} = 'article';
	}

		foreach my $node ( $dom_item->getChildNodes )
		{
			next if( !EPrints::XML::is_dom( $node, "Element" ) );
		
			my $name = $node->nodeName;

			if( $name eq "contributors" )
			{
				$plugin->contributors( $data, $node );
			}
			elsif ( $name eq "pages" || $name eq "posted_date" || $name eq "titles" )
			{
				$plugin->compound( $data, $node );
				if ( $name eq "posted_date" )
				{
					$data->{date_type} = "submitted";
				}
			}
			elsif ( $name eq "journal_metadata" )
			{
				$plugin->journal_metadata( $data, $node );
			}
			elsif ( $name eq "journal_issue" )
			{
				$plugin->journal_issue( $data, $node );
			}
			elsif ( $name eq "event_metadata" )
			{
				$plugin->event_metadata( $data, $node );
			}
			elsif ( $name eq "proceedings_metadata" )
			{
				$plugin->proceedings_metadata( $data, $node );
			}
			elsif ( $name eq "journal_article" || $name eq "conference_paper" || $name eq "book_metadata" )
			{
				$data->{type} = "book_section" if $name eq "content_item" && $data->{type} eq "book";
				$plugin->item_metadata( $data, $node );
			}
			elsif ( $name eq "content_item" )
			{
				$plugin->content_item( $data, $node );
			}
			else
			{
				$data->{$name} = EPrints::Utils::tree_to_utf8( $node );
			}
		}

		EPrints::XML::dispose( $dom_doc );

		my $epdata = $plugin->convert_input( $data );
		next unless( defined $epdata );

		my $dataobj = $plugin->epdata_to_dataobj( $opts{dataset}, $epdata );
		if( defined $dataobj )
		{
			push @ids, $dataobj->get_id;
		}
	}

	return EPrints::List->new( 
		dataset => $opts{dataset}, 
		session => $plugin->{session},
		ids=>\@ids );
}

sub contributors
{
	my( $plugin, $data, $node ) = @_;

	my @creators;
	my @corp_creators;
	my @editors;
	my @contributors;

	foreach my $contributor ($node->childNodes)
	{
		next unless EPrints::XML::is_dom( $contributor, "Element" );

		my $role = "author";
		my $attrs = $contributor->attributes;
		foreach my $attr ($contributor->attributes)
		{
			if( $attr->nodeName eq "contributor_role" )
			{
				$role = $attr->nodeValue;
				last;
			}
		}

		my $person_name = {};
		my $orcid = undef;
		foreach my $part ($contributor->childNodes)
		{
			if( $part->nodeName eq "given_name" )
			{
				$person_name->{given} = EPrints::Utils::tree_to_utf8($part);
			}
			elsif( $part->nodeName eq "surname" )
			{
				$person_name->{family} = EPrints::Utils::tree_to_utf8($part);
			}
			elsif( $part->nodeName eq "ORCID" )
			{
				$orcid = EPrints::Utils::tree_to_utf8($part);
				$orcid =~ s!https?://orcid.org/!!;
			}
		}

		if ( exists $person_name->{family} )
		{
			if ( $role eq "author" )
			{
				push @creators, { name => $person_name, orcid => $orcid };
			}
			elsif ( $role eq "editor" )
			{
				push @editors, { name => $person_name, orcid => $orcid };
			}
			else
			{
				my %contributor_types = (
					"author" => "http://www.loc.gov/loc.terms/relators/AUT",
					"editor" => "http://www.loc.gov/loc.terms/relators/EDT",
					"chair" => "http://www.loc.gov/loc.terms/relators/EDT",
					"reviewer" => "http://www.loc.gov/loc.terms/relators/REV",
					"reviewer-assistant" => "http://www.loc.gov/loc.terms/relators/REV",
					"stats-reviewer" => "http://www.loc.gov/loc.terms/relators/REV",
					"reviewer-external" => "http://www.loc.gov/loc.terms/relators/REV",
					"reader" => "http://www.loc.gov/loc.terms/relators/OTH",
					"translator" => "http://www.loc.gov/loc.terms/relators/TRL",
				);
				push @contributors, { name => $person_name, type => $contributor_types{$role} , orcid => $orcid };
			}
		}
		elsif ( $contributor->nodeName eq "organization" && $role eq "author" )
		{
			push @corp_creators, EPrints::Utils::tree_to_utf8($contributor) if $contributor->nodeName eq "organization" && $role eq "author";
 		}
	}

	$data->{creators} = \@creators if @creators;
	$data->{corp_creators} = \@corp_creators if @corp_creators;
	$data->{editors} = \@editors if @editors;
	$data->{contributors} = \@contributors if @contributors;
}

sub compound
{
	my( $plugin, $data, $node) = @_;

	foreach my $part ($node->childNodes)
	{
	next unless EPrints::XML::is_dom( $part, "Element" );
		$data->{$part->nodeName} = EPrints::Utils::tree_to_utf8($part);	
	}		
}

sub item_metadata
{
	my( $plugin, $data, $node ) = @_;

	foreach my $part ($node->childNodes) 
	{
		if ( $part->nodeName eq "contributors" )
		{
			$plugin->contributors( $data, $part );
		}
		elsif ( $part->nodeName eq "publication_date" )
		{
			$plugin->publication_date( $data, $part );
		}	
		elsif ( $part->nodeName eq "pages" || $part->nodeName eq "publisher" || $part->nodeName eq "titles" )
		{
			$plugin->compound( $data, $part );
		}
		elsif ( ref ( $part ) ne "XML::LibXML::Text" )
		{
			if ( $part->getAttribute( "media_type" ) )
			{
				$data->{$part->nodeName.".". $part->getAttribute( "media_type" )} = EPrints::Utils::tree_to_utf8( $part );
			}
			else 
			{
				$data->{$part->nodeName} = EPrints::Utils::tree_to_utf8( $part );
			}
		}
	}
}

sub content_item
{
	my( $plugin, $data, $node ) = @_;
	if ( $data->{type} eq "book" )
	{
		$data->{type} = "book_section";
		$data->{volume_title} = $data->{title};
	}
	$plugin->item_metadata( $data, $node );	
}


sub journal_issue 
{
	my( $plugin, $data, $node ) = @_;

	foreach my $part ($node->childNodes)
	{
		if ( $part->nodeName eq "journal_volume" )
		{
			$data->{volume} = EPrints::Utils::tree_to_utf8( ($part->childNodes)[1] );
		}
	elsif ( $part->nodeName eq "issue" )
		{
			$data->{issue} = EPrints::Utils::tree_to_utf8( $part );
		}
	}
}

sub journal_metadata
{
	my( $plugin, $data, $node ) = @_;

	foreach my $part ($node->childNodes)
	{
		if ( $part->nodeName eq "full_title" )
		{
			$data->{journal_title} = EPrints::Utils::tree_to_utf8( $part );
		}
		elsif ( $part->nodeName eq "issn" )
		{
		if ( $part->getAttribute( "media_type" ) eq "print"  || ! defined $part->getAttribute( "media_type" ) )
		{
			$data->{"issn.print"} = EPrints::Utils::tree_to_utf8( $part );
		}
		elsif ( $part->getAttribute( "media_type" ) eq "electronic" && !defined $data->{issn} )
		{
				$data->{"issn.electronic"} = EPrints::Utils::tree_to_utf8( $part );
			}
		}
	}
}

sub event_metadata
{
	my( $plugin, $data, $node ) = @_;

	foreach my $part ($node->childNodes)
	{
		if ( $part->nodeName eq "conference_name" )
		{
			$data->{event_title} = EPrints::Utils::tree_to_utf8( $part );
			$data->{event_type} = "conference";
		}
		elsif ( $part->nodeName eq "conference_location" )
		{
			$data->{event_location} = EPrints::Utils::tree_to_utf8( $part );
		}
	elsif ( $part->nodeName eq "conference_date" )
		{
			$data->{event_dates} = EPrints::Utils::tree_to_utf8( $part );
		}
	}
}

sub proceedings_metadata
{
	my( $plugin, $data, $node ) = @_;

	foreach my $part ($node->childNodes)
	{
		if ( $part->nodeName eq "proceedings_title" || $part->nodeName eq "isbn" )
		{
			$data->{$part->nodeName} = EPrints::Utils::tree_to_utf8( $part );
		}
		elsif ( $part->nodeName eq "publisher" )
		{
			$plugin->compound( $data, $part );
		}
	elsif ( $part->nodeName eq "publication_date" )
		{
			$plugin->publication_date( $data, $part );		
		}
	}
}

sub publication_date
{
	my( $plugin, $data, $node ) = @_;

	unless ( defined $data->{date_type} && $data->{date_type} eq "published" )
	{
		$plugin->compound( $data, $node );
		$data->{date_type} = 'published' if $node->getAttribute( "media_type" ) eq "print";
		$data->{date_type} = 'published_online' if $node->getAttribute( "media_type" ) eq "electronic";
	}
}

sub title 
{
	my( $plugin, $data, $node ) = @_;
   
	$data->{title} = EPrints::Utils::tree_to_utf8( ($node->childNodes)[1] );
}

sub convert_input
{
	my( $plugin, $data ) = @_;

	my $epdata = {};
	my $use_prefix = $plugin->param( "use_prefix" ) || 1;
	my $doi_field = $plugin->param( "doi_field" ) || "id_number";

	if( defined $data->{creators} )
	{
		$epdata->{creators} = $data->{creators};
	}
	elsif( defined $data->{author} )
	{
		$epdata->{creators} = [ 
			{ 
				name=>{ family=>$data->{author} }, 
			} 
		];
	}

	if( defined $data->{corp_creators} )
	{
		$epdata->{corp_creators} = $data->{corp_creators};
	}
	if( defined $data->{editors} )
	{
		$epdata->{editors} = $data->{editors};
	}
	if( defined $data->{contributors} )
	{
		$epdata->{contributors} = $data->{contributors};
	}

	if( defined $data->{year} && $data->{year} =~ /^[0-9]{4}$/ )
	{	
		$epdata->{date} = $data->{year};
		$epdata->{date} .= "-".$data->{month} if defined $data->{month} && $data->{month} =~ /^[0-9]{1,2}$/;
		$epdata->{date} .= "-".$data->{day} if defined $data->{day} && $data->{day} =~ /^[0-9]{1,2}$/;
		$epdata->{date_type} = $data->{date_type} if defined $data->{date_type};
		$epdata->{date_type} = "published" if $epdata->{date_type} eq "published_online";
		$epdata->{ispublished} = "pub" if defined $epdata->{date_type} && $epdata->{date_type} eq "published";
		$epdata->{ispublished} = "submitted" if defined $epdata->{date_type} && $epdata->{date_type} eq "submitted";
	}

	if( defined $data->{"issn.electronic"} )
	{
		$epdata->{issn} = $data->{"issn.electronic"};
	}
	if( defined $data->{"issn.print"} )
	{
		$epdata->{issn} = $data->{"issn.print"};
	}
	if( defined $data->{"isbn.electronic"} )
	{
		$epdata->{isbn} = $data->{"isbn.electronic"};
	}
	if( defined $data->{"isbn"} )
	{
		$epdata->{isbn} = $data->{"isbn"};
	}
	if( defined $data->{"issn.print"} )
	{
		$epdata->{isbn} = $data->{"isbn.print"};
	}

	if( defined $data->{"doi"} )
	{
		#Use doi field identified from config parameter, in case it has been customised. Alan Stiles, Open University 20140408
		my $doi = EPrints::DOI->parse( $data->{"doi"} );
	if( $doi )
	{
		$epdata->{$doi_field} = $doi->to_string( noprefix=>!$use_prefix );
		$epdata->{official_url} = $doi->to_uri->as_string;
	}
	else
	{
		$epdata->{$doi_field} = $data->{"doi"};
	}
	}
	if ( defined $epdata->{official_url} && defined $data->{resource} && $epdata->{official_url} ne $data->{resource} )
	{
		$epdata->{official_url} = $data->{resource};
	}
	if( defined $data->{"volume_title"} )
	{
		$epdata->{book_title} = $data->{"volume_title"};
	}
	if( defined $data->{"journal_title"} )
	{
		$epdata->{publication} = $data->{"journal_title"};
	}
	if( defined $data->{"proceedings_title"} )
	{
		$epdata->{publication} = $data->{"proceedings_title"};
	}
	if( defined $data->{"title"} )
	{
		$epdata->{title} = $data->{"title"};
	}
	if( defined $data->{"subtitle"} )
	{
		$epdata->{title} .= ": " . $data->{"subtitle"};
	}
	if( defined $data->{"publisher_name"} )
	{
		$epdata->{publisher} = $data->{"publisher_name"};
	}
	if( defined $data->{"publisher_place"} )
	{
		$epdata->{place_of_pub} = $data->{"publisher_place"};
	}
	if( defined $data->{"volume"} )
	{
		$epdata->{volume} = $data->{"volume"};
	}
	if( defined $data->{"issue"} )
	{
		$epdata->{number} = $data->{"issue"};
	}

	if( defined $data->{"first_page"} )
	{
		$epdata->{pagerange} = $data->{"first_page"};
		$epdata->{pages} = 1;
	}
	if( defined $data->{"last_page"} )
	{
		$epdata->{pagerange} = "" unless defined $epdata->{pagerange};
		$epdata->{pagerange} .= "-" . $data->{"last_page"};
		$epdata->{pages} = $data->{"last_page"} - $data->{"first_page"} + 1 if defined $data->{"first_page"};
	}

	if( defined $data->{"abstract"} )
	{
		$epdata->{abstract} = $data->{"abstract"};
	}
 
	if( defined $data->{"event_title"} )
	{
		$epdata->{event_title} = $data->{"event_title"};
	}
	if( defined $data->{"event_type"} )
	{
		$epdata->{event_type} = $data->{"event_type"};
	}
	if( defined $data->{"event_location"} )
	{
		$epdata->{event_location} = $data->{"event_location"};
	}
	if( defined $data->{"event_dates"} )
	{
		$epdata->{event_dates} = $data->{"event_dates"};
	}

	if( defined $data->{"type"} )
	{
		$epdata->{type} = $data->{"type"};
	}

	return $epdata;
}

sub url_encode
{
	my ($str) = @_;
	$str =~ s/([^A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg;
	return $str;
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


