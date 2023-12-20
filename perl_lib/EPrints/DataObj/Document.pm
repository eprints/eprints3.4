######################################################################
#
# EPrints::DataObj::Document
#
######################################################################
#
#
######################################################################


=pod

=for Pod2Wiki

=head1 NAME

B<EPrints::DataObj::Document> - A single format of a record.

=head1 DESCRIPTION

Document represents a single format of an EPrint (eg. PDF) - the 
actual file(s) rather than the metadata.

Inherits from L<EPrints::DataObj::SubObject>, which in turn inherits
from L<EPrints::DataObj>.

=head1 CORE METADATA FIELDS

=over 4

=item docid (int)

The unique ID of the document. 

=item rev_number (int)

The revision number of this document record.

=item pos (int)

The position of the document record within those associated with the 
eprint.

=item placement (int)

Placement of the document - the order documents in which should be 
shown.  This may be different to C<pos>, as the C<ultimate_doc_pos> 
may lead to a different ordering.

=item format (namedset)

The format of this document. One of the types of the namedset
c<document>.

=item formatdesc (text)

An additional description of this document. For example the specific 
version of a format.

=item language (namedset)

The ISO 639-1 code of the language of this document. The default 
configuration of EPrints does not set this.

=item security (namedset)

The security type of this document - who can view it. One of the 
types of the namedset C<security>.

=item license (namedset)

The license applied of this document - who can view it. One of the 
types of the namedset C<license>.

=item main (text)

The file which we should link to. For something like a PDF file this is
the only file. For an HTML document with images it would be the name of
the actual HTML file.

=item date_embargo (date)

The date until which the document has restricted access (set by 
C<security>).  At which point the embargo is lifted and C<security>
is set to C<public> and this field set back to C<undef>.

Requires C<bin/lift_embargos> script to be deployed as a cron job.

=item date_embargo_retained (date)

The retained date of any embargo originally placed on this document.
This is updated when a user modifies C<date_embargo> but is not unset
by the C<bin/lift_embargos> script.

=item media (compound)

A compound field containing a description of the document media - dimensions, codec etc.

=item upload_url (longtext)

If document is uploaed from a URL record this URL for reference purposes.

=back

=head1 REFERENCES AND RELATED OBJECTS 

=over 4

=item eprintid (itemref)

The ID number of the eprint to which this document belongs.

=item files (subobject, multiple)

A virtual field which represents the list of files which are part of
this record.

=item relation (relation, multiple)

Predicated relationships between this document and other data objects
within the archive.

=head1 INSTANCE VARIABLES

See L<EPrints::DataObj|EPrints::DataObj#INSTANCE_VARIABLES>.

=back

=head1 METHODS

=cut

package EPrints::DataObj::Document;

@ISA = ( 'EPrints::DataObj::SubObject' );

use EPrints;
use EPrints::Search;

use File::Copy;
use File::Find;
use Cwd;
use Fcntl qw(:DEFAULT :seek);

use URI::Heuristic;

use strict;

# Field to use for unsupported formats (if repository allows their deposit)
$EPrints::DataObj::Document::OTHER = "OTHER";


######################################################################
=pod

=head2 Constructor Methods

=cut
######################################################################

######################################################################
=pod

=over 4
 
=item $doc = EPrints::DataObj::Document::create( $session, $eprint )
 
Create and return a new document belonging to the given C<$eprint> 
object. 

N.B. This creates the document in the database, not just in memory.

=cut
######################################################################

sub create
{
	my( $session, $eprint ) = @_;

	return EPrints::DataObj::Document->create_from_data( 
		$session, 
		{
			_parent => $eprint,
			eprintid => $eprint->get_id
		},
		$session->dataset( "document" ) );
}

######################################################################
=pod

=item $dataobj = EPrints::DataObj::Document::create_from_data( $session, $data, $dataset )

Create document data object from C<$data> provided.

Returns C<undef> if a bad (or no) C<eprintid> specified in C<$data>.

Otherwise calls the parent method in L<EPrints::DataObj>.

=cut
######################################################################

