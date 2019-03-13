#!/usr/bin/perl

use Test::More tests => 7;
use Digest::MD5;

use strict;
use warnings;

BEGIN { use_ok( "EPrints" ); }
BEGIN { use_ok( "EPrints::Test" ); }
BEGIN { use_ok( "EPrints::Test::RepositoryLog" ); }

my $repoid = EPrints::Test::get_test_id();

my $ep = EPrints->new();
isa_ok( $ep, "EPrints", "EPrints->new()" );
if( !defined $ep ) { BAIL_OUT( "Could not obtain the EPrints System object" ); }

my $repo = $ep->repository( $repoid );
isa_ok( $repo, "EPrints::Repository", "Get a repository object ($repoid)" );
if( !defined $repo ) { BAIL_OUT( "Could not obtain the Repository object" ); }

EPrints::Test::RepositoryLog->logs; # clear logs
my $phrase = $repo->phrase( "xxx_invalid" );
my( $err ) = EPrints::Test::RepositoryLog->logs;
diag($err);
ok($err =~ /^Undefined phrase/, "invalid phrase triggers warning");

SKIP: {
	skip "Set EPRINTS_LANG_DUPES=n, n >= 1", 1
		unless $ENV{EPRINTS_LANG_DUPES};

	my $lang = $repo->get_language;

	my %phrases;
	foreach my $data ($lang->_get_data, $lang->_get_repositorydata)
	{
		%phrases = (%phrases, %{$data->{xml}});
	}

	my %seen;
	while(my( $id, $xml ) = each %phrases)
	{
		push @{$seen{Digest::MD5::md5(_phrase_toString($xml))}}, $id;
	}

	diag("");
	diag(sprintf("%d of %d phrases are unique", scalar keys %seen, scalar keys %phrases));

	my $show = $ENV{EPRINTS_LANG_DUPES};
	foreach my $md5 (sort { @{$seen{$b}} <=> @{$seen{$a}} } keys %seen)
	{
		my $c = scalar @{$seen{$md5}};
		last if $c == 1;
		my $id = $seen{$md5}->[0];
		my $phrase = _phrase_toString($phrases{$id});
		next if $phrase eq "";
		$phrase =~ s/\n/\\n/s;
		$phrase =~ s/^(.{20}).+$/$1 .../s;
		diag(sprintf("%d x '%s': %s", $c, $phrase, $id));
		last if !$show--;
	}

	ok(1, "lang dupes detection");
};

sub _phrase_toString
{
	my( $node ) = @_;
	my $str = "";
	for($node->childNodes)
	{
		$str .= $_->toString;
	}
	return $str;
}

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

