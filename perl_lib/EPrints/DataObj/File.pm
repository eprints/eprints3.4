######################################################################
#
# EPrints::DataObj::File
#
######################################################################
#
#
######################################################################

=pod

=for Pod2Wiki

=head1 NAME

B<EPrints::DataObj::File> - a stored file

=head1 DESCRIPTION

This class contains the technical metadata associated with a file. A 
file is a sequence of bytes stored in the storage layer (a "stored 
object"). Utility methods for storing and retrieving the stored object 
from the storage layer are made available.

Revision numbers on File work slightly differently to other objects. 
A File is only revised when it's stored object is changed and not when 
changes to it's metadata are made.

This class is a subclass of L<EPrints::DataObj::SubObject>.

=head1 CORE METADATA FIELDS

=over 4

=item fileid (counter)

Unique identifier for this file.

=item datasetid (id)

Id of the dataset of the parent object.

=item objectid (int)

Id of the parent object.

=item filename (id)

Name of the file (may contain directory separators).

=item mime_type (id)

MIME type of the file (e.g. "image/png").

=item hash (id)

Check sum of the file.

=item hash_type (id)

Name of check sum algorithm used (e.g. "MD5").

=item filesize (bigint)

Size of the file in bytes.

=item mtime (timestamp)

Last modification time of the file.

=item url (url)

Virtual field for storing the file's URL.

=item data (base64)

Virtual field for storing the file's content.

=back

=head1 REFERENCES AND RELATED OBJECTS

None.

=head1 INSTANCES VARIABLES

See L<EPrints::DataObj|EPrints::DataObj#INSTANCE_VARIABLES>.

=head1 METHODS

=cut
######################################################################

package EPrints::DataObj::File;

@ISA = ( 'EPrints::DataObj::SubObject' );

use EPrints;
use Digest::MD5;
use MIME::Base64 ();

use strict;

######################################################################
=pod

=head2 Constructor Methods

=cut
######################################################################

######################################################################
=pod

=over 4

=item $dataobj = EPrints::DataObj::File->new_from_filename( $session, $dataobj, $filename )

Convenience method to return an existing file object for C<$filename> 
stored in C<$dataobj>.

Returns C<undef> if no such record exists.

=cut
######################################################################

sub new_from_filename
{
	my( $class, $repo, $dataobj, $filename ) = @_;
	
	return undef if !EPrints::Utils::is_set( $filename );

	my $dataset = $repo->dataset( $class->get_dataset_id );

	my $results = $dataset->search(
		filters => [
			{
				meta_fields => [qw( datasetid )],
				value => $dataobj->get_dataset->base_id,
				match => "EX",
			},
			{
				meta_fields => [qw( objectid )],
				value => $dataobj->id,
				match => "EX",
			},
			{
				meta_fields => [qw( filename )],
				value => $filename,
				match => "EX",
			},
		]);

	return $results->item( 0 );
}


######################################################################
=pod

=item $dataobj = EPrints::DataObj::File->create_from_data( $session, $data, $dataset )

Returns a new file record using C<$data> and the file C<$dataset>.

Private data elements:

 _content - content to pass to L</set_file>.
 _filepath - path to source file used for improved mime-type detection

=cut
######################################################################

sub create_from_data
{
	my( $class, $session, $data, $dataset ) = @_;

	my $content = delete $data->{_content} || delete $data->{_filehandle};
	my $filepath = delete $data->{_filepath};

	# if things go wrong later filesize will be zero
	my $filesize = $data->{filesize};
	$data->{filesize} = 0;

	if( !EPrints::Utils::is_set( $data->{mime_type} ) )
	{
		$session->run_trigger( EPrints::Const::EP_TRIGGER_MEDIA_INFO,
			filepath => $filepath,
			filename => $data->{filename},
			epdata => my $media_info = {}
		);
		$data->{mime_type} = $media_info->{mime_type};
	}

	my $self;

	my $ok = 1;
	# read from filehandle/scalar etc.
	if( defined( $content ) )
	{
		EPrints->abort( "Must defined filesize when using _content" ) if !defined $filesize;

		$self = $class->SUPER::create_from_data( $session, $data, $dataset );
		return if !defined $self;

		$ok = defined $self->set_file( $content, $filesize );
	}
	# read from XML (Base64 encoded)
	elsif( EPrints::Utils::is_set( $data->{data} ) )
	{
		$self = $class->SUPER::create_from_data( $session, $data, $dataset );
		return if !defined $self;

		use bytes;
		my $data = MIME::Base64::decode( delete $data->{data} );
		$ok = defined $self->set_file( \$data, length($data) );
	}
	# read from a URL
	elsif( EPrints::Utils::is_set( $data->{url} ) )
	{
		$self = $class->SUPER::create_from_data( $session, $data, $dataset );
		return if !defined $self;

		my $tmpfile = File::Temp->new;

		my $r = EPrints::Utils::wget( $session, $data->{url}, $tmpfile );
		if( $r->is_success )
		{
			seek( $tmpfile, 0, 0 );
			$ok = $self->set_file( $tmpfile, -s $tmpfile );
		}
		else
		{
			$session->get_repository->log( "Failed to retrieve $data->{url}: " . $r->code . " " . $r->message );
			$ok = 0;
		}
	}
	else
	{
		$data->{filesize} = $filesize; # callers responsibility
		$self = $class->SUPER::create_from_data( $session, $data, $dataset );
		return if !defined $self;
	}

	# content write failed
	if( !$ok )
	{
		$self->remove();
		return undef;
	}

	$self->commit();

	return $self;
}


######################################################################
=pod

=back

=head2 Class Methods

=cut
######################################################################

######################################################################
=pod

=over 4

=item $fields = EPrints::DataObj::File->get_system_field_info

Returns an array describing the system metadata fields of the file 
dataset.

=cut
######################################################################

sub get_system_field_info
{
	my( $class ) = @_;

	return
	( 
		{ name=>"fileid", type=>"counter", required=>1, import=>0, show_in_html=>0,
			can_clone=>0, sql_counter=>"fileid" },

		{ name=>"datasetid", type=>"id", text_index=>0, import=>0,
			can_clone=>0 }, 

		{ name=>"objectid", type=>"int", import=>0, can_clone=>0 }, 

		{ name=>"filename", type=>"id", },

		{ name=>"mime_type", type=>"id", sql_index=>0, },

		{ name=>"hash", type=>"id", maxlength=>64, },

		{ name=>"hash_type", type=>"id", maxlength=>32, },

		{ name=>"filesize", type=>"bigint", sql_index=>0,
			render_value => \&render_filesize },

		{ name=>"mtime", type=>"timestamp", },

		{ name=>"url", type=>"url", virtual=>1 },

		{ name=>"data", type=>"base64", virtual=>1 },

		{
			name=>"copies", type=>"compound", multiple=>1, export_as_xml=>0,
			fields=>[{
				sub_name=>"pluginid",
				type=>"id",
			},{
				sub_name=>"sourceid",
				type=>"id",
			}],
		},
	);
}


######################################################################
=pod

=item $dataset = EPrints::DataObj::File->get_dataset_id

Returns the ID of the L<EPrints::DataSet> object to which this record 
belongs.

=cut
######################################################################

sub get_dataset_id
{
	return "file";
}


######################################################################
=pod

=back

=head2 Object Methods

=cut
######################################################################

######################################################################
=pod

=over 4

=item $new_file = $file->clone( $parent )

Clone the file object (including contained files) and return the new 
object. Uses C<$parent> to set the C<objectid> of the cloned file data
object, in case this needs to be different to the original.

=cut
######################################################################

sub clone
{
	my( $self, $parent ) = @_;

	my $data = EPrints::Utils::clone( $self->{data} );

	$data->{objectid} = $parent->get_id;
	$data->{_parent} = $parent;

	my $new_file = $self->{dataset}->create_object( $self->{session}, $data );
	return undef if !defined $new_file;

	my $storage = $self->{session}->get_storage;

	my $rc = 1;

	$rc &&= $storage->open_write( $new_file );
	$rc &&= $self->get_file( sub { $storage->write( $new_file, $_[0] ) } );
	$rc &&= $storage->close_write( $new_file );

	if( !$rc )
	{
		$new_file->remove;
		return undef;
	}

	return $new_file;
}


######################################################################
=pod

=item $success = $file->remove

Delete the file data object and the file it stores.

Returns boolean depending on the success of removing this file.

=cut
######################################################################

sub remove
{
	my( $self ) = @_;

	$self->SUPER::remove();

	$self->get_session->get_storage->delete( $self );
}


######################################################################
=pod

=item $file->update( $epdata )

Updates the metadata for the file with C<$epdata>.

=cut
######################################################################

sub update
{
	my( $self, $epdata ) = @_;

	my $content = delete $epdata->{_content};
	my $filesize = delete $epdata->{filesize};

	$self->SUPER::update( $epdata );

	$self->set_file(
			$content,
			$filesize
		) if defined $content;
}


######################################################################
=pod

=item $filename = $file->get_local_copy

Returns the name of a local copy of the file (may be a L<File::Temp> 
object).

Uses L<EPrints::Storage#get_local_copy> which in turn calls the 
configured local storage plugin.

=cut
######################################################################

sub get_local_copy
{
	my( $self ) = @_;

	return $self->get_session->get_storage->get_local_copy( $self );
}


######################################################################
=pod

=item $filename = $file->get_remote_copy

Returns the name of a remote copy of the file (may be a L<File::Temp>
object).

Uses L<EPrints::Storage#get_local_copy> which in turn calls the
configured remote storage plugin.

=cut
######################################################################

sub get_remote_copy
{
	my( $self ) = @_;

	return $self->get_session->get_storage->get_remote_copy( $self );
}

######################################################################
=pod

=item $success = $file->add_file( $filepath, $filename [, $preserve_path ] )

Reads and stores the contents of C<$filepath> at C<$filename>.

If C<$preserve_path> is not C<true> will strip any leading path in 
C<$filename>.

Returns a boolean depending on the success of adding the file.

=cut
######################################################################

sub add_file
{
	my( $self, $filepath, $filename, $preserve_path ) = @_;

	open(my $fh, "<", $filepath) or return 0;
	binmode($fh);

	my $rc = $self->upload( $fh, $filename, -s $filepath, $preserve_path );

	close($fh);

	return $rc;
}


######################################################################
=pod

=item $bytes = $file->upload( $filehandle, $filename, $filesize [, $preserve_path ] )

Reads and stores the data from C<$filehandle> at C<$filename> at the 
next revision number.

If C<$preserve_path> is not C<true> will strip any leading path in 
C<$filename>.

Returns the number of bytes read from $filehandle or undef on failure.

=cut
######################################################################

sub upload
{
	my( $self, $fh, $filename, $filesize, $preserve_path ) = @_;

	unless( $preserve_path )
	{
		$filename =~ s/^.*\///; # Unix
		$filename =~ s/^.*\\//; # Windows
	}

	$self->set_value( "filename", $filename );

	$filesize = $self->set_file( $fh, $filesize );
	
	$self->commit();

	return $filesize;
}


######################################################################
=pod

=item $success = $file->write_copy( $filename )

Write a copy of this file to C<$filename>.

Returns C<true> if the written file contains the same number of bytes 
as the stored file.

=cut
######################################################################

sub write_copy
{
	my( $self, $filename ) = @_;

	open(my $out, ">", $filename) or return 0;

	my $rc = $self->write_copy_fh( $out );

	close($out);

	return $rc;
}


######################################################################
=pod

=item $success = $file->write_copy_fh( $filehandle )

Write a copy of this file to C<$filehandle>.

Returns boolean depending on success of writing copy of file to the
file handle.

=cut
######################################################################

sub write_copy_fh
{
	my( $self, $out ) = @_;

	return $self->get_file(sub {
		print $out $_[0]
	});
}


######################################################################
=pod

=item $md5 = $file->generate_md5

Calculates and returns the MD5 for this file.

=cut
######################################################################

sub generate_md5
{
	my( $self ) = @_;

	my $md5 = Digest::MD5->new;

	$self->get_file(sub {
		$md5->add( $_[0] )
	});

	return $md5->hexdigest;
}


######################################################################
=pod

=item $md5 = $file->update_md5

Generates MD5 and sets C<hash> and C<has_type> (as C<MD5>) for this 
file data object.

=cut
######################################################################

sub update_md5
{
	my( $self ) = @_;

	my $md5 = $self->generate_md5;

	$self->set_value( "hash", $md5 );
	$self->set_value( "hash_type", "MD5" );
}

######################################################################
=pod

=item $digest = $file->generate_sha( [ $alg ] )

Generates a SHA for this file, see L<Digest::SHA> for a list of 
supported algorithms. Defaults to C<256> (SHA-256) if C<$alg> is not
set.

Returns the hex-encoded digest.

=cut
######################################################################

sub generate_sha
{
	my( $self, $alg ) = @_;

	$alg ||= "256";

	my $sha = Digest::SHA->new( $alg );

	$self->get_file(sub {
		$sha->add( $_[0] )
	});

	return $sha->hexdigest;
}

######################################################################
=pod

=item $md5 = $file->update_sha

Generates a SHA for this file, see L<Digest::SHA> for a list of
supported algorithms. Defaults to C<256> (SHA-256) if C<$alg> is not
set. Then sets the C<hash> and c<has_type> for this file data object.

=cut
######################################################################

sub update_sha
{
	my( $self, $alg ) = @_;

	$alg ||= "256";

	my $digest = $self->generate_sha( $alg );

	$self->set_value( "hash", $digest );
	$self->set_value( "hash_type", "SHA-$alg" );
}


######################################################################
=pod

=item $file->to_sax( %opts )

Generate SAX output for file data object and assign to C<Output> of
C<Handler> specified in C<%opts>.

=cut
######################################################################

sub to_sax
{
	my( $self, %opts ) = @_;

	my $handler = $opts{Handler};
	my $dataset = $self->dataset;
	my $name = $dataset->base_id;

	my %Attributes;

	my $uri = $self->uri;
	if( defined $uri )
	{
		$Attributes{'{}id'} = {
				Prefix => '',
				LocalName => 'id',
				Name => 'id',
				NamespaceURI => '',
				Value => $uri,
			};
	}

	$handler->start_element( {
		Prefix => '',
		LocalName => $name,
		Name => $name,
		NamespaceURI => EPrints::Const::EP_NS_DATA,
		Attributes => \%Attributes,
	});

	if( $self->value( "datasetid" ) eq "document" )
	{
		my $doc = $self->parent();
		my $url = $doc->get_url( $self->value( "filename" ) );
		$self->set_value( "url", $url );
	}

	foreach my $field ($dataset->fields)
	{
		next if !$field->property( "export_as_xml" );

		$field->to_sax(
			$field->get_value( $self ),
			%opts
		);
	}

	if( $opts{embed} && !$self->is_set( "data" ) )
	{
		$handler->start_element({
			Prefix => '',
			LocalName => 'data',
			Name => 'data',
			NamespaceURI => EPrints::Const::EP_NS_DATA,
			Attributes => {
				('{}encoding') => {
					Prefix => '',
					LocalName => 'encoding',
					Name => 'encoding',
					NamespaceURI => '',
					Value => 'base64',
				},
			},
		});
		for(my $buffer = "")
		{
			use bytes;
			$self->get_file(sub {
				$_ .= $_[0];

				$handler->characters({
					Data => MIME::Base64::encode_base64( substr($_,0,length($_) - length($_)%57 ) )
				});
				$_ = substr($_,length($_) - length($_)%57);

				1;
			});
			$handler->characters({
				Data => MIME::Base64::encode_base64( $_ )
			});
		}
		$handler->end_element({
			Prefix => '',
			LocalName => 'data',
			Name => 'data',
			NamespaceURI => EPrints::Const::EP_NS_DATA,
		});
	}

	$handler->end_element( {
		Prefix => '',
		LocalName => $name,
		Name => $name,
		NamespaceURI => EPrints::Const::EP_NS_DATA,
	});
}


######################################################################
=pod

=item $file->add_plugin_copy( $plugin, $sourceid )

Add a copy of this file stored using C<$plugin> identified by 
C<$sourceid>.

=cut
######################################################################

sub add_plugin_copy
{
	my( $self, $plugin, $sourceid ) = @_;

	for(@{$self->value( "copies" )})
	{
		return if
			$_->{pluginid} eq $plugin->get_id &&
			$_->{sourceid} eq $sourceid;
	}

	my $copies = EPrints::Utils::clone( $self->get_value( "copies" ) );
	push @$copies, {
		pluginid => $plugin->get_id,
		sourceid => $sourceid,
	};
	$self->set_value( "copies", $copies );
}


######################################################################
=pod

=item $file->remove_plugin_copy( $plugin )

Remove the copy of this file stored using C<$plugin>.

=cut
######################################################################

sub remove_plugin_copy
{
	my( $self, $plugin ) = @_;

	my $copies = EPrints::Utils::clone( $self->get_value( "copies" ) );
	@$copies = grep { $_->{pluginid} ne $plugin->get_id } @$copies;
	$self->set_value( "copies", $copies );
}


######################################################################
=pod

=item $success = $file->get_file( $f, [ $offset, $n ] )

Get the contents of the stored file.

C<$offset> is the position in bytes to start reading from, defaults to 
0.

C<$n> is the number of bytes to read, defaults to C<filesize>.

C<$f> is:

	sub {
		my( $buffer ) = @_;
		...
		return 1;
	}

Returns boolean dependent on whether file was successfully retrieved.

=cut
######################################################################

sub get_file
{
	my( $self, $f, $offset, $n ) = @_;

	$offset = 0 if !defined $offset;
	$n = $self->value( "filesize" ) if !defined $n;

	return $self->{session}->get_storage->retrieve( $self, $offset, $n, $f );
}


######################################################################
=pod

=item $content_length = $file->set_file( $content, $clen )

Write C<$clen> bytes from C<$content> to the file object. Updates 
C<filesize> and C<hash>. You must then call L</commit>) to save these 
changes.

