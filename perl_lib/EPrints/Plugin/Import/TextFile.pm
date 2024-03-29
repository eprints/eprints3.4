=head1 NAME

EPrints::Plugin::Import::TextFile

=cut

package EPrints::Plugin::Import::TextFile;

use Encode;

use strict;

our @ISA = qw/ EPrints::Plugin::Import /;

$EPrints::Plugin::Import::DISABLE = 1;

our %BOM2ENC = map { Encode::encode($_, "\x{feff}") => $_ } qw(
		UTF-8
		UTF-16BE
		UTF-16LE
		UTF-32BE
		UTF-32LE
	);

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	$self->{name} = "Base text input plugin: This should have been subclassed";
	$self->{visible} = "all";

	return $self;
}

sub mime_type { shift->SUPER::mime_type() . '; charset=utf-8' }

sub input_fh
{
	my( $self, %opts ) = @_;

	my $fh = $opts{fh};
	my $is_bom = 0;

	if( $^V gt v5.8.0 and seek( $fh, 0, 1 ) )
	{
		binmode($fh); # should be no-op
		use bytes;

		my $line = <$fh>;
		seek( $fh, 0, 0 )
			or die "Unable to reset file handle after BOM/CRLF read";

		# If the line ends with return add the crlf layer
		if( $line =~ /\r$/ )
		{
			binmode( $fh, ":crlf" );
		}	

		# Detect the Byte Order Mark and set the encoding appropriately
		# See http://en.wikipedia.org/wiki/Byte_Order_Mark
		for(2..4)
		{
			if( defined( my $enc = $BOM2ENC{substr($line,0,$_)} ) )
			{
				$is_bom = 1;
				seek( $fh, $_, 0 );
				binmode($fh, ":encoding($enc)");
				last;
			}
		}
	}

	if( !$is_bom )
	{
		my $enc = "UTF-8";
		if( $opts{encoding} )
		{
			my %available = map { $_ => 1 } Encode->encodings( ":all" );
			$enc = $opts{encoding} if $available{$opts{encoding}};
		}
		binmode($fh, ":encoding($enc)");
	}

	return $self->input_text_fh( %opts );
}

sub input_text_fh
{
	my( $self, %opts ) = @_;

	return undef;
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

