######################################################################
#
# EPrints::System
#
######################################################################
#
#
######################################################################


=pod

=for Pod2Wiki

=head1 NAME

B<EPrints::System> - Wrappers for system calls.

=head1 DESCRIPTION

When you call a method in this class, it is sent to the appropriate 
C<EPrints::System> sub-module:

 EPrints::System::darwin
 EPrints::System::freebsd
 EPrints::System::linux
 EPrints::System::MSWin32
 EPrints::System::openbsd
 EPrints::System::solaris

By default this will be L<EPrints::System::linux>.

Which module is used is configured by the C<platform> setting in 
L<EPrints::SystemSettings>

All file and directory names are absolute and joined by the 
UNIX separator character C</>.

=head1 INSTANCE VARIABLES

=over 4

=item $self->{uid}

The user ID of this EPrints system.

=item $self->{gid}

The group ID of this EPrints system.

=back

=head1 METHODS

=cut
######################################################################

package EPrints::System;

use strict;
use File::Copy;
use Digest::MD5;


######################################################################
=pod

=head2 Constructor Methods

=cut
######################################################################

######################################################################
=pod

=over 4

=item $sys = EPrints::System->new

Returns a new EPrints System object.

=cut
######################################################################

sub new
{
	my( $class, %opts ) = @_;

	my $osname = $^O;

	my $platform = $EPrints::SystemSettings::conf->{platform};
	if( defined $platform && $platform ne "unix" && $platform ne "win32" )
	{
		$osname = $platform;
	}

	my $real_class = $class;
	$real_class = __PACKAGE__ . "::$osname" if $real_class eq __PACKAGE__;

	eval "use $real_class; 1";
	die $@ if $@;

	my $self = bless \%opts, $real_class;

	$self->init();

	return $self;
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

=item $sys->init

Perform any platform-specific initialisation.

=cut
######################################################################

sub init
{
	my( $self ) = @_;

	if(
		!defined($EPrints::SystemSettings::conf->{user}) ||
		!defined($EPrints::SystemSettings::conf->{user})
	  )
	{
		EPrints->abort( "'user' and 'group' must be configured. Perhaps you need to add them to perl_lib/EPrints/SystemSettings.pm?" );
	}

	if( !defined $self->{uid} )
	{
		$self->{uid} = ($self->getpwnam( $EPrints::SystemSettings::conf->{user} ))[2];
	}
	if( !defined $self->{gid} )
	{
		$self->{gid} = $self->getgrnam( $EPrints::SystemSettings::conf->{group} );
	}

	if( !defined $self->{uid} )
	{
		EPrints->abort( sprintf( "'%s' is not a valid user on this system - check your SystemSettings",
			$EPrints::SystemSettings::conf->{user}
		) );
	}
	if( !defined $self->{gid} )
	{
		EPrints->abort( sprintf( "'%s' is not a valid group on this system - check your SystemSettings",
			$EPrints::SystemSettings::conf->{group}
		) );
	}
}


######################################################################
=pod

=item $sys->chmod( $mode, @files )

Change the access control on C<@files> listed to C<$mode>.

=cut
######################################################################

sub chmod 
{
	my( $self, $mode, @files ) = @_;

	return CORE::chmod( $mode, @files );
} 


######################################################################
=pod

=item $sys->chown( $uid, $gid, @files )

Change the user and group on C<@files> to C<$uid> and C<$gid>. C<$uid> 
and C<$gid> are as returned by L</getpwnam> (usually numeric).

=cut
######################################################################

sub chown 
{
	my( $self, $mode, @files ) = @_;

	return CORE::chown( $mode, @files );
}


######################################################################
=pod

=item $sys->chown_for_eprints( @files )

Change the user and group on C<@files> to the current EPrints user and 
group.

=cut
######################################################################

sub chown_for_eprints
{
	my( $self, @files ) = @_;

	$self->chown( $self->{uid}, $self->{gid}, @files );
}


######################################################################
=pod

=item $gid = $sys->getgrnam( $group )

Return the system group ID of the group C<$group>.

=cut
######################################################################

sub getgrnam 
{
	return CORE::getgrnam( $_[1] );
}


######################################################################
=pod

=item ($user, $crypt, $uid, $gid ) = $sys->getpwnam( $user )

Return the login name, password crypt, UID and GID for user C<$user>.

=cut
######################################################################

sub getpwnam 
{
	return CORE::getpwnam( $_[1] );
}


######################################################################
=pod

=item $sys->current_uid

Returns the current UID of the user running this process.

=cut
######################################################################

sub current_uid
{
	return $>;
}


######################################################################
=pod

=item $sys->test_uid

Test whether the current user is the same that is configured in 
L<EPrints::SystemSettings>.

=cut
######################################################################

sub test_uid
{
	my( $self ) = @_;

	my $cur_uid = $self->current_uid;
	my $req_uid = $self->{uid};

	if( $cur_uid ne $req_uid )
	{
		my $username = (CORE::getpwuid($cur_uid))[0];
		my $req_username = (CORE::getpwuid($req_uid))[0];

		EPrints::abort( 
"We appear to be running as user: $username ($cur_uid)\n".
"We expect to be running as user: $req_username ($req_uid)" );
	}
}


######################################################################
=pod

=item $sys->mkdir( $full_path, $perms )

Create a directory C<$full_path> (including parent directories as 
necessary) set permissions described by C<$perms>. If C<$perms> is 
undefined defaults to C<dir_perms> in L<EPrints::SystemSettings>.

=cut
######################################################################

sub mkdir
{
	my( $self, $full_path, $perms ) = @_;

	# Default to "dir_perms"
	$perms = eval($EPrints::SystemSettings::conf->{"dir_perms"}) if @_ < 3;
	if( !defined( $perms ))
	{
		EPrints->abort( "mkdir requires dir_perms is set in SystemSettings");
	}

	my $dir = "";
	my @parts = grep { length($_) } split( "/", "$full_path" );
	my @newdirs;
	while( scalar @parts )
	{
		$dir .= "/".(shift @parts );
		if( !-d $dir )
		{
			my $ok = CORE::mkdir( $dir, $perms );
			if( !$ok )
			{
				print STDERR "Failed to mkdir $dir: $!\n";
				return 0;
			}
			push @newdirs, $dir;
		}
	}

	# mkdir ignores sticky bits (01000, 02000, 04000)
	$self->chmod( $perms, @newdirs );
	# fix the file ownership
	$self->chown_for_eprints( @newdirs );

	return 1;
}

######################################################################
=pod

=item $sys->exec( $repository, $cmd_id, %map )

Executes certain named task C<$cmd_id> on C<$repository>, which were 
once (and may be) handled by external binaries. This allows a 
per-platform solution to each task. E.g. unpacking a .tar.gz file.

C<%map> includes variable names and values that need to be mapped into
the task command.

Returns the numerical return code from the executed command.

=cut
######################################################################

sub exec 
{
	my( $self, $repository, $cmd_id, %map ) = @_;

 	if( !defined $repository ) { EPrints::abort( "exec called with undefined repository" ); }

	my $command = $repository->invocation( $cmd_id, %map );

	my $rc = 0xffff & system $command;

	if( $rc != 0 )
	{
		$repository->log( Carp::longmess("Error ".($rc>>8)." from $cmd_id command: $command") );
	}

	return $rc;
}	


######################################################################
=pod

=item $rc = $sys->read_exec( $repo, $tmp, $cmd_id, %map )

Same as </exec> but write C<STDOUT> and C<STDERR> to the filename
specified by C<$tmp>.

=cut
######################################################################

sub read_exec
{
	my( $self, $repo, $tmp, $cmd_id, %map ) = @_;

	my $cmd = $repo->invocation( $cmd_id, %map );

	return $self->_read_exec( $repo, $tmp, $cmd );
}


######################################################################
=pod

=item $rc = $sys->read_perl_script( $repo, $tmp, @args )

Executes Perl with arguments from C<@args>, including the current 
EPrints library path. Writes C<STDOUT> and C<STDERR> from the script 
to file with name C<$tmp>.

Returns C<0> on success.

=cut
######################################################################

sub read_perl_script
{
	my( $self, $repo, $tmp, @args ) = @_;

	my $perl = $repo->config( "executables", "perl" );

	my $perl_lib = $repo->config( "base_path" ) . "/perl_lib";

	unshift @args, "-I$perl_lib";

	return $self->_read_exec( $repo, $tmp, $perl, @args );
}

sub _read_exec
{
	my( $self, $repo, $tmp, $cmd, @args ) = @_;

	my $perl = $repo->config( "executables", "perl" );

	my $fn = Data::Dumper->Dump( ["$tmp"], ['fn'] );
	my $args = Data::Dumper->Dump( [[$cmd, @args]], ['args'] );

	if( $repo->{noise} >= 2 )
	{
		$repo->log( "Executing: $cmd @args" );
	}

	my $script = <<EOP;
$fn$args
open(STDOUT,">>", \$fn);
open(STDERR,">>", \$fn);
exit(system( \@\{\$args\} ) >> 8);
EOP

	my $rc = system( $perl, "-e", $script );

	seek($tmp,0,0); # reset the file handle

	return 0xffff & $rc;
}


######################################################################
=pod

=item $sys->free_space( $dir )

Return the amount of free space (in bytes) available at C<$dir>. 
C<$dir> may contain a drive (e.g. C<C:>) on Windows platforms.

=cut
######################################################################

sub free_space
{
	my( $self, $dir ) = @_;

	# use -P for most UNIX platforms to get POSIX-compatible block counts

	$dir = $self->quotemeta($dir);
	open(my $fh, "df -P $dir|") or EPrints->abort( "Error calling df: $!" );

	my @output = <$fh>;
	my( $dev, $size, $used, $free, $capacity, undef ) = split /\s+/, $output[$#output], 6;

	return $free * 1024; # POSIX output mode block is 512 bytes
}


######################################################################
=pod

=item $bool = $sys->proc_exists( $pid )

Returns C<true> if a process exists for ID with C<$pid>.

Returns C<undef> if process identification is unsupported.

=cut
######################################################################

sub proc_exists
{
	my( $self, $pid ) = @_;

	return `ls /proc/ | grep '^$pid\$' | wc -l`;
}


######################################################################
=pod

=item $filename = $sys->get_hash_name

Returns the last part of the filename of the hashfile for a document.
(yes, it's a bad function name.)

=cut
######################################################################

sub get_hash_name
{
	return EPrints::Time::get_iso_timestamp().".xsh";
}


######################################################################
=pod 

=item $backup = write_config_file( $path, $content, [ %opts ] )

Write a config file containing C<$content> to the file located at 
C<$path>.

If C<$content> is undefined no file will be written.

C<%opts> not currently used but reserved for future use.

=cut
######################################################################

sub write_config_file
{
	my( $self, $path, $content, %opts ) = @_;

	my $rc;

	EPrints->abort( "Can't backup hidden or relative-path files: $path" )
		if $path =~ /\/\./;

	return if !-e $path && !defined $content;

	my $new_md5 = defined $content ? Digest::MD5::md5( $content ) : "";

	if( -e $path )
	{
		EPrints->abort( "Can't backup something that is not a file: $path" )
			if !-f _;
		open(my $fh, "<", $path)
			or EPrints->abort( "Error opening file $path: $!" );
		my $md5 = Digest::MD5->new;
		$md5->addfile( $fh );
		$md5 = $md5->digest;
		close($fh);

		return if $new_md5 eq $md5;

		my @now = localtime();

		my $newpath = sprintf("%s.%04d%02d%02d",
			$path,
			$now[5]+1900,
			$now[4]+1,
			$now[3]
		);
		my $i = 1;
		while(-e sprintf("%s%02d",$newpath,$i))
		{
			++$i;
		}
		$newpath = sprintf("%s%02d", $newpath, $i);

		File::Copy::copy( $path, $newpath );

		$rc = $newpath;
	}

	open(my $fh, ">", $path)
		or EPrints->abort( "Error opening $path: $!" );
	print $fh $content;
	close($fh);

	return $rc;
}


######################################################################
=pod

=item $quoted = $sys->quotemeta( $path )

Quote C<$path> so it is safe to be used in a shell call.

=cut
######################################################################

sub quotemeta
{
	my( $self, $path ) = @_;

	return CORE::quotemeta($path);
}


######################################################################
=pod

=item $tmpfile = $sys->capture_stderr

Captures STDERR output into a temporary file and return a file handle
to it.

=cut
######################################################################

sub capture_stderr
{
	my( $self ) = @_;

	no warnings; # stop perl moaning about OLD_STDERR
	my $tmpfile = File::Temp->new;

	open(OLD_STDERR, ">&STDERR") or die "Error saving STDERR: $!";
	open(STDERR, ">", $tmpfile) or die "Error redirecting STDERR: $!";

	return $tmpfile;
}


######################################################################
=pod

=item $sys->restore_stderr( $tmpfile )

Restores C<STDERR> after capturing. 

If C<$tmpfile> is set, reset seek and sysseek to the start of this 
file. 

=cut
######################################################################

sub restore_stderr
{
	my( $self, $tmpfile ) = @_;

	open(STDERR, ">&OLD_STDERR") or die "Error restoring STDERR: $!";

	seek($tmpfile, 0, 0), sysseek($tmpfile, 0, 0) if defined $tmpfile;
}


######################################################################
=pod

=item $path = $sys->join_path( @parts )

Returns C<@parts> joined together using the current system's path 
separator.

=cut
######################################################################

sub join_path
{
	my( $self, @parts ) = @_;

	return join '/', @parts;
}


######################################################################
=pod

=item $ext = $sys->file_extension( $filename )

Returns the file extension of $filename including the leading C<.> 
e.g. C<.tar.gz>.

Returns empty string if there is no file extension.

=cut
######################################################################

sub file_extension
{
	my( $self, $filename ) = @_;

	if( $filename =~ /((?:\.[a-z0-9]{1,4}){1,2})$/i )
	{
		return $1;
	}

	return "";
}


######################################################################
=pod

=item $filepath = $sys->sanitise( $filepath )

Replaces restricted file system characters and control characters in 
C<$filepath> with C<_>.

Removes path-walking elements (C<.> and C<..>) from the front of any 
path components and removes the leading C</>.

=cut
######################################################################

sub sanitise
{
	my( $self, $filepath, $repo ) = @_;

	$filepath = Encode::decode_utf8( $filepath )
		if !utf8::is_utf8( $filepath );

	# control characters + Win32 restricted
	$filepath =~ s![\x00-\x0f\x7f<>:"\\|?*]!_!g;

	$filepath =~ s!\.+/!/!g; # /foo/../bar
	$filepath =~ s!/\.+!/!g; # /foo/.bar/
	$filepath =~ s!//+!/!g; # /foo//bar
	$filepath =~ s!^/!!g;

	# This allows for custom substitutions to be set in the Archive
	# It is useful for replacing characters which are encoded for HTTP
	# There are sample substitutions in the optional_filename_sanitise.pl file in the repo config

	$repo ||= EPrints->new->current_repository;
	if ( defined $repo && ref( $repo ) eq "EPrints::Repository" && $repo->can_call( "optional_filename_sanitise" ) )
	{
		$filepath = $repo->call( "optional_filename_sanitise", $repo, $filepath );
	}


	return $filepath;
}


######################################################################
=pod

=item @paths = $sys->bin_paths

Get the list of absolute directories to search for system tools (e.g. 
C<convert>).

=cut
######################################################################

sub bin_paths
{
	my( $self ) = @_;

	return split ':', ($ENV{PATH} || "");
}

1;


######################################################################
=pod

=back

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
