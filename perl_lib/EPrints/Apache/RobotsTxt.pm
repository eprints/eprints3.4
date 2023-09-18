######################################################################
#
# EPrints::Apache::RobotsTxt
#
######################################################################
#
#
######################################################################

=pod

=for Pod2Wiki

=head1 NAME

B<EPrints::Apache::RobotsTxt> - Generates a dynamic robots.txt.

=head1 DESCRIPTION

Generate a dynamic output for request of F</robots.txt>

=head1 METHODS

=cut

package EPrints::Apache::RobotsTxt;

use EPrints::Apache::AnApache; # exports apache constants

use strict;
use warnings;

######################################################################
=pod

=over 4

=item $rc = EPrints::Apache::RobotsTxt::handler( $r )

Handler for managing EPrints requests for dynamically generated
F<robots.txt>.

=cut
######################################################################

sub handler
{
	my( $r ) = @_;

	my $repository = $EPrints::HANDLE->current_repository;


	my $langid = EPrints::Session::get_session_language( $repository, $r );
	my @static_dirs = $repository->get_static_dirs( $langid );
	my $robots;

	foreach my $static_dir ( @static_dirs )
	{
		my $file = "$static_dir/robots.txt";
		next if( !-e $file );
		
		open( ROBOTS, $file ) || EPrints::abort( "Can't read $file: $!" );
		$robots = join( "", <ROBOTS> );
		close ROBOTS;
		last;
	}	
	if( !defined $robots )
	{
		my $http_cgiroot = $repository->config( 'http_cgiroot' );
		my $https_cgiroot = $repository->config( 'https_cgiroot' ); 
		$robots = <<END;
User-agent: *
Disallow: $http_cgiroot/
END
		if( $http_cgiroot ne $https_cgiroot )
		{
			$robots .= "\nDisallow: $https_cgiroot/";
		}
	}

	my @lines = split( '\n', $robots );
	my $lineno = 0;
	my $default_ua_config = "";
	while ( lc( $lines[$lineno] ) !~ /user-agent: \*/ )
	{
		$lineno++;
	}
	$lineno++;
	while ( $lines[$lineno] !~ /^\s*$/ )
	{
		$default_ua_config .= $lines[$lineno] ."\n";
		$lineno++;
	}

	my $crawl_delay_default_secs = $repository->config( 'robotstxt', 'crawl_delay', 'default_seconds' ) || 0;
	my $crawl_delay_secs = $repository->config( 'robotstxt', 'crawl_delay', 'seconds' ) || 10;
	my $crawl_delay_uas = $repository->config( 'robotstxt', 'crawl_delay', 'user_agents' ) || [];
	
	$robots .= "\n" if $crawl_delay_default_secs || EPrints::Utils::is_set( $crawl_delay_uas );
	
	foreach my $ua ( @$crawl_delay_uas )
	{
		$robots .= "User-agent: $ua\n";
	}
	if ( EPrints::Utils::is_set( $crawl_delay_uas ) )
	{
		$robots .= "$default_ua_config" . "Crawl-delay: $crawl_delay_secs\n\n";	
	}

	if( $crawl_delay_default_secs )
	{
		$robots .= "User-agent: *\nCrawl-delay: $crawl_delay_default_secs\n\n";
	}

	my $sitemap = "Sitemap: ".$repository->config( 'base_url' )."/sitemap.xml";

	# Only add standard sitemap if it is not already added.
	if ( $robots !~ m/$sitemap/ )
	{
		# Add a new line to separate Sitemap line if necessary
		$robots .= "\n" unless substr( $robots, -2 ) eq "\n\n";
		$robots .= $sitemap;
	}

	binmode( *STDOUT, ":utf8" );
	$repository->send_http_header( "content_type"=>"text/plain; charset=UTF-8" );
	print $robots;

	return DONE;
}


1;

######################################################################
=pod

=back

=head1 COPYRIGHT

=befin COPYRIGHT

Copyright 2023 University of Southampton.
EPrints 3.4 is supplied by EPrints Services.

http://www.eprints.org/eprints-3.4/

=end COPYRIGHT

=begin LICENSE

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

=end LICENSE

