
######################################################################
#
# Dynamic Template
#
# If you use a dynamic template then this function is called every
# time a page is served to generate dynamic parts of it.
# 
# The dynamic template feature may be disabled to reduce server load.
#
# When enabling/disabling it, run 
# generate_apacheconf
# generate_static
# generate_views
# generate_abstracts
#
######################################################################

$c->{dynamic_template}->{enable} = 1;

# This method is called for every page to add/refine any parts that are
# specified in the template as <epc:pin ref="name" />

#$c->{dynamic_template}->{function} = sub {
#	my( $repository, $parts ) = @_;
#
#};

# To support backwards-compatibility the new-style key tools plugins are
# included here
$c->{plugins}->{"Screen::Login"}->{appears}->{key_tools} = 100;
$c->{plugins}->{"Screen::Register"}->{actions}->{register}->{appears}->{key_tools} = 150;
$c->{plugins}->{"Screen::Logout"}->{appears}->{key_tools} = 10000;
$c->{plugins}->{"Screen::Admin::Config::Edit::XPage"}->{actions}->{edit}->{appears}->{key_tools} = 1250;
$c->{plugins}->{"Screen::Admin::Phrases"}->{actions}->{edit}->{appears}->{key_tools} = 1350;
$c->{plugins}->{"Screen::OtherTools"}->{appears}->{key_tools} = 20000;

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

