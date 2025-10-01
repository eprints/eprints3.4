######################################################################
#
# EPrints::MetaField::Date
#
######################################################################
#
#
######################################################################

=pod

=for Pod2Wiki

=head1 NAME

B<EPrints::MetaField::Date> - no description

=head1 DESCRIPTION

not done

=over 4

=cut


package EPrints::MetaField::Date;

use strict;
use warnings;

BEGIN
{
	our( @ISA );

	@ISA = qw( EPrints::MetaField );
}

use EPrints::MetaField;

sub get_sql_names
{
	my( $self ) = @_;

	return map { $self->get_name . "_" . $_ } qw( year month day );
}

# parse either ISO or our format and output our value
sub _build_value
{
	my( $self, $value ) = @_;

	return undef if !defined $value;

	my @parts = split /[-: TZ]/, $value;

	$value = "";
	$value .= sprintf("%04d",$parts[0]) if( defined $parts[0] );
	$value .= sprintf("-%02d",$parts[1]) if( defined $parts[1] );
	$value .= sprintf("-%02d",$parts[2]) if( defined $parts[2] );

	return $value;
}

sub value_from_sql_row
{
	my( $self, $session, $row ) = @_;

	my @parts = grep { defined $_ } splice(@$row,0,3);

	return undef if !@parts;

	return $self->_build_value( join(' ', @parts) );
}

sub sql_row_from_value
{
	my( $self, $session, $value ) = @_;

	my @parts;
	@parts = split /[-: TZ]/, $value if defined $value;
	@parts = @parts[0..2];

	return @parts;
}

sub get_sql_type
{
	my( $self, $session ) = @_;

	my @parts = $self->get_sql_names;

	for(@parts)
	{
		$_ = $session->get_database->get_column_type(
			$_,
			EPrints::Database::SQL_SMALLINT,
			0, # force notnull
			undef,
			undef,
			$self->get_sql_properties,
		);
	}

	return @parts;
}

sub render_single_value
{
	my( $self, $session, $value ) = @_;

	return $session->make_doc_fragment if !EPrints::Utils::is_set( $value );

	my $res = $self->{render_res};
	my $l = 10;
	$l = 7 if( defined $res && $res eq "month" );
	$l = 4 if( defined $res && $res eq "year" );

	my $timezone = $session->config( 'timezone' );
	if( $self->{render_style} eq "short" )
	{
		return EPrints::Time::render_short_date( $session, substr( $value,0,$l ), $timezone );
	}
	elsif( $self->{render_style} eq "dow" )
	{
		return EPrints::Time::render_date_with_dow( $session, substr( $value,0,$l ), $timezone );
	}
	return EPrints::Time::render_date( $session, substr( $value,0,$l ), $timezone );
}
	
@EPrints::MetaField::Date::MONTHKEYS = ( 
	"00", "01", "02", "03", "04", "05", "06",
	"07", "08", "09", "10", "11", "12" );

sub _month_names
{
	my( $self , $session ) = @_;
	
	my $months = {};

	my $month;
	foreach $month ( @EPrints::MetaField::Date::MONTHKEYS )
	{
		if ( $self->{input_style} eq "short" )
		{
			$months->{$month} = EPrints::Time::short_month_label( 
				$session, 
				$month );
		}
		else
		{
			$months->{$month} = EPrints::Time::month_label(
				$session,
				$month );
		}
	}

	return $months;
}

sub get_basic_input_elements
{
	my( $self, $session, $value, $basename, $staff, $obj ) = @_;

	my( $frag, $div, $yearid, $monthid, $dayid );

	$frag = $session->make_doc_fragment;
		
	my $min_res = $self->get_property( "min_resolution" );
	
	if( $min_res eq "month" || $min_res eq "year" )
	{	
		$div = $session->make_element( "div", class=>"ep_form_field_help" );	
		$div->appendChild( $session->html_phrase( 
			"lib/metafield:date_res_".$min_res ) );
		$frag->appendChild( $div );
	}

	$div = $session->make_element( "div" );

	my $workflow_datepicker = $session->config( "workflow_datepicker" );
	if( defined $workflow_datepicker )
	{
		my $datepicker = &{ $workflow_datepicker }( $session, $basename );
		$div->appendChild( $datepicker ) if $datepicker;
	}

	my( $year, $month, $day ) = ("", "", "");
	if( defined $value && $value ne "" )
	{
		($year, $month, $day) = split /-/, $value;
		$month = "00" if( !defined $month || $month == 0 );
		$day = "00" if( !defined $day || $day == 0 );
		$year = "" if( !defined $year || $year == 0 );
	}
 	$dayid = $basename."_day";
 	$monthid = $basename."_month";
 	$yearid = $basename."_year";

	my $ylabel = $session->make_element( "label", for=>$yearid );
	$ylabel->appendChild( 
		$session->html_phrase( "lib/metafield:year" ) );
	$div->appendChild( $ylabel );
	$div->appendChild( $session->make_text(" ") );

	$div->appendChild( $session->render_noenter_input_field(
		class=>"ep_form_text",
		name => $yearid,
		id => $yearid,
		value => $year,
		size => 4,
		maxlength => 4 ) );

	$div->appendChild( $session->make_text(" ") );

	my $mlabel = $session->make_element( "label" );
	$mlabel->appendChild( 
		$session->html_phrase( "lib/metafield:month" ) );
	
	$mlabel->appendChild( $session->make_text(" ") );
	$mlabel->appendChild( $session->render_option_list(
		name => $monthid,
		id => $monthid,
		values => \@EPrints::MetaField::Date::MONTHKEYS,
		default => $month,
		labels => $self->_month_names( $session ) ) );
	$div->appendChild( $mlabel );

	$div->appendChild( $session->make_text(" ") );

	my $dlabel = $session->make_element( "label" );
	$dlabel->appendChild( 
		$session->html_phrase( "lib/metafield:day" ) );
	$dlabel->appendChild( $session->make_text(" ") );
	my @daykeys = ();
	my %daylabels = ();
	for( 0..31 )
	{
		my $key = sprintf( "%02d", $_ );
		push @daykeys, $key;
		$daylabels{$key} = ($_==0?"?":$key);
	}
	$dlabel->appendChild( $session->render_option_list(
		name => $dayid,
		id => $dayid,
		values => \@daykeys,
		default => $day,
		labels => \%daylabels ) );
	$div->appendChild( $dlabel );

	$frag->appendChild( $div );
	
	return [ [ { el=>$frag } ] ];
}

