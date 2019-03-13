=head1 NAME

EPrints::Plugin::Export::XMLFile

=cut

package EPrints::Plugin::Export::XMLFile;


use EPrints::Plugin::Export;
# This virtual super-class supports Unicode output

our @ISA = qw( EPrints::Plugin::Export );


sub new
{
	my( $class, %params ) = @_;

	$params{mimetype} = exists $params{mimetype} ? $params{mimetype} : "text/xml; charset=utf-8";
	$params{suffix} = exists $params{suffix} ? $params{suffix} : ".xml";

	return $class->SUPER::new( %params );
}

sub initialise_fh
{
	my( $plugin, $fh ) = @_;

	binmode($fh, ":utf8");
}

sub output_dataobj
{
	my( $self, $dataobj, %opts ) = @_;

	my $xml = $self->xml_dataobj( $dataobj, %opts );
	my $r = EPrints::XML::to_string( $xml );
	EPrints::XML::dispose( $xml );

	return $r;
}

1;

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

