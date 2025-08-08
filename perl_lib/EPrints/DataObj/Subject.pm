######################################################################
#
# EPrints::DataObj::Subject
#
######################################################################
#
#
######################################################################


=pod

=for Pod2Wiki

=head1 NAME

B<EPrints::DataObj::Subject> - Subjects within a hierarchical tree.

=head1 DESCRIPTION

This class represents a single node in the subjects tree. It also
contains a number of methods for handling the entire tree.

=head1 CORE METADATA FIELDS

=over 4

=item subjectid (id) 

=item rev_number (int)

=item name (multilang)

=item depositable (boolean)

=item sortvalue (multilang)

=back

=head1 REFERENCES AND RELATED OBJECTS

=over 4

=item parents (id)

=item ancestors (id)

=back

=head1 INSTANCE VARIABLES

See L<EPrints::DataObj|EPrints::DataObj#INSTANCE_VARIABLES>.

=head1 METHODS

=cut
######################################################################

package EPrints::DataObj::Subject;

@ISA = ( 'EPrints::DataObj' );

use EPrints;

use strict;

# Root subject specifier
$EPrints::DataObj::Subject::root_subject = "ROOT";


######################################################################
=pod

=head2 Constructor Methods

=cut
######################################################################

######################################################################
=pod

=over 4

=item $subject = EPrints::DataObj::Subject->new( $session, $subjectid )

Create a new subject object with the ID C<$subjectid>. The values
for the subject are loaded from the database.

=cut
######################################################################

sub new
{
    my( $class, $session, $subjectid ) = @_;

    if( $session->{subjects_cached} )
    {
        return $session->{subject_cache}->{$subjectid};
    }

    unless( defined $subjectid )
    {
        $session->get_repository->log( '[warning] Can\'t create Subject without an ID' );
        return undef;
    }

    if( $subjectid eq $EPrints::DataObj::Subject::root_subject )
    {
        my $data = {
            subjectid => $EPrints::DataObj::Subject::root_subject,
            name => [],
            parents => [],
            ancestors => [ $EPrints::DataObj::Subject::root_subject ],
            depositable => "FALSE"
        };
        my $name;
        foreach my $langid ( @{$session->config( "languages" )} )
        {
            my $top_level_name = EPrints::XML::to_string(
                $session->get_repository->get_language( $langid )->phrase(
                            "lib/subject:top_level",
                            {},
                            $session ) );

            push @{$data->{name}}, {
                lang => $langid,
                name => $top_level_name };
        }

        return EPrints::DataObj::Subject->new_from_data( $session, $data );
    }

    return $session->get_database->get_single(
            $session->dataset( "subject" ),
            $subjectid );

}


######################################################################
=pod

=item $subject = EPrints::DataObj::Subject->new_from_data( $session, $data )

Construct a new subject object from a hash reference containing
the relevant fields. Generally this method is only used to construct
new Subjects coming out of the database.

=cut
######################################################################

sub new_from_data
{
    my( $class, $session, $known ) = @_;

    return $class->SUPER::new_from_data(
            $session,
            $known,
            $session->dataset( "subject" ) );
}


######################################################################
=pod

=item $subject = EPrints::DataObj::Subject::create( $session, $id, $name, $parents, $depositable )

Creates a new subject in the database. C<$id> is the ID of the 
subject, C<$name> is a multilang data structure with the name of the 
subject in one or more languages. E.g.

 { en=>"Trousers", en-us=>"Pants" }

