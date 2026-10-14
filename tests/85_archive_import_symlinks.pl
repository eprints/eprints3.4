#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use FindBin;
use File::Find;
use File::Temp qw(tempdir);

{
	package EPrints::Const;
	sub EP_TRIGGER_MEDIA_INFO () { 1 }
}

{
	package TestRepository;
	sub new { bless {}, shift }
	sub config { 100 }
	sub run_trigger { return }
}

my $archive_plugin = "$FindBin::Bin/../perl_lib/EPrints/Plugin/Import/Archive.pm";
do $archive_plugin or BAIL_OUT("Could not load $archive_plugin: $@ $!");

my $root = tempdir(CLEANUP => 1);
my $source = "$root/source";
mkdir $source or BAIL_OUT("Could not create source directory: $!");

open my $regular, '>', "$source/regular.txt" or BAIL_OUT("Could not write regular file: $!");
print {$regular} "ordinary file\n";
close $regular;

my $outside = "$root/outside.txt";
open my $secret, '>', $outside or BAIL_OUT("Could not write outside file: $!");
print {$secret} "outside archive\n";
close $secret;

my $plugin = { repository => TestRepository->new };
my $normal = EPrints::Plugin::Import::Archive::create_epdata_from_directory(
	$plugin, $source, 0 );
is( scalar @$normal, 1, "regular file is imported" );
is( $normal->[0]->{files}->[0]->{filename}, "regular.txt", "regular filename is kept" );
my $normal_fh = $normal->[0]->{files}->[0]->{_content};
is( scalar <$normal_fh>, "ordinary file\n", "regular file content is readable" );

my $empty = "$root/empty";
mkdir $empty or BAIL_OUT("Could not create empty directory: $!");
my $empty_single = EPrints::Plugin::Import::Archive::create_epdata_from_directory(
	$plugin, $empty, 1 );
ok( !defined $empty_single, "single-document archive with no regular files is rejected" );

SKIP: {
	my $link = "$source/link.txt";
	skip "native symlinks are unavailable on this filesystem", 3
		unless symlink( $outside, $link ) && -l $link;

	my $mixed = EPrints::Plugin::Import::Archive::create_epdata_from_directory(
		$plugin, $source, 0 );
	is( scalar @$mixed, 1, "symlink to outside file is skipped" );
	is( $mixed->[0]->{files}->[0]->{filename}, "regular.txt", "regular file still imports" );

	my $link_only = "$root/link_only";
	mkdir $link_only or BAIL_OUT("Could not create link-only directory: $!");
	symlink( $outside, "$link_only/link.txt" ) or BAIL_OUT("Could not create second symlink: $!");
	my $single = EPrints::Plugin::Import::Archive::create_epdata_from_directory(
		$plugin, $link_only, 1 );
	ok( !defined $single, "single-document archive with only a symlink is rejected" );
}

done_testing();
