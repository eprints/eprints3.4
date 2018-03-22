=head1 NAME

EPrints::Plugin::Export::CSV

=head1 DESCRIPTION

Subclass of MultilineCSV but exports only fields set "export_as_xml" and is publicly visible.

=cut

package EPrints::Plugin::Export::CSV;

use EPrints::Plugin::Export::MultilineCSV;

@ISA = ( "EPrints::Plugin::Export::MultilineCSV" );

use strict;

sub new
{
	my( $class, %opts ) = @_;

	my $self = $class->SUPER::new( %opts );

	$self->{name} = "Multiline CSV";
	$self->{visible} = "all";
	
	return $self;
}

sub fields
{
	my( $self, $dataset ) = @_;

	# skip compound, subobjects
	return grep {
			$_->property("export_as_xml") &&
			!$_->is_virtual
		} 
		$dataset->fields;
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

