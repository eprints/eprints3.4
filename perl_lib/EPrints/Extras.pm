######################################################################
#
# EPrints::Extras;
#
######################################################################
#
#
######################################################################

=pod

=head1 NAME

B<EPrints::Extras> - Alternate versions of certain methods.

=head1 DESCRIPTION

This module contains methods provided as alternates to the
default render or input methods.

=head1 METHODS

=over 4

=cut

######################################################################

package EPrints::Extras;

use warnings;
use strict;

######################################################################
=pod

=item $xhtml = EPrints::Extras::render_xhtml_field( $session, $field,
$value )

Returns a XHTML DOM object of the contents of C<$value>. In the case of
an error parsing the XML in C<$value> return an XHTML DOM object
describing the problem.

This is intended to be used by the C<render_single_value> option of
L<EPrints::MetaField> as an alternative to the default text renderer.

This allows through any XML element, so could cause problems if
C<E<lt>scriptE<gt>> elements are used to make pop-up windows. A later
version may only allow a limited set of elements.

=cut
######################################################################

sub render_xhtml_field
{
	my( $session , $field , $value ) = @_;

	if( !defined $value ) { return $session->make_doc_fragment; }

	local $SIG{__DIE__};
        my $doc = eval { EPrints::XML::parse_xml_string( "<fragment>".$value."</fragment>" ); };
        if( $@ )
        {
                my $err = $@;
                $err =~ s# at /.*##;
		my $pre = $session->make_element( "pre" );
		$pre->appendChild( $session->make_text( "Error parsing XML in render_xhtml_field: ".$err ) );
		return $pre;
        }
	my $fragment = $session->make_doc_fragment;
	my $top = ($doc->getElementsByTagName( "fragment" ))[0];
	foreach my $node ( $top->getChildNodes )
	{
		$fragment->appendChild(
			$session->clone_for_me( $node, 1 ) );
	}
	EPrints::XML::dispose( $doc );
		
	return $fragment;
}

######################################################################
=pod

=item $xhtml = EPrints::Extras::render_preformatted_field( $session, $field, $value )

Returns a XHTML DOM object of the contents of C<$value>.

The contents of C<$value> will be rendered in a HTML C<E<lt>preE<gt>> element.

=cut
######################################################################

sub render_preformatted_field
{
	my( $session , $field , $value ) = @_;

	my $pre = $session->make_element( "pre" );
	$value =~ s/\r\n/\n/g;
	$pre->appendChild( $session->make_text( $value ) );
		
	return $pre;
}

######################################################################
=pod

=item $xhtml = EPrints::Extras::render_hightlighted_field( $session, $field, $value )

Returns an XHTML DOM object of the contents of C<$value>.

The contents of C<$value> will be rendered in a HTML C<E<lt>preE<gt>> element.

=cut
######################################################################

sub render_highlighted_field
{
	my( $session , $field , $value, $alllangs, $nolink, $object ) = @_;

	my $div = $session->make_element( "div", class=>"ep_highlight" );
	my $v=$field->render_value_actual( $session, $value, $alllangs, $nolink, $object );
	$div->appendChild( $v );	
	return $div;
}


######################################################################
=pod

=item $xhtml = EPrints::Extras::render_lookup_list( $session, $rows )

Returns a XHTML DOM object containing all the HTML C<<li>>
elements provided in array reference C<$rows>.

The elements of C<$rows> will be rendered as HTML C<E<lt>liE<gt>>
(list item) elements inside a HTML C<E<lt>ulE<gt>> (unordered list)
element.

=cut
######################################################################

sub render_lookup_list
{
	my( $session, $rows ) = @_;

	my $ul = $session->make_element( "ul" );

	my $first = 1;
	foreach my $row (@$rows)
	{
		my $li = $session->make_element( "li" );
		$ul->appendChild( $li );
		if( $first )
		{
			$li->setAttribute( "class", "ep_first" );
			$first = 0;
		}
		if( defined($row->{xhtml}) )
		{
			$li->appendChild( $row->{xhtml} );
		}
		elsif( defined($row->{desc}) )
		{
			$li->appendChild( $session->make_text( $row->{desc} ) );
		}
		my @values = @{$row->{values}};
		my $ul = $session->make_element( "ul" );
		$li->appendChild( $ul );
		for(my $i = 0; $i < @values; $i+=2)
		{
			my( $name, $value ) = @values[$i,$i+1];
			my $li = $session->make_element( "li", id => $name );
			$ul->appendChild( $li );
			$li->appendChild( $session->make_text( $value ) );
		}
	}

	return $ul;
}

######################################################################
=pod

=item $xhtml = EPrints::extras::render_paras( $session, $field, $value );

Returns C<$value> in paragraphs rather than one long text string.

The text string C<$value> will be render as XHTML DOM object with HTML
markup to make it into paragraphs.

=cut
######################################################################

sub render_paras
{
    my( $session, $field, $value ) = @_;

    if ( my $render_paras = $session->config( "render_paras" ) )
    {
		my $xhtml = &$render_paras( $session, $field, $value );
		return $xhtml if defined $xhtml;
    }

    my $frag = $session->make_doc_fragment;

    # normalise newlines
    $value =~ s/(\r\n|\n|\r)/\n/gs;

    my @paras = split( /\n\n/, $value );
    foreach my $para( @paras )
    {
        $para =~ s/^\s*\n?//;
        $para =~ s/\n?\s*$//;
        next if $para eq "";

        my $p = $session->make_element( "p", class=>"ep_field_para" );

        my @lines = split( /\n/, $para );
        for( my $i=0; $i<scalar( @lines ); $i++ )
        {
            $p->appendChild( $session->make_text( $lines[$i] ) );
            $p->appendChild( $session->make_element( "br" ) ) unless $i == $#lines;
        }

        $frag->appendChild( $p );
    }

    return $frag;
}


