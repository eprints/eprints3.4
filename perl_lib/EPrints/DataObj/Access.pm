######################################################################
#
# EPrints::DataObj::Access
#
######################################################################
#
#
######################################################################

=pod

=for Pod2Wiki

=head1 NAME

B<EPrints::DataObj::Access> - Accesses to the Web server

=head1 DESCRIPTION

Accesses to particular abstract/summary pages (views) or publication 
documents (downloads).

Inherits from L<EPrints::DataObj::SubObject>, which in turn inherits
from L<EPrints::DataObj>.

=head1 CORE METADATA FIELDS

=over 4

=item accessid (counter)

Unique ID for the access.

=item datestamp (timestamp)

Time of access.

=item requester_id (text)

ID of the requesting user-agent. (Typically an IP address).

=item requester_user_agent (longtext)

The HTTP user agent string. (Useful for robots spotting).

=item requester_country (text)

The country from which the request originated. (Typically determined 
using L<Geo::IP>). 

=item requester_institution (text)

The institution from which the request originated. (This could be used 
to store the Net-Name from a WHOIS lookup).

=item referring_entity_id (longtext)

ID of the object from which the user agent came from (i.e. HTTP 
referrer).

=item service_type_id (text)

Id of the type of service requested. (E.g. abstract view or full text
download).

=item referent_id (int)

ID of the object requested. (Normally the eprint ID).

=item referent_docid (int)

ID of the document requested (if relevant).

=back

=head1 REFERENCES AND RELATED OBJECTS

none

=head1 INSTANCE VARIABLES

See L<EPrints::DataObj/INSTANCE_VARIABLES>.

=head1 METHODS

=cut

package EPrints::DataObj::Access;

@ISA = ( 'EPrints::DataObj::SubObject' );

use EPrints;

use strict;


######################################################################
=pod

=back

=head2 Class Methods

=cut
######################################################################

######################################################################
=pod

=over 4

=item $fields = EPrints::DataObj::Access->get_system_field_info

Returns an array describing the system metadata of the access dataset.

=cut
######################################################################

sub get_system_field_info
{
    my( $class ) = @_;

    return
    (
        { name=>"accessid", type=>"counter", required=>1, can_clone=>0,
            sql_counter=>"accessid" },

        { name=>"datestamp", type=>"timestamp", required=>1, },

        { name=>"requester_id", type=>"text", required=>1, text_index=>0, },
		
        { name=>"requester_user_agent", type=>"longtext", required=>0, text_index=>0, },

        { name=>"requester_country", type=>"text", required=>0, text_index=>0, },

        { name=>"requester_institution", type=>"text", required=>0, text_index=>0, },

        { name=>"referring_entity_id", type=>"longtext", required=>0, text_index=>0, },

        { name=>"service_type_id", type=>"text", required=>1, text_index=>0, },

        { name=>"referent_id", type=>"int", required=>1, text_index=>0, },

        { name=>"referent_docid", type=>"int", required=>0, text_index=>0, },
    );
}


######################################################################
=pod

=item $dataset = EPrints::DataObj::Access->get_dataset_id

Returns the ID of the L<EPrints::DataSet> object to which this record
belongs.

=cut
######################################################################

sub get_dataset_id
{
	return "access";
}

######################################################################
=pod

=back

=head2 Object Methods

=cut
######################################################################

######################################################################
=pod

=over 4

=item $referent_id = $access->get_referent_id

Returns the fully-qualified referent ID.

=cut
######################################################################

sub get_referent_id
{
	my( $self ) = @_;

	my $id = $self->get_value( "referent_id" );

	$id =~ /:?(\d+)$/;

	$id = EPrints::OpenArchives::to_oai_identifier( EPrints::OpenArchives::archive_id( $self->{session} ), $1 );

	return $id;
}


######################################################################
=pod

=item $requester_id = $access->get_requester_id

Return the fully-qualified requester ID.

=cut
######################################################################

sub get_requester_id
{
	my( $self ) = @_;

	my $id = $self->get_value( "requester_id" );

	$id =~ s/^urn:ip://;

	return "urn:ip:$id";
}

1;

######################################################################
=pod

=back

=head1 SEE ALSO

L<EPrints::SubObject>, L<EPrints::DataObj> and L<EPrints::DataSet>.

=head1 COPYRIGHT

=begin COPYRIGHT

Copyright 2022 University of Southampton.
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

