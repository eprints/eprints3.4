######################################################################
#
# EPrints::List
#
######################################################################
#
#
######################################################################

=pod

=for Pod2Wiki

=head1 NAME

B<EPrints::List> - List of data objects, usually a L<EPrints::Search>
result.

=head1 DESCRIPTION

This class represents an ordered list of objects, all from the same
dataset. Usually this is the results of a search.

=head2 SYNOPSIS

	$list = $search->execute();

	$new_list = $list->reorder( "-creation_date" ); # makes a new list ordered by reverse order creation_date

	$new_list = $list->union( $list2, "creation_date" ) # makes a new list by adding the contents of $list to $list2. the resulting list is ordered by "creation_date"

	$new_list = $list->remainder( $list2, "title" ); # makes a new list by removing the contents of $list2 from $list orders the resulting list by title

	$n = $list->count() # returns the number of items in the list

	@dataobjs = $list->slice( 0, 20 );  #get the first 20 DataObjs from the list in an array

	$list->map( $function, $info ) # performs a function on every item in the list. This is very useful go and look at the detailed description.

	$plugin_output = $list->export( "BibTeX" ); #calls Plugin::Export::BibTeX on the list.

	$dataset = $list->get_dataset(); #returns the dataset in which the containing objects belong

=head1 INSTANCE VARIABLES

=over 4

=itenm $self->{session}

The current L<EPrints::Session>.

=item $self->{dataset}

The L<EPrints::Dataset> to which this list belongs.

=item $self->{ids}

An array reference for the IDs with the dataset that make up this list.

A special case: C<[ "ALL" ]> means it matches all items in the dataset.

=item $self->{order}

The order to return these items in.  Uses the same format as
C<custom_order> in L<EPrints::Search>.

=item $self->{encoded}

The serialised version of the search expression that created this list.

=item $self->{cache_id}

The database table in which list is cached.

=item $self->{keep_cache}

If this is C<true> then the cache will not be automatically tidied
when the L<EPrints::Session> terminates.

=item $self->{desc}
Contains an XHTML description of what this is the list.

=item $self->{desc_order}
Contains an XHTML description of how this list is ordered.

=back

=head1 METHODS

=cut
######################################################################

package EPrints::List;

use strict;

######################################################################
=pod

=item $list = EPrints::List->new( repository => $repository, dataset => $dataset, ids => $ids, [order => $order] );

=item $list = EPrints::List->new( repository => $repository, dataset => $dataset, [desc => $desc], [desc_order => $desc_order], cache_id => $cache_id );

B<N.B.> This method will be called infrequently as lists will
generally created by an L<EPrints::Search>.

Creates a new list object in memory only. Lists will be
cached if any method requiring order is called or an explicit
C<cache()> method is called.

A serialised version of the search expression which created this list
is store in the instance variable called  C<encoded>, if such a search
expression exists.

If C<keep_cache> instance vairable is set to C<true> then the cache
will not be disposed of at the end of the current L<EPrints::Session>.
If C<cache_id> is set then C<keep_cache> is automatically set to
C<true>.

=cut
######################################################################
sub new
{
	my( $class, %self ) = @_;

	$self{session} = $self{repository} if !defined $self{session};

	my $self = \%self;
#	$self->{session} = $opts{session} || $opts{repository};
#	$self->{dataset} = $opts{dataset};
#	$self->{ids} = $opts{ids};
#	$self->{order} = $opts{order};
#	$self->{encoded} = $opts{encoded};
#	$self->{cache_id} = $opts{cache_id};
#	$self->{keep_cache} = $opts{keep_cache};
#	$self->{searchexp} = $opts{searchexp};

	if( !defined $self->{cache_id} && !defined $self->{ids} )
	{
		EPrints::abort( "cache_id or ids must be defined in a EPrints::List->new()" );
	}
	if( !defined $self->{session} )
	{
		EPrints::abort( "session must be defined in a EPrints::List->new()" );
	}
	if( !defined $self->{dataset} )
	{
		EPrints::abort( "dataset must be defined in a EPrints::List->new()" );
	}
	bless $self, $class;

	if( $self->{cache_id} )
	{
		$self->{keep_cache} = 1;
	}

	if( $self->{keep_cache} )
	{
		$self->cache;
	}

	return $self;
}


######################################################################
=pod

=item $new_list = $list->reorder( $new_order );

Returns a new list from this one, but sorted using ordering defined in
the string C<$new_order>.

