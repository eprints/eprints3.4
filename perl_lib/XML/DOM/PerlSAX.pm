package XML::DOM::PerlSAX;
use strict;

BEGIN
{
    if ($^W)
    {
	warn "XML::DOM::PerlSAX has been renamed to XML::Handler::DOM, "
	    "please modify your code accordingly.";
    }
}

use XML::Handler::DOM;
use vars qw{ @ISA };
@ISA = qw{ XML::Handler::DOM };

1; # package return code

__END__

=head1 NAME

XML::DOM::PerlSAX - Old name of L<XML::Handler::BuildDOM>

=head1 SYNOPSIS

 See L<XML::DOM::BuildDOM>

=head1 DESCRIPTION

XML::DOM::PerlSAX was renamed to L<XML::Handler::BuildDOM> to comply
with naming conventions for PerlSAX filters/handlers.

For backward compatibility, this package will remain in existence 
(it simply includes XML::Handler::BuildDOM), but it will print a warning when 
running with I<'perl -w'>.

=head1 AUTHOR

Enno Derksen is the original author.

Send bug reports, hints, tips, suggestions to T.J Mather at
<F<tjmather@tjmather.com>>.

=head1 SEE ALSO

L<XML::Handler::BuildDOM>, L<XML::DOM>


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

