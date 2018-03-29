
######################################################################
#
# Latest_tool Configuration
#
#  the latest_tool script is used to output the last "n" items 
#  accepted into the repository
#
######################################################################

$c->{latest_tool_modes} = {
	default => { citation => "result" }
};

# Example of a latest_tool mode. This makes a mode=articles option
# which only lists eprints who's type equals "article".
#	
#	articles => {
#		citation => undef,
#		filters => [
#			{ meta_fields => [ "type" ], value => "article" }
#		],
#		max => 20
#	}



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