sub create_from_data
{
	my( $class, $session, $data, $dataset ) = @_;
       
	my $eprintid = $data->{eprintid}; 
	$data->{_parent} ||= delete $data->{eprint};

	my $files = $data->{files};
	$files = [] if !defined $files;

	if( !EPrints::Utils::is_set( $data->{main} ) && @$files > 0 )
	{
		$data->{main} = $files->[0]->{filename};
	}

	if( !EPrints::Utils::is_set( $data->{mime_type} ) && @$files > 0 )
	{
		foreach my $file (@$files)
		{
			$data->{mime_type} = $file->{mime_type}, last
				if $file->{filename} eq $data->{main};
		}
	}

	my $document = $class->SUPER::create_from_data( $session, $data, $dataset );

	return undef unless defined $document;

	if( scalar @$files )
	{
		$document->queue_files_modified;
	}

	my $eprint = $document->get_parent;
	if( defined $eprint && !$eprint->under_construction )
	{
		local $eprint->{non_volatile_change} = 1;
		$eprint->set_value( "fileinfo", $eprint->fileinfo );
		$eprint->commit( 1 );
	}

	return $document;
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

=item $fields = EPrints::DataObj::Document->get_system_field_info

Returns an array describing the system metadata of the document 
dataset.

=cut
######################################################################

sub get_system_field_info
{
	my( $class ) = @_;

	return 
	( 
		{ name=>"docid", type=>"counter", required=>1, import=>0, show_in_html=>0, can_clone=>0,
			sql_counter=>"documentid" },

		{ name=>"rev_number", type=>"int", required=>1, can_clone=>0, show_in_html=>0,
			default_value=>1 },

		{ name=>"files", type=>"subobject", datasetid=>"file", multiple=>1 },

		{ name=>"eprintid", type=>"itemref",
			datasetid=>"eprint", required=>1, show_in_html=>0 },

		{ name=>"pos", type=>"int", required=>1 },

		{ name=>"placement", type=>"int", },

		{ name=>"mime_type", type=>"id", volatile=>1, },

		{ name=>"format", type=>"namedset", required=>1, input_rows=>1,
			set_name=>"document", },

		{ name=>"formatdesc", type=>"text", input_cols=>40 },

		{ name=>"language", type=>"namedset", required=>1, input_rows=>1,
			set_name=>"languages" },

		{ name=>"security", type=>"namedset", required=>1, input_rows=>1,
			set_name=>"security" },

		{ name=>"license", type=>"namedset", required=>0, input_rows=>1,
			set_name=>"licenses", "search_input_style" => "default" },

		{ name=>"main", type=>"set", required=>1, options=>[], input_rows=>1,
			input_tags=>\&main_input_tags,
			render_option=>\&main_render_option },

		{ name=>"date_embargo", type=>"date", required=>0,
			min_resolution=>"day" },

		{ name=>"date_embargo_retained", type=>"date", required=>0,
                        min_resolution=>"day" },	

		{ name => "embargo_reason", type => "namedset", set_name => 'embargo_reason', required=>0, input_rows => 1, },

		{ name=>"content", type=>"namedset", required=>0, input_rows=>1,
			set_name=>"content" },

		{ name=>"upload_url", type=>"longtext", required=>0, export_as_xml => 0 },

		{ name=>"relation", type=>"relation", multiple=>1, },

		{
			name => "media",
			type => "compound",
			multiple => 0,
			fields => [
				{ sub_name => "duration", type => "id", sql_index => 0},
				{ sub_name => "audio_codec", type => "id", sql_index => 0},
				{ sub_name => "video_codec", type => "id", sql_index => 0},
				{ sub_name => "width", type => "int", sql_index => 0},
				{ sub_name => "height", type => "int", sql_index => 0},
				{ sub_name => "aspect_ratio", type => "id", sql_index => 0},

				{ sub_name => "sample_start", type => "id", sql_index => 0},
				{ sub_name => "sample_stop", type => "id", sql_index => 0},
			],
		},
	);

}


######################################################################
=pod

=item $defaults = EPrints::DataObj::Document->get_defaults( $session, $data, $dataset )

Returns default values for this data object based on the starting 
C<$data>.

=cut
######################################################################

sub get_defaults
{
	my( $class, $session, $data, $dataset ) = @_;

	$class->SUPER::get_defaults( $session, $data, $dataset );

	#if more than one document dataset, we want the next pos from any of them
	if( $session->can_call( "ultimate_doc_pos" ) )
	{
		$data->{pos} = $session->call( "ultimate_doc_pos", $session->get_database, $data->{eprintid} );
	}
	else #otherwise just get the next one for the document dataset
	{
		$data->{pos} = $session->get_database->next_doc_pos( $data->{eprintid} );
	}

	$data->{placement} = $data->{pos};

	return $data;
}


######################################################################
=pod

=item $dataset = EPrints::DataObj::Document->get_dataset_id

Returns the ID of the L<EPrints::DataSet> object to which this record 
belongs.

=cut
######################################################################

sub get_dataset_id
{
	return "document";
}


######################################################################
=pod

=item $dataset_id = EPrints::DataObj::Document->get_parent_dataset_id

Returns the ID of the parent dataset for a document, (i.e. C<eprint>).

=cut
######################################################################

sub get_parent_dataset_id
{
	"eprint";
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

=item $newdoc = $doc->clone( $eprint )

Attempt to clone this document. Both the document metadata and the
actual files. The clone will be associated with the given C<$eprint>.

Returns to the newly colument document.

=cut
######################################################################

sub clone
{
	my( $self, $eprint ) = @_;
	
	my $data = EPrints::Utils::clone( $self->{data} );

	# cloning within the same eprint, in which case get a new position!
	if( defined $self->parent && $eprint->id eq $self->parent->id )
	{
		$data->{pos} = undef;
	}

	$data->{eprintid} = $eprint->get_id;
	$data->{_parent} = $eprint;

	# First create a new doc object
	my $new_doc = $self->{dataset}->create_object( $self->{session}, $data );
	return undef if !defined $new_doc;
	
	my $ok = 1;

	# Copy files
	foreach my $file (@{$self->get_value( "files" )})
	{
		$file->clone( $new_doc ) or $ok = 0, last;
	}

	if( !$ok )
	{
		$new_doc->remove();
		return undef;
	}

	return $new_doc;
}


######################################################################
=pod

=item $success = $doc->remove

Attempt to completely delete this document. Including derived 
documents such as thumbnails.

Returns boolean dependent on success of deleting document.

=cut
######################################################################

sub remove
{
	my( $self ) = @_;

	# remove dependent objects and relations
	$self->search_related->map(sub {
			my( undef, undef, $doc ) = @_;

			$doc->set_parent( $self->parent );
			if( $doc->has_relation( $self, "isVolatileVersionOf" ) )
			{
				$doc->remove_relation( $self );
				$doc->remove;
			}
			else
			{
				$doc->remove_relation( $self );
				$doc->commit;
			}
		});

	foreach my $file (@{($self->get_value( "files" ))})
	{
		$file->remove();
	}

	# Remove database entry
	my $success = $self->SUPER::remove();

	if( !$success )
	{
		my $db_error = $self->{session}->get_database->error;
		$self->{session}->get_repository->log( "Error removing document ".$self->get_value( "docid" )." from database: $db_error" );
		return( 0 );
	}

	my $eprint = $self->get_parent;
	if( defined $eprint && !$eprint->under_construction )
	{
		$eprint->set_value( "fileinfo", $eprint->fileinfo );
		$eprint->commit();
	}

	return( $success );
}


######################################################################
=pod

=item $eprint = $doc->get_eprint

Returns the eprint this document is associated with.

Alias for:

 $doc->get_parent

=cut
######################################################################

sub get_eprint { &get_parent }
sub get_parent
{
	my( $self, $datasetid, $objectid ) = @_;

	# document without an eprint parent is broken
	return undef if !$self->is_set( "eprintid" );

	$datasetid = "eprint";
	$objectid = $self->get_value( "eprintid" );

	return $self->SUPER::get_parent( $datasetid, $objectid );
}


######################################################################
=pod

=item $url = $doc->get_baseurl

Returns the base URL of the document. 

=cut
######################################################################

sub get_baseurl
{
	my( $self ) = @_;

	my $repo = $self->{session};

	return $repo->config( "base_url" ).$self->path;
}


######################################################################
=pod

=item $boolean = $doc->is_public

Returns C<true> if this document has no security set and is in the 
live archive. Otherwise, returns C<false>.

=cut
######################################################################

sub is_public
{
	my( $self ) = @_;

	my $eprint = $self->get_parent;
	
	return 0 unless( EPrints::Utils::is_set( $self->get_value( "security" ) ) );

	return 0 if( $self->get_value( "security" ) ne "public" );

	return 0 if( $eprint->get_value( "eprint_status" ) ne "archive" );

	return 1;
}


######################################################################
=pod

=item $path = $doc->path

Returns the relative path to the document without specifying any file.

=cut
######################################################################

sub path
{
	my( $self ) = @_;

	my $eprint = $self->parent;
	return undef if !defined $eprint;

	return undef if !defined $eprint->path;

	return sprintf("%s%i/",
		$eprint->path,
		$self->value( "pos" ),
	);
}


######################################################################
=pod

=item $path = $doc->file_path( [ $file ] )

Returns the relative path to C<$file> stored in this document. 
If C<$file> is undefined returns the path to the main file.

This is an efficient shortcut to this:

 my $file = $doc->stored_file( $filename );
 my $path = $file->path;

=cut
######################################################################

sub file_path
{
	my( $self, $file ) = @_;

	my $path = $self->path;
	return undef if !defined $path;

	$file = $self->value( "main" ) if !defined $file;
	return $path if !defined $file;

	return $path . URI::Escape::uri_escape_utf8(
		$file,
		"^A-Za-z0-9\-\._~\/" # don't escape /
	);
}


######################################################################
=pod

=item $url = $doc->get_url( [ $file ] )

Returns the full URL of the document.

If C<$file> is not specified then the main file is used.

=cut
######################################################################

sub get_url
{
	my( $self, $file ) = @_;

	my $path = $self->file_path( $file );
	return undef if !defined $path;

	my $url = $self->{session}->config( 'base_url' ) . '/';

	$url .= 'id/eprint/' if $self->{session}->get_conf( "use_long_url_format");

	$url .= $path;

	return $url;
}


######################################################################
=pod

=item $path = $doc->local_path

DEPRECATED.

Returns the full path of the directory where this document is stored
in the filesystem.

=cut
######################################################################

sub local_path
{
	my( $self ) = @_;

	my $eprint = $self->get_parent();

	if( !defined $eprint )
	{
		$self->{session}->get_repository->log(
			"Document ".$self->get_id." has no eprint (eprintid is ".$self->get_value( "eprintid" )."!" );
		return( undef );
	}	
	
	return( $eprint->local_path()."/".sprintf( "%02d", $self->get_value( "pos" ) ) );
}


######################################################################
=pod

=item %files = $doc->files

Returns a hash, the keys of which are all the files belonging to this
document (relative to L</local_path>). The values are the sizes of the 
files in bytes.

=cut
######################################################################

sub files
{
	my( $self ) = @_;
	
	my %files;

	foreach my $file (@{($self->get_value( "files" ))})
	{
		next unless defined $file->get_value( "filename" );
		$files{$file->get_value( "filename" )} = $file->get_value( "filesize" );
	}

	return( %files );
}

sub _get_files
{
	my( $files, $root, $dir ) = @_;

	my $fixed_dir = ( $dir eq "" ? "" : $dir . "/" );

	# Read directory contents
	opendir CDIR, $root . "/" . $dir or return( undef );
	my @filesread = readdir CDIR;
	closedir CDIR;

	# Iterate through files
	my $name;
	foreach $name (@filesread)
	{
		if( $name ne "." && $name ne ".." )
		{
			# If it's a directory, recurse
			if( -d $root . "/" . $fixed_dir . $name )
			{
				_get_files( $files, $root, $fixed_dir . $name );
			}
			else
			{
				#my @stats = stat( $root . "/" . $fixed_dir . $name );
				$files->{$fixed_dir.$name} = -s $root . "/" . $fixed_dir . $name;
				#push @files, $fixed_dir . $name;
			}
		}
	}

}


######################################################################
=pod

=item $success = $doc->remove_file( $filename )

Attempts to remove the file with C<$filename>. C<$filename> must be 
specified in the format that can be retrieved by L</get_stored_file>.

=cut
######################################################################

sub remove_file
{
	my( $self, $filename ) = @_;
	
	my $fileobj = $self->get_stored_file( $filename );

	if( defined( $fileobj ) )
	{
		$fileobj->remove();

		$self->queue_files_modified;
	}
	else
	{
		$self->{session}->get_repository->log( "Error removing file $filename for doc ".$self->get_value( "docid" ).": $!" );
	}

	return defined $fileobj;
}


######################################################################
=pod

=item $doc->set_main( $main_file )

Sets C<main> for the document to the named C<$main_file> and adjusts 
C<format> and C<mime_type> as necessary. Will not affect the database 
until the document is committed.
 
Unsets C<main> if C<$main_file> is undefined.

=cut
######################################################################

sub set_main
{
	my( $self, $main_file ) = @_;
	
	if( defined $main_file )
	{
		# Ensure that the file exists
		my $fileobj = UNIVERSAL::isa( $main_file, "EPrints::DataObj::File" ) ?
			$main_file :
			$self->stored_file( $main_file );

		# Set the main file if it does
		if( defined $fileobj )
		{
			$self->set_value( "main", $fileobj->value( "filename" ) );
			$self->set_value( "format",
				$self->{session}->call( "guess_doc_type",
					$self->{session},
					$fileobj->value( "filename" ),
					$fileobj->value( "mime_type" )
				) );
			$self->set_value( "mime_type", $fileobj->value( "mime_type" ) );
		}
	}
	else
	{
		# The caller passed in undef, so we unset the main file
		$self->set_value( "main", undef );
	}
}


######################################################################
=pod

=item $filename = $doc->get_main

Returns the filename of the file set as C<main> in this document.

=cut
######################################################################

sub get_main
{
	my( $self ) = @_;

	if( defined $self->{data}->{main} )
	{
		return $self->{data}->{main};
	}

	# If there's only one file then just claim that's
	# the main one!
	my %files = $self->files;
	my @filenames = keys %files;
	if( scalar @filenames == 1 )
	{
		return $filenames[0];
	}

	return;
}


######################################################################
=pod

=item $doc->set_format( $format )

Set format for document to C<$format>. Will not affect the database 
until document is committed. 

Alias for:

 $doc->set_value( "format" , $format );

=cut
######################################################################

sub set_format
{
	my( $self, $format ) = @_;
	
	$self->set_value( "format" , $format );
}


######################################################################
=pod

=item $doc->set_format_desc( $format_desc )

Set format description for document to C<$format_desc>. Will not 
affect the database until document is committed.

Alias for:

 $doc->set_value( "format_desc" , $format_desc );

=cut
######################################################################

sub set_format_desc
{
	my( $self, $format_desc ) = @_;
	
	$self->set_value( "format_desc" , $format_desc );
}


######################################################################
=pod

=item $success = $doc->upload( $filehandle, $filename, [ $preserve_path, $filesize ] )

DEPRECATED - Use L</add_file>, which will automatically identify the 
file type.

Upload the contents of the given C<$filehandle> into this document as
the given C<$filename>.

If C<$preserve_path> then make any subdirectories needed, otherwise 
place this in the top level directory.

=cut
######################################################################

sub upload
{
	my( $self, $filehandle, $filename, $preserve_path, $filesize ) = @_;

	# Get the filename. File::Basename isn't flexible enough (setting 
	# internal globals in reentrant code very dodgy.)

	my $repository = $self->{session}->get_repository;
	if( $filename =~ m/^~/ )
	{
		$repository->log( "Bad filename for file '$filename' in document: starts with ~ (will not add)\n" );
		return 0;
	}
	if( $filename =~ m/\/~/ )
	{
		$repository->log( "Bad filename for file '$filename' in document: contains /~ (will not add)\n" );
		return 0;
	}
	if( $filename =~ m/\/\.\./ )
	{
		$repository->log( "Bad filename for file '$filename' in document: contains /.. (will not add)\n" );
		return 0;
	}
	if( $filename =~ m/^\.\./ )
	{
		$repository->log( "Bad filename for file '$filename' in document: starts with .. (will not add)\n" );
		return 0;
	}
	if( $filename =~ m/^\// )
	{
		$repository->log( "Bad filename for file '$filename' in document: starts with slash (will not add)\n" );
		return 0;
	}

	if( $filename =~ m/^ / )
        {
                $repository->log( "Bad filename for file '$filename' in document: starts with a space (will not add)\n" );
                return 0;
        }

        if( $filename =~ m/ $/ )
        {
                $repository->log( "Bad filename for file '$filename' in document: ends with a space (will not add)\n" );
                return 0;
        }

	$filename = sanitise( $filename );

	if( !$filename )
	{
		$repository->log( "Bad filename in document: no valid characters in file name\n" );
		return 0;
	}

	my $fileobj = $self->add_stored_file(
		$filename,
		$filehandle,
		$filesize
	);

	if( defined $fileobj )
	{
		if( !$self->is_set( "main" ) )
		{
			$self->set_main( $fileobj );
			$self->commit();
		}
		$self->queue_files_modified;
	}

	return defined $fileobj;
}

######################################################################
=pod

=item $fileobj = $doc->add_file( $file, $filename, [ $preserve_path ] )

C<$file> is the full path to a file to be added to the document, with
name C<$filename>. C<$filename> is passed through 
L<EPrints::System#sanitise> before being written.

If C<$preserve_path> is C<tru>e then include path components in 
C<$filename>.

Returns the file object if successfully created or C<undef> on 
failure.

=cut
######################################################################

sub add_file
{
	my( $self, $filepath, $filename, $preserve_path ) = @_;

	my $fileobj = $self->stored_file( $filename );
	$fileobj->remove if defined $fileobj;

	$filename = EPrints->system->sanitise( $filename );
	$filename = (split '/', $filename)[-1] if !$preserve_path;

	open(my $fh, "<", $filepath) or return undef;

	$fileobj = $self->create_subdataobj( "files", {
		_content => $fh,
		_filepath => $filepath,
		filename => $filename,
		filesize => -s $fh,
	});

	close $fh;

	return $fileobj;
}


######################################################################
=pod

=item $success = $doc->upload_archive( $filehandle, $filename, $archive_format )

DEPRECATED - use L</add_archive>.

Upload the file contents provided through C<$filehandle> using the
filename from C<$filename>. How to deal with the specified 
C<$archive_format> (e.g. C<.zip>, C<.tar.gz>) is configured in 
L<EPrints::SystemSettings>. 

=cut
######################################################################

sub upload_archive
{
	my( $self, $filehandle, $filename, $archive_format ) = @_;

	use bytes;

	binmode($filehandle);

	my $zipfile = File::Temp->new();
	binmode($zipfile);

	while(sysread($filehandle, $_, 4096))
	{
		syswrite($zipfile, $_);
	}

	my $rc = $self->add_archive( 
		"$zipfile",
		$archive_format );

	$self->queue_files_modified;

	return $rc;
}

######################################################################
=pod

=item $success = $doc->add_archive( $file, $archive_format )

Adds the contents of that archive C<$file> to the document, where 
C<$archive_format> is the format of the archive file (e.g. C<.zip>,
C<.tar.gz>, etc.)

Returns a boolean dependent on whether the contents of the archive 
file is added to the document's subdirectory on the filesystem.

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
	
	$self->add_directory( "$tmpdir" );

	return( $rc==0 );
}

######################################################################
=pod

=item $success = $doc->add_directory( $directory )

Upload the contents of C<$directory> to this document. This will not 
set the document's C<main> field.

This method expects C<$directory> to have a trailing slash C</>.

Returns boolean depending on success of adding directory to document.

=cut
######################################################################

sub add_directory
{
	my( $self, $directory ) = @_;

	$directory =~ s/[\/\\]?$/\//;

	my $rc = 1;

	if( !-d $directory )
	{
		EPrints::abort( "Attempt to call upload_dir on a non-directory: $directory" );
	}

	File::Find::find( {
		no_chdir => 1,
		wanted => sub {
			return unless $rc and !-d $File::Find::name;
			my $filepath = $File::Find::name;
			my $filename = substr($filepath, length($directory));
			my $stored = $self->add_file( $filepath, $filename, 1 );
			$rc = defined $stored;
		},
	}, $directory );

	return $rc;
}


######################################################################
=pod

=item $success = $doc->upload_url( $url )

Attempts to grab files from the given C<$url> over HTTP. Grabbing 
files this way is always problematic. Therefore, by default, only 
relative links will be followed and only links to files in the same 
directory or subdirectory will be followed.

This method by default uses L<wget|https://www.gnu.org/software/wget/>. 
However, you can modify this in L<EPrints::SystemSettings>.

Returns a boolean dependent of whether file(s) were successfully
uploaded.

=cut
######################################################################

sub upload_url
{
	my( $self, $url_in ) = @_;
	
	# Use the URI heuristic module to attempt to get a valid URL, in case
	# users haven't entered the initial http://.
	my $url = URI::Heuristic::uf_uri( $url_in );
	if( !$url->path )
	{
		$url->path( "/" );
	}
	$self->set_value( 'upload_url', $url ); 

	my $tmpdir = File::Temp->newdir();

	# save previous dir
	my $prev_dir = getcwd();

	# Change directory to destination dir., return with failure if this 
	# fails.
	unless( chdir "$tmpdir" )
	{
		chdir $prev_dir;
		return( 0 );
	}
	
	# Work out the number of directories to cut, so top-level files go in
	# at the top level in the destination dir.
	
	# Count slashes
	my $cut_dirs = substr($url->path,1) =~ tr"/""; # ignore leading /

	my $rc = $self->{session}->get_repository->exec( 
			"wget",
			CUTDIRS => $cut_dirs,
			URL => $url );
	
	chdir $prev_dir;

	# If something's gone wrong...

	return( 0 ) if ( $rc!=0 );

	$self->add_directory( "$tmpdir" );

	# Otherwise set the main file if appropriate
	if( !$self->is_set( "main" ) )
	{
		my $endfile = $url;
		$endfile =~ s/^.*\///;

		# the URL itself, otherwise index.html?
		for( $endfile, "index.html", "index.htm" )
		{
			$self->set_main( $_ ), last if -s "$tmpdir/$_";
		}

	}
	if( !$self->is_set( "main" ) )
	{
		# only one file so main must be it
		my $files = $self->value( "files" );
		if( scalar @$files == 1 )
		{
			$self->set_main( $files->[0] );
		}
	}
	
	$self->queue_files_modified;

	return( 1 );
}


######################################################################
=pod

=item $success = $doc->commit( [ $force ] )

Commit any changes that have been made to this data object to the
database.

Calls C<set_document_automatic_fields> in the archive's configuration 
first to set any automatic fields that may be needed.

If C<$force> is defined and C<true> then still commit even if there 
are no non-volatile changes.

Returns boolean depending on whether commit of document data object is
successful.

=cut
######################################################################

sub commit
{
	my( $self, $force ) = @_;

	my $dataset = $self->{session}->get_repository->get_dataset( "document" );

	my $security = $self->get_value( "security" );
	my $security_changed = $self->{changed}->{security} if defined $self->{changed}->{security};

	$self->update_triggers(); # might cause a new revision

	if( scalar( keys %{$self->{changed}} ) == 0 )
	{
		# don't do anything if there isn't anything to do
		return( 1 ) unless $force;
	}

	if( $self->{non_volatile_change} )
	{
		$self->set_value( "rev_number", ($self->get_value( "rev_number" )||0) + 1 );	
		if ( defined $self->{changed}->{date_embargo} || defined $self->get_value( 'date_embargo' ) )
		{
			if ( !defined $self->{session}->current_user && $0 =~ /lift_embargos/ )
			{
				$self->set_value( 'date_embargo_retained', $self->{changed}->{date_embargo} ) if EPrints::Utils::is_set( $self->{changed}->{date_embargo} );
			}
			else
			{
				$self->set_value( 'date_embargo_retained', $self->get_value( 'date_embargo' ) );
			}
		}
	}

	# SUPER::commit clears non_volatile_change
	my $success;
	{
		local $self->{non_volatile_change};
		$success = $self->SUPER::commit( $force );
	}
	
	if( $self->{non_volatile_change} )
	{
		my $eprint = $self->parent();
		if( defined $eprint && !$eprint->under_construction )
		{
			$eprint->set_value( "fileinfo", $eprint->fileinfo );
			$eprint->commit( 2 ); # 2 == Generate new revision for eprint even if it has not changed.
		}
	}
	
	# Make sure full text is reindexed to add/remove documents whose access restrictions have changed.
	if ( defined $security_changed && $security_changed eq "public" || defined $security && $security eq "public" )
	{
		$self->get_parent->queue_fulltext;
	}

	if ( defined $security_changed )
	{
		my @derived_docs = $self->get_derived_versions;	
		foreach my $ddoc ( @derived_docs )
		{
			$ddoc->set_value( 'security', $self->get_value( "security" ) );
			$ddoc->commit;
		}
	}
	
	return( $success );
}


######################################################################
=pod

=item @derived_docs = $doc->get_derived_versions

Returns an array of documents that are derived from the current
document through the C<isVersionOf> relation.

=cut
######################################################################	

sub get_derived_versions 
{
	my( $self ) = @_;

	my $dataset = $self->{session}->get_repository->get_dataset( "document" );

	my $search_exp = $dataset->prepare_search();
	$search_exp->add_field(
        	fields => [ $dataset->field( 'relation_type' ) ],
        	value => 'http://eprints.org/relation/isVolatileVersionOf',
        	match => "EQ",
	);
	$search_exp->add_field(
                fields => [ $dataset->field( 'relation_uri' ) ],
                value => '/id/document/' . $self->id,
                match => "EQ",
        );
	
	return $search_exp->perform_search->slice;
}	


######################################################################
=pod

=item $problems = $doc->validate( [ $for_archive ] )

Validates the document data object.  If C<$for_archive> is defined 
this will be passed through to the archive configured 
C<validate_document> method, in case it is required for bespoke 
changes to this method.

Returns a reference to an array of XHTML DOM objects describing 
validation problems with the entire document, including the metadata 
and repository config specific requirements.

A returned reference to an empty array indicates no problems.

=cut
######################################################################

sub validate
{
	my( $self, $for_archive ) = @_;

	return [] if $self->get_parent->skip_validation;

	my @problems;

	unless( EPrints::Utils::is_set( $self->get_type() ) )
	{
		# No type specified
		my $fieldname = $self->{session}->make_element( "span", class=>"ep_problem_field:documents" );
		push @problems, $self->{session}->html_phrase( 
					"lib/document:no_type",
					fieldname=>$fieldname );
	}
	
	# System default checks:
	# Make sure there's at least one file!!
	my %files = $self->files();

	if( scalar keys %files ==0 )
	{
		my $fieldname = $self->{session}->make_element( "span", class=>"ep_problem_field:documents" );
		push @problems, $self->{session}->html_phrase( "lib/document:no_files", fieldname=>$fieldname );
	}
	elsif( !$self->is_set( "main" ) )
	{
		# No file selected as main!
		my $fieldname = $self->{session}->make_element( "span", class=>"ep_problem_field:documents" );
		push @problems, $self->{session}->html_phrase( "lib/document:no_first", fieldname=>$fieldname );
	}

	# Test that all files uploaded successfully (i.e. have a non-zero file size).
	foreach my $filename ( keys %files )
	{
		unless ( EPrints::Utils::is_set( $files{$filename} ) && $files{$filename} > 0 )
		{
			my $fieldname = $self->{session}->make_element( "span", class=>"ep_problem_field:documents" );
			my $filename_text = $self->{session}->make_text( $filename );
			push @problems, $self->{session}->html_phrase( "lib/document:zero_file", fieldname=>$fieldname, filename=>$filename_text );
		}
	}
		
	# Site-specific checks
	push @problems, @{ $self->SUPER::validate( $for_archive ) };

	return( \@problems );
}


######################################################################
=pod

=item $boolean = $doc->user_can_view( $user )

Returns C<true> if this document's security settings allow the given 
C<$user> access to view it.

=cut
######################################################################

sub user_can_view
{
	my( $self, $user ) = @_;

	if( !defined $user )
	{
		$self->{session}->get_repository->log( '$doc->user_can_view called with undefined $user object.' );
		return( 0 );
	}

	my $result = $self->{session}->get_repository->call( 
		"can_user_view_document",
		$self,
		$user );	

	return( 1 ) if( $result eq "ALLOW" );
	return( 0 ) if( $result eq "DENY" );

	$self->{session}->get_repository->log( "Response from can_user_view_document was '$result'. Only ALLOW, DENY are allowed." );
	return( 0 );

}


######################################################################
=pod

=item $type = $doc->get_type

Returns the type of this document.

Alias for:

 $doc->value( "format" );

=cut
######################################################################

sub get_type
{
	my( $self ) = @_;

	return $self->get_value( "format" );
}


######################################################################
=pod

=item $doc->queue_files_modified

Adds a C<files_modified> task (e.g. for creating/updating thumbnails)
to the event queue.

=cut
######################################################################

sub queue_files_modified
{
	my( $self ) = @_;

	# volatile documents shouldn't be modified after creation
	if( $self->has_relation( undef, "isVolatileVersionOf" ) )
	{
		return;
	}

	EPrints::DataObj::EventQueue->create_unique( $self->{session}, {
			pluginid => "Event::FilesModified",
			action => "files_modified",
			params => [$self->internal_uri],
		});
}


######################################################################
=pod

=item $doc->files_modified

This method does all the things that need doing when a file has been
modified.

=cut
######################################################################

sub files_modified
{
	my( $self ) = @_;

	my $rc = $self->make_thumbnails;

	if( $self->{session}->can_call( "on_files_modified" ) )
	{
		$self->{session}->call( "on_files_modified", $self->{session}, $self );
	}
	$self->{dataset}->run_trigger( EPrints::Const::EP_TRIGGER_FILES_MODIFIED,
		dataobj => $self,
	);

	$self->commit;

	$self->get_parent->queue_fulltext;

	return $rc;
}


######################################################################
=pod

=item $doc->rehash

Recalculate the hash value of the document. Uses MD5 of the files (in
alphabetic order), but can use user-specified hashing function 
instead.

=cut
######################################################################

sub rehash
{
	my( $self ) = @_;

	my $files = $self->get_value( "files" );

	my $tmpfile = File::Temp->new;
	my $hashfile = $self->get_value( "docid" ).".".
		EPrints::Platform::get_hash_name();

	EPrints::Probity::create_log_fh( 
		$self->{session}, 
		$files,
		$tmpfile );

	seek($tmpfile, 0, 0);

	# Probity files must not be deleted when the document is deleted, 
	# therefore we store them in the parent eprint.
	$self->get_parent->add_stored_file( $hashfile, $tmpfile, -s "$tmpfile" );
}


######################################################################
=pod

=item $indexcodes_doc = $doc->make_indexcodes

Make the index codes document for this document. Returns the generated 
index codes document on success or C<undef> on failure.

=cut
######################################################################

sub make_indexcodes
{
	my( $self ) = @_;

	# if we're a volatile version of another document, don't make indexcodes 
	if( $self->has_relation( undef, "isVolatileVersionOf" ) )
	{
		return undef;
	}

	my $eprint = $self->parent;
	local $eprint->{under_construction} = 1; # prevent parent commit

	# find a conversion plugin to convert us to indexcodes
	my $type = "indexcodes";
	my %types = $self->{session}->plugin( "Convert" )->can_convert( $self, $type );
	if( !exists $types{$type} )
	{
		$self->remove_indexcodes;
		return undef;
	}
	my $plugin = $types{$type}->{"plugin"};

	my $doc = $self->search_related( "isIndexCodesVersionOf" )->item( 0 );

	# update the indexcodes file
	if( defined $doc )
	{
		$doc->set_parent( $eprint );

		my $dir = File::Temp->newdir;
		my @files = $plugin->export( $dir, $self, $type );

		if( !@files )
		{
			$self->remove_indexcodes;
			return;
		}

		open(my $fh, "<", "$dir/$files[0]" );
		my $file = $doc->stored_file( "indexcodes.txt" );
		if( !defined $file )
		{
			$doc->add_stored_file( "indexcodes.txt", $fh, -s $fh );
		}
		else
		{
			$file->set_file( sub {
				return "" if !sysread($fh, my $buffer, 4092);
				return $buffer;
			}, -s $fh);
		}
		close($fh);
	}
	# convert us to indexcodes
	else
	{
		my $epdata = {
			relation => [{
				type => EPrints::Utils::make_relation( "isVersionOf" ),
				uri => $self->internal_uri(),
			},{
				type => EPrints::Utils::make_relation( "isVolatileVersionOf" ),
				uri => $self->internal_uri(),
			},{
				type => EPrints::Utils::make_relation( "isIndexCodesVersionOf" ),
				uri => $self->internal_uri(),
			}],
		};

		$doc = $plugin->convert(
				$eprint,
				$self,
				$type,
				$epdata
			);
	}

	return $doc;
}

######################################################################
=pod

=item $doc = $doc->remove_indexcodes

Remove any documents containing index codes for this document. 
Returns the number of documents removed.

=cut
######################################################################

sub remove_indexcodes
{
	my( $self ) = @_;

	# if we're a volatile version of another document, don't make indexcodes 
	if( $self->has_relation( undef, "isVolatileVersionOf" ) )
	{
		return 0;
	}

	my $c = 0;

	my $eprint = $self->parent;
	local $eprint->{under_construction} = 1; # prevent parent commit

	# remove any existing indexcodes documents
	$self->search_related( "isIndexCodesVersionOf" )->map(sub {
			my( undef, undef, $doc ) = @_;

			$doc->set_parent( $eprint );

			$doc->remove_relation( $self );
			$doc->remove;

			++$c;
		});
	
	return $c;
}


######################################################################
=pod

=item $filename = $doc->cache_file( $suffix );

DEPRECATED

Returns a cache filename for this document with the given C<$suffix>.

=cut
######################################################################

sub cache_file
{
	my( $self, $suffix ) = @_;

	my $eprint =  $self->get_parent;
	return unless( defined $eprint );

	return $eprint->local_path."/".
		$self->get_value( "docid" ).".".$suffix;
}


######################################################################
=pod

=item $doc->register_parent( $parent )

Registers the C<$parent> L<EPrints::DataObj::EPrint> object for this 
document.

This may cause reference loops, but it does avoid two identical
eprint data objects existing at once.

=cut
######################################################################

sub register_parent
{
	my( $self, $parent ) = @_;

	$self->set_parent( $parent );
}

######################################################################
=pod

=item $doc->thumbnail_url( $size )

Returns the URL for the thumbnail of the document for a specified
C<$size>.  If C<$size> is unspecified defaults to C<small>. Other 
values for C<$size> include C<medium> and C<preview>.

Returns C<undef> if file for particular type of thumbnail does not
exist.

This method is called bt L</icon_url>.  It is best to use that method
to reliably retrieve the required URL.

=cut
######################################################################

sub thumbnail_url
{
	my( $self, $size ) = @_;

	$size = "small" unless defined $size;

	my $relation = "is${size}ThumbnailVersionOf";

	my $thumbnails = $self->search_related( $relation );

	return undef if $thumbnails->count == 0;

	$relation = "has${size}ThumbnailVersion";

	my $path = $self->path;
	$path =~ s! /$ !.$relation/!x;

	if( $self->is_set( "main" ) )
	{
		$path .= URI::Escape::uri_escape_utf8(
			$self->value( "main" ),
			"^A-Za-z0-9\-\._~\/"
		);
	}

	return $self->{session}->current_url(
		host => 1,
		path => "static",
		$path
	);
}


######################################################################
=pod

=item $doc->icon_url( $size )

Returns the URL for the icon of the document for a specified
C<$size>.  If C<$size> is unspecified defaults to C<small>. Other
values for C<$size> include C<medium> and C<preview>.

=cut
######################################################################

sub icon_url 
{
	my( $self, %opts ) = @_;

	$opts{public} = 1 unless defined $opts{public};
	$opts{size} = "small" unless defined $opts{size};

	if( !$opts{public} || $self->is_public )
	{
		my $thumbnail_url = $self->thumbnail_url( $opts{size} );

		return $thumbnail_url if defined $thumbnail_url;
	}

	my $session = $self->{session};
	my $langid = $session->get_langid;
	my @static_dirs = $session->get_repository->get_static_dirs( $langid );

	my $icon = "other.png";
	my $rel_path = "style/images/fileicons";

	my $format = $self->value( "format" );
	return $session->config( "base_url" )."/$rel_path/$icon" unless defined $format;

	# support old-style MIME types e.g. application/zip
	my( $major, $minor ) = split '/', $format, 2;
	$minor = "" if !defined $minor;
	DIR: foreach my $dir (@static_dirs)
	{
		# we'll use the major type if available e.g. 'image.png'
		foreach my $fn ("$major\_$minor.png", "$major.png")
		{
			if( -e "$dir/$rel_path/$fn" )
			{
				$icon = $fn;
				last DIR;
			}
		}
	}

	return $session->config( "base_url" )."/$rel_path/$icon";
}


######################################################################
=pod

=item $frag = $doc->render_icon_link( %opts )

Render a link to the icon for this document.

Options:

 new_window => 1 - Make link go to C<_blank> not current window.

 preview => 1 - If possible, provide a preview pop-up.

 public => 0 - Show thumbnail/preview only on public documents.

 public => 1 - Show thumbnail/preview on all documents if possible.

 with_link => 0 - Do not link.

=cut
######################################################################

sub render_icon_link
{
	my( $self, %opts ) = @_;

	$opts{public} = 1 unless defined $opts{public};
	$opts{with_link} = 1 unless defined $opts{with_link};
	if( $opts{public} && !$self->is_public )
	{
		$opts{preview} = 0;
	}

	my %aopts;
	$aopts{class} = "ep_document_link";
	$aopts{target} = "_blank" if( $opts{new_window} );
	$aopts{href} = $self->get_url;

	my $preview_id = "doc_preview_".$self->get_id;
	my $preview_url;
	if( $opts{preview} )
	{
		$preview_url = $self->thumbnail_url( "preview" );
		if( !defined $preview_url ) { $opts{preview} = 0; }
	}
	if( $opts{preview} )
	{
		$opts{preview_side} = 'right' unless defined $opts{preview_side};
		$aopts{onmouseover} = "EPJS_ShowPreview( event, '$preview_id', '$opts{preview_side}' );";
		$aopts{onmouseout} = "EPJS_HidePreview( event, '$preview_id', '$opts{preview_side}' );";
		$aopts{onfocus} = "EPJS_ShowPreview( event, '$preview_id', '$opts{preview_side}' );";
		$aopts{onblur} = "EPJS_HidePreview( event, '$preview_id', '$opts{preview_side}' );";
	}
	my $f = $self->{session}->make_doc_fragment;
	my $img_class = ( $opts{size} ) ? 'ep_doc_icon ep_doc_icon_'.$opts{size} : "ep_doc_icon";
	my $img_alt = $self->value('main');
	$img_alt = $self->value('formatdesc') if EPrints::Utils::is_set( $self->value('formatdesc') );
	my $img = $self->{session}->make_element(
		"img",
		class=>$img_class,
		alt=>"[thumbnail of $img_alt]",
  		title=>"$img_alt",
		src=>$self->icon_url( public=>$opts{public}, size=>$opts{size} ),
		border=>0 );
	if ( $opts{with_link} )
	{
		my $a = $self->{session}->make_element( "a", %aopts );
		$a->appendChild( $img );
		$f->appendChild( $a );
	}
	else
	{
		$f->appendChild( $img );
	}
	if( $opts{preview} )
	{
		my $preview = $self->{session}->make_element( "div",
				id => $preview_id,
				class => "ep_preview", );
		my $pdiv = $self->{session}->make_element( "div" );
		$preview->appendChild( $pdiv );
		my $cdiv = $self->{session}->make_element( "div" );
		my $span = $self->{session}->make_element( "span" );
		$cdiv->appendChild( $span );
		$pdiv->appendChild( $cdiv );
		$span->appendChild( $self->{session}->make_element( 
			"img", 
			class=>"ep_preview_image",
			id=>$preview_id . "_img",
			alt=>"",
			src=>$preview_url,
			border=>0 ));
		my $tdiv = $self->{session}->make_element( "div", class=>"ep_preview_title" );
		$tdiv->appendChild( $self->{session}->html_phrase( "lib/document:preview"));
		$span->appendChild( $tdiv );
		$f->appendChild( $preview );
	}

	return $f;
}


######################################################################
=pod

=item $frag = $doc->render_preview_link( %opts )

Render a link to the preview for this document (if available) using a 
lightbox.

Options:

=over 4

=item caption => $frag

XHTML fragment to use as the caption, defaults to empty.

=item set => "name"

The name of the set this document belongs to, defaults to none 
(preview won't be shown as part of a set).

=back

=cut
######################################################################

sub render_preview_link
{
	my( $self, %opts ) = @_;

	my $f = $self->{session}->make_doc_fragment;

	my $caption = $opts{caption} || $self->{session}->make_doc_fragment;
	my $set = $opts{set};
	if( EPrints::Utils::is_set($set) )
	{
		$set = "[$set]";
	}
	else
	{
		$set = "";
	}

	my $size = $opts{size};
	$size = "lightbox" if !defined $size;

	my $url = $self->thumbnail_url( $size );
	if( defined $url )
	{
		my $link;
		if ( EPrints::Utils::tree_to_utf8($caption) eq EPrints::Utils::tree_to_utf8( $self->{session}->html_phrase( "lib/document:preview" ) ) )
		{
			$link = $self->{session}->make_element( "a",
					href=>$url,
					rel=>"lightbox$set nofollow",
				);
		}
		else {
			$link = $self->{session}->make_element( "a",
					href=>$url,
					rel=>"lightbox$set nofollow",
					title=>EPrints::Utils::tree_to_utf8($caption),
				);
		}
		$link->appendChild( $self->{session}->html_phrase( "lib/document:preview" ) );
		$f->appendChild( $link );
	}

	EPrints::XML::dispose($caption);

	return $f;
}


######################################################################
=pod

=item $plugin = $doc->thumbnail_plugin( $size )

Returns the plugin used to generatee thumbnails of the specified 
C<$size>.

=cut
######################################################################

sub thumbnail_plugin
{
	my( $self, $size ) = @_;

	my $convert = $self->{session}->plugin( "Convert" );
	my %types = $convert->can_convert( $self );

	my $def = $types{'thumbnail_'.$size};

	return unless defined $def;

	return $def->{ "plugin" };
}

######################################################################
=pod

=item $path = $doc->thumbnail_path

DEPRECATED

Returns the filesystem path to location of thumbnails for the 
document.

=cut
######################################################################

sub thumbnail_path
{
	my( $self ) = @_;

	my $eprint = $self->get_parent();

	if( !defined $eprint )
	{
		$self->{session}->get_repository->log(
			"Document ".$self->get_id." has no eprint (eprintid is ".$self->get_value( "eprintid" )."!" );
		return( undef );
	}	
	
	return( $eprint->local_path()."/thumbnails/".sprintf("%02d",$self->get_value( "pos" )) );
}


######################################################################
=pod

=item $doc->thumbnail_types

Returns array containing names of all the thumbnail types available 
for this document.

=cut
######################################################################

sub thumbnail_types
{
	my( $self ) = @_;

	my @list = qw/ small medium preview lightbox audio_ogg audio_mp4 video_ogg video_mp4 /;

	if( $self->{session}->can_call( "thumbnail_types" ) )
	{
		$self->{session}->call( "thumbnail_types", \@list, $self->{session}, $self );
	}
	$self->{session}->run_trigger( EPrints::Const::EP_TRIGGER_THUMBNAIL_TYPES,
			dataobj => $self,
			list => \@list,
		);

	return reverse @list;
}

######################################################################
=pod

=item $doc->remove_thumbnails

Removes all thumbnail files associated with this document.

=cut
######################################################################

sub remove_thumbnails
{
	my( $self ) = @_;

	my $eprint = $self->parent;
	return unless $eprint;

	my $under_construction = $eprint->under_construction;
	$under_construction = 0 unless $under_construction;
	$eprint->{under_construction} = 1;

	my @sizes = $self->thumbnail_types;
	my %lookup = map { $_ => 1 } @sizes;

	my $regexp = EPrints::Utils::make_relation( "is(\\w+)ThumbnailVersionOf" );
	$regexp = qr/^$regexp$/;

	$self->search_related->map(sub {
		my( undef, undef, $doc ) = @_;

		for(@{$doc->value( "relation" )})
		{
			next if $_->{uri} ne $self->internal_uri;
			next if $_->{type} !~ $regexp;

			# only remove configured sizes (otherwise we can nuke externally
			# generated thumbnails)
			if( exists($lookup{$1}) )
			{
				$doc->set_parent( $self->parent );
				$doc->remove_relation( $self );
				$doc->remove;
				return;
			}
		}
	});

	$eprint->{under_construction} = $under_construction;

	$eprint->set_value( "fileinfo", $eprint->fileinfo );

	# we don't want to do anything heavy after changing thumbnails
	local $eprint->{non_volatile_change};
	$eprint->commit();
}

######################################################################
=pod

=item $doc->make_thumbnails

Make all the thumbnail files required for this document.

=cut
######################################################################

sub make_thumbnails
{
	my( $self ) = @_;

	# If we're a volatile version of another document, don't make thumbnails 
	# otherwise we'll cause a recursive loop
	if( $self->has_relation( undef, "isVolatileVersionOf" ) )
	{
		return;
	}

	my $src_main = $self->get_stored_file( $self->value( "main" ) );

	return unless defined $src_main;

	my $eprint = $self->parent;
	return unless $eprint;

	my $under_construction = $eprint->under_construction;
	$under_construction = 0 unless $under_construction;
	$eprint->{under_construction} = 1;

	my %thumbnails;

	my $regexp = EPrints::Utils::make_relation( "is(\\w+)ThumbnailVersionOf" );
	$regexp = qr/^$regexp$/;

	$self->search_related->map(sub {
		my( undef, undef, $doc ) = @_;

		for(@{$doc->value( "relation" )})
		{
			next if $_->{uri} ne $self->internal_uri;
			next if $_->{type} !~ $regexp;

			$doc->set_parent( $self->parent );
			# remove multiple thumbnails of the same type, keeping the first
			if( defined $thumbnails{$1} )
			{
				$doc->remove;
				return;
			}
			$thumbnails{$1} = $doc;
		}
	});

	my @list = $self->thumbnail_types;

	SIZE: foreach my $size ( @list )
	{
		my $tgt = $thumbnails{$size};

		# remove the existing thumbnail
   		if( defined($tgt) )
		{
			my $tgt_main = $tgt->get_stored_file( $tgt->value( "main" ) );
			if( defined $tgt_main && $tgt_main->get_datestamp gt $src_main->get_datestamp )
			{
				# ignore if tgt's main file is newer than document's main file
				next SIZE;
			}
			$tgt->remove_relation( $self );
			$tgt->remove;
		}

		my $plugin = $self->thumbnail_plugin( $size );

		next if !defined $plugin;

		$tgt = $plugin->convert( $self->get_parent, $self, 'thumbnail_'.$size );
		next if !defined $tgt;

		$tgt->add_relation( $self, "is${size}ThumbnailVersionOf" );
		$tgt->commit();
	}

	if( $self->{session}->get_repository->can_call( "on_generate_thumbnails" ) )
	{
		$self->{session}->get_repository->call( "on_generate_thumbnails", $self->{session}, $self );
	}

	$eprint->{under_construction} = $under_construction;

	$eprint->set_value( "fileinfo", $eprint->fileinfo );

	# we don't want to do anything heavy after changing thumbnails
	local $eprint->{non_volatile_change};
	$eprint->commit();
}


######################################################################
=pod

=item $mime_type = $doc->mime_type

DEPRECATED - use C<$doc-E<gt>value( "mime_type" )>

Returns the MIME type of this document.

=cut
######################################################################

sub mime_type
{
	my( $self, $file ) = @_;

	# Primary doc if no filename
	$file = $self->value( "main" ) unless( defined $file );

	my $fileobj = $self->get_stored_file( $file );

	return undef unless defined $fileobj;

	return $fileobj->get_value( "mime_type" );
}


######################################################################
=pod

=item $eprintid = $doc->get_parent_id

Returns the ID of the parent for this document, (i.e. the eprint ID).

=cut
######################################################################

sub get_parent_id
{
	my( $self ) = @_;

	return $self->get_value( "eprintid" );
}


######################################################################
=pod

=item $doc->add_relation( $tgt, @types )

Add one or more relations with type(s) specified by C<@types> to the 
document data object and pointing to the C<$tgt> data object.  

This will not update the C<$tgt> data object even if reflexive
relations exist.

=cut
######################################################################

sub add_relation
{
	my( $self, $tgt, @types ) = @_;

	@types = map { EPrints::Utils::make_relation( $_ ) } @types;

	my %lookup = map { $_ => 1 } @types;

	my @relation;
	for(@{$self->value( "relation" )})
	{
		next if
			$_->{uri} eq $tgt->internal_uri &&
			exists($lookup{$_->{type}});
		push @relation, $_;
	}
	push @relation,
		map { { uri => $tgt->internal_uri, type => $_ } } @types;
	
	$self->set_value( "relation", \@relation );
}


######################################################################
=pod

=item $doc->remove_relation( $tgt, [ @types ] )

Removes the relations for the document data object to the C<$tgt> data 
object. If C<@types> is not defined, remove all relations to C<$tgt>. 
If C<$tgt> is also undefined removes all relations given in C<@types>.

If both C<$tgt>, and C<@types> are both undefined no relations will be 
removed. If you want to remove all relations do:

 $doc->set_value( "relation", [] );

=cut
######################################################################

sub remove_relation
{
	my( $self, $tgt, @types ) = @_;

	return if !defined($tgt) && !@types;

	@types = map { EPrints::Utils::make_relation( $_ ) } @types;

	my %lookup = map { $_ => 1 } @types;

	my @relation;
	for(@{$self->value( "relation" )})
	{
# logic:
#  we remove the relation if uri and type match
#  we remove the relation if uri and type=* match
#  we remove the relation if uri=* and type match
# otherwise we keep it
		next if defined($tgt) && $_->{uri} eq $tgt->internal_uri && exists($lookup{$_->{type}});
		next if defined($tgt) && $_->{uri} eq $tgt->internal_uri && !@types;
		next if !defined($tgt) && exists($lookup{$_->{type}});
		push @relation, $_;
	}

	$self->set_value( "relation", \@relation );
}


######################################################################
=pod

=item $bool = $doc->has_relation( $tgt, [ @types ] )

Returns C<true> if document data object has relations to C<$tgt>. If 
C<@types> is also given, check these relations satisfy all of the 
given types. If C<$tgt> is undefined, relations that satisfy the
given types may be to any data object.

=cut
######################################################################

sub has_relation
{
	my( $self, $tgt, @types ) = @_;

	@types = map { EPrints::Utils::make_relation( $_ ) } @types;

	my %lookup = map { $_ => 1 } @types;
	for(@{$self->value( "relation" )})
	{
		next if defined($tgt) && $_->{uri} ne $tgt->internal_uri;
		return 1 if !@types;
		delete $lookup{$_->{type}} if EPrints::Utils::is_set( $_->{type} );
	}

	return !scalar(keys %lookup);
}


######################################################################
=pod

=item $list = $doc->search_related( [ $type ] )

Returns an L<EPrints::List> that contains all document data objects 
related to this document data object. If C<$type> is defined return 
only those document data object related by that type.

=cut
######################################################################

sub search_related
{
	my( $self, $type ) = @_;

	if( $type )
	{
		return $self->dataset->search(
			filters => [{
				meta_fields => [qw( relation )],
				value => {
					uri => $self->internal_uri,
					type => EPrints::Utils::make_relation( $type )
				},
				match => "EX",
			},{
				meta_fields => [qw( eprintid )],
				value => $self->parent->id,
			}]);
	}
	else
	{
		return $self->dataset->search(
			filters => [{
				meta_fields => [qw( relation_uri )],
				value => $self->internal_uri,
				match => "EX",
			},{
				meta_fields => [qw( eprintid )],
				value => $self->parent->id,
			}]);
	}
}


######################################################################
=pod

=item $citation = $doc->render_citation_link( $style, %params )

Returns a XHTML DOM citation rendering of the document data object.
Using citation C<$style> and C<%params> provided and setting class
for DOM parent element to C<ep_document_link>.

=cut
######################################################################

sub render_citation_link
{
	my( $self , $style , %params ) = @_;

	$params{url} = $self->get_url;
	$params{class} = "ep_document_link";
	
	return $self->render_citation( $style, %params );
}

######################################################################
=pod

=item $frag = $doc->render_video_preview( $css_class )

Returns a XHTML DOM fragment rendering of a HTML5 video preview with 
optional subtitles.  Assigning the C<$css_class> to the parent element 
if the XHTML DOM fragment, if provided.

Access / security concerns should be addressed at a higher level.

=cut
######################################################################

sub render_video_preview
{
	my ( $self, $css_class ) = @_;

	my $session = $self->{session};
	my $class = ( $css_class ) ? $css_class : "ep_embedded_video";

	my $eprint = $self->get_eprint;
	my $doc_frag = $session->make_doc_fragment();
	my @thumbnail_types = $self->thumbnail_types();
	my $preview_docs;
	my $format_to_show;

	foreach my $thumbnail_type (@thumbnail_types)
	{
		next unless !($thumbnail_type =~ /(small)|(medium)|(lightbox)/); # we dont want to use small, medium or lightbox for the preview
		$self->search_related( "is${thumbnail_type}ThumbnailVersionOf" )->map( sub {
			my ( undef, undef, $doc ) = @_;
			$format_to_show = "video" if( $thumbnail_type =~ /(video)/ );
			$format_to_show = "audio" if( $thumbnail_type =~ /(audio)/ );
			$preview_docs->{$thumbnail_type} = $doc;
		});
	}

	if( defined $preview_docs && defined $format_to_show && $format_to_show =~ /(video)/ )
	{
		my $video_link = $session->make_element( "video", class=>$class, controls=>"", id=>"doc_".$self->get_id, "data-src"=>"#doc_".$self->get_id );
		my $video_type;
		foreach my $video_format (qw/ video_mp4 video_ogg video_webm /)
		{
			$video_type = $video_format;
			$video_type =~ s/_/\//g;
			my $video_url = $self->thumbnail_url( $video_format );
			# $video_url =~ s/^http/https/;
			$video_link->appendChild( $session->make_element("source", src=>$video_url, type=>$video_type) );
		}
		$video_link->appendChild( $session->make_text("Your browser does not support HTML5 video") );
		$doc_frag->appendChild( $video_link );

		# add subtitles - assume for now that tracks are supplied in vtt format with a name matching the video file
		my $subs = $self->get_value("main");
		$subs =~ s/\.([^.]+)$/.vtt/; # the file we are looking for
		my @docs = $eprint->get_all_documents();
		foreach my $d ( @docs )
		{
			# assume suitable access rights
			if( $d->get_value("main") eq $subs )
			{
				my $srclang = $d->get_value( "language" );
				   $srclang = "en" unless $srclang; # default to English
				my $label = EPrints::Utils::tree_to_utf8( $session->html_phrase( "languages_typename_" . $srclang ) );
				my $track = $session->make_element( "track", src => $d->get_url, kind => "subtitles", srclang => $srclang, label => $label );
				$video_link->appendChild( $track );
			}
		}
	}

	return $doc_frag;
}


######################################################################
=pod

=item $boolean = $doc->permit( $priv, $user )

Returns boolean depending on whether the C<$user> has the privilege 
C<$priv> to carry out a particular action on this document data 
object.

See L<EPrints::DataObj#permit>.

=cut
######################################################################

sub permit
{
	my( $self, $priv, $user ) = @_;

	if( $priv eq "document/view" )
	{
		my $r;
		if( defined $user )
		{
			eval {
				$r = $self->{session}->call( "can_user_view_document",
						$self,
						$user
					);
			};
			EPrints->abort( "can_user_view_document call caused an error" ) if $@;
			return 1 if $r eq "ALLOW";
			EPrints->abort( "can_user_view_document returned '$r': expected ALLOW or DENY" ) if $r ne "DENY";
		}
		eval {
			$r = $self->{session}->call( "can_request_view_document",
					$self,
					$self->{session}->{request}
				);
		};
		EPrints->abort( 'can_request_view_document call caused an error. Hint: is security.pl still using $r->connection()->remote_ip();' ) if $@;
		return 1 if $r eq "ALLOW";
		return 0 if $r eq "DENY" || $r eq "USER";
		EPrints->abort( "can_request_view_document returned '$r': expected ALLOW, DENY or USER" );
	}

	return $self->SUPER::permit( $priv, $user );
}


######################################################################
=pod

=back

=head2 Utility Methods

=cut
######################################################################

######################################################################
=pod

=over 4

=item EPrints::DataObj::doc_with_eprintid_and_pos( $repository, $eprintid, $pos )

Find the document for an eprint based on the C<$eprintid> and C<$pos>
values supplied matching the document's corresponding fields.

Returns the document data object matching the criteria. Otherwise,
checks C<dark_document> dataset if it exists to find a corresponding
match.

=cut
######################################################################

sub doc_with_eprintid_and_pos
{
	my( $repository, $eprintid, $pos ) = @_;
	
	my $dataset = $repository->dataset( "document" );

	my $results = $dataset->search(
		filters => [
			{
				meta_fields => [qw( eprintid )],
				value => $eprintid
			},
			{
				meta_fields => [qw( pos )],
				value => $pos
			},
		]);

	#if no results, fall back to a different document dataset
	if( !defined $results->item( 0 ) )
	{
		#try dark_document dataset
		if (  $repository->exists_dataset( "dark_document"  ) )
		{
			$dataset = $repository->dataset( "dark_document" );
			$results = $dataset->search(
				filters => [
					{
						meta_fields => [qw( eprintid )],
						value => $eprintid
					},
					{
						meta_fields => [qw( pos )],
						value => $pos
					},
				]);
		}
	}

	#return the result
	return $results->item( 0 );
}


######################################################################
=pod

=item EPrints::DataObj::Document::main_input_tags( $session, $object )

=cut
######################################################################

sub main_input_tags
{
	my( $session, $object ) = @_;

	my %files = $object->files;

	my @tags;
	foreach ( sort keys %files ) { push @tags, $_; }

	return( @tags );
}


######################################################################
=pod

=item EPrints::DataObj::main_render_option( $session, $object )

=cut
######################################################################

sub main_render_option
{
	my( $session, $option ) = @_;

	return $session->make_text( $option );
}


######################################################################
=pod

=item $cleanfilename = EPrints::DataObj::Document::sanitise( $filename )

Sanitises filename by replacing invalid characters. Mainly uses
L<EPrints::System#sanitise> but also replaces C</> with C<_> to 
ensure these do not get confused as a separator between direectories.

=cut
######################################################################

sub sanitise 
{
	my( $filename ) = @_;

	$filename = EPrints->system->sanitise( $filename );
	$filename =~ s!/!_!g;

	return $filename;
}


1;

######################################################################
=pod

=back

=head1 SEE ALSO

L<EPrints::DataObj::SubObject>, L<EPrints::DataObj> and 
L<EPrints::DataSet>.

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
