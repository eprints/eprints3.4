

use Digest::MD5 qw(md5 md5_hex md5_base64);

$c->{rdf}->{xmlns}->{dc}   = 'http://purl.org/dc/elements/1.1/';
$c->{rdf}->{xmlns}->{dct}  = 'http://purl.org/dc/terms/';
$c->{rdf}->{xmlns}->{foaf} = 'http://xmlns.com/foaf/0.1/';
$c->{rdf}->{xmlns}->{owl}  = 'http://www.w3.org/2002/07/owl#';
$c->{rdf}->{xmlns}->{rdf}  = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#';
$c->{rdf}->{xmlns}->{rdfs} = 'http://www.w3.org/2000/01/rdf-schema#';
$c->{rdf}->{xmlns}->{xsd}  = 'http://www.w3.org/2001/XMLSchema#';

$c->{rdf}->{xmlns}->{epid} = $c->{base_url}."/id/";


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