Returns an integer for the content length or C<undef> on failure.

C<$content> may be one of:

 CODEREF - Will be called until it returns empty string ("").
 SCALARREF - A scalar reference to a string of octets that will be written as-is.
 GLOB - Will be treated as a file handle and read with sysread().

=cut
######################################################################

sub set_file
{
	my( $self, $content, $clen ) = @_;

	$self->{session}->get_storage->delete( $self );

	$self->set_value( "filesize", 0 );
	$self->set_value( "hash", undef );
	$self->set_value( "hash_type", undef );

	return 0 if $clen == 0;

	use bytes;
	# on 32bit platforms this will cause wrapping at 2**31, without integer
	# Perl will wrap at some much larger value (so use 64bit O/S!)
#	use integer;

	# calculate the MD5 as the data goes past
	my $md5 = Digest::MD5->new;

	my $f;
	if( ref($content) eq "CODE" )
	{
		$f = sub {
				my $buffer = &$content;
				$md5->add( $buffer );
				return $buffer;
			};
	}
	elsif( ref($content) eq "SCALAR" )
	{
		return 0 if length($$content) == 0;

		my $i = 0;
		$f = sub {
				return "" if $i++;
				$md5->add( $$content );
				return $$content;
			};
	}
	else
	{
		binmode($content);
		$f = sub {
				return "" unless sysread($content,my $buffer,16384);
				$md5->add( $buffer );
				return $buffer;
			};
	}

	my $rlen = do {
		local $self->{data}->{filesize} = $clen;
		$self->{session}->get_storage->store( $self, $f );
	};

	# no storage plugin or plugins failed
	if( !defined $rlen )
	{
		$self->{session}->log( $self->get_dataset_id."/".$self->get_id."::set_file(".$self->get_value( "filename" ).") failed: No storage plugins succeeded" );
		return undef;
	}

	# read failed
	if( $rlen != $clen )
	{
		$self->{session}->log( $self->get_dataset_id."/".$self->get_id."::set_file(".$self->get_value( "filename" ).") failed: expected $clen bytes but actually got $rlen bytes" );
		return undef;
	}

	$self->set_value( "filesize", $rlen );
	$self->set_value( "hash", $md5->hexdigest );
	$self->set_value( "hash_type", "MD5" );

	return $rlen;
}


