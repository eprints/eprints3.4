
# event_uri
$c->{rdf}->{event_uri} = sub {
	my( $eprint ) = @_;

	return if( !$eprint->dataset->has_field( "event_title" ) );

	my $ev_title = $eprint->get_value( "event_title" );
	return if( !defined $ev_title  );

	my $ev_dates = "";
	if( $eprint->dataset->has_field( "event_dates" ) )
	{
		$ev_dates = $eprint->get_value( "event_dates" ) || "";
	}

	my $ev_location = "";
	if( $eprint->dataset->has_field( "event_location" ) )
	{
		$ev_location = $eprint->get_value( "event_location" ) || "";
	}

	my $raw_id = "eprintsrdf/$ev_title/$ev_location/$ev_dates";
	utf8::encode( $raw_id ); # md5 takes bytes, not characters

	return "epid:event/ext-".md5_hex( $raw_id );
};

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