sub get_basic_input_ids
{
	my( $self, $session, $basename, $staff, $obj, $from_compound ) = @_;

	return( $basename ) if $from_compound;
	return( $basename."_day", $basename."_month", $basename."_year" );
}

sub form_value_basic
{
	my( $self, $session, $basename ) = @_;
	
	my @parts;
	for(qw( year month day ))
	{
		my $part = $session->param( $basename."_$_" );
		last if !EPrints::Utils::is_set( $part ) || $part =~ m/[^0-9]/ || $part == 0;
		push @parts, $part;
	}

	return undef if !@parts;

	return $self->_build_value( join('-', @parts) );
}


sub get_unsorted_values
{
	my( $self, $session, $dataset ) = @_;

	my $values = $session->get_database->get_values( $self, $dataset );

	my $res = $self->{render_res};

	if( $res eq "day" )
	{
		return $values;
	}

	my $l = 10;
	if( $res eq "month" ) { $l = 7; }
	if( $res eq "year" ) { $l = 4; }
		
	my %ov = ();
	foreach my $value ( @{$values} )
	{
		if( !defined $value )
		{
			$ov{undef} = 1;
			next;
		}
		$ov{substr($value,0,$l)}=1;
	}
	my @outvalues = keys %ov;
	return \@outvalues;
}

sub get_id_from_value
{
	my( $self, $session, $value ) = @_;

	return 'NULL' if !EPrints::Utils::is_set( $value );
	my $id = $self->SUPER::get_id_from_value( $session, $value );

	my $res = $self->{render_res};

	return substr($id,0,4) if $res eq "year";
	return substr($id,0,7) if $res eq "month";
	return substr($id,0,10) if $res eq "day";

	return $res;
}

sub get_value_label
{
	my( $self, $session, $value, %opts ) = @_;

	if( !EPrints::Utils::is_set( $value ) && $opts{fallback_phrase} )
        {
                return $session->html_phrase( $opts{fallback_phrase} );
        }
	return $self->render_single_value( $session, $value );
}

sub render_search_input
{
	my( $self, $session, $searchfield ) = @_;
	
	return $session->render_input_field(
				class => "ep_form_text",
				type => "text",
				name => $searchfield->get_form_prefix,
				value => $searchfield->get_value,
				size => 21,
				maxlength => 21,
				'aria-labelledby' => $searchfield->get_form_prefix . "_label" );
}


sub from_search_form
{
	my( $self, $session, $basename ) = @_;

	return $self->EPrints::MetaField::Int::from_search_form( $session, $basename );
}


sub render_search_value
{
	my( $self, $session, $value ) = @_;

	my $regexp = $self->property( "regexp" );
	my $range = qr/-|(?:\.\.)/;

	if( $value =~ /^($regexp)$range($regexp)$/ )
	{
		return $session->html_phrase(
			"lib/searchfield:desc:date_between",
			from => EPrints::Time::render_date( 
					$session, 
					$1 ),
			to => EPrints::Time::render_date( 
					$session, 
					$2 ) );
	}

	if( $value =~ /^$range($regexp)$/ )
	{
		return $session->html_phrase(
			"lib/searchfield:desc:date_orless",
			to => EPrints::Time::render_date( 
					$session,
					$1 ) );
	}

	if( $value =~ /^($regexp)$range$/ )
	{
		return $session->html_phrase(
			"lib/searchfield:desc:date_ormore",
			from => EPrints::Time::render_date( 
					$session,
					$1 ) );
	}
	
	return EPrints::Time::render_date( $session, $value );
}

