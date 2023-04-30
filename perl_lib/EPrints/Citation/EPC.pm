######################################################################
#
# EPrints::Citation::EPC
#
######################################################################
#
#
######################################################################

=pod

=for Pod2Wiki

=head1 NAME

B<EPrints::Citation::EPC> - Loading and rendering of EPC XML based 
citation styles.

=head1 DESCRIPTION

Loads EPC XML citation style files and renders citations for a 
particular type of data object.

This class inherits from L<EPrints::Citation>.

=head1 METHODS

=cut

package EPrints::Citation::EPC;

use EPrints::Const qw( :namespace );

@ISA = qw( EPrints::Citation );

use strict;

######################################################################
=pod

=over 4

=item $citation->load_source

Load EPC citation source from file.

Returns 1 if citation source was successfully loaded.

=cut
######################################################################

sub load_source
{
	my( $self ) = @_;

	my $repo = $self->{repository};
	my $file = $self->{filename};

	my $doc = $repo->parse_xml( $file, 1 );
	return if !$doc;

	my $citation = ($doc->getElementsByTagName( "citation" ))[0];
	if( !defined $citation )
	{
		$repo->log(  "Missing <citations> tag in $file\n" );
		$repo->xml->dispose( $doc );
		return;
	}
	my $type = $citation->getAttribute( "type" );
	$type = "default" unless EPrints::Utils::is_set( $type );

	my $whitespace = $citation->getAttributeNodeNS( EP_NS_CITATION, "trim-whitespace" );
	my $disable_caching = $citation->getAttributeNodeNS( EP_NS_CITATION, "disable-caching" );

	$self->{type} = $type;
	$self->{style} = $repo->xml->contents_of( $citation );
	$self->{mtime} = EPrints::Utils::mtime( $file );
	$self->{trim_whitespace} = defined $whitespace && lc($whitespace->nodeValue) eq "yes";
        $self->{disable_caching} = defined $disable_caching && lc($disable_caching->nodeValue) eq "yes";

	$repo->xml->dispose( $doc );

	return 1;
}

######################################################################
=pod

=item $frag = $citation->render( $dataobj, %opts )

Used to render a L<EPrints::DataObj> using this citation style.

Returns a XML document fragment of the citation rendering.

=cut
######################################################################

sub render
{
	my( $self, $dataobj, %opts ) = @_;

	my $repo = $self->{repository};

	my $style = $repo->xml->clone( $self->{style} );

	$opts{repository} = $repo;
	$opts{session} = $repo;

	my $collapsed = EPrints::XML::EPC::process( $style,
		%opts,
		item => $dataobj );

	# only apply <linkhere> processing on the outer-most citation
	if( !exists $opts{finalize} || $opts{finalize} != 0 )
	{
		$collapsed = _render_citation_aux( $collapsed, %opts );
	}

	EPrints::XML::trim_whitespace( $collapsed ) if $self->{trim_whitespace};

	return $collapsed;
}

sub _render_citation_aux
{
	my( $node, %params ) = @_;

	my $addkids = $node->hasChildNodes;

	my $rendered;
	if( EPrints::XML::is_dom( $node, "Element" ) )
	{
		my $name = $node->tagName;
		$name =~ s/^ep://;
		$name =~ s/^cite://;

		if( $name eq "iflink" )
		{
			$rendered = $params{repository}->make_doc_fragment;
			$addkids = defined $params{url};
		}
		elsif( $name eq "ifnotlink" )
		{
			$rendered = $params{repository}->make_doc_fragment;
			$addkids = !defined $params{url};
		}
		elsif( $name eq "linkhere" )
		{
			if( defined $params{url} )
			{
				$rendered = $params{repository}->make_element( 
					"a",
					class=>$params{class},
					onclick=>$params{onclick},
					target=>$params{target},
					href=> $params{url} );
			}
			else
			{
				$rendered = $params{repository}->make_doc_fragment;
			}
		}
	}

	if( !defined $rendered )
	{
		$rendered = $params{repository}->clone_for_me( $node );
	}

	if( $addkids )
	{
		foreach my $child ( $node->getChildNodes )
		{
			$rendered->appendChild(
				_render_citation_aux( 
					$child,
					%params ) );			
		}
	}
	return $rendered;
}

1;

######################################################################
=pod

=back

=head1 SEE ALSO

L<EPrints::Citation>

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

