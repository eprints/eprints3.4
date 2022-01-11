######################################################################
#
# EPrints::DataObj::UploadProgress
#
######################################################################
#
#
######################################################################


=pod

=for Pod2Wiki

=head1 NAME

B<EPrints::DataObj::UploadProgress> - uploads-in-progress state

=head1 DESCRIPTION

This is an internal class, which inherits from L<EPrints::DataObj>. 
It is just for managing the progress of files being uploaded to 
EPrints.

=head1 CORE METADATA FIELDS

=over 4

=item progressid (text)

The unique identifier for an upload progress.  This is a 32-character
hexadecimal string.

=item expires (int)

The time (in seconds since the start of the last epoch) when this
upload progress will expire if it is not completed.

=item size (bigint)

The total size in bytes of the file being uploaded.

=item size (bigint)

The number of bytes of the file being uploaded that have already been
received.

=back

=head1 REFERENCES AND RELATED OBJECTS

None.

=head1 INSTANCE VARIABLES

See L<EPrints::DataObj|EPrints::DataObj#INSTANCE_VARIABLES>.

=head1 METHODS

=cut

package EPrints::DataObj::UploadProgress;

@ISA = ( 'EPrints::DataObj' );

use EPrints;

use strict;


######################################################################
=pod

=head2 Constructor Methods

=cut
######################################################################

######################################################################
=pod

=over 4

=item $progress = EPrints::DataObj::UploadProgress->new_from_request( $session )

Creates and returns a new upload progress data object based on the
current request.

Returns C<undef> if no file upload is pointed to by this request.

=cut
######################################################################

sub new_from_request
{
    my( $class, $session ) = @_;

    my $uri = $session->get_request->unparsed_uri;

    my $progressid = ($uri =~ /progress_?id=([a-fA-F0-9]{32})/)[0];

    if( !$progressid )
    {
        return undef;
    }

    my $progress;

    for(1..16)
    {
        $progress = EPrints::DataObj::UploadProgress->new( $session, $progressid );
        last if defined $progress;
        select(undef, undef, undef, 0.250);
    }

    return $progress;
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

=item $fields = EPrints::DataObj::UploadProgress->get_system_field_info

Returns an array describing the system metadata of the upload progress
dataset.

=cut
######################################################################

sub get_system_field_info
{
	my( $class ) = @_;

	return
	( 
		{ name=>"progressid", type=>"text", required=>1 },

		{ name=>"expires", type=>"int", required=>1 },

		{ name=>"size", type=>"bigint", required=>1 },

		{ name=>"received", type=>"bigint", required=>1 },
	);
}


######################################################################
=pod

=item $dataset = EPrints::DataObj::UploadProgress->get_dataset_id

Returns the id of the L<EPrints::DataSet> object to which this record 
belongs.

=cut
######################################################################

sub get_dataset_id
{
	return "upload_progress";
}


######################################################################
=pod

=item $progress = EPrints::DataObj::UploadProgress->remove_expired( $session )

Remove all upload progress data objects where C<expired> is earlier
than the current time.

=cut
######################################################################

sub remove_expired
{
	my( $class, $session ) = @_;

	my $dataset = $session->dataset( $class->get_dataset_id );

	my $dbh = $session->get_database;

	my $Q_table = $dbh->quote_identifier( $dataset->get_sql_table_name() );
	my $Q_expires = $dbh->quote_identifier( "expires" );
	my $Q_time = $dbh->quote_int( time() );

	$dbh->do( "DELETE FROM $Q_table WHERE $Q_expires <= $Q_time" );
}


######################################################################
=pod

=item $defaults = EPrints::DataObj::UploadProgress->get_defaults( $session, $data )

Returns default values for this object based on the starting C<$data>.

Sets C<expires> to one week from now.

=cut
######################################################################

sub get_defaults
{
	my( $class, $session, $data ) = @_;
	
	$data->{expires} = time() + 60*60*24*7; # 1 week

	return $data;
}


######################################################################
=pod

=back

=head2 Object Methods

=cut
######################################################################

######################################################################
=pod

=item $progress->update_cb( $filename, $buffer, $bytes_read, $progress )

Updates callback for use with L<CGI>. Limits database writes to a 
minimum of 1 second between updates of the C<received> field to the
value provided by C<$bytes_read>.

=cut
######################################################################

sub update_cb
{
	my( $filename, $buffer, $bytes_read, $self ) = @_;

	$self->set_value( "received", $bytes_read );
	if( !defined( $self->{_mtime} ) || (time() - $self->{_mtime}) > 0 )
	{
		$self->commit;
		$self->{_mtime} = time();
	}
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
