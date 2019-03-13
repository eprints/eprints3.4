######################################################################
#
# EPrints::MetaField::Relation;
#
######################################################################
#
#
######################################################################

=pod

=head1 NAME

B<EPrints::MetaField::Relation> - Subclass of compound for relations

=head1 DESCRIPTION

not done

=over 4

=cut

package EPrints::MetaField::Relation;

use EPrints::MetaField::Compound;

@ISA = qw( EPrints::MetaField::Compound );

use strict;

sub new
{
	my( $self, %params ) = @_;

	$params{fields} = [
		{ sub_name=>"type", type=>"id", },
		{ sub_name=>"uri", type=>"id", },
	];

	return $self->SUPER::new( %params );
}

sub to_sax_basic
{
	my( $self, $value, %opts ) = @_;

	return if !EPrints::Utils::is_set( $value );

	return $self->SUPER::to_sax_basic( {
		type => $value->{type},
		uri => $self->{repository}->config( "base_url" ) . $value->{uri},
	}, %opts );
}

######################################################################

######################################################################
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

