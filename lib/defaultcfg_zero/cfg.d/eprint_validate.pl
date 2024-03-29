

######################################################################
#
# validate_eprint( $eprint, $repository, $for_archive ) 
#
######################################################################
#
# $eprint 
# - EPrint object
# $repository 
# - Repository object (the current repository)
# $for_archive
# - boolean (see comments at the start of the validation section)
#
# returns: @problems
# - ARRAY of DOM objects (may be null)
#
######################################################################
# Validate the whole eprint, this is the last part of a full 
# validation so you don't need to duplicate tests in 
# validate_eprint_meta, validate_field or validate_document.
#
######################################################################

$c->{validate_eprint} = sub
{
	my( $eprint, $repository, $for_archive ) = @_;

	my $xml = $repository->xml();

	my @problems = ();

	# If we don't have creators (eg. for a book) then we 
	# must have editor(s). To disable that rule, remove the 
	# following block.	
    #if( !$eprint->is_set( "creators" ) && 
    #	!$eprint->is_set( "editors" ) )
    #{
    #	my $fieldname = $xml->create_element( "span", class=>"ep_problem_field:creators" );
    #	push @problems, $repository->html_phrase( 
    #			"validate:need_creators_or_editors",
    #			fieldname=>$fieldname );
    #}


	return( @problems );
};

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

