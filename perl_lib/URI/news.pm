=head1 NAME

URI::news  # draft-gilman-news-url-01

=cut

package URI::news;  # draft-gilman-news-url-01

require URI::_server;
@ISA=qw(URI::_server);

use strict;
use URI::Escape qw(uri_unescape);
use Carp ();

sub default_port { 119 }

#   newsURL      =  scheme ":" [ news-server ] [ refbygroup | message ]
#   scheme       =  "news" | "snews" | "nntp"
#   news-server  =  "//" server "/"
#   refbygroup   = group [ "/" messageno [ "-" messageno ] ]
#   message      = local-part "@" domain

sub _group
{
    my $self = shift;
    my $old = $self->path;
    if (@_) {
	my($group,$from,$to) = @_;
	if ($group =~ /\@/) {
            $group =~ s/^<(.*)>$/$1/;  # "<" and ">" should not be part of it
	}
	$group =~ s,%,%25,g;
	$group =~ s,/,%2F,g;
	my $path = $group;
	if (defined $from) {
	    $path .= "/$from";
	    $path .= "-$to" if defined $to;
	}
	$self->path($path);
    }

    $old =~ s,^/,,;
    if ($old !~ /\@/ && $old =~ s,/(.*),, && wantarray) {
	my $extra = $1;
	return (uri_unescape($old), split(/-/, $extra));
    }
    uri_unescape($old);
}


sub group
{
    my $self = shift;
    if (@_) {
	Carp::croak("Group name can't contain '\@'") if $_[0] =~ /\@/;
    }
    my @old = $self->_group(@_);
    return if $old[0] =~ /\@/;
    wantarray ? @old : $old[0];
}

sub message
{
    my $self = shift;
    if (@_) {
	Carp::croak("Message must contain '\@'") unless $_[0] =~ /\@/;
    }
    my $old = $self->_group(@_);
    return unless $old =~ /\@/;
    return $old;
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

