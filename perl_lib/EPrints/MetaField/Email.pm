######################################################################
#
# EPrints::MetaField::Email;
#
######################################################################
#
#
######################################################################

=pod

=head1 NAME

B<EPrints::MetaField::Email> - no description

=head1 DESCRIPTION

Contains an Email address that is linked when rendered.

=over 4

=cut

package EPrints::MetaField::Email;

use EPrints::MetaField::Idci;
@ISA = qw( EPrints::MetaField::Idci );

use strict;

sub render_single_value
{
	my( $self, $session, $value ) = @_;
	
	return $session->make_doc_fragment if !EPrints::Utils::is_set( $value );

	my $text = $session->make_text( $value );

	return $text if !defined $value;
	return $text if( $self->{render_dont_link} );

	my $link = $session->render_link( "mailto:".$value );
	$link->appendChild( $text );
	return $link;
}

sub validate
{
        my( $self, $session, $value, $object ) = @_;

	# closure for generating the field link fragment
        my $f_fieldname = sub {
                my $f = defined $self->property( "parent" ) ? $self->property( "parent" ) : $self;
                my $fieldname = $session->xml->create_element( "span", class=>"ep_problem_field:".$f->get_name );
                $fieldname->appendChild( $f->render_name( $session ) );
                return $fieldname;
        };

        my @probs = $self->SUPER::validate( $session, $value, $object );

	my $values = ( ref $value eq "ARRAY" ? $value : [ $value ] );

        for my $value ( @{$values} )
        {
		push @probs, $session->html_phrase( "validate:bad_email", fieldname =>  &$f_fieldname ) if defined $value && !EPrints::Utils::validate_email( $value );
	}

	return @probs;
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