# overridden, date searches being EX means that 2000 won't match 
# 2000-02-21
sub get_search_conditions
{
	my( $self, $session, $dataset, $search_value, $match, $merge,
		$search_mode ) = @_;

	if( $match eq "SET" )
	{
		return $self->SUPER::get_search_conditions( @_[1..$#_] );
	}

	if( $match eq "EX" )
	{
		if( !EPrints::Utils::is_set( $search_value ) )
		{	
			return EPrints::Search::Condition->new( 
					'is_null', 
					$dataset, 
					$self );
		}
	}

	return $self->get_search_conditions_not_ex(
			$session, 
			$dataset, 
			$search_value, 
			$match, 
			$merge, 
			$search_mode );
}

sub get_search_conditions_not_ex
{
	my( $self, $session, $dataset, $search_value, $match, $merge,
		$search_mode ) = @_;

	# DATETIME
	# DATETIME-
	# -DATETIME
	# DATETIME-DATETIME
	# DATETIME := YEAR-MON-DAY{'T',' '}HOUR:MIN:SEC{'Z'}

	return $self->EPrints::MetaField::Int::get_search_conditions_not_ex(
		$session, $dataset, $search_value, $match, $merge, $search_mode
	);
}

sub get_search_group { return 'date'; } 

sub get_property_defaults
{
	my( $self ) = @_;
	my %defaults = $self->SUPER::get_property_defaults;
	$defaults{min_resolution} = "day";
	$defaults{render_res} = "day";
	$defaults{render_style} = "long";
	$defaults{input_style} = "long";
	$defaults{regexp} = qr/\d\d\d\d(?:-\d\d(?:-\d\d)?)?/;
	return %defaults;
}

sub trim_date
{
	my( $self, $date, $resolution ) = @_;

	return undef unless defined $date;

	return substr( $date, 0, 4  ) if $resolution == 1;
	return substr( $date, 0, 7  ) if $resolution == 2;
	return substr( $date, 0, 10 ) if $resolution == 3;
	return substr( $date, 0, 13 ) if $resolution == 4;
	return substr( $date, 0, 16 ) if $resolution == 5;
	return substr( $date, 0, 19 ) if $resolution == 6;

	return $date;
}

sub ordervalue_basic
{
	my( $self , $value ) = @_;

	return $self->_build_value( $value );
}

sub set_value
{
	my( $self, $dataobj, $value ) = @_;

	# reformat date/time values so they are always consistently stored
	local $_;
	for(ref($value) eq "ARRAY" ? @$value : $value)
	{
		$_ = $self->_build_value( $_ );
	}

	$self->SUPER::set_value( $dataobj, $value );
}

sub get_resolution
{
	my( $self, $date ) = @_;

	return 0 unless defined $date;

	my $l = length( $date );

	return 0 if $l == 0;
	return 1 if $l == 4;
	return 2 if $l == 7;
	return 3 if $l == 10;
	return 4 if $l == 13;
	return 5 if $l == 16;
	return 6;
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
	my @orig_probs = @probs;

	push @probs, $session->html_phrase( "validate:invalid_date", fieldname => &$f_fieldname );

	my $values = ( ref $value eq "ARRAY" ? $value : [ $value ] );

	for my $value ( @{$values} )
	{
		my $resolution = $self->get_resolution( $value );

		return @orig_probs if $resolution == 0;
		return @probs if $resolution > 6;

		$value = $self->trim_date( $value, $resolution );
		my @date = split( /[-: TZ]/, $value );

		return @probs if scalar( @date ) != $resolution;
		foreach ( @date )
		{
			return @probs unless $_ =~ /^\d+$/;
		}
		return @probs if $resolution >= 2 && ( $date[1] < 1 || $date[1] > 12 );
		if ( $resolution > 2 ) 
		{
			return @probs if $date[2] < 1 || $date[2] > 31;
			return @probs if $date[2] == 31 && grep( /^$date[1]$/, ( '02', '04', '06', '09', '11' ) );
			return @probs if $date[2] == 30 && $date[1] == 2;
			return @probs if $date[2] == 29 && $date[1] == 2 && ( $date[0] % 4 != 0 || ( $date[0] % 100 == 0 && $date[0] % 400 != 0 ) );
			return @probs if $resolution > 3 && ( $date[3] < 0 || $date[3] > 23 );
			return @probs if $resolution > 4 && ( $date[4] < 0 || $date[4] > 59 );
			return @probs if $resolution == 6 && ( $date[5] < 0 || $date[5] > 59 );
		}
	}
	return @orig_probs;
}


sub should_reverse_order { return 1; }

sub render_xml_schema_type
{
	my( $self, $session ) = @_;

	my $type = $session->make_element( "xs:simpleType", name => $self->get_xml_schema_type );

	my $restriction = $session->make_element( "xs:restriction", base => "xs:string" );
	$type->appendChild( $restriction );
	my $pattern = $session->make_element( "xs:pattern", value => "([0-9]{4}-[0-9]{2}-[0-9]{2})|([0-9]{4}-[0-9]{2})|([0-9]{4})" );
	$restriction->appendChild( $pattern );

	return $type;
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

