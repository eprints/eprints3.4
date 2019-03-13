use strict;
use Test::More tests => 4;

# this is only really useful for profiling (we can't test the GUI output)

BEGIN { use_ok( "EPrints" ); }
BEGIN { use_ok( "EPrints::Test" ); }
BEGIN { use_ok( "EPrints::ScreenProcessor" ); }

my $session = EPrints::Test::get_test_session();

# find an example eprint
my $dataset = $session->dataset( "eprint" );
my $eprint = EPrints::Test::get_test_dataobj( $dataset );

my $workflow = EPrints::Workflow->new( $session, 'default',
	item => $eprint,
);
my @stages = $workflow->get_stage_ids;

foreach my $stage (@stages)
{
	$session = EPrints::Test::OnlineSession->new( $session, {
		method => "GET",
		path => "/cgi/users/home",
		username => "admin",
		query => {
			screen => "EPrint::Edit",
			eprintid => $eprint->id,
			stage => $stage,
		},
	});
	EPrints::ScreenProcessor->process(
		session => $session,
		url => $session->config( "base_url" ) . "/cgi/users/home"
		);

	my $content = $session->test_get_stdout();
}

#diag($content);

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

