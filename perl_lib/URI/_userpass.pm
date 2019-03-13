=head1 NAME

URI::_userpass

=cut

package URI::_userpass;

use strict;
use URI::Escape qw(uri_unescape);

sub user
{
    my $self = shift;
    my $info = $self->userinfo;
    if (@_) {
	my $new = shift;
	my $pass = defined($info) ? $info : "";
	$pass =~ s/^[^:]*//;

	if (!defined($new) && !length($pass)) {
	    $self->userinfo(undef);
	} else {
	    $new = "" unless defined($new);
	    $new =~ s/%/%25/g;
	    $new =~ s/:/%3A/g;
	    $self->userinfo("$new$pass");
	}
    }
    return unless defined $info;
    $info =~ s/:.*//;
    uri_unescape($info);
}

sub password
{
    my $self = shift;
    my $info = $self->userinfo;
    if (@_) {
	my $new = shift;
	my $user = defined($info) ? $info : "";
	$user =~ s/:.*//;

	if (!defined($new) && !length($user)) {
	    $self->userinfo(undef);
	} else {
	    $new = "" unless defined($new);
	    $new =~ s/%/%25/g;
	    $self->userinfo("$user:$new");
	}
    }
    return unless defined $info;
    return unless $info =~ s/^[^:]*://;
    uri_unescape($info);
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

