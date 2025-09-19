######################################################################
#
# EPrints::MetaField::Url;
#
######################################################################
#
#
######################################################################

=pod

=head1 NAME

B<EPrints::MetaField::Url> - no description

=head1 DESCRIPTION

Contains a URL that is turned into a hyperlink when rendered. Same length as a L<EPrints::MetaField::Longtext>.

=over 4

=cut

package EPrints::MetaField::Url;

use EPrints::MetaField::Longtext; # get_sql_type
use EPrints::MetaField::Id;
@ISA = qw( EPrints::MetaField::Id );

use strict;

sub get_sql_type
{
	my( $self, $session ) = @_;

	return $self->EPrints::MetaField::Longtext::get_sql_type( $session );
}

sub sql_row_from_value
{
	my( $self, $session, $value ) = @_;

	return undef unless defined $value;
	# Prevent 'javascript:' links from being saved as there are no benevolent
	# uses for them.
	return undef if $value =~ /^\s*javascript:/;

	return $self->SUPER::sql_row_from_value( $session, $value );
}

sub get_property_defaults
{
	my( $self ) = @_;
	return (
		$self->SUPER::get_property_defaults, # Id
		$self->EPrints::MetaField::Longtext::get_property_defaults, # LongText - maxlength
		text_index => 1,
		sql_index => 0,
		match => "IN"
	);
}

sub render_single_value
{
	my( $self, $session, $value ) = @_;

	my $text = $session->make_text( $value );

	return $text if( $self->{render_dont_link} );

	my $link = $session->render_link( $value );
	$link->appendChild( $text );
	return $link;
}

sub get_xml_schema_type
{
	return "xs:anyURI";
}

sub render_xml_schema_type
{
	my( $self, $session ) = @_;

	return $session->make_doc_fragment;
}

######################################################################
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

