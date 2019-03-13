
# This is a simple demo to show how to add code to redirect certain URLs,
# or to do more clever stuff too.

# EPrints will stop working through the triggers if EP_TRIGGER_DONE is 
#   returned.
# EPrints will stop processing the request if the $o{return_code} is set at 
#   the end of the triggers.

# $c->add_trigger( EP_TRIGGER_URL_REWRITE, sub {
#	my( %o ) = @_;
#
#	if( $o{uri} eq $o{urlpath}."/testpath" )
#	{
#		${$o{return_code}} = EPrints::Apache::Rewrite::redir( $o{request}, "http://totl.net/" );
#		return EP_TRIGGER_DONE;
#	}
# } );


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

