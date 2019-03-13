=head1 NAME

URI::ftp

=cut

package URI::ftp;

require URI::_server;
require URI::_userpass;
@ISA=qw(URI::_server URI::_userpass);

use strict;

sub default_port { 21 }

sub path { shift->path_query(@_) }  # XXX

sub _user     { shift->SUPER::user(@_);     }
sub _password { shift->SUPER::password(@_); }

sub user
{
    my $self = shift;
    my $user = $self->_user(@_);
    $user = "anonymous" unless defined $user;
    $user;
}

sub password
{
    my $self = shift;
    my $pass = $self->_password(@_);
    unless (defined $pass) {
	my $user = $self->user;
	if ($user eq 'anonymous' || $user eq 'ftp') {
	    # anonymous ftp login password
            # If there is no ftp anonymous password specified
            # then we'll just use 'anonymous@'
            # We don't try to send the read e-mail address because:
            # - We want to remain anonymous
            # - We want to stop SPAM
            # - We don't want to let ftp sites to discriminate by the user,
            #   host, country or ftp client being used.
	    $pass = 'anonymous@';
	}
    }
    $pass;
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