######################################################################
=pod

=item $content_length = $file->set_file_chunk( $content, $clen, $offset, $total )

Write a chunk of data to the content, overwriting or appending to the 
existing content. See L</set_file> for C<$content> and C<$clen>. 
C<filesize> is updated if C<$offset + $content_length> is greater than 
the current C<filesize>.

C<$offset> is the starting point (in bytes) to write. C<$total> is the 
total size of the file, used to determine where to store the content.

Returns the number of bytes written or C<undef> on failure.

=cut
######################################################################

sub set_file_chunk
{
	my( $self, $content, $clen, $offset, $total ) = @_;

	$self->set_value( "hash", undef );
	$self->set_value( "hash_type", undef );

	my $f;
	if( ref($content) eq "CODE" )
	{
		$f = $content;
	}
	elsif( ref($content) eq "SCALAR" )
	{
		return 0 if length($$content) == 0;

		my $i = 0;
		$f = sub {
				return "" if $i++;
				return $$content;
			};
	}
	else
	{
		binmode($content);
		$f = sub {
				return "" unless sysread($content,my $buffer,16384);
				return $buffer;
			};
	}

	my $rlen = do {
		local $self->{data}->{filesize} = $total;
		$self->{session}->get_storage->store( $self, $f, $offset );
	};

	# no storage plugin or plugins failed
	if( !defined $rlen )
	{
		$self->{session}->log( $self->get_dataset_id."/".$self->get_id."::set_file(".$self->get_value( "filename" ).") failed: No storage plugins succeeded" );
		return undef;
	}

	# read failed
	if( $rlen != $clen )
	{
		$self->{session}->log( $self->get_dataset_id."/".$self->get_id."::set_file(".$self->get_value( "filename" ).") failed: expected $clen bytes but actually got $rlen bytes" );
		return undef;
	}

	my $filesize = $self->value( "filesize" );
	$filesize = 0 if !defined $filesize;
	$self->set_value( "filesize", $offset + $clen )
		if $offset + $clen > $filesize;

	return $rlen;
}


