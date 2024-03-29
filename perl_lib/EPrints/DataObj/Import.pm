######################################################################
#
# EPrints::DataObj::Import
#
######################################################################
#
#
######################################################################

=pod

=for Pod2Wiki

=head1 NAME

B<EPrints::DataObj::Import> - bulk imports logging

=head1 DESCRIPTION

This class represents a mass import of record's (i.e. eprint data 
objects) into a repository.

=head1 CORE METADATA FIELDS

=over 4

=item importid (counter)

Unique ID for the import.

=item datestamp (timestamp)

Time import record was created.

=item source_repository (text)

Source entity from which this import came.

=item url (longtext)

Location of the imported content (e.g. the file name).

=item description (longtext)

Human-readable description of the import.

=item last_run (time)

Time the import was last started.

=item last_success (time)

Time the import was last successfully completed.

=back

=head1 REFERENCES AND RELATED OBJECTS

=over 4

=item userid (itemref)

ID of the user responsible for causing the import.

=back

=head1 INSTANCE VARIABLES

See L<EPrints::DataObj|EPrints::DataObj#INSTANCE_VARIABLES>.

=head1 METHODS

=cut

package EPrints::DataObj::Import;

@ISA = ( 'EPrints::DataObj' );

use EPrints;

use strict;


######################################################################
=pod

=head2 Class Methods

=cut
######################################################################

######################################################################
=pod

=over 4

=item $fields = EPrints::DataObj::Import->get_system_field_info

Returns an array describing the system metadata of the import dataset.

=cut
######################################################################

sub get_system_field_info
{
	my( $class ) = @_;

	return
	( 
		{ name=>"importid", type=>"counter", required=>1, can_clone=>0,
			sql_counter=>"importid" },

		{ name=>"datestamp", type=>"timestamp", required=>1, },

		{ name=>"userid", type=>"itemref", required=>0, datasetid => "user" },

		{ name=>"source_repository", type=>"text", required=>0, },

		{ name=>"url", type=>"longtext", required=>0, },

		{ name=>"description", type=>"longtext", required=>0, },

		{ name=>"last_run", type=>"time", required=>0, },

		{ name=>"last_success", type=>"time", required=>0, },

	);
}

######################################################################
=pod

=item $dataset = EPrints::DataObj::Import->get_dataset_id

Returns the ID of the L<EPrints::DataSet> object to which this record 
belongs.

=cut
######################################################################

sub get_dataset_id
{
	return "import";
}


######################################################################
=pod

=back 

=head2 Object Methods

=cut
######################################################################

######################################################################
=pod

=over

=item $list = $import->run( $processor )

Run this bulk import. Returns a list of created eprint data objects. 
C<$processor> is used for reporting errors.

=cut
######################################################################

sub run
{
	my( $self, $processor ) = @_;

	$self->set_value( "last_run", EPrints::Time::get_iso_timestamp() );
	$self->commit();

	my $session = $self->{session};

	my $url = $self->get_value( "url" );

	if( !EPrints::Utils::is_set( $url ) )
	{
		$processor->add_message( "error", $session->make_text( "Can't run import that doesn't contain a URL" ) );
		return;
	}

	my $file = File::Temp->new;

	my $ua = LWP::UserAgent->new;
	my $r = $ua->get( $url, ":content_file" => "$file" );

	if( !$r->is_success )
	{
		my $err = $session->make_doc_fragment;
		$err->appendChild( $session->make_text( "Error requesting " ) );
		$err->appendChild( $session->render_link( $url ) );
		$err->appendChild( $session->make_text( ": ".$r->status_line ) );
		$processor->add_message( "error", $err );
		return;
	}

	my $plugin = EPrints::DataObj::Import::XML->new(
			session => $session,
			import => $self,
		);

	my $list = $plugin->input_file(
			filename => "$file",
			dataset => $session->dataset( "eprint" ),
		);

	$self->set_value( "last_success", EPrints::Time::get_iso_timestamp() );
	$self->commit();

	return $list;
}


