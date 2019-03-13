#!/usr/bin/perl

use Test::More tests => 17;

use strict;
use warnings;

BEGIN { use_ok( "EPrints" ); }
BEGIN { use_ok( "EPrints::Test" ); }

my $repoid = EPrints::Test::get_test_id();

my $ep = EPrints->new();
isa_ok( $ep, "EPrints", "EPrints->new()" );
if( !defined $ep ) { BAIL_OUT( "Could not obtain the EPrints System object" ); }

my $repo = $ep->repository( $repoid );
isa_ok( $repo, "EPrints::Repository", "Get a repository object ($repoid)" );
if( !defined $repo ) { BAIL_OUT( "Could not obtain the Repository object" ); }

my $xml = $repo->xml;

my $XML = <<EOX;
<?xml version='1.0'?>
<root>
<ele attr='foo'>
<child>content</child>
</ele>
</root>
EOX

my $doc = $xml->parse_string( $XML );
ok(defined($doc) && $doc->documentElement->nodeName eq "root", "parse_string");
ok($xml->is($doc->documentElement, "Element"), "is type matches Element");

my $node;

$node = $xml->create_element( "ele", attr => "foo" );
ok(defined($node) && $xml->is( $node, "Element" ) && $node->getAttribute( 'attr' ) eq "foo", "create_element");

$node = $xml->create_text_node( "content" );
ok(defined($node) && $xml->is( $node, "Text" ) && $node->nodeValue eq "content", "create_text_node" );
$node = $xml->create_comment( "content" );
ok(defined($node) && $xml->is( $node, "Comment" ) && $node->nodeValue eq "content", "create_comment" );
$node = $xml->create_document_fragment;
ok(defined($node) && $xml->is( $node, "DocumentFragment" ), "create_document_fragment" );

my $xhtml = $repo->xhtml;

$node = $xhtml->hidden_field( "foo", "bar" );
ok(defined($node) && $node->getAttribute( "name" ) eq "foo" && $node->getAttribute( "value" ) eq "bar" && $node->getAttribute( "type" ) eq "hidden", "xhtml hidden field");
$node = $xml->create_element( "html" );
$node->appendChild( $xml->create_element( "script", type => 'text/javascript' ) );
$node->appendChild( $xml->create_element( "div" ) );
$node->appendChild( $xml->create_element( "br" ) );
my $str = $xml->to_string( $node );
is($str,'<html><script type="text/javascript"/><div/><br/></html>',"to_string");
$str = $xhtml->to_xhtml( $node );
is($str,'<html xmlns="http://www.w3.org/1999/xhtml"><script type="text/javascript">// <!-- No script --></script><div></div><br /></html>',"to_xhtml");

$xml->dispose( $doc );

$node = $xml->create_element( "foo" );
my $clone = $xml->clone( $node );
$node->setAttribute( foo => "bar" );
ok( !$clone->hasAttribute( "foo" ), "same-doc clones are cloned" );

$node->appendChild( $xml->create_element( "bar" ) );
$clone = $xml->clone( $node );
ok( $clone->hasChildNodes, "deep clone clones child nodes" );

$clone = $xml->clone_node( $node );
ok( !$clone->hasChildNodes, "shallow clone doesn't clone children" );

$node = eval { $xhtml->tree([ # dl
		[ "fruit", # dt
			[ "apple", "orange", ], # ul {li, li}
		],
		[ "vegetable", # dt
			[ "potato", "carrot", ], # ul {li, li}
			],
		[ "animal", # dt
			[ # dl
				[ "cat", # dt
					[ "lion", "leopard", ], # ul {li, li}
				],
			],
		],
		"soup", # ul {li}
		$xml->create_element( "p" ), # <p> is appended
	],
	prefix => "mytree",
) };

ok( defined $node && $node->toString =~ /leopard/, "XHTML::tree" );

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

