######################################################################
#
# EPrints::DataObj::Cachemap
#
######################################################################
#
#
######################################################################

=pod

=for Pod2Wiki

=head1 NAME

B<EPrints::DataObj::Cachemap> - Cache tables

=head1 DESCRIPTION

This is an internal class that shouldn't be used outside 
L<EPrints::Database>.

=head1 CORE METADATA FIELDS

=over 4

=item cachemapid (int)

The unique numerical ID of this cachemap object.

=item created (int)

The time the cachemap record was created in seconds since start of 
last epoch.

=item lastused (int)

The time the cachemap record was last used in seconds since start of
last epoch.

=item searchexap (longtext)

A serialisation of the search carried out that is stored in this
cachemap record.

=item oneshot (boolean)

DEPRECATED. A boolean to record whether the cache is for single use
where it will be created, used and immediately deleted.  Such as 
type of caching is no longer required.

=back

=head1 REFERENCES AND RELATED OBJECTS

=over 4

=item userid (itemref)

Reference to the userid of the user who caused the cachemap record
to be created, if this is known.

=back

=head1 INSTANCE VARIABLES

See L<EPrints::DataObj|EPrints::DataObj#INSTANCE_VARIABLES>.

=head1 METHODS

=cut
######################################################################

package EPrints::DataObj::Cachemap;

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

=item EPrints::DataObj::Cachemap->create_from_data( $session, $data, $dataset )

Creates a new cachemap data object in the database.

C<$dataset> is the dataset it will belong to.

C<$data> is the data structured as with L<EPrints::DataObj#new_from_data>.

This will create sub-objects as well.

Call this via:

 $dataset->create_object( $session, $data )

=cut
######################################################################

sub create_from_data
{
	my( $class, $session, $data, $dataset ) = @_;

	# if we're online delay clean-up until Apache cleanup, which will prevent
	# the request blocking
	if( $session->get_online )
	{
		$session->get_request->pool->cleanup_register(sub {
				__PACKAGE__->cleanup( $session )
			}, $session );
	}
	else
	{
		$class->cleanup( $session );
	}

	return $class->SUPER::create_from_data( $session, $data, $dataset );
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

=item $fields = EPrints::DataObj::Access->get_system_field_info

Returns an array describing the system metadata of the cachemap
dataset.

=cut
######################################################################

sub get_system_field_info
{
	my( $class ) = @_;

	return
	( 
		{ name=>"cachemapid", type=>"counter", required=>1, can_clone=>0,
			sql_counter=>"cachemapid" },

		{ name=>"created", type=>"int", required=>1, text_index=>0 },

		{ name=>"lastused", type=>"int", required=>0, text_index=>0 },

		{ name=>"userid", type=>"itemref", datasetid=>"user", required=>0, text_index=>0 },

		{ name=>"searchexp", type=>"longtext", required=>0, text_index=>0 },

		{ name=>"oneshot", type=>"boolean", required=>0, text_index=>0 },
	);
}


######################################################################
=pod

=over 4

=item $dataset = EPrints::DataObj::Cachemap->get_dataset_id

Returns the ID of the L<EPrints::DataSet> object to which this record 
belongs.

=cut
######################################################################

sub get_dataset_id
{
	return "cachemap";
}


######################################################################
=pod

=item $defaults = EPrints::DataObj::Cachemap->get_defaults( $session, $data )

Return default values for this object based on the starting C<$data>.

=cut
######################################################################

sub get_defaults
{
	my( $class, $session, $data, $dataset ) = @_;
 	
	$class->SUPER::get_defaults( $session, $data, $dataset );

	$data->{created} = time();

	return $data;
}


######################################################################
=pod

=item $dropped = EPrints::DataObj::Cachemap->cleanup( $repo )

Clean up old caches for specified C<$repo>. 

Returns the number of caches dropped.

=cut
######################################################################

sub cleanup
{
	my( $class, $repo ) = @_;

	my $dropped = 0;

	my $dataset = $repo->dataset( $class->get_dataset_id );
	my $cache_maxlife = $repo->config( "cache_maxlife" );
	my $cache_max = $repo->config( "cache_max" );

	my $expired_time = time() - $cache_maxlife * 3600;

	# cleanup expired cachemaps
	my $list = $dataset->search(
		filters => [
			{ meta_fields => [qw( created )], value => "..$expired_time" },
		] );
	$list->map( sub {
		my( undef, undef, $cachemap ) = @_;

		$dropped++ if $cachemap->remove();
	} );

	# enforce a limit on the maximum number of cachemaps to allow
	if( defined $cache_max && $cache_max > 0)
	{
		my $count = $repo->database->count_table( $dataset->get_sql_table_name );
		if( $count >= $cache_max )
		{
			my $list = $dataset->search(
				custom_order => "created", # oldest first
				limit => ($count - ($cache_max-1))
			);
			$list->map( sub {
				my( undef, undef, $cachemap ) = @_;

				if( $count-- >= $cache_max ) # LIMIT might fail!
				{
					$dropped++ if $cachemap->remove();
				}
			} );
		}
	}

	return $dropped;
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

=item $rc = $cachemap->remove

Remove this record from the data set and the cache table from the 
database.

Returns a code based of success of removing record / cache table.

=cut
######################################################################

sub remove
{
	my( $self ) = @_;
	
	my $rc = 1;
	
	my $database = $self->{session}->get_database;

	$rc &&= $database->remove(
		$self->{dataset},
		$self->get_id );

	my $table = $self->get_sql_table_name;

	# cachemap table might not exist
	$database->drop_table( $table );

	return $rc;
}


######################################################################
=pod

=item $sql_name = $cachemap->get_sql_table_name

Returns the name of the cache table for this cachemap record.

=cut
######################################################################

sub get_sql_table_name
{
	my( $self ) = @_;

	return "cache" . $self->get_id;
}

######################################################################
=pod

=item $ok = $cachemap->create_sql_table( $dataset )

Create the cachemap database table that can store IDs for the 
specified C<$dataset>.

Returns code based on the success of creating cache table.

=cut
######################################################################

sub create_sql_table
{
	my( $self, $dataset ) = @_;

	my $cache_table = $self->get_sql_table_name;
	my $key_field = $dataset->get_key_field;
	my $database = $self->{session}->get_database;

	my $rc = $database->_create_table( $cache_table, ["pos"], [
			$database->get_column_type( "pos", EPrints::Database::SQL_INTEGER, EPrints::Database::SQL_NOT_NULL ),
			$key_field->get_sql_type( $self->{session} ),
			]);

	return $rc;
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

