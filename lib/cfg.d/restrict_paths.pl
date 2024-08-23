# Restrict paths is intended to forbid access to specified paths for certain IP addresses or subnets, sending a 403 HTTP error code. This is useful if you want to block a bot from accessing processor-intensive pages but don't want to block it outright as that may stop it usefully indexing your EPrints repository.
#$c->{restrict_paths} = [
#   Prevent access to exportview from 1.2.3.4 and 5.6.7.8
#	{
#		path => '/cgi/exportview/',
#		ips => [ '1.2.3.4', '5.6.7.8' ],
#	},
#   Prevent access to export from 9.10.11.0/24 subnet
#   {
#       path => '/cgi/export/',
#       ips => [ '9.10.11.' ],
#   },
#];

=head1 COPYRIGHT

=for COPYRIGHT BEGIN

Copyright 2024 University of Southampton.
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