######################################################################
=pod

=item $xhtml = EPrints::Extras::render_url_truncate_end( $session, $field, $value, $target )

Returns a XHTML DOM object containing a hyperlink (C<E<lt>aE<gt>)
that links to C<$target> with the label C<$value>.

Where the string length of C<$value> is E<gt> 50 characters then
the end will be truncated and replaced with an ellipsis.

=cut
######################################################################

sub render_url_truncate_end
{
	my( $session, $field, $value, $target ) = @_;

	my $len = 50;	
	my $link = $session->render_link( $value, $target );
	my $text = $value;
	if( defined( $value ) && length( $value ) > $len )
	{
		$text = substr( $value, 0, $len )."...";
	}
	$link->appendChild( $session->make_text( $text ) );
	return $link
}

######################################################################
=pod

=item $xhtml = EPrints::Extras::render_url_truncate_middle( $session, $field, $value, $target )

Returns a XHTML DOM object containing a hyperlink (C<E<lt>aE<gt>)
that links to C<$target> with the label C<$value>.

Where the string length of C<$value> is E<gt> 50 characters then
the middle will be truncated and replaced with an ellipsis.

=cut
######################################################################

sub render_url_truncate_middle
{
	my( $session, $field, $value, $target ) = @_;

	my $len = 50;	
	my $link = $session->render_link( $value, $target );
	my $text = $value;
	if( defined( $value ) && length( $value ) > $len )
	{
		$text = substr( $value, 0, $len/2 )."...".substr( $value, -$len/2, -1 );
	}
	$link->appendChild( $session->make_text( $text ) );
	return $link
}

######################################################################
=pod

=item $xhtml = EPrints::Extras::render_related_url( $session, $field, $value )

Returns a XHTML DOM object containing all the elements in the array
reference C<$value>, which contains all the URLs that relate to a
particular C<DataObj> (e.g. C<EPrint>).

Where related URLs do not have a C<type> set the C<url> will be used
as a label instead.  Where the is  E<gt> 40 characters will be truncated
and replaced with an ellipsis.

The elements of C<$value> will be rendered as HTML C<E<lt>liE<gt>>
(list item) elements inside a HTML C<E<lt>ulE<gt>> (unordered list)
element.

=cut
######################################################################

sub render_related_url
{
	my( $session, $field, $value ) = @_;

	my $f = $field->get_property( "fields_cache" );
	my $fmap = {};	
	foreach my $field_conf ( @{$f} )
	{
		my $fieldname = $field_conf->{name};
		my $field = $field->{dataset}->get_field( $fieldname );
		$fmap->{$field_conf->{sub_name}} = $field;
	}

	my $ul = $session->make_element( "ul" );
	foreach my $row ( @{$value} )
	{
		my $li = $session->make_element( "li" );
		my $link = $session->render_link( $row->{url} );
		if( EPrints::Utils::is_set( $row->{type} ) )
		{
			$link->appendChild( $fmap->{type}->render_single_value( $session, $row->{type} ) );
		}
		else
		{
			my $text = $row->{url};
			if( length( $text ) > 40 ) { $text = substr( $text, 0, 40 )."..."; }
			$link->appendChild( $session->make_text( $text ) );
		}
		$li->appendChild( $link );
		$ul->appendChild( $li );
	}

	return $ul;
}

######################################################################
=pod

=item $orderkey = EPrints::Extras::english_title_orderkey( $field, $value, $dataset )

Returns C<$value> stripped of leading a/an/the and any non-alpha-numeric
characters from the start of a orderkey value. Suitable for
C<make_single_value_orderkey> on the title field.

=cut
######################################################################

sub english_title_orderkey
{
        my( $field, $value, $dataset ) = @_;

        $value =~ s/^[^a-z0-9]+//gi;
        if( $value =~ s/^(a|an|the) [^a-z0-9]*//i ) { $value .= ", $1"; }

        return $value;
}

######################################################################
=pod

=item $xhtml = EPrints::Extras::render_possible_doi( $field, $value, $dataset )

Returns an XHTML DOM object containing a hyperlink (C<E<lt>aE<gt>>) for
a DOI determined from C<$value>.

Where C<$value> is not determine as a DOI just the text is returned
withn an XHTML DOM object.

The label for the hyperlink is generated by the L<EPrints::DOI>'s
C<to_string> function with the attribute C<noprefix> set to 1.

=cut
######################################################################

sub render_possible_doi
{
	my( $session, $field, $value ) = @_;

	$value = "" unless defined $value;
	my $doi = EPrints::DOI->parse( $value );
	if( !$doi )
	{
		# Doesn't look like a DOI we can turn into a link,
		# so just render it as-is.
		return $session->make_text( $value );
	}
	my $link = $session->render_link( $doi->to_uri, "_blank" );
	$link->appendChild( $session->make_text( $doi->to_string( noprefix=>1 ) ) );
	return $link;
}


######################################################################
=pod

=back

=cut
######################################################################

1;

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

