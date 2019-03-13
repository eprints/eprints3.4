use strict;
use Test::More tests => 15;

BEGIN { use_ok( "EPrints" ); }
BEGIN { use_ok( "EPrints::Test" ); }

EPrints::Test::mem_increase();

my $session = EPrints::Test::get_test_session( 0 );
ok(defined $session, 'opened an EPrints::Session object (noisy, no_check_db)');

# check it's the right type
ok($session->isa('EPrints::Repository'),'it really was an EPrints::Repository');

is($session->{noise},0,"Correct noise setting?");
is($session->{offline},1,"Correct offline setting?");
is($session->{query},undef,"There should be no query, we're offline");

ok(defined $session->get_repository, "is there a repository config attached?");
ok($session->get_repository->isa('EPrints::Repository'), "and it's really an repository");

ok(defined $session->get_database, "is there a database attached?");
ok($session->get_database->isa('EPrints::Database'), "and it's really an EPrints::Database?");

ok(defined $session->{lang}, "session has a language set" );
ok($session->{lang}->isa('EPrints::Language'), "and it's EPrints::Language" );
is($session->{lang}->{id}, 'en', "and it's the default (english)" );

$session->terminate;
ok(!defined $session->{database}, "cleaned up session" );

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

