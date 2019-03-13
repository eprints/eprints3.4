=head1 NAME

URI::file::Unix

=cut

package URI::file::Unix;

require URI::file::Base;
@ISA=qw(URI::file::Base);

use strict;
use URI::Escape qw(uri_unescape);

sub _file_extract_path
{
    my($class, $path) = @_;

    # tidy path
    $path =~ s,//+,/,g;
    $path =~ s,(/\.)+/,/,g;
    $path = "./$path" if $path =~ m,^[^:/]+:,,; # look like "scheme:"

    return $path;
}

sub _file_is_absolute {
    my($class, $path) = @_;
    return $path =~ m,^/,;
}

sub file
{
    my $class = shift;
    my $uri = shift;
    my @path;

    my $auth = $uri->authority;
    if (defined($auth)) {
	if (lc($auth) ne "localhost" && $auth ne "") {
	    $auth = uri_unescape($auth);
	    unless ($class->_file_is_localhost($auth)) {
		push(@path, "", "", $auth);
	    }
	}
    }

    my @ps = $uri->path_segments;
    shift @ps if @path;
    push(@path, @ps);

    for (@path) {
	# Unix file/directory names are not allowed to contain '\0' or '/'
	return undef if /\0/;
	return undef if /\//;  # should we really?
    }

    return join("/", @path);
}

1;

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