The following example re-orders the list in reverse order based on
C<datestamp>.  I.e. the date an L<EPrints::DataObj::EPrint> is first
moved to the live archive.

	$new_list = $list->reorder( "-datestamp" ); #

=cut
######################################################################

sub reorder
{
	my( $self, $new_order ) = @_;

	# no need to order 0 or 1 length lists.
	if( $self->count < 2 )
	{
		return $self;
	}

	# must be cached to be reordered

	$self->cache;

	my $db = $self->{session}->get_database;

	my $srctable = $db->cache_table( $self->{cache_id} );

	my $encoded = defined($self->{encoded}) ? $self->{encoded} : "";
	my $new_cache_id  = $db->cache(
		"$encoded(reordered:$new_order)", # nb. not very neat.
		$self->{dataset},
		$srctable,
		$new_order );

	my $new_list = EPrints::List->new(
		session=>$self->{session},
		dataset=>$self->{dataset},
		searchexp=>$self->{searchexp},
		order=>$new_order,
		keep_cache=>$self->{keep_cache},
		cache_id => $new_cache_id );
		
	return $new_list;
}
		
######################################################################
=pod

=item $new_list = $list->union( $list2, [$order] );

Returns a new list combining this list and C<$list2>. If C<$order> is
not  defined then this combined list will not be in any particular
order.

=cut
######################################################################

sub union
{
	my( $self, $list2, $order ) = @_;

	my $ids1 = $self->get_ids;
	my $ids2 = $list2->get_ids;

	my %newids = ();
	foreach( @{$ids1}, @{$ids2} ) { $newids{$_}=1; }
	my @objectids = keys %newids;

	# losing desc, although could be added later.
	return EPrints::List->new(
		dataset => $self->{dataset},
		session => $self->{session},
		order => $order,
		ids=>\@objectids );
}

######################################################################
=pod

=item $new_list = $list->remainder( $list2, [$order] );

Returns a new list from this list with elements from C<$list2> removed.
If C<$order> is not defined then this new list will not be in any
particular order.

=cut
######################################################################

sub remainder
{
	my( $self, $list2, $order ) = @_;

	my $ids1 = $self->get_ids;
	my $ids2 = $list2->get_ids;

	my %newids = ();
	foreach( @{$ids1} ) { $newids{$_}=1; }
	foreach( @{$ids2} ) { delete $newids{$_}; }
	my @objectids = keys %newids;

	# losing desc, although could be added later.
	return EPrints::List->new(
		dataset => $self->{dataset},
		session => $self->{session},
		order => $order,
		ids=>\@objectids );
}

######################################################################
=pod

=item $new_list = $list->intersect( $list2, [$order] );

Returns a new list containing only the elements which are in both this
list and C<$list2>.  If C<$order> is not defined then this new list
will not be in any particular order.

=cut
######################################################################

sub intersect
{
	my( $self, $list2, $order ) = @_;

	my $ids1 = $self->get_ids;
	my $ids2 = $list2->get_ids;

	my %n= ();
	foreach( @{$ids1} ) { $n{$_}=1; }
	my @objectids = ();
	foreach( @{$ids2} ) { next unless( $n{$_} ); push @objectids, $_; }

	# losing desc, although could be added later.
	return EPrints::List->new(
		dataset => $self->{dataset},
		session => $self->{session},
		order => $order,
		ids=>\@objectids );
}

######################################################################
=pod

=item $list->cache

Cache this list in the database.

This method should not generally need to be called as caching should
be managed internally.

=cut
######################################################################

sub cache
{
	my( $self ) = @_;

	return if( defined $self->{cache_id} );

	if( $self->_matches_none && !$self->{keep_cache} )
	
	{
		# not worth caching zero in a temp table!
		return;
	}

#	if( defined $self->{ids} && scalar @{$self->{ids}} < 2 )
#	{
#		# not worth caching one item either. Can't sort one
#		# item can you?
#		return;
#	}

	my $db = $self->{session}->get_database;
	if( $self->_matches_all )
	{
		$self->{cache_id} = $db->cache(
			$self->{encoded},
			$self->{dataset},
			"ALL",
			$self->{order} );
		$self->{ids} = undef;
		return;	
	}

	my $ids = $self->{ids};
	$self->{cache_id} = $db->cache(
		$self->{encoded},
		$self->{dataset},
		"LIST",	
		undef,
		$ids );

	if( defined $self->{order} )
	{
		my $srctable = $db->cache_table( $self->{cache_id} );

		my $new_cache_id = $db->cache(
			$self->{encoded},
			$self->{dataset},
			$srctable,
			$self->{order} );

		# clean up intermediate cache table
		$self->{session}->get_database->drop_cache( $self->{cache_id} );

		$self->{cache_id} = $new_cache_id;
	}
}

