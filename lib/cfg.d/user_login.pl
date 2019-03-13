
=pod

# Please see http://wiki.eprints.org/w/User_login.pl
$c->{check_user_password} = sub {
	my( $repo, $username, $password ) = @_;

	... check whether $password is ok

	return $ok ? $username : undef;
};

=cut

# Maximum time (in seconds) before a user must log in again
# $c->{user_session_timeout} = undef; 

# Time (in seconds) to allow between user actions before logging them out
# $c->{user_inactivity_timeout} = 86400 * 7;

# Set the cookie expiry time
# $c->{user_cookie_timeout} = undef; # e.g. "+3d" for 3 days



# Additional restrictions to allow parts of a repository to be limited to logged in users
# see Rewrite.pm for implementation

# restrict access to abstract/summary pages
# $c->{login_required_for_eprints}->{enable} = 1;

# restrict access to view pages
# $c->{login_required_for_views}->{enable} = 1;

# restrict access to cgi pages
# $c->{login_required_for_cgi}->{enable} = 1;
# cant restrict access to the login cgi page
# $c->{login_required_for_cgi}->{exceptions} = [ "users/login", "handle_404" ];

# login page to redirct users to
# $c->{login_required_url} = "/cgi/users/login";



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

