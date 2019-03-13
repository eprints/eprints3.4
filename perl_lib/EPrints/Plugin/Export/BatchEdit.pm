=head1 NAME

EPrints::Plugin::Export::BatchEdit

=cut

package EPrints::Plugin::Export::BatchEdit;

use EPrints::Plugin::Export::Tool;

@ISA = ( "EPrints::Plugin::Export::Tool" );

use strict;

sub new
{
	my( $class, %opts ) = @_;

	my $self = $class->SUPER::new( %opts );

	$self->{name} = "Batch Edit";
	$self->{accept} = [ 'list/eprint' ];
	$self->{visible} = "staff";
	$self->{suffix} = ".html";
	$self->{mimetype} = "text/html; charset=utf-8";
	
	return $self;
}


sub output_list
{
	my( $plugin, %opts ) = @_;

	my $session = $plugin->{session};

	my $list = $opts{list};

    $list = EPrints::List->new(
        repository => $session, 
        dataset => $list->{dataset},
        ids=> $list->get_ids,
        keep_cache => 1,
    );

	my $uri = URI->new("");
	$uri->path( $session->config( "rel_cgipath" ) . "/users/home" );
	$uri->query_form(
		screen => "BatchEdit",
		cache => $list->get_cache_id,
	);

	if( $session->get_online )
	{
		$session->redirect( $uri );
	}
	else
	{
		$uri = URI->new_abs( $uri, $session->config( "http_url" ));
		if( $opts{fh} )
		{
			print {$opts{fh}} "$uri\n";
		}
		else
		{
			return "$uri";
		}
	}

	return "";
}

1;

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

