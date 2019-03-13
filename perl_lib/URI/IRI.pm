=head1 NAME

URI::IRI

=cut

package URI::IRI;

# Experimental

use strict;
use URI ();

use overload '""' => sub { shift->as_string };

sub new {
    my($class, $uri, $scheme) = @_;
    utf8::upgrade($uri);
    return bless {
	uri => URI->new($uri, $scheme),
    }, $class;
}

sub clone {
    my $self = shift;
    return bless {
	uri => $self->{uri}->clone,
    }, ref($self);
}

sub as_string {
    my $self = shift;
    return $self->{uri}->as_iri;
}

sub AUTOLOAD
{
    use vars qw($AUTOLOAD);
    my $method = substr($AUTOLOAD, rindex($AUTOLOAD, '::')+2);

    # We create the function here so that it will not need to be
    # autoloaded the next time.
    no strict 'refs';
    *$method = sub { shift->{uri}->$method(@_) };
    goto &$method;
}

sub DESTROY {}   # avoid AUTOLOADing it

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

