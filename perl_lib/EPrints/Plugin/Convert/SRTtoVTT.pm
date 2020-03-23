=head1 NAME

EPrints::Plugin::Convert::SRTtoVTT

=cut

package EPrints::Plugin::Convert::SRTtoVTT;

use strict;

our @ISA = qw( EPrints::Plugin::Convert );

sub new
{
	my( $class, %opts ) = @_;

	my $self = $class->SUPER::new( %opts );

	$self->{name} = "SRT to VTT";
	$self->{visible} = "all";
	$self->{advertise} = 1;

	return $self;
}

sub can_convert
{
        my ($plugin, $doc) = @_;

        # Get the main file name
        my $fn = $doc->get_main() or return ();

        my $mimetype = 'text/vtt';

        my @type = ($mimetype => {
                plugin => $plugin,
                encoding => 'utf-8',
                phraseid => $plugin->html_phrase_id( $mimetype ),
        });

        if( $fn =~ /\.srt$/i )
        {
                return @type;
        }

        return ();
}


sub export
{
	my( $self, $dir, $doc, $type ) = @_;

	my @results;
	foreach my $file ( @{($doc->get_value( "files" ))} )
	{
		my $filename_in = $file->get_value( "filename" );
		next unless $filename_in =~ m/\.srt$/i;
		my $filename_out = $` . ".vtt";

		open( FH_OUT, ">:utf8", "$dir/$filename_out" );
		open( FH_IN, "<:utf8", $file->get_local_copy );
		print FH_OUT "WEBVTT\n\n";
		while( <FH_IN> )
		{
			s/^(\d\d:\d\d:\d\d),(\d\d\d) --> (\d\d:\d\d:\d\d),(\d\d\d)/$1.$2 --> $3.$4/; # replace commas for dots in timestamps
			print FH_OUT $_;
		}
		close( FH_OUT );
		push @results, $filename_out;
	}

	return @results;
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

