######################################################################
#
# EPrints::Apache::Sword
#
######################################################################

=pod

=for Pod2Wiki

=head1 NAME

B<EPrints::Apache::Sword> - Authenticates requests to EPrints' SWORD 
API.

=head1 DESCRIPTION

Authenticates requests to EPrints' SWORD API returning a suitable HTTP
response.

=head1 METHODS

=cut

package EPrints::Apache::Sword;

use strict;
use warnings;

use MIME::Base64;

######################################################################
=pod

=over 4

=item $response = EPrints::Apache::Sword::authenticate( $session, $request )

Authenticates a SWORD request and returns suitable HTTP response.

=cut
######################################################################

sub authenticate
{
        my ( $session, $request ) = @_;

        my %response;

        my $authen = EPrints::Apache::AnApache::header_in( $request, 'Authorization' );

        $response{verbose_desc} = "";

        if(!defined $authen)
        {
                $response{error} = {
                                        status_code => 401,
                                        x_error_code => "ErrorAuth",
                                        error_href => "http://eprints.org/sword/error/ErrorAuth",
                                        no_auth => 1,
                                   };

                $response{verbose_desc} .= "[ERROR] No authentication found in the headers.\n";
                return \%response;
        }

        # Check we have Basic authentication sent in the headers, and decode the Base64 string:
        if($authen =~ /^Basic\ (.*)$/)
        {
                $authen = $1;
        }
        my $decode_authen = MIME::Base64::decode_base64( $authen );
        if(!defined $decode_authen)
        {
                $response{error} = {
                                        status_code => 401,
                                        x_error_code => "ErrorAuth",
                                        error_href => "http://eprints.org/sword/error/ErrorAuth",
                                   };
                $response{verbose_desc} .= "[ERROR] Authentication failed (invalid base64 encoding).\n";
                return \%response;
        }

        my $username;
        my $password;

	if($decode_authen =~ /^(\w+)\:(\w+)$/)
        {
                $username = $1;
                $password = $2;
        }
        else
        {
                $response{error} = {
                                        status_code => 401,
                                        x_error_code => "ErrorAuth",
                                        error_href => "http://eprints.org/sword/error/ErrorAuth",
                                   };
                $response{verbose_desc} .= "[ERROR] Authentication failed (invalid base64 encoding).\n";
                return \%response;
        }

        unless( $session->valid_login( $username, $password ) )
        {
                $response{error} = {
                                        status_code => 401,
                                        x_error_code => "ErrorAuth",
                                        error_href => "http://eprints.org/sword/error/ErrorAuth",
                                   };
                $response{verbose_desc} .= "[ERROR] Authentication failed.\n";
                return \%response;
        }

        my $user = EPrints::DataObj::User::user_with_username( $session, $username );

        # This error could be a 500 Internal Error since the previous check ($db->valid_login) succeeded.
        if(!defined $user)
        {
                $response{error} = {
                                        status_code => 401,
                                        x_error_code => "ErrorAuth",
                                        error_href => "http://eprints.org/sword/error/ErrorAuth",
                                   };
                $response{verbose_desc} .= "[ERROR] Authentication failed.\n";
                return \%response;
        }

        # Now check we have a behalf user set, and whether the mediated deposit is allowed
        my $xbehalf = EPrints::Apache::AnApache::header_in( $request, 'X-On-Behalf-Of' );
	if(defined $xbehalf)
        {
                my $behalf_user = EPrints::DataObj::User::user_with_username( $session, $xbehalf );

                if(!defined $behalf_user)
                {
                        $response{error} = {
                                        status_code => 401,
                                        x_error_code => "TargetOwnerUnknown",
                                        error_href => "http://purl.org/net/sword/error/TargetOwnerUnknown",
                                   };

                        $response{verbose_desc} .= "[ERROR] Unknown user for mediation: '".$xbehalf."'\n";
                        return \%response;
                }

                if(!can_user_behalf( $session, $user->get_value( "username" ), $behalf_user->get_value( "username" ) ))
                {
                        $response{error} = {
                                        status_code => 403,
                                        x_error_code => "TargetOwnerUnknown",
                                        error_href => "http://eprints.org/sword/error/MediationForbidden",
                                   };
                        $response{verbose_desc} .= "[ERROR] The user '".$user->get_value( "username" )."' cannot deposit on behalf of user '".$behalf_user->get_value("username")."'\n";
                        return \%response;
                }

                $response{depositor} = $user;
                $response{owner} = $behalf_user;
        }
        else
        {
                $response{owner} = $user;
        }

        $response{verbose_desc} .= "[OK] Authentication successful.\n";

        return \%response;
}


1;

######################################################################
=pod

=back

=head1 SEE ALSO

L<https://en.wikipedia.org/wiki/SWORD_(protocol)>

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