######################################################################
=pod

=item $file->start_element( $data, $epdata, $state )

Consumes a SAX event.  See <EPrints::DataObj#start_element> for more
information.

=cut
######################################################################

sub start_element
{
	my( $self, $data, $epdata, $state ) = @_;

	$self->SUPER::start_element( $data, $epdata, $state );

	if( $state->{depth} == 2 )
	{
		my $attr = $data->{Attributes}->{"{}encoding"};
		if( defined $attr && $data->{LocalName} eq "data" && $attr->{Value} eq "base64" )
		{
			delete $state->{handler};

			$state->{encoding} = $attr->{Value};
			$state->{buffer} = "";
			my $tmpfile = $epdata->{_content} = File::Temp->new();
			binmode($tmpfile);
		}
	}
}


######################################################################
=pod

=item $file->end_element( $data, $epdata, $state )

Ends element from L</start_element>.

=cut
######################################################################

sub end_element
{
	my( $self, $data, $epdata, $state ) = @_;

	if( $state->{depth} == 2 && defined $state->{encoding} )
	{
		my $tmpfile = $epdata->{_content};
		print $tmpfile MIME::Base64::decode_base64( $state->{buffer} );
		seek($tmpfile,0,0);
		delete $state->{encoding};
		delete $state->{buffer};
                $epdata->{filesize} = -s $epdata->{_content} if ( !exists $epdata->{filesize} );
	}

	$self->SUPER::end_element( $data, $epdata, $state );
}


