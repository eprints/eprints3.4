=head1 NAME

EPrints::Apache::Login

=cut

######################################################################
#
# EPrints::Apache::Login
#
######################################################################
#
#
######################################################################

package EPrints::Apache::Login;

use strict;

use EPrints;
use EPrints::Apache::AnApache;

sub handler
{
	my( $r ) = @_;

	my $session = new EPrints::Session;
	my $problems;

	if( $session->param( "login_check" ) )
	{
		# If this is set, we didn't log in after all!
		$problems = $session->html_phrase( "cgi/login:no_cookies" );
	}

	my $screenid = $session->param( "screen" );
	if( !defined $screenid || $screenid !~ /^Login::/ )
	{
		$screenid = "Login";
	}

	EPrints::ScreenProcessor->process(
		session => $session,
		screenid => $screenid,
		problems => $problems,
	);

	return DONE;
}

1;

=head1 COPYRIGHT

=for COPYRIGHT BEGIN

Copyright 2018 University of Southampton.
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

