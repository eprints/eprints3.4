
######################################################################
#
# User Roles
#
#  Here you can configure which different types of user are 
#  parts of the system they are allowed to use.
#
######################################################################

	
$c->{user_roles}->{user} = [qw{
	general
	edit-own-record
	saved-searches
	set-password
	deposit
	change-email
}];

$c->{user_roles}->{editor} = [qw{
	general
	edit-own-record
	saved-searches
	set-password
	deposit
	change-email
	editor
	view-status
	staff-view
}];

$c->{user_roles}->{admin} = [qw{
	general
	edit-own-record
	saved-searches
	set-password
	deposit
	change-email
	editor
	view-status
	staff-view
	admin
	edit-config
}];
# Note -- nobody has the very powerful "toolbox" or "rest" roles, by default!

# Use this to set public privilages. 
$c->{public_roles} = [qw{
	+eprint/archive/rest/get
	+subject/rest/get
}];

$c->{user_roles}->{minuser} = [qw{
	general
	edit-own-record
	saved-searches
	set-password
	lock-username-to-email
}];

# If you want to add additional roles to the system, you can do it here.
# These can be useful to create "hats" which can be given to a user via
# the roles field. You can also override the default roles.
#
#$c->{roles}->{"approve-hat"} = [
#	"eprint/buffer/view:editor",
#	"eprint/buffer/summary:editor",
#	"eprint/buffer/details:editor",
#	"eprint/buffer/move_archive:editor",
#];



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

