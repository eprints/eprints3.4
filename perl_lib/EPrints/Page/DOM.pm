=head1 NAME

EPrints::Page::DOM

=cut

######################################################################
#
# EPrints::Page::DOM
#
######################################################################
#
#
######################################################################

package EPrints::Page::DOM;

@ISA = qw/ EPrints::Page /;

use strict;

sub new
{
	my( $class, $repository, $page_dom, %options ) = @_;

	EPrints::Utils::process_parameters( \%options, {
		   add_doctype => 1,
	});

	return bless { repository=>$repository, page_dom=>$page_dom, %options }, $class;
}

sub send
{
	my( $self, %options ) = @_;

	if( !defined $self->{page_dom} ) 
	{
		EPrints::abort( "Attempt to send the same page object twice!" );
	}

	$self->{page} =
		$self->{repository}->xhtml->to_xhtml( $self->{page_dom} );

	$self->SUPER::send( %options );

	EPrints::XML::dispose( $self->{page_dom} );
	delete $self->{page_dom};
}

sub write_to_file
{
	my( $self, $filename, $wrote_files ) = @_;
	
	if( !defined $self->{page_dom} ) 
	{
		EPrints::abort( "Attempt to write the same page object twice!" );
	}

	$self->{page} =
		$self->{repository}->xhtml->to_xhtml( $self->{page_dom} );

	$self->SUPER::write_to_file( $filename );

	if( defined $wrote_files )
	{
		$wrote_files->{$filename} = 1;
	}

	EPrints::XML::dispose( $self->{page_dom} );
	delete $self->{page_dom};
}

sub DESTROY
{
	my( $self ) = @_;

	if( defined $self->{page_dom} )
	{
		EPrints::XML::dispose( $self->{page_dom} );
	}
}

1;


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