C<$parents> is a reference to an array containing the ID of one or more 
other subjects (don't make loops!). If C<$depositable> is C<true> then 
data objects (typically eprints) may belong to this subject.

=cut
######################################################################

sub create
{
    my( $session, $id, $name, $parents, $depositable ) = @_;

    my $actual_parents = $parents;
    $actual_parents = [ $EPrints::DataObj::Subject::root_subject ] if( !defined $parents );

    my $data =
        { "subjectid"=>$id,
          "name"=>$name,
          "parents"=>$actual_parents,
          "ancestors"=>[],
          "depositable"=>($depositable ? "TRUE" : "FALSE" ) };

    return EPrints::DataObj::Subject->create_from_data(
        $session,
        $data,
        $session->dataset( "subject" ) );
}


######################################################################
=pod

=item $dataobj = EPrints::DataObj::Subject->create_from_data( $session, $data, $dataset )

Returns C<undef> if a bad (or no) C<subjectid> is specified in
C<$data>.

Otherwise calls the parent method in L<EPrints::DataObj>.

=cut
######################################################################

sub create_from_data
{
    my( $class, $session, $data, $dataset ) = @_;

    my $id = $data->{subjectid};
    unless( valid_id( $id ) )
    {
        EPrints::abort( <<END );
Error. Can't create new subject.
The value '$id' is not a valid subject identifier.
Subject id's may not contain whitespace.
END
    }

    my $subject = $class->SUPER::create_from_data( $session, $data, $dataset );

    return unless( defined $subject );

    # regenerate ancestors field
    $subject->commit;

    return $subject;
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

=item $fields = EPrints::DataObj::Subject->get_system_field_info

Returns an array describing the system metadata of the subject 
dataset.

=cut
######################################################################

sub get_system_field_info
{
	my( $class ) = @_;

	return 
	( 
		{ name=>"subjectid", type=>"id", required=>1, can_clone=>1, maxlength=>128 },

		{ name=>"rev_number", type=>"int", required=>1, can_clone=>0,
			default_value=>1 },

		{ name=>"name", type=>"multilang", required=>1,	multiple=>1,
			fields=>[ 
				{
            				'sub_name' => 'name',
            				'type' => 'text',
					'input_cols' => 30,
				},
				# EPrints Services/tmb 2010-07-30 optional user-supplied sort value
				{
            				'sub_name' => 'sortvalue',
            				'type' => 'text',
					'input_cols' => 30,
				},
			]
		},

		# should be a itemid?
		{ name=>"parents", type=>"id", required=>1,
			multiple=>1 },

		{ name=>"ancestors", type=>"id", required=>0,
			multiple=>1, export_as_xml=>0 },

		{ name=>"depositable", type=>"boolean", required=>1,
			input_style=>"radio" },

		# EPrints Services/tmb 2010-07-30 derived sort value - not to be confused with name_sortvalue!
		{ name=>"sortvalue", type=>"multilang", required=>1, multiple=>1, volatile => 1, export_as_xml => 0,
			fields=>[ 
				{
            				'sub_name' => 'sortvalue',
            				'type' => 'text',
				},
			]
		},
	);
}


######################################################################
=pod

=item $dataset = EPrints::DataObj::Subject->get_dataset_id

Returns the id of the L<EPrints::DataSet> object to which this record 
belongs.

=cut
######################################################################

sub get_dataset_id
{
    return "subject";
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

=item $success = $subject->commit( [ $force ] )

Commit this subject to the database, but only if any fields have 
changed since we loaded it.

If C<$force> is set then always commit, even if there appear to be no
changes.

=cut
######################################################################

sub commit 
{
	my( $self, $force ) = @_;

	my @ancestors = $self->_get_ancestors( {} );
	$self->set_value( "ancestors", \@ancestors );

	# EPrints Services/tmb 2010-07-30 derive sort values
	my @svals;
	for( @{ $self->get_value( "name" ) } )
	{
		next unless EPrints::Utils::is_set( $_->{name} );
		my $sv = {
			lang => $_->{lang},
			sortvalue => $_->{name},
		};
		$sv->{sortvalue} = $_->{sortvalue} if EPrints::Utils::is_set( $_->{sortvalue} );
		push @svals, $sv;
	}
	$self->set_value( "sortvalue", \@svals );

	if( !defined $self->{changed} || scalar( keys %{$self->{changed}} ) == 0 )
	{
		# don't do anything if there isn't anything to do
		return( 1 ) unless $force;
	}
	if( $self->{non_volatile_change} )
	{
		$self->set_value( "rev_number", ($self->get_value( "rev_number" )||0) + 1 );	
	}

	my $rv = $self->SUPER::commit( $force );

	# Need to update all children in case ancesors have changed.
	# This is pretty slow esp. For a top level subject, but subject
	# changes will be rare and only done by admin, so mnya.
	my $child;
	foreach $child ( $self->get_children() )
	{
		$rv = $rv && $child->commit();
	}
	return $rv;
}


######################################################################
=pod

=item $success = $subject->remove

Remove this subject from the database.

=cut
######################################################################

sub remove
{
	my( $self ) = @_;
	
	if( scalar $self->get_children() != 0 )
	{
		return( 0 );
	}

	#cjg Should we unlink all eprints linked to this subject from
	# this subject?

	return $self->{session}->get_database->remove(
		$self->{dataset},
		$self->{data}->{subjectid} );
}


######################################################################
=pod

=item @subject_ids = $subject->_get_ancestors

Returns and array of all the ancestor subjects of this subject.

=cut
######################################################################

sub _get_ancestors
{
    my( $self, $seen ) = @_;

    return () if exists $seen->{$self->{data}->{subjectid}};
    $seen->{$self->{data}->{subjectid}} = undef;

    my @ancestors = ($self->{data}->{subjectid});

    foreach my $parent ( $self->get_parents() )
    {
        push @ancestors, $parent->_get_ancestors( $seen );
    }

    return @ancestors;
}


######################################################################
=pod

=item $subject = $subject->top

Returns the subject that is at the top of this subject's tree, which 
may be the subject itself.

Returns C<undef> if the subject is not part of a tree.

=cut
######################################################################

sub top
{
    my( $self ) = @_;

    foreach my $id ($self->id, @{$self->value( "ancestors" )})
    {
        my $subject = $self->{dataset}->dataobj( $id );
        next if !defined $subject;
        foreach my $parentid (@{$subject->value( "parents" )})
        {
            return $subject
                if $parentid eq $EPrints::DataObj::Subject::root_subject;
        }
    }

    return undef;
}


######################################################################
=pod

=item $child_subject = $subject->create_child( $id, $name, $depositable )

Similar to L</create> but this creates a new subject as a child of 
the current subject.

C<$id> is the ID for the new child subject. C<$name> is the label for 
this new subject and C<$depositable> is a boolean indicating whether 
this new subject is depositable.

Returns the new child subject.

=cut
######################################################################

sub create_child
{
	my( $self, $id, $name, $depositable ) = @_;

	return $self->{dataset}->create_object( $self->{session}, 	
		{ "subjectid"=>$id,
		  "name"=>$name,
		  "parents"=>[$self->{subjectid}],
		  "ancestors"=>[],
		  "depositable"=>($depositable ? "TRUE" : "FALSE" ) } );
}


######################################################################
=pod

=item @children = $subject->get_children

Returns a list of subject data objects which are direct children of 
the current subject.

=cut
######################################################################

sub get_children
{
	my( $self ) = @_;

	my $subjectid = $self->id;

	if( $self->{session}->{subjects_cached} )
	{
		return @{$self->{session}->{subject_child_map}->{$subjectid} || []};
	}

	my $dataset = $self->get_dataset;

	my $results = $dataset->search(
		filters => [
			{
				meta_fields => [qw( parents )],
				value => $subjectid
			}
		],
		custom_order=>"sortvalue_sortvalue/name_name" );
	return $results->slice;
}


######################################################################
=pod

=item @parents = $subject->get_parents

Returns a list of subject data objects which are direct parents of the 
current subject.

=cut
######################################################################

sub get_parents
{
	my( $self ) = @_;

	my @parents = ();
	foreach( @{$self->{data}->{parents}} )
	{
		push @parents, new EPrints::DataObj::Subject( $self->{session}, $_ );
	}
	return grep { defined } ( @parents );
}


######################################################################
=pod

=item $boolean = $subject->can_post( [ $user ] )

Determines whether the given C<$user> if specified can post in this 
subject.

Currently there is no way to configure subjects for certain users,
so this just returns the C<true> or C<false> depending on the 
C<depositable> flag.

=cut
######################################################################

sub can_post
{
	my( $self, $user ) = @_;

	# Depends on the subject	
	return( $self->{data}->{depositable} eq "TRUE" ? 1 : 0 );
}



######################################################################
=pod

=item $xhtml = $subject->render_with_path( $session, $topsubjid )

Returns the XHTML DOM rendering name of this subject including it's 
path from C<$topsubjid>.

C<$topsubjid> must be an ancestor of this subject.

E.g.

 Library of Congress > B Something > BC Something more Detailed

=cut
######################################################################

sub render_with_path
{
	my( $self, $session, $topsubjid ) = @_;

	my @paths = $self->get_paths( $session, $topsubjid );

	my $v = $session->make_doc_fragment();

	my $first = 1;
	foreach( @paths )
	{
		if( $first )
		{
			$first = 0;	
		}	
		else
		{
			$v->appendChild( $session->html_phrase( 
				"lib/metafield:join_subject" ) );
			# nb. using one from metafield!
		}
		my $first = 1;
		foreach( @{$_} )
		{
			if( !$first )
			{
				$v->appendChild( $session->html_phrase( 
					"lib/metafield:join_subject_parts" ) );
			}
			$first = 0;
			$v->appendChild( $_->render_description() );
		}
	}
	return $v;
}


######################################################################
=pod

=item @paths = $subject->get_paths( $session, $topsubjid )

This function returns all the paths from this subject back up to the
specified top subject.

@paths is an array of array references. Each of the inner arrays
is a list of subject id's describing a path down the tree from
$topsubjid to $session.

=cut
######################################################################

sub get_paths
{
	my( $self, $session, $topsubjid ) = @_;

	if( $self->get_value( "subjectid" ) eq $topsubjid )
	{
		# empty list, for the top level we care about
		return ([]);
	}
	if( $self->get_value( "subjectid" ) eq $EPrints::DataObj::Subject::root_subject )
	{
		return ([]);
	}
	my( @paths ) = ();
	foreach my $subjectid ( @{$self->{data}->{parents}} )
	{
		my $subj = new EPrints::DataObj::Subject( $session, $subjectid );
		if( !defined $subj )
		{
			$session->get_repository->log( "Non-existent subjectid: $subjectid in parents of ".$self->get_value( "subjectid" ) );
			next;
		}
		push @paths, $subj->get_paths( $session, $topsubjid );
	}
	foreach( @paths )
	{
		push @{$_}, $self;
	}
	return @paths;
}


######################################################################
=pod

=item $subject_pairs = $subject->get_subjects ( [$postable_only], [$show_top_level], [$nes_tids], [$no_nest_label] )

Return a reference to an array. Each item in the array is a two 
element list. 

The first element in the list is an indenifier string. 

The second element is a utf-8 string describing the subject (in the 
current language), including all the items above it in the tree, but
only as high as this subject.

The subjects which are returned are this item and all its children, 
and children's children etc. The order is it returns 
this subject, then the first child of this subject, then children of 
that (recursively), then the second child of this subject etc.

If $postable_only is true then filter the results to only contain 
subjects which have the "depositable" flag set to true.

If $show_top_level is not true then the pair representing the current
subject is not included at the start of the list.

If $nest_ids is true then each then the ids returned are nested so
that the ids of the children of this subject are prefixed with this 
subjects id and a colon, and their children are prefixed by their 
nested id and a colon. eg. L:LC:LC003 rather than just "LC003"

if $no_nest_label is true then the subject label only contains the
name of the subject, not the higher level ones.

A default result from this method would look something like this:

  [
    [ "D", "History" ],
    [ "D1", "History: History (General)" ],
    [ "D111", "History: History (General): Medieval History" ]
 ]

=cut
######################################################################

sub get_subjects 
{
	my( $self, $postableonly, $showtoplevel, $nestids, $nonestlabel ) = @_; 

#cjg optimisation to not bother getting labels?
	$postableonly = 0 unless defined $postableonly;
	$showtoplevel = 1 unless defined $showtoplevel;
	$nestids = 0 unless defined $nestids;
	$nonestlabel = 0 unless defined $nonestlabel;
	my( $subjectmap, $rmap ) = EPrints::DataObj::Subject::get_all( $self->{session} );
	return $self->_get_subjects2( $postableonly, !$showtoplevel, $nestids, $subjectmap, $rmap, "", !$nonestlabel );
}


######################################################################
=pod 

=item $subjects = $subject->_get_subjects2( $postableonly, $hidenode, $nestids, $subjectmap, $rmap, $prefix )

Recursive function used by get_subjects.

=cut
######################################################################

sub _get_subjects2
{
	my( $self, $postableonly, $hidenode, $nestids, $subjectmap, $rmap, $prefix, $cascadelabel ) = @_; 

	my $depositable = $self->get_value( "depositable" );
	my $postable = (defined $depositable && $depositable eq "TRUE" ? 1 : 0 );
	my $id = $self->get_value( "subjectid" );

	my $desc = $self->render_description;
	my $label = EPrints::Utils::tree_to_utf8( $desc );
	EPrints::XML::dispose( $desc );

	my $subpairs = [];
	if( (!$postableonly || $postable) && (!$hidenode) )
	{
		if( $prefix ne "" ) { $prefix .= ":"; }
		$prefix.=$id;
		push @{$subpairs},[ ($nestids?$prefix:$id), $label ];
	}
	$prefix = "" if( $hidenode );
	foreach my $kid ( @{$rmap->{$id}} )# cjg sort on labels?
	{
		my $kidmap = $kid->_get_subjects2( 
				$postableonly, 0, $nestids, $subjectmap, $rmap, $prefix, $cascadelabel );
		if( !$cascadelabel )
		{
			push @{$subpairs}, @{$kidmap};
			next;
		}
		foreach my $pair ( @{$kidmap} )
		{
			my $label = ($hidenode?"":$label.": ").$pair->[1];
			push @{$subpairs}, [ $pair->[0], $label ];
		}
	}

	return $subpairs;
}


######################################################################
=pod

=item $count = $subject->count_eprints( $dataset )

Returns the number of data objects in the dataset (typically eprints),
which are in this subject or one of its descendants. Searches all 
fields of type subject.

=cut
######################################################################

sub count_eprints
{
	my( $self, $dataset ) = @_;

	# Create a search expression
	my $searchexp = new EPrints::Search(
		satisfy_all => 0, 
		session => $self->{session},
		dataset => $dataset );

	my $n = 0;
	my $field;
	foreach $field ( $dataset->get_fields() )
	{
		next unless( $field->is_type( "subject" ) );
		$n += 1;
		$searchexp->add_field(
			$field,
			$self->get_value( "subjectid" ) );
	}

	if( $n == 0 )
	{
		# no actual subject fields
		return( 0 );
	}

	my $list = $searchexp->perform_search;
	my $count = $list->count;

	return $count;

}


######################################################################
=pod

=item $subject->render_description

Returns a rendering describing the subject.

This is an alias for:

 $subject->render_value( "name" )

=cut
######################################################################

sub render_description
{
	my( $self, $use_citation ) = @_;

	if ( $use_citation )
	{
		return $self->render_citation( $use_citation );
	}
	return $self->render_value( "name" );
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

=item EPrints::DataObj::Subject::remove_all( $session )

Remove all subjects from the database. Use with care!

=cut
######################################################################

sub remove_all
{
    my( $session ) = @_;

    my $ds = $session->dataset( "subject" );
    my @subjects = $session->get_database->get_all( $ds );
    foreach( @subjects )
    {
        my $id = $_->get_value( "subjectid" );
        $session->get_database->remove( $ds, $id );
    }
    return;
}


######################################################################
=pod

=item ( $subject_map, $reverse_map ) = EPrints::DataObj::Subject::get_all( $session )

Get all the subjects for the current archvive of $session.

$subject_map is a reference to a hash. The keys of the hash are
the id's of the subjects. The values of the hash are the
EPrint::Subject object relating to that id.

$reverse_map is a reference to a hash. Each key is the id of a
subject. Each value is a reference to an array. The array contains
a EPrints::DataObj::Subject objects, one for each child of the subject
with the id. The array is sorted by the labels for the subjects,
in the current language.

=cut
######################################################################

sub get_all
{
    my( $session ) = @_;

    if( $session->{subjects_cached} )
    {
        return ( $session->{subject_cache}, $session->{subject_child_map} );
    }

    my( %subjectmap ); # map subject ids to subject objects
    my( %rmap ); # map parents to children

    # callback method for result map
    my $f = sub {
        my( undef, undef, $subject ) = @_;
        my $subjectid = $subject->get_id;
        $subjectmap{$subjectid} = $subject;
        $rmap{$subjectid} = [] if !exists $rmap{$subjectid};
        foreach my $pid ( @{$subject->get_value( "parents" )} )
        {
            $rmap{$pid} = [] if !exists $rmap{$pid};
            push @{$rmap{$pid}}, $subject;
        }
    };

    my $ds = $session->dataset( "subject" );

    # Retrieve all of the subjects
    my $results = $ds->search( custom_order => "sortvalue_sortvalue/name_name" ); # EPrints Services/tmb 2010-07-30 order by derived sort value

    $results->map($f);

    # Plus the virtual root subject
    &$f( $session, $ds, EPrints::DataObj::Subject->new( $session, $EPrints::DataObj::Subject::root_subject ) );

    return( \%subjectmap, \%rmap );
}


######################################################################
=pod

=item $boolean = EPrints::DataObj::Subject::valid_id( $id )

Returns C<true> if the string C<$id> is an acceptable identifier for a 
subject.

This does not check all possible illegal values, just that it has no 
whitespace.

=cut
######################################################################

sub valid_id
{
    my( $id ) = @_;

    return 0 if( $id =~ m/\s/ ); # no whitespace

    return 1;
}


######################################################################
=pod

=back

=head2 Deprecated Methods

=cut
######################################################################

######################################################################
=pod

=over 4

=item @eprints = $subject->posted_eprints( $dataset )

DEPRECATED

This method is no longer used by EPrints, and may be
removed in a later release.

Returns all the data objects in the C<$dataset>, (typically, C<eprint>
or its virtual datasets, such as C<archive>, C<buffer> and C<inbox>,
which are in this subject (or below it in the tree, its children,
etc.). It searches all fields of type C<subject>.

=cut
######################################################################

sub posted_eprints
{
    my( $self, $dataset ) = @_;

    EPrints->deprecated();

    my $searchexp = new EPrints::Search(
        session => $self->{session},
        dataset => $dataset,
        satisfy_all => 0 );

    my $n = 0;
    my $field;
    foreach $field ( $dataset->get_fields() )
    {
        next unless( $field->is_type( "subject" ) );
        $n += 1;
        $searchexp->add_field(
            $field,
            $self->get_value( "subjectid" ) );
    }

    if( $n == 0 )
    {
        # no actual subject fields
        return();
    }

    my $list = $searchexp->perform_search;
    my @data = $list->get_records;

    return @data;
}


######################################################################
=pod

=item $subj->render

DEPRECATED

Subjects cannot be rendered. Use L</render_description> instead.

=cut
######################################################################

sub render
{
	EPrints::abort( "subjects can't be rendered. Use render_description instead." ); 
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

