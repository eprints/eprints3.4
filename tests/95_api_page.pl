#!/usr/bin/perl

use Test::More tests => 14;

use strict;
use warnings;

BEGIN { use_ok( "EPrints" ); }
BEGIN { use_ok( "EPrints::Test" ); }

my $TEMP_FILE = File::Temp->new( UNLINK => 0 );
unlink("$TEMP_FILE");

my $repoid = EPrints::Test::get_test_id();

my $ep = EPrints->new();
isa_ok( $ep, "EPrints", "EPrints->new()" );
if( !defined $ep ) { BAIL_OUT( "Could not obtain the EPrints System object" ); }

my $repo = $ep->repository( $repoid );
isa_ok( $repo, "EPrints::Repository", "Get a repository object ($repoid)" );
if( !defined $repo ) { BAIL_OUT( "Could not obtain the Repository object" ); }

# Test EPrints::Page::Text
{
	my $test_dom = $repo->xml->create_element( "element" );
	$test_dom->appendChild( $repo->xml->create_text_node( "some text" ) );
	my $title = $repo->xml->create_text_node( "test title" );
	
	my $page = $repo->xhtml->page( { page=>$test_dom, title=>$title } );
	isa_ok( $page, "EPrints::Page", "\$repo->xhtml->page(..)" );

	$page->write_to_file( $TEMP_FILE );
	ok( -e $TEMP_FILE, "EPrints::Page: \$page->write_to_file creates file" );

	open( T, $TEMP_FILE ) || BAIL_OUT( "Failed to read $TEMP_FILE: $!" );
	my $data = join( "", <T> );
	close T;

	ok( $data =~ m/test title/, "EPrints::Page: Output file contains title string" );
	ok( $data =~ m/<element>some text<\/element>/, "EPrints::Page: Output file contains body string" );
	#print STDERR $data;

	unlink( "$TEMP_FILE" );
}


# Test EPrints::Page::DOM
{
	my $test_dom = $repo->xml->create_element( "element" );
	$test_dom->appendChild( $repo->xml->create_text_node( "some text" ) );
	
	my $page = EPrints::Page::DOM->new( $repo, $test_dom, add_doctype=>0 );
	isa_ok( $page, "EPrints::Page::DOM", "\$repo->xhtml->page(..)" );
	$page->write_to_file( $TEMP_FILE );
	ok( -e $TEMP_FILE, "EPrints::Page::DOM: \$page->write_to_file creates file" );

	open( T, $TEMP_FILE ) || BAIL_OUT( "Failed to read $TEMP_FILE: $!" );
	my $data = join( "", <T> );
	close T;

	ok( $data eq "<element>some text</element>", "EPrints::Page::DOM: Output file contains body string" );

	unlink( "$TEMP_FILE" );
}

# DOCTYPE
{
	my $test_dom = $repo->xml->create_element( "element" );
	$test_dom->appendChild( $repo->xml->create_text_node( "some text" ) );
	
	my $page = EPrints::Page::DOM->new( $repo, $test_dom );
	isa_ok( $page, "EPrints::Page::DOM", "\$repo->xhtml->page(..)" );
	$page->write_to_file( $TEMP_FILE );
	ok( -e $TEMP_FILE, "EPrints::Page::DOM: \$page->write_to_file creates file" );

	open( T, $TEMP_FILE ) || BAIL_OUT( "Failed to read $TEMP_FILE: $!" );
	my $data = join( "", <T> );
	close T;

	ok( $data =~ m/<!DOCTYPE /, "EPrints::Page::DOM: Starts with <!DOCTYPE" );

	unlink( $TEMP_FILE );
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

