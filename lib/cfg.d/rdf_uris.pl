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

# event location uri
$c->{rdf}->{event_location_uri} = sub {
	my( $eprint ) = @_;

	return if( !$eprint->dataset->has_field( "event_location" ) );

	my $ev_location = $eprint->get_value( "event_location" );
	return if( !EPrints::Utils::is_set( $ev_location ) );

	utf8::encode( $ev_location ); # md5 takes bytes, not characters
	return "epid:location/ext-".md5_hex( $ev_location );
};
	
# org_uri
$c->{rdf}->{org_uri} = sub {
    my( $eprint, $org_name ) = @_;

    return if( !$org_name );

    my $raw_id = "eprintsrdf/$org_name";
    utf8::encode( $raw_id ); # md5 takes bytes, not characters

    return "epid:org/ext-".md5_hex( $raw_id );
};

# person_uri
$c->{rdf}->{person_uri} = sub {
    my( $eprint, $person ) = @_;

    my $repository = $eprint->repository;
    if( EPrints::Utils::is_set( $person->{id} ) )
    {
        # If you want to use hashed ID's to prevent people reverse engineering
        # them from the URI, uncomment the following line and edit SECRET to be
        # something unique and unguessable.
        #
        # return "epid:person/ext-".md5_hex( utf8::encode( $person->{id}." SECRET" ));

        return "epid:person/ext-".$person->{id};
    }

    my $name = $person->{name};
    my $code = "eprintsrdf/".$eprint->get_id."/".($name->{family}||"")."/".($name->{given}||"");
    utf8::encode( $code ); # md5 takes bytes, not characters
    return "epid:person/ext-".md5_hex( $code );
};

# publication_uri
$c->{rdf}->{publication_uri} = sub {
    my( $eprint ) = @_;

    my $repository = $eprint->repository;
    if( $eprint->dataset->has_field( "issn" ) && $eprint->is_set( "issn" ) )
    {
        my $issn = $eprint->get_value( "issn" );
        $issn =~ s/[^0-9X]//g;

        return "epid:publication/ext-$issn";
    }

    return if( !$eprint->is_set( "publication" ) );

    my $code = "eprintsrdf/".$eprint->get_value( "publication" );
    utf8::encode( $code ); # md5 takes bytes, not characters
    return "epid:publication/ext-".md5_hex( $code );
};


=head1 COPYRIGHT

=for COPYRIGHT BEGIN

Copyright 2021 University of Southampton.
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

