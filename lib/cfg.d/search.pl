
# If set to true, this option causes name searches to match the
# starts of surnames. eg. if true then "smi" will match the name
# "Smith".
$c->{match_start_of_name} = 0;

# customise the citation used to give results on the latest page
# nb. This is the "last 7 days" page not the "latest_tool" page.
$c->{latest_citation} = "default";

# This configuration file had got rather large, so has been split
# into the following other config. files:
#   user_review_scope.pl
#   latest_tool.pl
#   issues_search.pl
#   user_search.pl
#   eprint_search_advanced.pl
#   eprint_search_simple.pl


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

