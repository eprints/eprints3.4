
######################################################################
#
#  Document file upload information
#
######################################################################

# This sets the minimum amount of free space allowed on a disk before EPrints
# starts using the next available disk to store EPrints. Specified in kilobytes.
$c->{diskspace_error_threshold} = 64*1024;

# If ever the amount of free space drops below this threshold, the
# repository administrator is sent a warning email. In kilobytes.
$c->{diskspace_warn_threshold} = 512*1024;

# Disable document "Upload from URL" by default. If you re-enable considering
# validating URLs with "upload_url_validate" configuration below.
$c->{plugins}->{"Screen::EPrint::UploadMethod::URL"}->{params}->{disable} = 1;

# Validate a URL specified for document upload
#$c->{upload_url_validate} = sub {
#        my( $session, $url ) = @_;
#
#        # Only allow HTTPS URLs
#        return if $url !~ /^https:/;
#
#        return $url;
#};


# Add an additional MIME type mapping from file extensions
# $c->{mimemap}->{html} = "text/html";

# Limit maximum files that can be expanded from an archive (e.g. zip file)
# $c->{archive_max_files} = 100;

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

