
######################################################################

=item $xhtmlfragment = user_render( $user, $repository )

This subroutine takes a user object and renders the XHTML view
of this user for public viewing.

Takes the L<$user|EPrints::DataObj::User> to render and the current L<$repository|EPrints::Session>.

Returns an $xhtmlfragment (see L<EPrints::XML>).

=cut

######################################################################


$c->{user_render} = sub
{
	my( $user, $repository ) = @_;
	
	my $xml = $repository->xml();

	my $html;	

	my( $info, $p, $a );
	$info = $xml->create_document_fragment;


	# Render the public information about this user.
	$p = $xml->create_element( "p" );
	$p->appendChild( $user->render_citation("brief") );
	# Address, Starting with dept. and organisation...
	if( $user->is_set( "dept" ) )
	{
		$p->appendChild( $xml->create_element( "br" ) );
		$p->appendChild( $user->render_value( "dept" ) );
	}
	if( $user->is_set( "org" ) )
	{
		$p->appendChild( $xml->create_element( "br" ) );
		$p->appendChild( $user->render_value( "org" ) );
	}
	if( $user->is_set( "address" ) )
	{
		$p->appendChild( $xml->create_element( "br" ) );
		$p->appendChild( $user->render_value( "address" ) );
	}
	if( $user->is_set( "country" ) )
	{
		$p->appendChild( $xml->create_element( "br" ) );
		$p->appendChild( $user->render_value( "country" ) );
	}
	$info->appendChild( $p );
	
	if( $user->is_set( "usertype" ) )
	{
		$p = $xml->create_element( "p" );
		$p->appendChild( $repository->html_phrase( "user_fieldname_usertype" ) );
		$p->appendChild( $xml->create_text_node( ": " ) );
		$p->appendChild( $user->render_value( "usertype" ) );
		$info->appendChild( $p );
	}

	## E-mail and URL last, if available.
	if( $user->value( "hideemail" ) ne "TRUE" )
	{
		if( $user->is_set( "email" ) )
		{
			$p = $xml->create_element( "p" );
			$p->appendChild( $user->render_value( "email" ) );
			$info->appendChild( $p );
		}
	}

	if( $user->is_set( "url" ) )
	{
		$p = $repository->create_element( "p" );
		$p->appendChild( $user->render_value( "url" ) );
		$info->appendChild( $p );
	}
		

	return( $info );
};


=head1 COPYRIGHT

=for COPYRIGHT BEGIN

Copyright 2018 University of Southampton.
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

