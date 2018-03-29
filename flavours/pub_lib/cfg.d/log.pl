
# Internal log handling
#  Enables a hook into Apache to catch logging events and
#  record them directly into the eprints database for usage analysis

# set this to 1 to enable log handling
# (then run generate_apacheconf and restart apache)
$c->{loghandler}->{enable} = 1;

# Log timings on submissions. 
# This feature creates a log file in the eprints var directory
# which logs timestamps of users doing the submission process. It's
# useful for us to monitor time taken on various pages in the submission
# process and maybe you want to to...
# $c->{log_submission_timing} = 1; 



######################################################################
#
# log( $repository, $message )
#
######################################################################
# $repository 
# - repository object
# $message 
# - log message string
#
# returns: nothing 
#
######################################################################
# This method is called to log something important. By default it 
# sends everything to STDERR which means it ends up in the apache
# error log ( or just stderr for the command line scripts in bin/ )
# If you want to write to a file instead, or add extra information 
# such as the name of the repository, this is the place to do it.
#
######################################################################

$c->{log} = sub
{
	my( $repository, $message ) = @_;

	print STDERR $message."\n";

	# You may wish to use this line instead if you have many repositories, but if you
	# only have on then it's just more noise.
	#print STDERR "[".$repository->get_id()."] ".$message."\n";
};



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

