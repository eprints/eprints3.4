######################################################################
#
# EPrints::MetaField::Int
#
######################################################################
#
#
######################################################################

=pod

=for Pod2Wiki

=head1 NAME

B<EPrints::MetaField::Int> - no description

=head1 DESCRIPTION

not done

=over 4

=cut

package EPrints::MetaField::Int;

use strict;
use warnings;

BEGIN
{
	our( @ISA );

	@ISA = qw( EPrints::MetaField );
}

use EPrints::MetaField;

sub get_sql_type
{
	my( $self, $session ) = @_;

	return $session->get_database->get_column_type(
		$self->get_sql_name(),
		EPrints::Database::SQL_INTEGER,
		!$self->get_property( "allow_null" ),
		undef,
		undef,
		$self->get_sql_properties,
	);
}

sub get_max_input_size
{
	my( $self ) = @_;

	return $self->get_property( "digits" );
}

sub ordervalue_basic
{
	my( $self , $value ) = @_;

	unless( EPrints::Utils::is_set( $value ) )
	{
		return "";
	}

	# just in case we still use eprints in year 200k 
	my $pad = $self->get_property( "digits" );
	return sprintf( "%0".$pad."d",$value );
}

sub render_search_input
{
	my( $self, $session, $searchfield ) = @_;

	if( defined $self->{render_search_input} )
	{
		return $self->call_property( "render_search_input", $self, $session, $searchfield );
	}

	return $session->render_input_field(
				class => "ep_form_text",
				name=>$searchfield->get_form_prefix,
				value=>$searchfield->get_value,
				size=>9,
				maxlength=>100,
				'aria-labelledby'=>$searchfield->get_form_prefix . "_label"  );
}

sub from_search_form
{
	my( $self, $session, $prefix ) = @_;

	my $value = $session->param( $prefix );
	if( defined $self->{fromsearchform} )
	{
		$value = $self->call_property( "fromsearchform", $value, $session, $prefix );
	}

	return $value unless EPrints::Utils::is_set( $value );

	my $regexp = $self->property( "regexp" );
	my $range = qr/-|(?:\.\.)/;

	if( $value !~ /^(?:$regexp$range?)|(?:$regexp?$range$regexp)$/ )
	{
		return( undef,undef,undef, $session->html_phrase( "lib/searchfield:int_err" ) );
	}

	return( $value );
}

sub render_search_value
{
	my( $self, $session, $value ) = @_;

	my $type = $self->get_type;

	my $regexp = $self->property( "regexp" );
	my $range = qr/-|(?:\.\.)/;

	if( $value =~ m/^($regexp)$range($regexp)$/ )
	{
		return $session->html_phrase(
			"lib/searchfield:desc:".$type."_between",
			from => $session->make_text( $1 ),
			to => $session->make_text( $2 ) );
	}

	if( $value =~ m/^$range($regexp)$/ )
	{
		return $session->html_phrase(
			"lib/searchfield:desc:".$type."_orless",
			to => $session->make_text( $1 ) );
	}

	if( $value =~ m/^($regexp)$range$/ )
	{
		return $session->html_phrase(
			"lib/searchfield:desc:".$type."_ormore",
			from => $session->make_text( $1 ) );
	}

	return $session->make_text( $value );
}

sub get_search_conditions_not_ex
{
	my( $self, $session, $dataset, $search_value, $match, $merge,
		$search_mode ) = @_;
	
	# N
	# N..
	# ..N
	# N..N

	my $regexp = $self->property( "regexp" );
	my $range = qr/-|(?:\.\.)/;

	if( $search_value =~ m/^$regexp$/ )
	{
		return EPrints::Search::Condition->new( 
			'=', 
			$dataset,
			$self, 
			$search_value );
	}

	my( $lower, $higher ) = $search_value =~ m/^($regexp)?$range($regexp)?$/;

	my @r = ();
	if( defined $lower )
	{
		push @r, EPrints::Search::Condition->new( 
				'>=',
				$dataset,
				$self,
				$1);
	}
	if( defined $higher )
	{
		push @r, EPrints::Search::Condition->new( 
				'<=',
				$dataset,
				$self,
				$2 );
	}

	if( !@r )
	{
		return EPrints::Search::Condition->new( 'FALSE' );
	}
	elsif( @r == 1 )
	{
		return $r[0];
	}
	else
	{
		return EPrints::Search::Condition->new( "AND", @r );
	}
}

sub get_search_group { return 'number'; } 

sub get_property_defaults
{
	my( $self ) = @_;
	my %defaults = $self->SUPER::get_property_defaults;
	$defaults{digits} = $EPrints::MetaField::FROM_CONFIG;
	$defaults{regexp} = qr/-?[0-9]+/;
	return %defaults;
}

sub get_xml_schema_type
{
	return "xs:integer";
}

sub render_xml_schema_type
{
	my( $self, $session ) = @_;

	return $session->make_doc_fragment;
}

# integer fields must be NULL or a number, can't be ''
sub xml_to_epdata_basic
{
	my( $self, $session, $xml, %opts ) = @_;

	my $value = EPrints::Utils::tree_to_utf8( scalar $xml->childNodes );

	return EPrints::Utils::is_set( $value ) ? $value : undef;
}

sub sql_row_from_value
{
	my( $self, $session, $value ) = @_;

	# Also validate on regex for when called via CRUD API
	my $regexp = defined $self->property( 'regexp' ) ? $self->property( 'regexp' ) : '.*';
	if ( defined $value && ( $value !~ m/^($regexp)$/ ||  $value > 2**31-1 || $value < -2**31 ) ) # Make sure value is within 32-bit signed int
	{
		$value = undef;
        $session->log( "WARNING: Value for field '".$self->name."' was unset as it cannot be stored as a 32-bit signed integer or value does not match field's regexp." );
	}

	return( $value );
}

sub form_value_single
{
	my( $self, $session, $basename, $object ) = @_;
	my $value = $self->SUPER::form_value_single( $session, $basename, $object );
	my $regexp = defined $self->property( 'regexp' ) ? $self->property( 'regexp' ) : '.*';
	return defined $value && $value =~ m/^($regexp)$/ ? $value : undef;
}

sub empty_value 
{
	my ( $self ) = @_;
	$self->property( 'allow_null' ) == 1 ? undef : 0;
}

######################################################################
1;

=head1 COPYRIGHT

=begin COPYRIGHT

Copyright 2023 University of Southampton.
EPrints 3.4 is supplied by EPrints Services.

http://www.eprints.org/eprints-3.4/

=end COPYRIGHT

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

