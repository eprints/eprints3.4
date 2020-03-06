=head1 NAME

EPrints::Plugin::Import::DOI_UNIXREF

=cut

package EPrints::Plugin::Import::DOI_UNIXREF;

# 10.1002/asi.20373

use strict;

use EPrints::Plugin::Import::TextFile;
use URI;

our @ISA = qw/ EPrints::Plugin::Import::TextFile /;

sub new
{
    my( $class, %params ) = @_;

    my $self = $class->SUPER::new( %params );

    $self->{name} = "DOI (via CrossRef - UNIXREF)";
    $self->{visible} = "all";
    $self->{produce} = [ 'dataobj/eprint', 'list/eprint' ];
    $self->{screen} = "Import::DOI_UNIXREF";

    # http://www.crossref.org/openurl - original url, valid up to feb 2017
    # https://doi.crossref.org/openurl - current preferred url, but below code does not support https
    $self->{ base_url } = "http://doi.crossref.org/openurl";

    return $self;
}

sub screen
{
    my( $self, %params ) = @_;

    return $self->{repository}->plugin( "Screen::Import::DOI_UNIXREF", %params );
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
        $plugin->error( 'You need to configure your pid by setting the `pid\' variable in cfg.d/plugins.pl (see http://www.crossref.org/openurl): $c->{plugins}->{"Import::DOI_UNIXREF"}->{params}->{pid} = "ourl_username:password";' );
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
        eval {
            $dom_doc = EPrints::XML::parse_url( $url );
        };

        my $dom_crossref = ($dom_doc->findnodes( "doi_records/doi_record/crossref" ))[0];

        if( $@ || !defined $dom_crossref)
        {
            $plugin->handler->message( "warning", $plugin->html_phrase( "invalid_doi",
                doi => $plugin->{session}->make_text( $doi ),
                msg => $plugin->{session}->make_text( "No or unrecognised response" )
            ));
            next;
        }

        my $dom_item = ($dom_doc->findnodes( "doi_records/doi_record/crossref/*" ))[0];

        if( $dom_item->nodeName eq 'error' )
        {
            $plugin->handler->message( "warning", $plugin->html_phrase( "invalid_doi",
                doi => $plugin->{session}->make_text( $doi ),
                msg => $plugin->{session}->make_text( "error with DOI" )
            ));
            next;
        }
	my $data = { doi => $doi };
	if ( $dom_item->nodeName eq 'conference' )
	{
		$data->{type} = 'conference_item';	
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
	    elsif ( $name eq "pages" || $name eq "posted_date" )
	    {
		$plugin->compound( $data, $node );
	    }
	    elsif ( $name eq "titles" )
            {
                $plugin->title( $data, $node );
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
	    elsif ( $name eq "journal_article" || $name eq "conference_paper" )
            {
                $plugin->item_metadata( $data, $node );
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

    foreach my $contributor ($node->childNodes)
    {
        next unless EPrints::XML::is_dom( $contributor, "Element" );

        my $creator_name = {};
        foreach my $part ($contributor->childNodes)
        {
            if( $part->nodeName eq "given_name" )
            {
                $creator_name->{given} = EPrints::Utils::tree_to_utf8($part);
            }
            elsif( $part->nodeName eq "surname" )
            {
                $creator_name->{family} = EPrints::Utils::tree_to_utf8($part);
            }
        }
        push @creators, { name => $creator_name }
            if exists $creator_name->{family};
    }

    $data->{creators} = \@creators if @creators;
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
        if ( $part->nodeName eq "titles" )
        {
            $plugin->title( $data, $part );	
        }
	elsif ( $part->nodeName eq "contributors" )
	{
	    $plugin->contributors( $data, $part );
	}
	elsif ( $part->nodeName eq "publication_date" || $part->nodeName eq "pages" )
	{
	    $plugin->compound( $data, $part );
	}
	else
	{
	    $data->{$part->nodeName} = EPrints::Utils::tree_to_utf8( $node );
	}
    }
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
            $data->{publisher} = EPrints::Utils::tree_to_utf8( ($part->childNodes)[1] );
        }
	elsif ( $part->nodeName eq "publication_date" )
        {
            $plugin->compound( $data, $part );
        }
    }
}

sub title 
{
    my( $plugin, $data, $node ) = @_;
   
    $data->{article_title} = EPrints::Utils::tree_to_utf8( ($node->childNodes)[1] );
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

    if( defined $data->{year} && $data->{year} =~ /^[0-9]{4}$/ )
    {
	
        $epdata->{date} = $data->{year};
	$epdata->{date} .= "-".$data->{month} if defined $data->{month} && $data->{month} =~ /^[0-9]{1,2}$/;
	$epdata->{date} .= "-".$data->{day} if defined $data->{day} && $data->{day} =~ /^[0-9]{1,2}$/;
    }

    if( defined $data->{"issn.electronic"} )
    {
        $epdata->{issn} = $data->{"issn.electronic"};
    }
    if( defined $data->{"issn.print"} )
    {
        $epdata->{issn} = $data->{"issn.print"};
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
    if( defined $data->{"article_title"} )
    {
        $epdata->{title} = $data->{"article_title"};
    }
    if( defined $data->{"publisher"} )
    {
        $epdata->{publisher} = $data->{"publisher"};
    }
    if( defined $data->{"isbn"} )
    {
        $epdata->{isbn} = $data->{"isbn"};
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
    }
    if( defined $data->{"last_page"} )
        {
                $epdata->{pagerange} = "" unless defined $epdata->{pagerange};
                $epdata->{pagerange} .= "-" . $data->{"last_page"};
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


