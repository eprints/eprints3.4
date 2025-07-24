

######################################################################
#
# Advanced Options
#
# Don't mess with these unless you really know what you are doing.
#
######################################################################

# If you use the Latex render function and want to use the mimetex
# package rather than the latex->dvi->ps->png route then enable this
# option and put the location of the executable "mimetex.cgi" into 
# SystemSettings.pm
$c->{use_mimetex} = 0;

# This is a list of fields which the user is asked for when registering
# If true then use cookie based authentication.
# Don't use basic login unless you are coming from EPrints 2.
$c->{cookie_auth} = 1;

# If you are setting up a very simple system or 
# are starting with lots of data entry you can
# make user submissions bypass the editorial buffer
# by setting this option:
$c->{skip_buffer} = 0;

# If you have a user that may be posting from a third-party application 
# or maybe you just want to save the hassle of the review stage for 
# certain eprint owners, then set their userid in the following arrayref:
$c->{skip_buffer_owners} = [];

# domain for the login and lang. cookies to be set in.
$c->{cookie_domain} = defined $c->{host} ? $c->{host} : $c->{securehost};

# Set user for request even when using cookie_auth so that username
# appears in Apache access logs. Disabled by default.
$c->{cookie_auth_set_user} = 0;

######################################################################
#
# Timeouts
#
######################################################################

# Time (in hours) to allow a email/password change "pin" to be active.
# Set a time of zero ("0") to make pins never time out.
$c->{pin_timeout} = 24*7; # a week

# Search cache.
#
#   Number of minutes of unuse to timeout a search cache
$c->{cache_timeout} = 10;

#   Maximum lifespan of a cache, in use or not. In hours.
#   ( This will be the length of time an OAI resumptionToken is 
#   valid for ).
$c->{cache_maxlife} = 12;

# Maximum number of persistent cache tables to allow
$c->{cache_max} = 100;

# If a search request contains a 'cache' param referencing a cache that
# does not exist, by default EPrints will automatically re-run the search.
#
# Setting this config option to 1 will prevent the search being re-run,
# and render an error message instead.
# $c->{cache_not_found_no_search} = 1;

######################################################################
# 
# Local sitemap URLs
#
######################################################################

# Adds local sitemap URLs to the repository sitemap.xml file

#$c->add_trigger( EP_TRIGGER_LOCAL_SITEMAP_URLS, sub
#{
#        my( %args ) = @_;
#
#        my( $repository, $urlset ) = @args{qw( repository urlset )};
#
#        $urlset->appendChild( EPrints::Utils::make_sitemap_url( $repository, {
#                loc => $repository->config( "base_url" ).'/view/creators/',
#                changefreq => 'monthly'
#        } ) );
#
#        return EP_TRIGGER_OK;
#});


=head1 COPYRIGHT

=for COPYRIGHT BEGIN

Copyright 2024 University of Southampton.
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

