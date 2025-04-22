$c->{guess_doc_type} ||= sub {
	my( $repo, $filename, $mimetype ) = @_;

	my %valid = map { $_ => 1 } $repo->get_types( "document" );

	if( $mimetype )
	{
		my( $major, $minor ) = split '/', $mimetype, 2;
		if( $major =~ /^video|audio|image|text$/ && $valid{$major} )
		{
			return $major;
		}
	}

	if( $filename =~ /\.(pdf|doc|docx|odt)$/i && $valid{text} )
	{
		return "text";
	}
	elsif( $filename =~ /\.(ppt|pptx|odp)$/i && $valid{slideshow} )
	{
		return "slideshow";
	}
	elsif( $filename =~ /\.(zip|tgz|gz)$/i && $valid{archive} )
	{
		return "archive";
	}
	elsif( $filename =~ /\.(xls|xlsx|ods)$/i && $valid{spreadsheet} )
	{
		return "spreadsheet";
	}
	elsif( $filename =~ /\.([^.]+)$/ )
	{
		my $suffix = "\L$1";
		my $format = $repo->config( "mimemap", $suffix );
		return $format if defined $format && $valid{$format};
	}

	return "other";
};

# GNU file
$c->add_trigger( EP_TRIGGER_MEDIA_INFO, sub {
	my( %params ) = @_;

	my $epdata = $params{epdata};
	my $repo = $params{repository};
	my $filename = $params{filename};
	my $filepath = $params{filepath};

	return 0 if defined $epdata->{mime_type};
	return 0 if !defined $filepath;
	return 0 if !defined $repo->config( "executables", "file" );

	# file thinks OpenXML office types are x-zip
	return 0 if $filename =~ /.(docx|pptx|xlsx)$/i;
	return 0 if $filename =~ /\.bib$/; # BibTeX

	if( open(my $fh, "file -b -i ".quotemeta($filepath)."|") )
	{
		my $output = <$fh>;
		close($fh);
		chomp($output);
		my( $mime_type, $opts ) = split /;\s*/, $output, 2;
		$opts = "" if !defined $opts;
		return 0 if !defined $mime_type;
		return 0 if $mime_type =~ /^ERROR:/;
		return 0 if $mime_type eq "application/octet-stream";
		# more file fubar
		return 0 if $mime_type =~ /^very short file/;
		# doc = "application/msword application/msword" ?!
		($epdata->{mime_type}) = split /\s+/, $mime_type;
		my( $charset ) = $opts =~ s/charset=(\S+)//;
		# unsupported in document metadata
		# $epdata->{charset} = $charset if defined $charset;
	}
	else
	{
		$repo->log( "Error executing command file -b -i ".quotemeta($filepath).": $!" );
		return undef;
	}

	return 0;
}, priority => 1000);

# ffmpeg media info
$c->add_trigger( EP_TRIGGER_MEDIA_INFO, sub {
	my( %params ) = @_;

	my $epdata = $params{epdata};
	my $repo = $params{repository};
	my $filename = $params{filename};
	my $filepath = $params{filepath};

	return 0 if !defined $filepath;
	return 0 if !defined $repo->config( "executables", "ffmpeg" );

	if( $epdata->{mime_type} && $epdata->{mime_type} !~ /^audio|video/ )
	{
		return 0;
	}

	my $ffmpeg_log = File::Temp->new;

	$repo->read_exec( $ffmpeg_log, "ffprobe", SOURCE => $filepath );
	seek($ffmpeg_log,0,0);

	my $media = $epdata->{media} ||= {};

	my @streams;
	my $stream;
	while(<$ffmpeg_log>)
	{
		chomp;
		m{^\[STREAM\]} and ($stream={}, next);
		m{^\[/STREAM\]} and (push(@streams, $stream), $stream=undef, next);
		next if !defined $stream;
		my( $k, $v ) = split '=', $_, 2;
		$stream->{$k} = $v;
	}

	foreach my $stream (@streams)
	{
		my $type = $stream->{codec_type};
		next if !defined $type;
		$media->{streams}->{$type} = 1;
		# pick out the seconds (fraction part is frames)
		if( $stream->{duration} && $stream->{duration} =~ /^([0-9]+)/ )
		{
			$media->{duration} = $1;
		}
		if( $type eq "video" && ( !defined $media->{video_codec} || ( $media->{width} < $stream->{width} && $media->{height} < $stream->{height} ) ) )
		{
			my $stream_width = $stream->{width};
			my $stream_height = $stream->{height};
			if( $stream->{rotation} =~ m/^-?(90|270)$/){
				#video is rotated 90deg
				$stream_width = $stream->{height};
				$stream_height = $stream->{width};
			}
			$media->{width} = $stream_width;
			$media->{height} = $stream_height;
			$media->{video_codec} = $stream->{codec_name};
			$media->{aspect_ratio} = $stream->{display_aspect_ratio};
		}
		elsif( $type eq "audio" )
		{
			$media->{audio_codec} = $stream->{codec_name};
		}
	}

	return 0;
}, priority => 7000);

# by file extension
$c->add_trigger( EP_TRIGGER_MEDIA_INFO, sub {
	my( %params ) = @_;

	my $epdata = $params{epdata};
	my $filename = $params{filename};
	my $repo = $params{repository};

	return 0 if defined $epdata->{mime_type};

	if( $filename=~m/\.([^.]+)$/ )
	{
		my $suffix = "\L$1";
		$epdata->{mime_type} = $repo->config( "mimemap", $suffix );
	}

	return 0;
}, priority => 5000);

# defaults
$c->add_trigger( EP_TRIGGER_MEDIA_INFO, sub {
	my( %params ) = @_;

	my $epdata = $params{epdata};
	my $filename = $params{filename};
	my $repo = $params{repository};

	$epdata->{mime_type} = "application/octet-stream"
		if !defined $epdata->{mime_type};

	$epdata->{format} = $repo->call( "guess_doc_type",
			$repo,
			$filename,
			$epdata->{mime_type},
		) if !defined $epdata->{format};

	return 0;
}, priority => 10000);

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

