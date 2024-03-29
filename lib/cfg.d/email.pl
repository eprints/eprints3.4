
# If you want to override the way eprints sends email, you can
# set the send_email config option to be a function to use 
# instead.
#
# The function will have to take the following parameters.
# $repository, $langid, $name, $address, $subject, $body, $sig, $replyto, $replytoname
# repository   string   utf8   utf8      utf8      DOM    DOM   string    utf8
#

# $c->{send_email} = \&EPrints::Email::send_mail_via_sendmail;
# $c->{send_email} = \&some_function;

# Uses the smtp_server specified in SystemSettings
$c->{send_email} = \&EPrints::Email::send_mail_via_smtp;


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

