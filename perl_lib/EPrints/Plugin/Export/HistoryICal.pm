=head1 NAME

EPrints::Plugin::Export::HistoryICal

=cut

package EPrints::Plugin::Export::HistoryICal;

use EPrints::Plugin::Export;

@ISA = ( "EPrints::Plugin::Export" );

use strict;

sub new
{
	my( $class, %opts ) = @_;

	my $self = $class->SUPER::new( %opts );

	$self->{name} = "History ICal";
	$self->{accept} = [ 'list/history' ];
	$self->{visible} = "all";
	$self->{suffix} = ".ics";
	$self->{mimetype} = "text/calendar; charset=utf-8";
	
	return $self;
}


sub output_list
{
	my( $plugin, %opts ) = @_;

	my $header = <<END;
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//EPRINTS/
END
	my $r = [];
	if( defined $opts{fh} )
	{
		print {$opts{fh}} $header;
	}
	else
	{
		push @{$r}, $header;
	}

	$opts{list}->map( sub {
		my( $session, $dataset, $item ) = @_;

		my $part = $plugin->output_dataobj( $item, %opts );
		if( defined $opts{fh} )
		{
			print {$opts{fh}} $part;
		}
		else
		{
			push @{$r}, $part;
		}
	} );

	if( defined $opts{fh} )
	{
		return undef;
	}

	my $footer = <<END;
END:VCALENDAR
END
	if( defined $opts{fh} )
	{
		print {$opts{fh}} $footer;
	}
	else
	{
		push @{$r}, $footer;
	}

	return join( '', @{$r} );
}

#stub.
sub output_dataobj
{
	my( $plugin, $dataobj ) = @_;

	my $hostname = $plugin->get_repository()->config( "host" );
	$hostname ||= $plugin->get_repository()->config( "securehost" );

	my $r = "";

	$r.="BEGIN:VEVENT\n";
	$r.="CATEGORY:action\n";
	$r.="SUMMARY:".$dataobj->get_value( "action" )." on ".$dataobj->get_value( "datasetid" ).".".$dataobj->get_value( "objectid" )."\n";
	$r.="UID:history.".$dataobj->get_value( 'historyid' )."\@".$hostname."\n";
	my $timestamp = $dataobj->get_value( "timestamp" ) ;
	$timestamp =~s/ /T/;
	$timestamp =~s/[:-]//g;
	$r.="DTSTART:$timestamp\n";
	$r.="DTEND:$timestamp\n";
	$r.="END:VEVENT\n";


	return $r;
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