######################################################################
=pod

=item $import->map( $fn, $info )

Maps the function C<$fn> onto every eprint in this import.

C<$info> provides additional information that may need to be processed
by the function C<$fn>.

=cut
######################################################################

sub map
{
	my( $self, $fn, $info ) = @_;

	my $list = $self->get_list();

	$list->map($fn, $info );

	$list->dispose;
}


######################################################################
=pod

=item $import->clear

Clear the contents of this bulk import.

=cut
######################################################################

sub clear
{
	my( $self ) = @_;

	$self->map(sub {
		my( $session, $dataset, $eprint ) = @_;

		$eprint->remove();
	});
}


######################################################################
=pod

=item $list = $import->get_list

Returns a list of the items in this import.

=cut
######################################################################

sub get_list
{
	my( $self ) = @_;

	my $dataset = $self->{session}->get_repository->get_dataset( "eprint" );

	my $searchexp = EPrints::Search->new(
		session => $self->{session},
		dataset => $dataset,
	);

	$searchexp->add_field( $dataset->get_field( "importid" ), $self->get_id );

	my $list = $searchexp->perform_search;

	$searchexp->dispose;

	return $list;
}


######################################################################
=pod

=item $eprint = $import->get_from_source( $sourceid )

Get the eprint that is from this import set and identified by 
C<$sourceid>.

=cut
######################################################################

sub get_from_source
{
	my( $self, $sourceid ) = @_;

	return undef if !defined $sourceid;

	my $dataset = $self->{session}->dataset( "eprint" );

	my $results = $dataset->search(
		filters => [
			{
				meta_fields => [qw( importid )], value => $self->id,
			},
			{
				meta_fields => [qw( source )], value => $sourceid,
			}
		]);

	return $results->item( 0 );
}


######################################################################
=pod

=item $dataobj = $import->epdata_to_dataobj( $dataset, $epdata )

Convert C<$epdata> to an eprint data object. If an existing object 
exists in this import that has the same identifier that object will be 
used instead of creating a new object.

Also calls C<set_eprint_import_automatic_fields> on the object before 
writing it to the database.

=cut
######################################################################

sub epdata_to_dataobj
{
	my( $self, $dataset, $imdata ) = @_;

	my $epdata = {};

	my $keyfield = $dataset->get_key_field();

	foreach my $fieldname (keys %$imdata)
	{
		next if $fieldname eq $keyfield->get_name();
		next if $fieldname eq "rev_number";
		my $field = $dataset->get_field( $fieldname );
		next if $field->get_property( "volatile" );
		next unless $field->get_property( "import" ); # includes datestamp

		my $value = $self->_cleanup_data( $field, $imdata->{$fieldname} );
		$epdata->{$fieldname} = $value;
	}

	# the source is the eprintid
	$epdata->{"source"} = $imdata->{$keyfield->get_name()};

	# importid will always be us
	$epdata->{"importid"} = $self->get_id();

	# any objects created by this import must be owned by our owner
	$epdata->{"userid"} = $self->get_value( "userid" );

	my $dataobj = $self->get_from_source( $epdata->{"source"} );

	if( defined $dataobj )
	{
		foreach my $fieldname (keys %$epdata)
		{
			$dataobj->set_value( $fieldname, $epdata->{$fieldname} );
		}
	}
	else
	{
		$dataobj = $dataset->create_object( $self->{session}, $epdata );
	}

	return undef unless defined $dataobj;

	$self->update_triggers();

	$dataobj->commit();

	return $dataobj;
}

sub _cleanup_data
{
    my( $self, $field, $value ) = @_;

    if( EPrints::Utils::is_set($value) && $field->isa( "EPrints::MetaField::Text" ) )
    {
        if( $field->get_property( "multiple" ) )
        {
            for(@$value)
            {
                $_ = substr($_,0,$field->get_property( "maxlength" ));
            }
        }
        else
        {
            $value = substr($value,0,$field->get_property( "maxlength"));
        }
    }

    return $value;
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

