

######################################################################
#
# session_init( $repository, $offline )
#
#  Invoked each time a new repository is needed (generally one per
#  script invocation.) $repository is a repository object that can be used
#  to store any values you want. To prevent future clashes, prefix
#  all of the keys you put in the hash with repository.
#
#  If $offline is non-zero, the repository is an `off-line' repository, i.e.
#  it has been run as a shell script and not by the web server.
#
######################################################################

$c->{session_init} = sub
{
	my( $repository, $offline ) = @_;
};


######################################################################
#
# session_close( $repository )
#
#  Invoked at the close of each repository. Here you should clean up
#  anything you did in session_init().
#
######################################################################

$c->{session_close} = sub
{
	my( $repository ) = @_;
};

######################################################################
#
# email_for_doc_request( $repository, $eprint )
#
#  Invoked to determine the contact email address for an eprint. Used
#  by the "request documents" feature
#
######################################################################

=head1 COPYRIGHT

=for COPYRIGHT BEGIN

Copyright 2019 University of Southampton.
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

