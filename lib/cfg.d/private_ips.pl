######################################################################
#
#  Private IP Addresses
#
######################################################################
#
#  If in X_FORWARDED_FOR has a private IP address listed below use the
#  just use original remote IP address.  This is useful where a client
#  is on a network using private IP address space but then is being 
#  a proxy with a public IP address. This is more useful than the 
#  private IP address when it comes to determining their location.
#
######################################################################

$c->{ignore_x_forwarded_for_private_ip_prefixes} = [ '10\.', '127\.', '172\.16\.', '172\.17\.', '172\.18\.', '172\.19\.', '172\.20\.', '172\.21\.', '172\.22\.', '172\.23\.', '172\.24\.', '172\.25\.', '172\.26\.', '172\.27\.', '172\.28\.', '172\.29\.', '172\.30\.', '172\.31\.', '192\.168\.' ];

=head1 COPYRIGHT

=begin COPYRIGHT

Copyright 2023 University of Southampton.
EPrints 3.4 is supplied by EPrints Services.

http://www.eprints.org/eprints-3.4/

=end COPYRIGHT END

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
