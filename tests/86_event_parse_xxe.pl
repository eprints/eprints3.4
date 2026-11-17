#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use FindBin;
use File::Temp qw(tempdir);

# Load EPrints::XML::LibXML on its own, with XML::SAX::ExpatXS reported as
# missing, so that event_parse uses its XML::LibXML::SAX fallback.
{
	package EPrints::Utils;
	no warnings 'redefine';
	sub require_if_exists { return 0 }
}

my $libxml = "$FindBin::Bin/../perl_lib/EPrints/XML/LibXML.pm";
{
	package EPrints::XML;
	do $libxml or main::BAIL_OUT("Could not load $libxml: $@ $!");
}

{
	package TextHandler;
	sub new { bless { text => '' }, shift }
	sub characters { $_[0]{text} .= $_[1]{Data} }
	sub AUTOLOAD { }
}

my $root = tempdir(CLEANUP => 1);
my $secret = "$root/secret.txt";
open my $s, '>', $secret or BAIL_OUT("Could not write $secret: $!");
print {$s} "SECRET-CONTENT";
close $s;

sub parse
{
	my( $xml ) = @_;
	open my $fh, '<', \$xml or die $!;
	my $handler = TextHandler->new;
	eval { EPrints::XML::event_parse( $fh, $handler ) };
	return( $@, $handler->{text} );
}

my( $err, $text ) = parse( qq{<?xml version="1.0"?>\n<!DOCTYPE a [ <!ENTITY x SYSTEM "file://$secret"> ]>\n<a>[&x;]</a>} );
unlike( $text, qr/SECRET-CONTENT/, 'external general entity is not expanded' );
ok( $err, 'document with an external entity is rejected' );

( $err, $text ) = parse( qq{<?xml version="1.0"?>\n<!DOCTYPE a [ <!ENTITY % p SYSTEM "file://$secret"> %p; ]>\n<a>ok</a>} );
unlike( $text, qr/SECRET-CONTENT/, 'external parameter entity is not loaded' );

( $err, $text ) = parse( qq{<?xml version="1.0" encoding="UTF-8"?>\n<a>A&amp;B &#233; &lt;x&gt; \xc3\xa9t\xc3\xa9</a>} );
ok( !$err, 'ordinary document is parsed' ) or diag $err;
is( $text, "A&B \x{e9} <x> \x{e9}t\x{e9}", 'predefined and character entities, UTF-8 text' );

( $err, $text ) = parse( qq{<?xml version="1.0"?>\n<!DOCTYPE a [ <!ENTITY e "internal"> ]>\n<a>[&e;]</a>} );
ok( !$err, 'document with an internal entity is parsed' ) or diag $err;
like( $text, qr/internal/, 'internal entity still works' );

done_testing();
