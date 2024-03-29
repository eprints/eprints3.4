=head1 NAME

LibXMLDoc

=cut

#!/usr/bin/perl

use strict;
use warnings;

use lib "../perl_lib";
use lib "perl_lib";

use XML::DOM;
use XML::LibXML;
use XML::GDOME;

{
package LibXMLDoc;

use vars qw( @ISA );
@ISA = qw( XML::LibXML::Document );

sub appendChild
{
	shift->SUPER::setDocumentElement(@_);
}

1;
}

my( $doc, $root, $attrs );

our $TI = 1;

# DOM
print "\n--XML::DOM--\n\n";

$doc = XML::DOM::Document->new;
$doc->appendChild($root = $doc->createElement('foo'));
print $doc->toString;
print $doc->getDocumentElement->toString, "\n";
print $doc->cloneNode(1)->toString, "\n";
print(($doc->getElementsByTagName( "foo" ))[0]->toString, "\n");
$root->appendChild( $doc->createTextNode( "bar" ));
#test(sub {$root->nodeName . "/" . $root->tagName . "\n"});
#test(sub {$root->getFirstChild->nodeName . "\n"});
$root->setAttribute( 'foo', 'bar' );
$root->appendChild( $doc->createTextNode( undef ));
test( sub { $root->toString . "\n" });
#$attrs = $root->attributes;
#for(my $i = 0; $i < $attrs->length; $i++)
#{
#	my $attr = $attrs->item($i);
#	$attr->setValue( 'barbar' );
#	test(sub {$attr->name . "=" . $attr->value . "\n"});
#}

# LibXML
print "\n--XML::LibXML--\n\n";

$doc = XML::LibXML::Document->new;
$doc = bless $doc, 'LibXMLDoc';
$doc->appendChild($root = $doc->createElement('foo'));
test(sub {$doc->toString});
test(sub {$doc->getDocumentElement->toString, "\n"});
test(sub {$doc->cloneNode(1)->toString, "\n"});
test(sub {($doc->getElementsByTagName( "foo" ))[0]->toString . "\n"});
$root->appendText( "bar" );
test(sub {$root->nodeName . "/" . $root->tagName . "\n"});
test(sub {$root->getFirstChild->nodeName . "\n"});
$root->setAttribute( 'foo', 'bar' );
$attrs = $root->attributes;
for(my $i = 0; $i < $attrs->length; $i++)
{
	my $attr = $attrs->item($i);
	$attr->setValue( 'barbar' );
	test(sub {$attr->name . "=" . $attr->value . "\n"});
}

#my $subdoc = XML::LibXML->new( expand_entities=>1, load_external_dtd=>1 )->parse_file( "/tmp/index.xpage" );
#$root->appendChild( $subdoc->documentElement );
#print $doc->toString;
#$root->appendChild( $root->cloneNode(0) );
#print "<<<\n", $doc->toString, "<<<\n";

#$root->appendChild( $doc->createTextNode( undef ));
$root->setAttribute( 'foo', undef );
test( sub { $root->toString . "\n" });

# GDOME
print "\n--XML::GDOME--\n\n";

$doc = XML::GDOME->createDocument( undef, "namespace", undef );
$doc->removeChild( $doc->getFirstChild );
$doc->appendChild($root = $doc->createElement('foo'));
test(sub {$doc->toString});
test(sub {$doc->getDocumentElement->toString, "\n"});
test(sub {$doc->cloneNode(1)->toString});
test(sub {($doc->getElementsByTagName( "foo" ))[0]->toString . "\n"});
$root->appendChild( $doc->createTextNode( "bar" ));
test(sub {$root->nodeName . "/" . $root->tagName . "\n"});
test(sub {$root->getFirstChild->nodeName . "\n"});
$root->setAttribute( 'foo', 'bar' );
$attrs = $root->attributes;
for(my $i = 0; $i < $attrs->length; $i++)
{
	my $attr = $attrs->item($i);
	$attr->setValue( 'barbar' );
	test(sub {$attr->name . "=" . $attr->value . "\n"});
}

#$root->appendChild( $doc->createTextNode( undef ));
#test( sub { $root->toString . "\n" });

sub test
{
	print $TI++ . ":\n";
	my $f = shift;
	print &$f;
}

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

