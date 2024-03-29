=head1 NAME

EPrints::Plugin::Import::Archive

=cut

package EPrints::Plugin::Import::Archive;

use strict;

our @ISA = qw/ EPrints::Plugin::Import /;

$EPrints::Plugin::Import::DISABLE = 1;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	$self->{name} = "Base archive import plugin: This should have been subclassed";
	$self->{visible} = "all";

	return $self;
}

sub input_fh
{
	my( $self, %opts ) = @_;

	my $fh = $opts{fh};

	

}


######################################################################
=pod

=item $success = $doc->add_archive( $file, $archive_format )

$file is the full path to an archive file, eg. zip or .tar.gz 

This function will add the contents of that archive to the document.

=cut
######################################################################

sub add_archive
{
        my( $self, $file, $archive_format ) = @_;

        my $tmpdir = File::Temp->newdir();

        # Do the extraction
        my $rc = $self->{session}->get_repository->exec(
                        $archive_format,
                        DIR => $tmpdir,
                        ARC => $file );
	unlink($file);	
	
	return( $tmpdir );
}

sub create_epdata_from_directory
{
	my( $self, $dir, $single ) = @_;

	my $repo = $self->{repository};
	my $too_many_files = $repo->config( 'archive_max_files' ) || 100;

	my $epdata = $single ?
		{ files => [] } :
		[];

	my $media_info = {};

	eval { File::Find::find( {
		no_chdir => 1,
		wanted => sub {
			return if -d $File::Find::name;
			my $filepath = $File::Find::name;
			my $filename = substr($filepath, length($dir) + 1);

			$media_info = {};
			$repo->run_trigger( EPrints::Const::EP_TRIGGER_MEDIA_INFO,
				filename => $filename,
				filepath => $filepath,
				epdata => $media_info,
				);

			open(my $fh, "<", $filepath) or die "Error opening $filename: $!";
			if( $single )
			{
				push @{$epdata->{files}}, {
					filename => $filename,
					filesize => -s $fh,
					mime_type => $media_info->{mime_type},
					_content => $fh,
				};
				die "Too many files" if @{$epdata->{files}} > $too_many_files
			}
			else
			{
				push @{$epdata}, {
					%$media_info,
					main => $filename,
					files => [{
						filename => $filename,
						filesize => -s $fh,
						mime_type => $media_info->{mime_type},
						_content => $fh,
					}],
				};
				die "Too many files" if @{$epdata} > $too_many_files
			}
		},
	}, $dir ) };

	if( $single )
	{
		# bootstrap the document data from the last file
		$epdata = {
			%$media_info,
			%$epdata,
			main => $epdata->{files}->[-1]->{filename},
		};
	}

	return !$@ ? $epdata : undef;
}

1;

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

