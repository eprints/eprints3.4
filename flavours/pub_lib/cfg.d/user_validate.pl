######################################################################
#
# validate_user( $user, $repository, $for_archive ) 
#
######################################################################
# $user 
# - User object
# $repository 
# - Repository object (the current repository)
# $for_archive
# - boolean (see comments at the start of the validation section)
#
# returns: @problems
# - ARRAY of DOM objects (may be null)
#
######################################################################
# Validate a user, although all the fields will already have been
# checked with validate_field so only complex problems need to be
# tested.
#
######################################################################

$c->{validate_user} = sub
{
	my( $user, $repository, $for_archive ) = @_;

	my @problems = ();

	# CHECKS IN HERE

	return( @problems );
};

1;

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