######################################################################
=pod

=item $file->characters( $data, $epdata, $state )

Consumes characters within L</start_element>.

=cut
######################################################################

sub characters
{
	my( $self, $data, $epdata, $state ) = @_;

	$self->SUPER::characters( $data, $epdata, $state );

	if( $state->{depth} == 2 && defined $state->{encoding} )
	{
		my $tmpfile = $epdata->{_content};
		for($state->{buffer})
		{
			use bytes;
			$_ .= $data->{Data};
			$_ =~ s/\s+//g;
			print $tmpfile MIME::Base64::decode_base64( substr($_,0,length($_) - length($_)%4) );
			$_ = substr($_,length($_) - length($_)%4);
		}
	}
}


######################################################################
=pod

=item EPrints::DataObj::File->render_filesize( $repo, $field, $value )

Returns an XHTML DOM fragment, which is either empty if C<$value> is
not set or a human-readable rendering of this file size.

=cut
######################################################################

sub render_filesize
{
	my( $repo, $field, $value ) = @_;

	return $repo->make_doc_fragment if !EPrints::Utils::is_set( $value );
	return $repo->make_text( EPrints::Utils::human_filesize( $value ) );
}


######################################################################
=pod

=item $file->get_url

Returns the URL from which this file can be downloaded.  

