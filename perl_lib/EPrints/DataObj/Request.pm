######################################################################
#
# EPrints::DataObj::Request
#
######################################################################
#
#
######################################################################


=pod

=for Pod2Wiki

=head1 NAME

B<EPrints::DataObj::Request> - User requests.

=head1 DESCRIPTION

This class stores user requests and their responses for requesting a 
copy of a document.

=head1 CORE METADATA FIELDS

=over 4

=item requestid (counter)

The unique identifier for this request

=item docid (text)

The ID for any document this request may relate.

=item datestamp (timestamp)

The datestamp this request was created.

=item email (email)

The email address to which this request is sent.

=item requester_email (email)

The email address of the requester.

=item reason (longtext)

The reason the request was made.

=item expiry_date (time)

The time at which this request will expires.

=item code (text)

The code for this request, which can be used to created private URLS.

=item captcha (recaptcha)

The ReCAPTCHA field for the form for this request.

=back

=head1 REFERENCES AND RELATED OBJECTS

=over 4

=item eprintid (itemref)

The ID of the eprint data object associated with this request.

=item userid (itemref)

The ID of the user to whom this request is assigned.

=back

=head1 INSTANCES VARIABLES

See L<EPrints::DataObj|EPrints::DataObj#INSTANCE_VARIABLES>.

=head1 METHODS

=cut
######################################################################

package EPrints::DataObj::Request;

@ISA = ( 'EPrints::DataObj' );

use EPrints;
use Time::Local 'timegm_nocheck';

use strict;


######################################################################
=pod

=head2 Class Methods

=cut
######################################################################

######################################################################
=pod

=over 4

=item $fields = EPrints::DataObj::Request->get_system_field_info

Returns an array describing the system metadata of the request
dataset.

=cut
######################################################################

sub get_system_field_info
{
	my( $class ) = @_;

	return (

		{ name=>"requestid", type=>"counter", required=>1, can_clone=>1,
			sql_counter=>"requestid" },

		{ name=>"eprintid", type=>"itemref", 
			datasetid=>"eprint", required=>1 },

		{ name=>"docid", type=>"text", required=>0 },

		{ name=>"datestamp", type=>"timestamp", required=>1, },

		{ name=>"userid", type=>"itemref", 
			datasetid=>"user", required=>0 },

		{ name=>"email", type=>"email", required=>1 },

		{ name=>"requester_email", type=>"email", required=>1 },

		{ name=>"reason", type=>"longtext", required=>0 },

		{ name=>"expiry_date", type=>"time", required=>0 },

		{ name=>"code", type=>"text", required=>0 },

		{ name => "captcha",type => "recaptcha" },
	);
}

######################################################################
=pod

=item $dataset = EPrints::DataObj::Request->get_dataset_id

Returns the ID of the L<EPrints::DataSet> object to which this record 
belongs.

=cut
######################################################################

sub get_dataset_id
{
	return "request";
}


######################################################################
=pod

=item $request = EPrints::DataObj::Request->new_from_code( $session, $code )

Returns request that matches provided C<$code>.

=cut
######################################################################

sub new_from_code
{
	my( $class, $session, $code ) = @_;
	
	return unless( defined $code );

	return $session->dataset( $class->get_dataset_id )->search(
                filters => [
                        { meta_fields => [ 'code' ], value => "$code", match => 'EX' },
                ])->item( 0 );
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

=item $boolean = $request->has_expired

Returns a boolean depending on whether this request has expired.

=cut
######################################################################

sub has_expired
{
	my( $self ) = @_;

	my $expiry = $self->get_value( "expiry_date" );
	return 1 unless( defined $expiry );

	my( $year,$mon,$day,$hour,$min,$sec ) = split /[- :]/, $expiry;
	my $t = timegm_nocheck $sec||0,$min||0,$hour,$day,$mon-1,$year-1900;

	return 1 if( !defined $t ||  $t <= time );

	return 0;
}

1;

######################################################################
=pod

=back

=head1 SEE ALSO

L<EPrints::DataObj> and L<EPrints::DataSet>.

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

