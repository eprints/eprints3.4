=head1 NAME

URI::_query

=cut

package URI::_query;

use strict;
use URI ();
use URI::Escape qw(uri_unescape);

sub query
{
    my $self = shift;
    $$self =~ m,^([^?\#]*)(?:\?([^\#]*))?(.*)$,s or die;

    if (@_) {
	my $q = shift;
	$$self = $1;
	if (defined $q) {
	    $q =~ s/([^$URI::uric])/ URI::Escape::escape_char($1)/ego;
	    utf8::downgrade($q);
	    $$self .= "?$q";
	}
	$$self .= $3;
    }
    $2;
}

# Handle ...?foo=bar&bar=foo type of query
sub query_form {
    my $self = shift;
    my $old = $self->query;
    if (@_) {
        # Try to set query string
        my $delim;
        my $r = $_[0];
        if (ref($r) eq "ARRAY") {
            $delim = $_[1];
            @_ = @$r;
        }
        elsif (ref($r) eq "HASH") {
            $delim = $_[1];
            @_ = %$r;
        }
        $delim = pop if @_ % 2;

        my @query;
        while (my($key,$vals) = splice(@_, 0, 2)) {
            $key = '' unless defined $key;
	    $key =~ s/([;\/?:@&=+,\$\[\]%])/ URI::Escape::escape_char($1)/eg;
	    $key =~ s/ /+/g;
	    $vals = [ref($vals) eq "ARRAY" ? @$vals : $vals];
            for my $val (@$vals) {
                $val = '' unless defined $val;
		$val =~ s/([;\/?:@&=+,\$\[\]%])/ URI::Escape::escape_char($1)/eg;
                $val =~ s/ /+/g;
                push(@query, "$key=$val");
            }
        }
        if (@query) {
            unless ($delim) {
                $delim = $1 if $old && $old =~ /([&;])/;
                $delim ||= $URI::DEFAULT_QUERY_FORM_DELIMITER || "&";
            }
            $self->query(join($delim, @query));
        }
        else {
            $self->query(undef);
        }
    }
    return if !defined($old) || !length($old) || !defined(wantarray);
    return unless $old =~ /=/; # not a form
    map { s/\+/ /g; uri_unescape($_) }
         map { /=/ ? split(/=/, $_, 2) : ($_ => '')} split(/[&;]/, $old);
}

# Handle ...?dog+bones type of query
sub query_keywords
{
    my $self = shift;
    my $old = $self->query;
    if (@_) {
        # Try to set query string
	my @copy = @_;
	@copy = @{$copy[0]} if @copy == 1 && ref($copy[0]) eq "ARRAY";
	for (@copy) { s/([;\/?:@&=+,\$\[\]%])/ URI::Escape::escape_char($1)/eg; }
	$self->query(@copy ? join('+', @copy) : undef);
    }
    return if !defined($old) || !defined(wantarray);
    return if $old =~ /=/;  # not keywords, but a form
    map { uri_unescape($_) } split(/\+/, $old, -1);
}

# Some URI::URL compatibility stuff
*equery = \&query;

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

