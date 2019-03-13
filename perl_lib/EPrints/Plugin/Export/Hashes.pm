=head1 NAME

EPrints::Plugin::Export::Hashes

=cut

package EPrints::Plugin::Export::Hashes;

use EPrints::Plugin::Export;

@ISA = ( "EPrints::Plugin::Export" );

use strict;


sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new( %params );

	$self->{name} = "Hashes";
	$self->{accept} = [ 'list/document' ];
	$self->{visible} = "staff";
	$self->{suffix} = ".xml";
	$self->{mimetype} = "text/xml";

	return $self;
}


sub output_list
{
	my( $plugin, %opts ) = @_;

	my $session = $plugin->{session};

	if( !defined $opts{fh} )
	{
		$opts{fh} = *STDOUT;
	}

	my @files = ();
	$opts{list}->map( sub {
		my( $session, $dataset, $item ) = @_;

		my $file = find_latest_doc_hash( $session, $item );
		push @files, $file if defined $file;
	} );

	EPrints::Probity::create_log_fh(
		$session,
		\@files,
		$opts{fh} );
}


sub find_latest_doc_hash
{
	my( $session, $doc ) = @_;

	my $id = $doc->get_id;
	my $eprint = $doc->get_eprint;
	if( !defined $eprint )
	{
		$session->get_repository->log( "No eprint for document: $id" );
		return ();
	}
	my $path = $eprint->local_path;

 	opendir CDIR, $path or return;
	my @filesread = readdir CDIR;
	closedir CDIR;

	my $latest;
	foreach my $file ( sort @filesread )
	{
		if( $file =~ m/^$id\.(.*).xsh$/ )
		{
			my $filename = $path."/".$file;
			$latest = $filename;
		}
	}

	return $latest;
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

