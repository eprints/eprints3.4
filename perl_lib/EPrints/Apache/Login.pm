######################################################################
#
# EPrints::Apache::Login
#
######################################################################
#
#
######################################################################

=pod

=for Pod2Wiki

=head1 NAME

EPrints::Apache::Login

=head1 DESCRIPTION

EPrints Login handler.

=head1 METHODS

=cut

package EPrints::Apache::Login;

use strict;

use EPrints;
use EPrints::Apache::AnApache;

######################################################################
=pod

=over 4

=item $rc = EPrints::Apache::Login::handler( $r )

Handler for managing EPrints login requests.

=cut
######################################################################

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

######################################################################
=pod

=back

=head1 COPYRIGHT

=begin COPYRIGHT

Copyright 2023 University of Southampton.
EPrints 3.4 is supplied by EPrints Services.

http://www.eprints.org/eprints-3.4/

=end COPYRIGHT

=begin LICENSE

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

=end LICENSE

