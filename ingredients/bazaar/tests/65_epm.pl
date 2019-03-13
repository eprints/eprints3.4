#!/usr/bin/perl

use Test::More tests => 7;

use strict;
use warnings;

BEGIN { use_ok( "EPrints" ); }
BEGIN { use_ok( "EPrints::Test" ); }

my $repo = EPrints::Test::get_test_repository();

my $data = "Hello, World";
my $base64 = MIME::Base64::encode_base64( $data );

my $dataset = $repo->dataset( "epm" );

my $tmpfile = File::Temp->new;
syswrite($tmpfile, $data);
sysseek($tmpfile, 0, 0);

my $epm = $dataset->make_dataobj({
	version => '4.2.3',
	documents => [{
		content => "install",
		format => "other",
		main => "main.bin",
		files => [{
			_content => $tmpfile,
			filename => "main.bin",
			filesize => length($base64),
			mime_type => "application/octet-stream",
		}],
	}],
});

my $buffer;
open(my $fh, ">", \$buffer) or die "Open scalar for writing: $!";
$epm->serialise($fh, 1);
ok($buffer =~ /$base64/, "serialise with files");

$buffer = "";
open($fh, ">", \$buffer);
$epm->serialise($fh, 0);
ok($buffer !~ /$base64/, "serialise without files");

my $epm2 = $dataset->make_dataobj({
	version => '4.2.2',
});
ok($epm->version gt $epm2->version, "version gt");
$epm2->set_value( "version", "4.2.4" );
ok($epm->version lt $epm2->version, "version lt");

ok(1);

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

