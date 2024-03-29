# These configuration variables are mostly unused and should be deprecated.

{
	my $uri = URI->new( "http://" );
        if( EPrints::Utils::is_set( $c->{securehost} ) )
        {
                $uri->scheme( "https" );
                $uri->host( $c->{securehost} );
                $uri->port( $c->{secureport} );
                $uri = $uri->canonical;
                $uri->path( $c->{https_root} );
        }
        else
        {
                $uri->scheme( "http" );
                $uri->host( $c->{host} );
                $uri->port( $c->{port} );
                $uri = $uri->canonical;
                $uri->path( $c->{http_root} );
        }

# EPrints base URL without trailing slash
	$c->{base_url} = "$uri";
# CGI base URL without trailing slash
	$c->{perl_url} = "$uri/cgi";
# Uncomment to keep URI for eprint items as http or different to base_url.
# May need editing, if repository on unusual port number, not on the root path or host is unset because HTTPS everywhere is configured.
	#$c->{uri_url} = "http://" . $c->{host};
}

# If you don't want EPrints to respond to a specific URL add it to the
# exceptions here. Each exception is matched against the uri using regexp:
#  e.g. /myspecial/cgi
# Will match http://yourrepo/myspecial/cgi
#$c->{rewrite_exceptions} = [];

#if turned on, the abstract page url will be: http://domain.com/id/eprint/43/. This format helps google scholar to index eprints repository.
#if turned off: http://domain.com/43/
$c->{use_long_url_format} = 0;

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