######################################################################
=pod

=item $cache_id = $list->get_cache_id

Returns the ID of the cache table for this list or C<undef> is no
such cache table exists.

This method should not generally need to be called as caching should
be managed internally.

=cut
######################################################################

sub get_cache_id
{
	my( $self ) = @_;
	
	return $self->{cache_id};
}



######################################################################
=begin InternalDoc

=item $list->dispose

Cleans up the cache table if appropriate.

This method should not generally need to be called as caching should
be managed internally.

=end InternalDoc

=cut
######################################################################

sub dispose
{
	my( $self ) = @_;

	if( defined $self->{cache_id} && !$self->{keep_cache} )
	{
		if( !defined $self->{session}->get_database )
		{
			print STDERR "Wanted to drop cache ".$self->{cache_id}." but we've already entered clean up and closed the database connection.\n";
		}
		else
		{
			$self->{session}->get_database->drop_cache( $self->{cache_id} );
			delete $self->{cache_id};
		}
	}

	%$self = ();
}


######################################################################
=pod

=item $n = $list->count

Returns the number of items (i.e L<EPrints::DataObj>) in this list.

=cut
######################################################################

sub count
{
	my( $self ) = @_;

	if( defined $self->{ids} )
	{
		if( $self->_matches_all )
		{
			return $self->{dataset}->count( $self->{session} );
		}
		return( scalar @{$self->{ids}} );
	}

	if( defined $self->{cache_id} )
	{
		#cjg Should really have a way to get at the
		# cache. Maybe we should have a table object.
		return $self->{session}->get_database->count_table(
			"cache".$self->{cache_id} );
	}

	EPrints::abort( "Called \$list->count() where there was no cache or ids." );
}


######################################################################
=pod

=item $dataobj = $list->item( $offset )

Returns the L<EPrints::DataObj> at C<$offset> position in this list.

Returns C<undef> if C<$offset> is out of range for this list.

=cut
######################################################################

sub item
{
	my( $self, $offset ) = @_;

	return ($self->slice( $offset, 1 ))[0];
}

######################################################################
=pod

=item @dataobjs = $list->slice( [$offset], [$count] )

Returns an array of C<$count> L<EPrints::DataObj> items from the C<$offset>
position onwards in this list.

If C<$count> is not set all items from the C<$offset> position are
returned in the array. If C<$offset> is not set then all items in the
list are returned.

Returns an empty array if C<$offset> is out of range for this list.

Returns an array of fewer elements if list is smaller than C<$count> or
number items from C<$offset> position is fewer than C<$count>.

=cut
######################################################################

sub get_records { shift->slice( @_ ) }
sub slice
{
	my( $self , $offset , $count ) = @_;
	
	return $self->_get_records( $offset , $count, 0 );
}


######################################################################
=pod

=item $ids = $list->ids( [$offset], [$count] )

Returns an array reference containing the L<EPrints::DataObj> IDs of
the items in the list.

If C<$offset> is specified only IDs for items from that position
onwards will be returned.

If C<$count> is also specified that is the maximum number of IDs that
will be returned.

Returns an empty array reference if C<$offset> is out of range for
this list.

=cut
######################################################################

sub get_ids { shift->ids( @_ ) }
sub ids
{
	my( $self , $offset , $count ) = @_;
	
	return $self->_get_records( $offset , $count, 1 );
}


######################################################################
#
# $bool = $list->_matches_none
#
######################################################################

sub _matches_none
{
	my( $self ) = @_;

	if( !defined $self->{ids} )
	{
		EPrints::abort( "Error: Calling _matches_none when {ids} not set\n" );
	}

	return( scalar @{$self->{ids}} == 0 );
}

######################################################################
#
# $bool = $list->_matches_all
#
######################################################################

sub _matches_all
{
	my( $self ) = @_;

	if( !defined $self->{ids} )
	{
		EPrints::abort( "Error: Calling _matches_all when {ids} not set\n" );
	}

	return( 0 ) if( !defined $self->{ids}->[0] );

	return( $self->{ids}->[0] eq "ALL" );
}

######################################################################
#
# $ids/@dataobjs = $list->_get_records ( $offset, $count, $justids )
#
# Method which sessions getting objects or just ids.
#
######################################################################