Calls L<EPrints::DataObj::Document#get_url> on the parent object for
this file with the C<filename> as a parameter.

=cut
######################################################################

sub get_url
{
	my( $self ) = @_;

	my $doc = $self->parent or return;
	return $doc->get_url( $self->value( "filename" ) );
}


######################################################################
=pod

=item $file->path

Returns the path for this file as it appears as a URL.

=cut
######################################################################

sub path
{
	my( $self ) = @_;

	my $parent = $self->parent;
	return undef if !defined $parent || !defined $parent->path;

	return $parent->path . URI::Escape::uri_escape_utf8( $self->value( "filename" ), "^A-Za-z0-9\-\._~\/" );
}


######################################################################
=pod

=item $file->local_path

Returns the local filesystem path for this file.

=cut
######################################################################

sub local_path
{	
	my( $self ) = @_;

	my $session = $self->get_session;

	if( UNIVERSAL::isa( $session, "EPrints::Repository" ))
    {
        if( defined $session->config( "file_local_path_function" ) && ref( $session->config( "file_local_path_function" ) ) eq "CODE" )
        {
            my $file_local_path_function = $session->config( "file_local_path_function" );
			return $file_local_path_function->( $self );
        }
    }

	my $parent = $self->parent;
	return undef if !defined $parent;

	my $grandparent = $parent->parent;
	return undef if !defined $grandparent;

	if ( $parent->dataset->id eq "document" )
	{
		my $docdir = sprintf "%02d", $parent->get_value( 'pos' );
		return $session->config( 'base_path' ) . "/archives/" . $session->id . "/documents/" . $grandparent->get_value( 'dir' ) . "/" . $docdir . "/" . $self->get_value( 'filename' );
	}
	elsif ( $parent->dataset->id eq "history" )
	{
		return $session->config( 'base_path' ) . "/archives/" . $session->id . "/documents/" . $grandparent->get_value( 'dir' ) . "/revisions/" . $parent->get_value( 'revision' ) . ".xml";
	}

	return undef;
}


1;


######################################################################
=pod

=back

=head1 SEE ALSO

L<EPrints::DataObj> and L<EPrints::DataSet>.

=head1 COPYRIGHT

=begin COPYRIGHT

Copyright 2022 University of Southampton.
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
