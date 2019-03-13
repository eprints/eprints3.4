#$c->{optional_filename_sanitise} = sub
#{
#	my ($repo, $filepath) = @_;
#
#	# To sanitise characters that get encoded in HTTP, or for any other reason
#	# Uncomment any of these substitutions to use them or add your own
#
#	#$filepath =~ s!\s!_!g; # convert white space to underscore
#	#$filepath =~ s!\x28!_!g; # convert left bracket to underscore
#	#$filepath =~ s!\x29!_!g; # convert right bracket to underscore
#	#$filepath =~ s!\x40!_!g; # convert at sign to underscore
#
#	return $filepath;
#
#};

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

