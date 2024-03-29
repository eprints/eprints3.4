=head1 NAME

EPrints::Plugin::Export::XMLFiles

=cut

package EPrints::Plugin::Export::XMLFiles;

use EPrints::Plugin::Export::StaffXML;

@ISA = ( "EPrints::Plugin::Export::StaffXML" );

use strict;

sub new
{
	my( $class, %opts ) = @_;

	my $self = $class->SUPER::new( %opts );

	$self->{name} = "EP3 XML with Files Embedded";
	$self->{accept} = [ 'list/eprint', 'dataobj/eprint' ];

	# this module outputs the files of an eprint with
	# no regard to the security settings so should be 
	# not made public without a very good reason.
	# This should already be set by StaffXML but lets
	# not risk it.
	$self->{visible} = "staff";

	$self->{suffix} = ".xml";
	$self->{mimetype} .= '; files="base64"';
	$self->{qs} = 0.1;

	return $self;
}

sub output_dataobj
{
	my( $self, $dataobj, %opts ) = @_;

	return $self->SUPER::output_dataobj( $dataobj, %opts, embed => 1 );
}

1;

=head1 COPYRIGHT

=for COPYRIGHT BEGIN

Copyright 2022 University of Southampton.
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

