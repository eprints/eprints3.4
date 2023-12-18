######################################################################
#
# EPrints::DataObj::EPM
#
######################################################################
#
#
######################################################################


=pod

=for Pod2Wiki

=head1 NAME

B<EPrints::DataObj::EPM> - An EPrints Package Manager (EPM) package.

=head1 DESCRIPTION

This class represents an EPrint Package Manager (EPM) package that 
can be stored in XML format as a .epm file or are hosted on EPM 
repositories such as L<http://bazaar.eprints.org>.

The EPM data object is now hosted in the bazaar ingredient found at:

 ingredients/bazaar/plugins/EPrints/DataObj/EPM.pm

=head1 CORE METADATA FIELDS

=over 4

=item epmid (id)

The text ID of the EPM package 

=item eprintid (int)

The ID number of the EPrint record from the EPM repository.

E.g. L<http://bazaar.eprints.org/>.

=item uri (url)

The URI of the EPM package from the EPM repository it is hosted. 

E.g. L<http://bazaar.eprints.org/id/epm/reports>

=item version (text)

The version (e.g. 1.0.0) of the EPM package.

=item controller (text)

=item creators (compound, multiple)

Creators of the EPM package including both their full name and email 
address.

=item datestamp (time)

The date and time this version of this EPM package was published.

=item title (longtext)

The title of this EPM package.

=item description (longtext)

The description of this EPM package and its purpose.

=item requirements (longtext)

A description of the requirements for this EPM package.

=item home_page (url)

A URL for the home page of the EPM package. Maybe a page including 
documentation on how to use the EPM package.

=item icon (url)

A URL for the icon for the EPM package.

=back

=head1 REFERENCES AND RELATED OBJECTS

=over 4

=item documents (subobject, multiple)

The documents for this EPM package. Effectively a manifest of files
required to install the EPM om a repository.

=back

=head1 INSTANCE VARIABLES

See L<EPrints::DataObj|EPrints::DataObj#INSTANCE_VARIABLES>.

=head1 METHODS

=cut

######################################################################

package EPrints::DataObj::EPM;

@ISA = ( 'EPrints::DataObj' );

use EPrints::Plugin::Screen::EPMC; 
use strict;

our $MAX_SIZE = 2097152;


######################################################################
=pod

=head2 Constructor Methods

=cut
######################################################################

######################################################################
=pod

=over 4

=item $epm = EPrints::DataObj::EPM->new( $repo, $id )

Returns a new object representing the installed EPM package C<$id>.

=cut
######################################################################

sub new
{
    my( $class, $repo, $id ) = @_;

    my $filepath = $repo->config( "base_path" ) . "/lib/epm/$id/$id.epmi";
    if( open(my $fh, "<", $filepath) )
    {
        my $dataobj = $class->new_from_file( $repo, $fh );
        close($fh);

        return $dataobj;
    }

    return;
}


######################################################################
=pod

=item $epm = EPrints::DataObj::EPM->new_from_data( $repo, $epdata, $dataset )

Returns a new object representing the EPM package based on the 
C<$epdata> and C<$dataset>.

=cut
######################################################################

sub new_from_data
{
    my( $class, $repo, $epdata, $dataset ) = @_;

    my $uri = delete $epdata->{_id};

    my $self = $class->SUPER::new_from_data( $repo, $epdata, $dataset );
    return undef if !defined $self;

    $self->_upgrade;

    $self->set_value( "uri", $uri );

    return $self;
}


######################################################################
=pod

=item $epm = EPrints::DataObj::EPM->new_from_data( $repo, $xml )

Returns a new object representing the EPM package based on the 
C<$xml> provided.

=cut
######################################################################

sub new_from_xml
{
    my( $class, $repo, $xml ) = @_;

    my $doc = $repo->xml->parse_string( $xml );

    my $epdata = $repo->dataset( "epm" )->dataobj_class->xml_to_epdata(
        $repo, $doc->documentElement
    );

    return $repo->dataset( "epm" )->make_dataobj( $epdata );
}


######################################################################
=pod

=item $epm = EPrints::DataObj::EPM->new_from_data( $repo, $fh )

Returns a new object representing the EPM package based on the XML 
from the file handle C<$fh> provided.

=cut
######################################################################

