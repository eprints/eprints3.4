######################################################################
#
# EPrints::System::linux
#
######################################################################
#
#
######################################################################


=pod

=for Pod2Wiki

=head1 NAME

B<EPrints::System::MSWin32> - Wrappers for MS Windows 32 system calls.

=head1 DESCRIPTPION

This class provides MS Windows 32 specific system calls required by 
EPrints.

This class inherits from L<EPrints::System>.

=head1 INSTANCE VARIABLES

See L<EPrints::System|EPrints::System#INSTANCE_VARIABLES>.

=head1 METHODS

=cut
######################################################################

package EPrints::System::MSWin32;

@ISA = qw( EPrints::System );

use Win32::Service;
use Win32::Daemon;
use Win32::DriveInfo;

use EPrints::Index::Daemon::MSWin32;

use strict;


######################################################################
=pod

=over 4

=item $sys->init

Perform any platform-specific initialisation is not required on MS 
Windows 32 systems.

=cut
######################################################################

sub init { }


######################################################################
=pod

=item $sys->chmod( $mode, @files )

Changing the access control for C<@files> is not possible on MS 
Windows 32 systems.

=cut
######################################################################

sub chmod { } 


######################################################################
=pod

=item $sys->chown( $uid, $gid, @files )

Changing the user/group ownership on C<@files> is not possible on MS
Windows 32 systems.

=cut
######################################################################

sub chown { }


######################################################################
=pod

=item $sys->chown_for_eprints( @files )

Changing the user/group ownership on C<@files> to the current EPrints
user is not possible on MS Windows 32 systems.

=cut
######################################################################

sub chown_for_eprints { }


######################################################################
=pod

=item $gid = $sys->getgrnam( $group )

Getting the group name for C<$group> is not possible on MS Windows 32 
systems.

=cut
######################################################################

sub getgrnam { }


######################################################################
=pod

=item ($user, $crypt, $uid, $gid ) = $sys->getpwnam( $user )

Getting the login name, password crypt, UID and GID for user C<$user>
is not possible on MS Windows 32 systems.

=cut
######################################################################

sub getpwnam { }


######################################################################
=pod

=item $sys->test_uid

Testing whether the current user is the same that is configured in
L<EPrints::SystemSettings> is not possible on MS Windows 32 systems.

=cut
######################################################################

sub test_uid { }



######################################################################
=pod

=item $sys->free_space( $dir )

Returns the amount of free space (in bytes) available at C<$dir>.
As this is a MS Windows 32 system C<$dir> may contain a drive 
(e.g. C<C:>).

=cut
######################################################################

sub free_space
{
	my( $self, $dir ) = @_;

	$dir =~ s/\//\\/g;

	my $drive = $dir =~ /^([a-z]):/i ? $1 : 'c';

	my $free_space = (Win32::DriveInfo::DriveSpace($drive))[6];

	if( !defined $free_space )
	{
		EPrints->abort( "Win32::DriveSpace::DriveSpace $dir: $^E" );
	}

	return $free_space;
}


######################################################################
=pod

=item $bool = $sys->proc_exists( $pid )

Returns C<true> if a process exists for ID with C<$pid> or access is
denied to the process, implying it must exist.

Returns C<false> otherwise.

=cut
######################################################################

sub proc_exists
{
	my( $self, $pid ) = @_;

	return 1 if Win32::Process::Open(my $obj, $pid, 0) != 0;
	return 1 if $^E == 5; # Access is denied
	return 0;
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

	my( $drive, $dir ) = split /:/, $full_path, 2;
	($drive,$dir) = ($dir,$drive) if !$dir;

	if( !$drive )
	{
		if( $EPrints::SystemSettings::conf->{base_path} =~ /^([A-Z]):/i )
		{
			$drive = $1;
		}
	}

	my @parts = grep { length($_) } split "/", $dir;
	foreach my $i (1..$#parts)
	{
		my $dir = "$drive:/".join("/", @parts[0..$i]);
		if( !-d $dir && !CORE::mkdir($dir) )
		{
			print STDERR "Failed to mkdir $dir: $!\n";
			return 0;
		}
	}

	return 1;
}


######################################################################
=pod

=item $quoted = $sys->quotemeta( $path )

Quote C<$path> so it is safe to be used in a shell call.

=cut
######################################################################

sub quotemeta
{
	my( $self, $str ) = @_;

	$str =~ s/"//g; # safe but means you can't pass "
	$str = "\"$str\"" if $str =~ /[\s&|<>?]/;

	return $str;
}

1;


######################################################################
=pod

=back

=head1 SEE ALSO

L<EPrints::System>

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

