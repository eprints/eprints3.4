######################################################################
#
# EPrints::Apache::AnApache
#
######################################################################
#
#
######################################################################


=pod

=for Pod2Wiki

=head1 NAME

B<EPrints::Apache::AnApache> - Utility methods for talking to mod_perl

=head1 DESCRIPTION

This module provides a number of utility methods for interacting with the
request object.

=head1 CONSTANTS

For backwards compatibility - use C<HTTP_> constants instead of C<:common> 
constants.

=over 4

=item AUTH_REQUIRED

Maps to C<EPrints::Const::HTTP_UNAUTHORIZED>.  Authorization is required 
to access the requested resource.

=item FORBIDDEN 

Maps to C<EPrints::Const::HTTP_FORBIDDEN>.  Access to the requested 
resource is forbidden.

=item SERVER_ERROR

Maps to C<EPrints::Const::HTTP_INTERNAL_SERVER_ERROR>.  Requesting the
resource has caused an internal server error.

=back

=head1 METHODS

=cut

package EPrints::Apache::AnApache;

use EPrints::Const qw( :http );

use Exporter;
@ISA	 = qw(Exporter);
@EXPORT  = qw(OK AUTH_REQUIRED FORBIDDEN DECLINED SERVER_ERROR NOT_FOUND DONE);

use ModPerl::Registry;
use Apache2::Util;
use Apache2::SubProcess;
use Apache2::Connection;
use Apache2::RequestUtil;
use Apache2::MPM;
use Apache2::Directive;

# Backwards compatibility - use HTTP_ constants instead of :common constants
use constant {
	AUTH_REQUIRED => EPrints::Const::HTTP_UNAUTHORIZED,
	FORBIDDEN => EPrints::Const::HTTP_FORBIDDEN,
	SERVER_ERROR => EPrints::Const::HTTP_INTERNAL_SERVER_ERROR,
};

use strict;

######################################################################
=pod

=over 4

=item EPrints::Apache::AnApache::send_http_header( $request )

Send the HTTP header, if needed.

C<$request> is the current Apache request. 

=cut
######################################################################

sub send_http_header
{
	my( $request ) = @_;

	# do nothing!
}

######################################################################
=pod

=item EPrints::Apache::AnApache::header_out( $request, $header, $value )

Set a value in the HTTP headers of the response. C<$request> is the
apache request object, C<$header> is the name of the header and 
C<$value> is the value to give that header.

=cut
######################################################################

sub header_out
{
	my( $request, $header, $value ) = @_;
	
	$request->headers_out->{$header} = $value;
}

######################################################################
=pod

=item $value = EPrints::Apache::AnApache::header_in( $request, $header )

Return the specified HTTP header from the current request.

=cut
######################################################################

sub header_in
{
	my( $request, $header ) = @_;	

	return $request->headers_in->{$header};
}

######################################################################
=pod

=item $request = EPrints::Apache::AnApache::get_request

Return the current Apache request object.

=cut
######################################################################

sub get_request
{
	return EPrints->new->request;
}

######################################################################
=pod

=item $value = EPrints::Apache::AnApache::cookie( $request, $cookieid )

Return the value of the named cookie, or undef if it is not set.

This avoids using CGI, so does not consume the POST data.

=cut
######################################################################

sub cookie
{
	my( $request, $cookieid ) = @_;

	my $cookies = EPrints::Apache::AnApache::header_in( $request, 'Cookie' );

	return unless defined $cookies;

	foreach my $cookie ( split( /;\s*/, $cookies ) )
	{
		my( $k, $v ) = URI::Escape::uri_unescape(split( '=', $cookie, 2 ));
		if( $k eq $cookieid )
		{
			return $v;
		}
	}

	return undef;
}

######################################################################
=pod

=item EPrints::Apache::AnApache::upload_doc_file( $session, $document, $paramid );

Collect a file named $paramid uploaded via HTTP and add it to the 
specified C<$document>.

=cut
######################################################################

sub upload_doc_file
{
	my( $session, $document, $paramid ) = @_;

	my $cgi = $session->get_query;

	my $filename = Encode::decode_utf8( $cgi->param( $paramid ) );

	return $document->upload( 
		$cgi->upload( $paramid ), 
		$filename,
		0, # preserve_path
		-s $cgi->upload( $paramid )
	);	
}

