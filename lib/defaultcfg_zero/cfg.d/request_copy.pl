# The 'Request a copy' feature allows any user to request a copy of a 
# non-OA document by email. This function determines who to send the 
# request to. If, for a given eprint, the function returns undef, 
# the 'Request a copy' button(s) will not be shown.
#
# Tip: if the returned email address is a registered eprints user,
# requests for restricted documents can be handled within EPrints.
$c->{email_for_doc_request} = sub 
{
	my ( $repository, $eprint, $document ) = @_;

	# Uncomment the line below to turn off this feature
	#return undef;

    # Uncomment the line below to use eprint field "contact_email"
    #if( $eprint->is_set("contact_email") ) 
    #{
    #	return $eprint->value("contact_email");
    #}

	# Uncomment the lines below to fall back to the email
	# address of the person who deposited this eprint - beware
	# that this may not always be the author!
	my $user = $eprint->get_user;
	if( defined $user && $user->is_set( "email" ) )
	{
		return $user->value( "email" );
	}

	# Uncomment the line below to fall back to the email
	# address of the archive administrator - think carefully!
	#return $repository->config( "adminemail" );

	# Uncomment the lines below to fall back to a different
	# email address according on the divisions with which
	# the eprint is associated
	#foreach my $division ( @{ $eprint->value( "divisions" ) } )
	#{
	#	if( $division eq "sch_law" )
	#	{
	#		# email address of individual/team within the
	#		# department who will deal with requests
	#		return "enquiries\@law.yourrepository.org";
	#	}
	#	if( $division eq "sch_phy" )
	#	{
	#		# author email address (assumes "id" part of
	#		# creators field used for author email)
	#		if( $eprint->is_set( "creators" ) )
	#		{
	#			my $creators = $eprint->value( "creators" );
	#			my $contact = $creators->[1]; # first author
	#			#my $contact = $creators->[-1]; # last author
	#			return $contact->{id} if defined $contact->{id} && $contact->{id} ne "";
	#		}
	#	}
	#	# ...
	#}

	# 'Request a copy' not available for this eprint
	return undef; 
};

# Define the descriptor you want for the EPrint to appear in the subject line of the request a copy and confirmation emails.
#$c->{get_request_eprint_descriptor} = sub 
#{
#        my ( $eprint ) = @_;
#
#        if( $eprint->is_set("title") )
#        {
#                return $eprint->value("title");
#        }
#        if( $eprint->is_set("publication") )
#        {
#                return $eprint->value("publication");
#        }
#        return "EPrint ID ".$eprint->id;
#}


# The expiry for the download link for accepted document request (in days)
# $c->{expiry_for_doc_request} = 7;

# The expiry for document requests if they are not responded (in days)
# $c->{expiry_for_unresponded_doc_request} = 90;

# Use a pin-based security model for contact authors responding to
# copy requests?
#
# The pin-based model allows the contact author to respond whether
# they have an EPrints account associated with the specified email
# address or not. The normal repository authentication mechanism is
# not used, instead the presence of a random pin in the querystring
# identifies the contact author and grants access.
#
# $c->{use_request_copy_pin_security} = 1;

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