sub new_from_file
{
    my( $class, $repo, $fh ) = @_;

    my $epdata = {};
    EPrints::XML::event_parse( $fh, EPrints::DataObj::SAX::Handler->new(
        $class,
        $epdata = {},
        { dataset => $repo->dataset( "epm" ) }
    ) );
    return if !keys %$epdata;
    return $class->new_from_data( $repo, $epdata );

    return;
}


######################################################################
=pod

=item $epm = EPrint::DataObj::EPM->new_from_manifest( $repo, $epdata, [ @manifest ] )

Makes and returns a new EPM object based on the C<$epdata> and a 
manifest of installable files.

=cut
######################################################################

sub new_from_manifest
{
    my( $class, $repo, $epdata, @manifest ) = @_;

    my $self = $class->SUPER::new_from_data( $repo, $epdata );

    my $base_path = $self->repository->config( "base_path" ) . "/lib";

    my $install = $repo->dataset( "document" )->make_dataobj({
        _parent => $self,
        content => "install",
        format => "other",
        files => [],
    });
    $self->set_value( "documents", [ $install ]);

    foreach my $filename (@manifest)
    {
        my $filepath = "$base_path/$filename";
        use bytes;
        open(my $fh, "<", $filepath) or die "Error opening $filepath: $!";
        sysread($fh, my $data, -s $fh);
        close($fh);
        my $md5 = Digest::MD5::md5_hex( $data );

        $repo->run_trigger( EPrints::Const::EP_TRIGGER_MEDIA_INFO,
            filename => $filename,
            filepath => $filepath,
            epdata => my $media_info = {},
        );

        my $copy = { pluginid => "Storage::EPM", sourceid => $filepath };

        my $file = $repo->dataset( "file" )->make_dataobj({
            _parent => $install,
            filename => $filename,
            filesize => length($data),
#           data => MIME::Base64::encode_base64( $data ),
            hash => $md5,
            hash_type => "MD5",
            mime_type => $media_info->{mime_type},
            copies => [$copy],
        });
        $install->set_value( "files", [
            @{$install->value( "files")},
            $file,
        ]);
        $install->set_main( $file );

        if( $filename =~ m#^static/(images/epm/.*)# )
        {
            $self->set_value( "icon", $1 );
            my $icon = $repo->dataset( "document" )->make_dataobj({
                _parent => $self,
                content => "coverimage",
                main => $filename,
                files => [],
                format => "image",
            });
            $icon->set_value( "files", [
                $repo->dataset( "file" )->make_dataobj({
                    _parent => $icon,
                    filename => $filename,
                    filesize => length($data),
#                   data => MIME::Base64::encode_base64( $data ),
                    hash => $md5,
                    hash_type => "MD5",
                    mime_type => $media_info->{mime_type},
                    copies => [$copy],
                })
            ]);
            $self->set_value( "documents", [
                @{$self->value( "documents" )},
                $icon,
            ]);
        }
    }

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

=item $metadata = EPrints::DataObj::EPM->get_system_field_info

Returns an array describing the system metadata of the epm dataset.

=cut
######################################################################

sub get_system_field_info
{
	my( $class ) = @_;

	return ( 
	
	# a unique name for this package
	{ name=>"epmid", type=>"id", required=>1, import=>0, can_clone=>0, },

	# bazaar.eprint.eprintid
	{ name=>"eprintid", type=>"int", can_clone=>0, },

	# bazaar.uri
	{ name=>"uri", type=>"url", can_clone=>0, },

	# package contents
	{ name=>"documents", type=>"subobject", datasetid=>'document',
		multiple=>1 },

	# version in x.y.z
	{ name=>"version", type=>"text" },

	# control 'Screen' plugin
	# 	action_enable, action_disable
	# 	render_action_link [configure link]
	# 	render [configuration]
	{ name=>"controller", type=>"text", render_value => \&render_controller, },

	# creators
	{ name=>"creators", type=>"compound", multiple=>1, fields=>[
		{ sub_name=>"name", type=>"name", hide_honourific=>1, },
		{ sub_name=>"id", type=>"id", input_cols=>20, },
		]},

	# change to functional content
	{ name=>"datestamp", type=>"time" },

	# human-readable title
	{ name=>"title", type=>"longtext", },

	# human-readable description
	{ name=>"description", type=>"longtext", },
	
	# human-readable description of requirements
	{ name=>"requirements", type=>"longtext", },

	# add-on home-page
	{ name=>"home_page", type=>"url" },

	# icon filename
	{ name=>"icon", type=>"url", render_value => \&render_icon, },

	{
 		name=>"verb",
 		type=>"text",
 		multiple => 1,
 	},
 	{
 		name=>"verb_rendered",
 		type=>"text",
 		render_single_value => "EPrints::Extras::render_xhtml_field",
 		multiple => 1,
 	},
 	{
 		name=>"verb_rendered_long",
 		type=>"text",
 		render_single_value => "EPrints::Extras::render_xhtml_field",
 		multiple => 1,
 	},




	);
}


######################################################################
=pod

=item $dataset = EPrints::DataObj::EPM->get_dataset_id

Returns the ID of the L<EPrints::DataSet> object to which this record
belongs.

=cut
######################################################################

sub get_dataset_id
{
    return "epm";
}


######################################################################
=pod

=item EPrints::DataObj::EPM->map( $repo, $f, $ctx )

Apply a function C<$f> over all installed EPMs with and only context
C<$ctx>, which is not currently implemented.

	sub {
		my( $repo, $dataset, $epm, [ $ctx ] ) = @_;
	}

This loads the EPM index files only.

=cut
######################################################################

sub map
{
	my( $class, $repo, $f, $ctx ) = @_;

	my $dataset = $repo->dataset( "epm" );

	my $epm_dir = $repo->config( "base_path" ) . "/lib/epm";
	opendir(my $dh, $epm_dir) or return;
	foreach my $file (sort readdir($dh))
	{
		next if $file =~ /^\./;
		next if !-f "$epm_dir/$file/$file.epmi";
		&$f( $repo, $dataset, $class->new( $repo, $file ) );
	}
	closedir($dh);
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

=item $epm->commit

Commit any changes to the installed .epm, .epmi files.

=cut
######################################################################

sub commit
{
	my( $self ) = @_;

	EPrints->system->mkdir( $self->epm_dir )
		or EPrints->abort( "Error creating directory ".$self->epm_dir.": $!" );
	# give the user a hint for where to put cfg.d.s
	EPrints->system->mkdir( $self->epm_dir . "/cfg/cfg.d" );

	if( open(my $fh, ">", $self->epm_dir . "/" . $self->id . ".epm") )
	{
		$self->serialise( $fh, 1 );
		close($fh);
	}
	if( open(my $fh, ">", $self->epm_dir . "/" . $self->id . ".epmi") )
	{
		$self->serialise( $fh, 0 );
		close($fh);
	}
}


######################################################################
=pod

=item $epm->rebuild

Reload all of the installed files (regenerating hashes if necessary).

=cut
######################################################################

sub rebuild
{
	my( $self ) = @_;

	my @files = $self->installed_files;

	my $epm = ref($self)->new_from_manifest(
		$self->repository,
		$self->get_data,
		map { $_->value( "filename" ) } @files
	);

	$self->set_value( "documents", $epm->value( "documents" ) );
	for(keys %{$epm->{changed}})
	{
		$self->set_value( $_, $epm->value( $_ ) );
	}
}


######################################################################
=pod

=item $v = $epm->version

Returns a stringified version suitable for string gt/lt matching.

=cut
######################################################################

sub version
{
	my( $self ) = @_;

	my $v = $self->value( "version" );
	$v = "0.0.0" if !defined $v;

	$v = join('.', map { sprintf("%04d", $_||0) } split /\./, $v, 3);

	return $v;
}


######################################################################
=pod

=item $bool = $epm->is_enabled

Returns C<true> if the EPM is enabled for the current repository.

=cut
######################################################################

sub is_enabled
{
	my( $self ) = @_;

	return -f $self->_is_enabled_filepath;
}


######################################################################
=pod

=item @repoids = $epm->repositories

Returns a list of repository IDs in which this EPM is enabled.

=cut
######################################################################

sub repositories
{
	my( $self ) = @_;

	my @repoids;

	foreach my $repoid (EPrints->repository_ids)
	{
		local $self->{session} = EPrints->repository( $repoid );
		push @repoids, $repoid if $self->is_enabled;
	}

	return @repoids;
}


######################################################################
=pod

=item $filename = $epm->package_filename

Returns the complete package filename.

=cut
######################################################################

sub package_filename
{
	my( $self ) = @_;

	return $self->id . '-' . $self->value( "version" ) . '.epm';
}


######################################################################
=pod

=item $dir = $epm->epm_dir

Path to the epm directory for this EPM.

=cut
######################################################################

sub epm_dir
{
	my( $self ) = @_;

	return $self->repository->config( "base_path" ) . "/lib/epm/" . $self->id;
}


######################################################################
=pod

=item @files = $epm->installed_files

Returns a list of installed files as L<EPrints::DataObj::File>.

=cut
######################################################################

sub installed_files
{
	my( $self ) = @_;

	return if !$self->is_set( "documents" );

	my $install;
	for(@{$self->value( "documents" )})
	{
		$install = $_ if $_->value( "content" ) eq "install";
	}
	return () if !defined $install;

	return @{$install->value( "files" )};
}


######################################################################
=pod

=item @files = $epm->repository_files

Returns the list of configuration files used to enable/configure this
EPM.

=cut
######################################################################

sub repository_files
{
	my( $self ) = @_;
	my $epmid = $self->id;
	return grep {
			$_->value( "filename" ) =~ m# ^epm/$epmid/[^/]+/ #x
		} $self->installed_files;
}


######################################################################
=pod

=item $screen = $epm->control_screen( %params )

Returns the control screen for this EPM. C<%params> are passed to the 
plugin constructor.

=cut
######################################################################

sub control_screen
{
	my( $self, %params ) = @_;

	my $controller = $self->value( "controller" );
	$controller = "EPMC" if !defined $controller;
	$controller = $self->repository->plugin( "Screen::$controller",
			%params,
		);
	$controller = $self->repository->plugin( "Screen::EPMC",
			%params,
		) if !defined $controller;

	return $controller;
}


######################################################################
=pod

=item $epm->serialise( $fh, [ $files ] )

Serialises this EPM to the open file handle C<$fh>. If C<$files> is 
true file contents are included.

=cut
######################################################################

sub serialise
{
	my( $self, $fh, $files ) = @_;

	my $repo = $self->repository;

	$self->_upgrade;

	$self->export( "XML",
		fh => $fh,
		omit_root => 1,
		embed => $files,
	);
}


######################################################################
=pod

=item $url_stem = $epm->url_stem

Returns the URL stem for this EPM. Always just an empty string.

=cut
######################################################################

sub url_stem { "" }


######################################################################
=pod

=item $xhtml_phrase = $epm->html_phrase( $phraseid, [ @pins ] )

Returns and XHTML DOM object of the HTML phrase for and EPM with the
C<$phraseid> using the C<@pins> provided if required.

=cut
######################################################################

sub html_phrase
{
    my( $self, $phraseid, @pins ) = @_;

    return $self->repository->html_phrase( "epm:$phraseid", @pins );
}


######################################################################
=pod

=item $ok = $epm->install( $handler, [ $force ] )

Install the EPM into the system. C<$handler> is a 
L<EPrints::CLIProcessor> or L<EPrints::ScreenProcessor>, used for 
reporting errors.  

C<$force> ignores checking the hashes of the files to make sure they 
have not been changed.

Returns boolean dependent on whether install was successful.

=cut
######################################################################

sub install
{
	my( $self, $handler, $force ) = @_;

	my $repo = $self->repository;

	$self->_upgrade;

	my @files = $self->installed_files;
	if( !@files )
	{
		$handler->add_message( "error", $self->html_phrase( "no_files" ) );
		return 0;
	}

	my %files;

	my $base_path = $repo->config( "base_path" ) . "/lib";

	for(@files)
	{
		my $filename = $_->value( "filename" );
		if( $filename =~ m#[\/]\.# )
		{
			$handler->add_message( "error", $self->html_phrase( "bad_filename",
					filename => $repo->xml->create_text_node( $filename ),
				) );
			return 0;
		}
		my $ctx = Digest::MD5->new;
		$_->get_file(sub { $ctx->add( $_[0] ) });
		my $hash = $ctx->hexdigest;
		if( $hash ne $_->value( "hash" ) )
		{
			$handler->add_message( "error", $self->html_phrase( "bad_checksum",
					filename => $repo->xml->create_text_node( $filename ),
				) );
			return 0;
		}
		my $filepath = "$base_path/$filename";
		if( !$force && -e $filepath )
		{
			open(my $fh, "<", $filepath)
				or die "Error reading from $filename: $!";
			my $ctx = Digest::MD5->new;
			$ctx->addfile( $fh );
			close($fh);
			if( $ctx->hexdigest ne $hash )
			{
				$handler->add_message( "error", $self->html_phrase( "file_exists",
						filename => $repo->xml->create_text_node( $filename ),
					) );
				return 0;
			}
		}
		my $directory = $filepath;
		$directory =~ s/[^\/]+$//;
		if( !-d $directory && !EPrints->system->mkdir( $directory ) )
		{
			$handler->add_message( "error", $self->html_phrase( "file_error",
					filename => $repo->xml->create_text_node( $directory ),
					error => $repo->xml->create_text_node( $! ),
				) );
			return 0;
		}
		$files{$filepath} = $_;
	}

	while(my( $filepath, $file ) = each %files)
	{
		my $fh;
		if( !open($fh, ">", $filepath) )
		{
			$handler->add_message( "error", $self->html_phrase( "file_error",
					filename => $repo->xml->create_text_node( $filepath ),
					error => $repo->xml->create_text_node( $! ),
				) );
			return 0;
		}
		$file->get_file(sub { syswrite($fh, $_[0]) });
		close($fh);
	}

	$self->commit;

	return 1;
}

######################################################################
=pod

=item $ok = $epm->uninstall( $handler, [ $force ] )

Remove the EPM from the system. C<$handler> is a 
L<EPrints::CLIProcessor> or L<EPrints::ScreenProcessor>, used for 
reporting errors.

C<$force> ignores checking the hashes of the files to make sure they
have not been changed.

Returns boolean dependent on whether uninstall was successful.

=cut
######################################################################

sub uninstall
{
	my( $self, $handler, $force ) = @_;

	my $repo = $self->repository;

	$self->_upgrade;

	my @files = $self->installed_files;

	my %files;

	my $base_path = $repo->config( "base_path" ) . "/lib";

	for(@files)
	{
		my $filename = $_->value( "filename" );
		my $filepath = "$base_path/$filename";
		next if !-e $filepath; # skip missing files
		my $hash;
		if( open(my $fh, "<", $filepath) )
		{
			my $ctx = Digest::MD5->new;
			$ctx->addfile( $fh );
			close($fh);
			$hash = $ctx->hexdigest;
		}
		if( !$force && defined($hash) && $hash ne $_->value( "hash" ) )
		{
			$handler->add_message( "error", $self->html_phrase( "bad_checksum",
					filename => $repo->xml->create_text_node( $filename ),
				) );
			return 0;
		}
		$files{$filepath} = 1;
	}

	foreach my $filepath (keys %files)
	{
		if( !unlink($filepath) )
		{
			$handler->add_message( "error", $self->html_phrase( "unlink_failed",
					filename => $repo->xml->create_text_node( $filepath ),
				) );
		}
	}

	for(qw( .epm .epmi ))
	{
		unlink($self->epm_dir . "/" . $self->id . $_);
	}

	# sanity check
	if( length($self->id) )
	{
		EPrints::Utils::rmtree( "$base_path/epm/".$self->id );
	}

	return 1;
}

sub _is_enabled_filepath
{
	my( $self ) = @_;

	return $self->{session}->config( "archiveroot" ) . "/cfg/epm/" . $self->id;
}


######################################################################
=pod

=item $ok = $epm->disable_unchanged

Remove unchanged files from the repository directory. This allows a 
new version of the EPM to be installed/enabled.

Returns boolean dependent on whether disabling unchanged was 
successful.

=cut
######################################################################

sub disable_unchanged
{
	my( $self ) = @_;

	my $repo = $self->repository;

	my $epmid = $self->id;
	my $epmdir = "epm/".$epmid;

	foreach my $file ($self->repository_files)
	{
		my $filename = $file->value( "filename" );
		next if $filename !~ m# ^$epmdir(.+)$ #x;
		my $targetpath = $repo->config( "archiveroot" ) . $1;
		next if !-f $targetpath;

		# be safe and don't clobber an unknown file
		next if !$file->is_set( "hash" );

		my $ctx = Digest::MD5->new;
		open(my $fh, "<", $targetpath) or next;
		$ctx->addfile( $fh );
		close($fh);

		# it was changed by the user
		next if $file->value( "hash") ne $ctx->hexdigest;

		# can safely remove it
		unlink( $targetpath );
	}

	unlink( $self->_is_enabled_filepath );

	return 1;
}


######################################################################
=pod

=item $ok = $epm->enable( $handler )

Enables the EPM for the current repository using C<$handler> to manage
messaging for the enabling process.

Returns boolean dependent on whether enabling was successful.

=cut
######################################################################

sub enable
{
	my( $self, $handler ) = @_;

	my $repo = $self->repository;

	my $datasets = $self->current_datasets;
	my $counters = $self->current_counters;

	my $epmid = $self->id;
	my $epmdir = "epm/".$epmid;

	FILE: foreach my $file ($self->repository_files)
	{
		my $filename = $file->value( "filename" );
		my $filepath = $repo->config( "base_path" ) . "/lib/" . $filename;
		next if $filename !~ m# ^$epmdir(.+)$ #x;

		my $targetpath = $repo->config( "archiveroot" ) . $1;
		if(!-f $filepath)
		{
			$handler->add_message( "warning", $self->html_phrase( "missing",
					filename => $repo->xml->create_text_node( $filepath ),
				) );
			next FILE;
		}
		my $ctx = Digest::MD5->new;
		$file->get_file(sub { $ctx->add( $_[0] ) });
		my $hash = $ctx->hexdigest;
		if( !$file->is_set( "hash" ) )
		{
			$file->set_value( "hash", $hash );
		}
		elsif( $file->value( "hash" ) ne $hash )
		{
			$handler->add_message( "error", $self->html_phrase( "bad_checksum",
					filename => $repo->xml->create_text_node( $filename ),
				) );
			return 0;
		}
		if( -f $targetpath )
		{
			my $thash;
			if(open(my $fh, "<", $targetpath))
			{
				my $ctx = Digest::MD5->new;
				$ctx->addfile( $fh );
				$thash = $ctx->hexdigest;
				close($fh);
			}
			if( $file->value( "hash" ) eq $thash )
			{
				next FILE;
			}
			# something went wrong in a previous upgrade
			elsif( -f "$targetpath.epmsave" )
			{
				$handler->add_message( "error", $self->html_phrase( "file_exists",
						filename => $repo->xml->create_text_node( "$targetpath.epmsave" ),
					) );
			}
			else
			{
				rename($targetpath, "$targetpath.epmsave");
			}
		}
		my $targetdir = $targetpath;
		$targetdir =~ s/[^\/]+$//;
		EPrints->system->mkdir( $targetdir );
		if(open(my $fh, ">", $targetpath))
		{
			$file->get_file(sub { syswrite($fh, $_[0]) });
			close($fh);
		}
	}

	EPrints->system->mkdir( $repo->config( "archiveroot" ) . "/cfg/epm" );
	open( my $fh, ">", $self->_is_enabled_filepath );
	close( $fh );

	# reload the configuration
	$repo->load_config;

	$self->update_datasets( $datasets );
	$self->update_counters( $counters );

	return 1;
}


######################################################################
=pod

=item $ok = $epm->enable( $handler )

Enables the EPM for the current repository using C<$handler> to manage
messaging for the disabling process.

Returns boolean dependent on whether disabling was successful.

=cut
######################################################################

sub disable
{
	my( $self, $handler ) = @_;

	my $repo = $self->repository;

	my $datasets = $self->current_datasets;
	my $counters = $self->current_counters;

	my $epmid = $self->id;
	my $epmdir = "epm/".$epmid;

	foreach my $file ($self->repository_files)
	{
		my $filename = $file->value( "filename" );
		next if $filename !~ m# ^$epmdir(.+)$ #x;
		my $targetpath = $repo->config( "archiveroot" ) . $1;
		next if !-f $targetpath;
		unlink( $targetpath );
	}

	unlink( $self->_is_enabled_filepath );

	# reload the configuration
	$repo->load_config;

	$self->update_datasets( $datasets );
	$self->update_counters( $counters );

	return 1;
}


######################################################################
=pod

=item $conf = $epm->current_counters

Get SQL counters for current data objects.

=cut
######################################################################

sub current_counters
{
	my( $self ) = @_;

	return [$self->{session}->get_sql_counter_ids];
}


######################################################################
=pod

=item $conf = $epm->current_datasets

Get dataset for current data objects.

=cut
######################################################################

sub current_datasets
{
	my( $self ) = @_;

	my $repo = $self->repository;

	my $data = {};

	foreach my $datasetid ( $repo->get_sql_dataset_ids() )
	{
		my $dataset = $repo->dataset( $datasetid );
		$data->{$datasetid}->{dataset} = $dataset;
		foreach my $field ($repo->dataset( $datasetid )->fields)
		{
			next if $field->is_virtual;
			$data->{$datasetid}->{fields}->{$field->name} = $field;
		}
	}

	return $data;
}

######################################################################
=pod

=item $ok = $epm->update_counters( $before )

Update the SQL counters. Removing any counters listed in C<$before> 
that are not used any more. (C<$before> should be retrieved before 
enabling by using L</current_counters>.)

=cut
######################################################################

sub update_counters
{
	my( $self, $before ) = @_;

	my $repo = $self->repository;
	
	my $db = $repo->get_db();

	my %before = map { $_ => 1 } @$before;
	my %after = map { $_ => 1 } $repo->get_sql_counter_ids;

	foreach my $id (keys %before)
	{
		if( !defined delete $after{$id} )
		{
			$db->drop_counter( $id );
		}
	}
	foreach my $id (keys %after)
	{
		$db->create_counter( $id );
	}
}


######################################################################
=pod

=item $ok = $epm->update_datasets( $before )

Update the datasets following any configuration changes made by the 
extension on being enabled. Removing any datasets listed in C<$before>
that are not used any more. C<$before> should be retrieved before 
enabling by using L</current_datasets>.

=cut
######################################################################

sub update_datasets
{
	my( $self, $before ) = @_;

	my $repo = $self->repository;
	
	my $db = $repo->get_db();

	my $rc = 1;

	# create new datasets/fields tables
	foreach my $datasetid ($repo->get_sql_dataset_ids)
	{
		my $dataset = $repo->dataset( $datasetid );
		if( !exists $before->{$datasetid} )
		{
			$db->create_dataset_tables( $dataset );
		}
		else
		{
			foreach my $field ($dataset->fields)
			{
				next if $field->is_virtual;
				if( !exists $before->{$datasetid}->{fields}->{$field->name} )
				{
					$db->add_field( $dataset, $field );
				}
			}
		}
	}

	# destroy removed datasets/fields tables
	foreach my $datasetid ( keys %$before )
	{
		my $dataset = $before->{$datasetid}->{dataset};
		if( !defined $repo->dataset( $datasetid ) )
		{
			$db->drop_dataset_tables( $dataset );
		}
		else
		{
			foreach my $field (values %{$before->{$datasetid}->{fields}})
			{
				if( !$repo->dataset( $datasetid )->has_field( $field->name ) )
				{
					$db->remove_field( $dataset, $field );
				}
			}
		}
	}
	
	return 1;
}


######################################################################
=pod

=item $ok = $epm->publish( $handler, $url, %opts )

Publish this EPM to a remote system using SWORD, using C<$handler> to 
manage messaging for the publishing process.

C<$url> is the URL of the SWORD endpoint or a page containing 
a SWORD link.

Options:

 username - username for Basic auth
 password - password for Basic auth

Returns a boolean dependent on whether the publishing was successful.

=cut
######################################################################

sub publish
{
	my( $self, $handler, $url, %opts ) = @_;

	my $username = $opts{username};
	my $password = $opts{password};

	my $filename = sprintf("%s-%s.epm", $self->id, $self->value( "version" ) );

	my $ua = LWP::UserAgent->new;

	$url = URI->new( $url );

	$ua->credentials( $url->host . ":" . ($url->port || '80'), '*', $username, $password );

	my $req = HTTP::Request->new( POST => $url );

	$req->header( Accept => 'application/atom+xml' );
	$req->header( 'Content-Type' => "application/vnd.eprints.epm+xml;charset=utf-8" );
	$req->header( 'Content-Disposition' => "attachment; filename=\"$filename\"" );
	if( defined $username )
	{
		$password = '' if !defined $password;
		$req->header( Authorization => "Basic ".MIME::Base64::encode(join(":",
			$username,
			$password,
		), "") );
	}
	my $buffer;
	open(my $fh, ">", \$buffer) or die "Error opening scalar: $!";
	$self->serialise( $fh, 1 );
	close($fh);
	$req->content_ref( \$buffer );

	my $r = $ua->request( $req );
	if( $r->code != 201 )
	{
		my $err = $self->{session}->xml->create_document_fragment;
		$err->appendChild( $self->{session}->xml->create_text_node(
				$r->status_line,
			) );
		$err->appendChild( $self->{session}->xml->create_data_element( "pre",
				$r->content,
			) );
		$handler->add_message( "error", $self->html_phrase( "publish_failed",
			base_url => $self->{session}->xml->create_text_node( $url ),
			summary => $err,
			) );
		return undef;
	}

	return $r->header( 'Location' );
}


######################################################################
=pod

=item $ok = $epm->is_set( $fieldid )

Returns a boolean dependent on whether a value is set for the field 
with C<$fieldid> for this EPM.

=cut
######################################################################

sub is_set
{
	my( $self, $fieldid ) = @_;

	my $field = $self->{dataset}->field( $fieldid );
	return $self->SUPER::is_set( $fieldid )
		if !$field->isa( "EPrints::MetaField::Subobject" );

	return EPrints::Utils::is_set( $self->{data}->{$fieldid} );
}

# convert epdata to objects in documents/documents.files
sub _upgrade
{
    my( $self ) = @_;

    my $repo = $self->repository;

    my $document_dataset = $repo->dataset( "document" );
    my $file_dataset = $repo->dataset( "file" );

    my $libpath = $repo->config( "base_path" ) . "/lib";

    # can't retrieve documents if they weren't included
    return if !$self->is_set( "documents" );

    foreach my $doc (@{$self->value( "documents" )})
    {
        if( !UNIVERSAL::isa( $doc, "EPrints::DataObj" ) )
        {
            $doc = $document_dataset->make_dataobj({
                _parent => $self,
                pos => "lib", # horrible - better ideas for get_url?
                %$doc,
            });
        }
        # can't retrieve files if they weren't included
        next if !EPrints::Utils::is_set( $doc->{data}->{files} );
        foreach my $file (@{$doc->value( "files" )})
        {
            if( !UNIVERSAL::isa( $file, "EPrints::DataObj" ) )
            {
                my $content = delete $file->{_content};
                $file = $file_dataset->make_dataobj({
                    _parent => $doc,
                    datasetid => "document",
                    %$file,
                });
                # get the file from the included temp file
                if( defined $content )
                {
                    if( !UNIVERSAL::isa( $content, "File::Temp" ) )
                    {
                        EPrints->abort( "Expected File::Temp in file content but got: $content" );
                    }
                    $file->set_value( "copies", [{
                            pluginid => "Storage::EPM",
                            sourceid => $content,
                    }]);
                }
                # get the file from the installed location
                elsif( -f "$libpath/".$file->value( "filename" ) )
                {
                    $file->set_value( "copies", [{
                            pluginid => "Storage::EPM",
                    }]);
                }
            }
        }
    }
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

=item $xhtml = EPrints::DataObj::EPM::render_controller( $repo, $field, $value, under, undef, $epm )

Returns and XHTML DOM object rendering for the action link of the EPM
using the screen plugin with name supplied by C<$value>.

=cut
######################################################################

sub render_controller
{
    my( $repo, $field, $value, undef, undef, $epm ) = @_;

    $value = "EPMC" if !defined $value;

    my $plugin = $repo->plugin( "Screen::$value" );
    return $repo->xml->create_document_fragment if !defined $plugin;

    return $plugin->render_action_link;
}


######################################################################
=pod

=item $xhtml = EPrints::DataObj::EPM::render_icon( $repo, $field, $value, under, undef, $epm )

Returns and XHTML DOM object rendering for the icon of the EPM using
the image with the filename supplied by C<$value>.

=cut
######################################################################

sub render_icon
{
    my( $repo, $field, $value, undef, undef, $epm ) = @_;

    $value = "images/epm/unknown.png" if !EPrints::Utils::is_set( $value );

    my $url = $value =~ /^https?:/ ?
        $value :
        $repo->current_url( host => 1, path => "static", $value );

    return $repo->xml->create_element( "img",
        width => "70px",
        src => $url,
        alt => $epm->value( "title" ) . " icon",
    );
}


1;

######################################################################
=pod

=back

=head1 SEE ALSO

L<EPrints::DataObj> and L<EPrints::DataSet>

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

