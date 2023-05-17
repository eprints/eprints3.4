# set this to 1 if disk free doesn't work on your system
$c->{disable_df} = 0 if !defined $EPrints::SystemSettings::conf->{disable_df};
$c->{executables} ||= {};

# location of executables
{
use Config; # for perlpath
my %executables = (
	  'convert' => '/usr/bin/convert',
	  'tar' => '/bin/tar',
	  'rm' => '/bin/rm',
	  'dvips' => '/usr/bin/dvips',
	  'gunzip' => '/bin/gunzip',
	  'sendmail' => '/usr/sbin/sendmail',
	  'unzip' => '/usr/bin/unzip',
	  'html2text' => '/usr/bin/html2text',
	  'cp' => '/bin/cp',
	  'latex' => '/usr/bin/latex',
	  'perl' => $Config{perlpath},
	  'pdftotext' => '/usr/bin/pdftotext',
	  'wget' => '/usr/bin/wget',
	  'antiword' => '/usr/bin/antiword',
	  'ffmpeg' => '/usr/bin/ffmpeg',
	  'file' => '/usr/bin/file',
	  'doc2txt' => "$c->{base_path}/tools/doc2txt",
	  'unoconv' => '/usr/bin/unoconv',
	  'txt2refs' => "$c->{base_path}/tools/txt2refs",
	  'ffprobe' => '/usr/bin/ffprobe',
	  'cal' => '/usr/bin/cal',
	  'ncal' => '/usr/bin/ncal',
	);
my @paths = EPrints->system->bin_paths;
EXECUTABLE: while(my( $name, $path ) = each %executables)
{
	next if exists $c->{executables}->{$name};
	if( -x $path )
	{
		$c->{executables}->{$name} = $path;
		next EXECUTABLE;
	}
	for(@paths)
	{
		if( -x "$_/$name" )
		{
			$c->{executables}->{$name} = "$_/$name";
			next EXECUTABLE;
		}
	}
}
}

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