sub _get_records
{
	my ( $self , $offset , $count, $justids ) = @_;

	$offset = $offset || 0;
	# $count = $count || 1; # unspec. means ALL not 1.
	$justids = $justids || 0;

	my @ids;
	if( defined $self->{ids} )
	{
		if( $offset > $#{$self->{ids}} )
		{
			@ids = ();
		}
		if( !defined $count || $offset+$count > @{$self->{ids}} )
		{
			@ids = @{$self->{ids}}[$offset..$#{$self->{ids}}];
		}
		else
		{
			@ids = @{$self->{ids}}[$offset..$offset+$count-1];
		}
	}
	else
	{
		my $cachemap = $self->{session}->get_database->get_cachemap( $self->{cache_id} );
		@ids = $self->{session}->get_database->get_cache_ids( $self->{dataset}, $cachemap, $offset, $count );
	}

	return \@ids if $justids;
	return $self->{session}->get_database->get_dataobjs( $self->{dataset}, @ids );
}


######################################################################
=pod

=item $list->map( $function, $info )

Map the given C<$function> pointer to all the items in the list, in
order. This loads the items in batches of 100 to reduce memory
requirements.

C<$info> is a hash reference which will be passed to the function each
time and is useful for holding or collecting state.

Example:

 my $info = { matches => 0 };
 $list->map( \&deal, $info );
 print "Matches: ".$info->{matches}."\n";


 sub deal
 {
 	my( $session, $dataset, $eprint, $info ) = @_;

 	if( $eprint->get_value( "a" ) eq $eprint->get_value( "b" ) ) {
 		$info->{matches} += 1;
 	}
 }	

=cut
######################################################################

sub map
{
	my( $self, $function, $info ) = @_;	

	my $count = $self->count();

	my $CHUNKSIZE = 100;

	for( my $offset = 0; $offset < $count; $offset+=$CHUNKSIZE )
	{
		my @records = $self->slice( $offset, $CHUNKSIZE );
		foreach my $item ( @records )
		{
			&{$function}(
				$self->{session},
				$self->{dataset},
				$item,
				$info );
		}
	}
}


######################################################################
=pod

=item $plugin_output = $list->export( $plugin_id, %params )

Returns the output of an export plugin (with ID C<$plugin_id>) applied
to this list of items. If C<$params{fh}> index is set, it will send
the results to a file handle (e.g. C<temp_dir/my_file.txt> rather than
returning them as a string.

C<$plugin_id> is just the type of export plugin rather than the full
plugin name. E.g. C<BibTeX> rather than C<Export::BibTeX>.

=cut
######################################################################

sub export
{
	my( $self, $out_plugin_id, %params ) = @_;

	my $plugin_id = "Export::".$out_plugin_id;
	my $plugin = $self->{session}->plugin( $plugin_id );

	unless( defined $plugin )
	{
		EPrints::abort( "Could not find output plugin $plugin_id" );
	}

	my $req_plugin_type = "list/".$self->{dataset}->confid;

	unless( $plugin->can_accept( $req_plugin_type ) )
	{
		EPrints::abort(
"Plugin $plugin_id can't process $req_plugin_type data." );
	}

	return $plugin->output_list( list=>$self, %params );
}

######################################################################
=pod

=begin InternalDoc

=item $dataset = $list->get_dataset

Returns the L<EPrints::DataSet> which this list relates to.

=end InternalDoc

=cut
######################################################################

sub get_dataset
{
	my( $self ) = @_;

	return $self->{dataset};
}

######################################################################
=pod

=item $xhtml = $list->render_description

Return a XHTML DOM object containing a description of the search
expression used to generate this list escription of this list. If no
search expression exists an empty XHTML DOM object is returned.

=cut
######################################################################

sub render_description
{
	my( $self ) = @_;

	my $frag = $self->{session}->make_doc_fragment;

	if( defined $self->{searchexp} )
	{
		$frag->appendChild( $self->{searchexp}->render_description );
		if( !defined $self->{order} )
		{
			$frag->appendChild( $self->{session}->make_text( " " ) );
			$frag->appendChild( $self->{searchexp}->render_order_description );
		}
	}

	return $frag;
}

######################################################################
#
# Clean up any caches and XML belonging to this object.
#
######################################################################

sub DESTROY
{
	my( $self ) = @_;
	
	$self->dispose;
	if( defined $self->{desc} ) { EPrints::XML::dispose( $self->{desc} ); }
	if( defined $self->{desc_order} ) { EPrints::XML::dispose( $self->{desc_order} ); }
}

1;

######################################################################
=pod

=back

=head1 SEE ALSO

L<EPrints::Search>

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