######################################################################
=pod

=item EPrints::Apache::AnApache::upload_doc_archive( $session, $document, $paramid, $archive_format );

Collect an archive file (.ZIP, .tar.gz, etc.) uploaded via HTTP and 
unpack it then add it to the specified document.

=cut
######################################################################

sub upload_doc_archive
{
	my( $session, $document, $paramid, $archive_format ) = @_;

	my $cgi = $session->get_query;

	my $filename = Encode::decode_utf8( $cgi->param( $paramid ) );

	return $document->upload_archive( 
		$cgi->upload( $paramid ), 
		$filename,
		$archive_format );	
}

######################################################################
=pod

=item EPrints::Apache::AnApache::send_status_line( $request, $code, $message )

Send a HTTP status to the client with C<$code> and C<$message>.

=cut
######################################################################

sub send_status_line
{	
	my( $request, $code, $message ) = @_;
	
	if( defined $message )
	{
		$request->status_line( "$code $message" );
	}
	$request->status( $code );
}

######################################################################
=pod

=item EPrints::Apache::AnApache::send_hidden_status_line( $request, $code )

Send a hidden HTTP status to the client with $code.

This is intended for where EPrints already displays a useful error 
message but a 200 HTTP status code is otherwise logged.

=cut
######################################################################

sub send_hidden_status_line
{
        my( $request, $code ) = @_;

        $request->status( $code );
	$request->custom_response( $code, "" );
}

######################################################################
=pod

=item $rc = EPrints::Apache::AnApache::ranges( $r, $maxlength, $chunks )

Populates the byte-ranges in $chunks requested by the client.

C<$maxlength> is the length, in bytes, of the resource.

Returns the appropriate byte-range result code or C<OK> if no C<Range>
header is set.

=cut
######################################################################

sub ranges
{
	my( $r, $maxlength, $chunks ) = @_;

	my $ranges = EPrints::Apache::AnApache::header_in( $r, "Range" );
	return OK if !defined $ranges;

	$ranges =~ s/\s+//g;
	return HTTP_RANGE_NOT_SATISFIABLE if $ranges !~ s/^bytes=//;
	return HTTP_RANGE_NOT_SATISFIABLE if $ranges =~ /[^0-9,\-]/;

	my @ranges = map { [split /\-/, $_] } split(/,/, $ranges);
	return HTTP_RANGE_NOT_SATISFIABLE if !@ranges;

	# handle -500 and 9500-
	# check for broken ranges (in which case we give-up)
	for(@ranges)
	{
		return HTTP_RANGE_NOT_SATISFIABLE if @$_ > 2;
		return HTTP_RANGE_NOT_SATISFIABLE if !length($_->[0]) && !length($_->[1]);
		if( !defined $_->[1] || !length $_->[1] )
		{
			$_->[1] = $maxlength-1;
		}
		if( !length($_->[0]) )
		{
			$_->[0] = $maxlength-$_->[1];
			$_->[1] = $maxlength-1;
		}
		return HTTP_RANGE_NOT_SATISFIABLE if $_->[0] >= $maxlength;
		return HTTP_RANGE_NOT_SATISFIABLE if $_->[1] >= $maxlength;
		return HTTP_RANGE_NOT_SATISFIABLE if $_->[0] > $_->[1];
	}

	@ranges = sort { $a->[0] <=> $b->[0] } @ranges;

	for(my $i = 0; $i < $#ranges;)
	{
		my( $l, $r ) = @ranges[$i,$i+1];
		# left range is superset of right range
		if( $$l[1] >= $$r[1] )
		{
			splice(@ranges,$i+1,1);
		}
		# left range overlaps right range
		elsif( $$l[1] >= $$r[0] )
		{
			$$l[1] = $$r[1];
			splice(@ranges,$i+1,1);
		}
		else
		{
			++$i;
		}
	}

	@$chunks = @ranges;

	return HTTP_PARTIAL_CONTENT;
}

1;

######################################################################
=pod

=back

=head1 COPYRIGHT

=begin COPYRIGHT

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

