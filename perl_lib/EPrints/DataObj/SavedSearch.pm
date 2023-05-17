######################################################################
#
# EPrints::DataObj::SavedSearch
#
######################################################################
#
#
######################################################################

=pod

=for Pod2Wiki

=head1 NAME

B<EPrints::DataObj::SavedSearch> - Single saved search.

=head1 DESCRIPTION

A saved search is a sub class of L<EPrints::DataObj::SubObject>.

Each one belongs to one and only one user, although one user may own
multiple saved searches.

=head1 CORE METADATA FIELDS

=over 4

=item id (counter)

The ID of the saved search,

=item name (text)

A name assigned to the saved search.

=item spec (search)

A serialization of the search specification.

=item frequency (set)

How often to send saves search email updates.

=item mailempty (boolean)

Whether to send saved search  email updates if there are no results.

=item additional_recipients (text)

Additional email addresses to send updates about saved search results.

=item public (boolean)

If the saved search results should be publicly accessible.

=back

=head1 REFERENCES AND RELATED OBJECTS

=over 4

=item userid (itemref)

The ID of the user to whom created this saved search.

=back

=head1 INSTANCE VARIABLES

Also see L<EPrints::DataObj|<EPrints::DataObj#INSTANCE_VARIABLES>.

=over 4

=item $self->{user}

The user who owns this saved search.

=back

=head1 METHODS

=cut

package EPrints::DataObj::SavedSearch;

@ISA = ( 'EPrints::DataObj::SubObject' );

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

=item $saved_search = EPrints::DataObj::SavedSearch->create( $session, $userid )

Creates a new saved search, belonging to user with ID C<$userid>.

=cut
######################################################################

sub create
{
    my( $class, $session, $userid ) = @_;

    return EPrints::DataObj::SavedSearch->create_from_data(
        $session,
        { userid=>$userid },
        $session->dataset( "saved_search" ) );
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

=item $field_config = EPrints::DataObj::SavedSearch->get_system_field_info

Returns an array describing the system metadata of the saved search 
dataset.

=cut
######################################################################

sub get_system_field_info
{
	my( $class ) = @_;

	return 
	( 
		{ name=>"id", type=>"counter", required=>1, import=>0, can_clone=>1,
			sql_counter=>"savedsearchid" },

		{ name=>"userid", type=>"itemref", 
			datasetid=>"user", required=>1 },

		{ name=>"name", type=>"text" },

		{ name => "spec", type => "search", datasetid => "eprint",
			default_value=>"", text_index => 0 },

		{ name=>"frequency", type=>"set", required=>1,
			options=>["never","daily","weekly","monthly"],
			default_value=>"never" },

		{ name=>"mailempty", type=>"boolean", input_style=>"radio",
			default_value=>"TRUE" },

		{ name=>"additional_recipients", type=>"text" },

		{ name=>"public", type=>"boolean", input_style=>"radio",
			default_value=>"FALSE" },
	);
}

######################################################################
=pod

=item $dataset = EPrints::DataObj::SavedSearch->get_dataset_id

Returns the ID of the L<EPrints::DataSet> object to which this record 
belongs.

=cut
######################################################################

sub get_dataset_id
{
	return "saved_search";
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

=item $dataset = $saved_search->get_dataset

Get the dataset that this saved search covers.

=cut
######################################################################

sub get_dataset
{
    my( $self ) = @_;

    return $self->is_set( "public" ) && $self->value( "public" ) eq "TRUE" ?
            $self->{session}->dataset( "public_saved_search" ) :
            $self->{session}->dataset( "saved_search" );
}


######################################################################
=pod

=item $success = $saved_search->commit( [ $force ] )

Writes this object to the database.

If C<$force> is not true then it only actually modifies the database
if one or more fields have been changed.

Returns C<true> if commit was successfully. Otherwise, returns 
C<false>.

=cut
######################################################################

sub commit
{
	my( $self, $force ) = @_;
	
	$self->update_triggers();

	if( !defined $self->{changed} || scalar( keys %{$self->{changed}} ) == 0 )
	{
		# don't do anything if there isn't anything to do
		return( 1 ) unless $force;
	}

	my $success = $self->SUPER::commit( $force );

	return $success;
}


######################################################################
=pod

=item $user = $saved_search->get_user

Returns the C<EPrints::DataObj::User> which owns this saved search.

=cut
######################################################################

sub get_user
{
	my( $self ) = @_;

	return undef unless $self->is_set( "userid" );

	if( defined($self->{user}) )
	{
		# check we still have the same owner
		if( $self->{user}->get_id eq $self->get_value( "userid" ) )
		{
			return $self->{user};
		}
	}

	$self->{user} = EPrints::DataObj::User->new( 
		$self->{session}, 
		$self->get_value( "userid" ) );

	return $self->{user};
}

######################################################################
=pod

=item $searchexp = $saved_search->make_searchexp

Returns an L<EPrints::Search> describing how to find the data objects
which are in the scope of this saved search.

=cut
######################################################################

sub make_searchexp
{
	my( $self ) = @_;

	my $ds = $self->{session}->get_repository->get_dataset( 
		"saved_search" );
	
	return $ds->get_field( 'spec' )->make_searchexp( 
		$self->{session},
		$self->get_value( 'spec' ) );
}


######################################################################
=pod

=item $saved_search->send_out_alert

Sends out an email for this subscription. If there are no matching new
data objects then an email is only sent if the saved search has 
C<mailempty> set to C<true>.

=cut
######################################################################

sub send_out_alert
{
	my( $self ) = @_;

	my $freq = $self->get_value( "frequency" );

	if( $freq eq "never" )
	{
		$self->{session}->get_repository->log( 
			"Attempt to send out an alert for a\n".
			"which has frequency 'never'\n" );
		return;
	}
		
	my $user = $self->get_user;

	if( !defined $user )
	{
		$self->{session}->get_repository->log( 
			"Attempt to send out an alert for a\n".
			"non-existent user. SavedSearch ID#".$self->get_id."\n" );
		return;
	}

	# change language temporarily to the user's language
	local $self->{session}->{lang} = $user->language();

	my $searchexp = $self->make_searchexp;

	if( $searchexp->isa( "EPrints::Plugin::Search::Xapian" ) || $searchexp->isa( "EPrints::Plugin::Search::Xapianv2" ) )
	{
		$self->{session}->log( "send_alerts: Xapian search engine not yet supported. Cannot send alerts for SavedSearch id=".$self->id );
		return;
	}

	# get the description before we fiddle with searchexp
 	my $searchdesc = $searchexp->render_description,

	my $datestamp_field = $self->{session}->get_repository->get_dataset( 
		"archive" )->get_field( "datestamp" );

	if( $freq eq "daily" )
	{
		# Get the date for yesterday
		my $yesterday = EPrints::Time::get_iso_date( 
			time - (24*60*60) );
		# Get from the last day
		$searchexp->add_field( 
			$datestamp_field,
			$yesterday."-" );
	}
	elsif( $freq eq "weekly" )
	{
		# Work out date a week ago
		my $last_week = EPrints::Time::get_iso_date( 
			time - (7*24*60*60) );

		# Get from the last week
		$searchexp->add_field( 
			$datestamp_field,
			$last_week."-" );
	}
	elsif( $freq eq "monthly" )
	{
		# Get today's date
		my( $year, $month, $day ) = EPrints::Time::get_date_array( time );
		# Subtract a month		
		$month--;

		# Check for year "wrap"
		if( $month==0 )
		{
			$month = 12;
			$year--;
		}
		
		# Ensure two digits in month
		while( length $month < 2 )
		{
			$month = "0".$month;
		}
		my $last_month = $year."-".$month."-".$day;
		# Add the field searching for stuff from a month onwards
		$searchexp->add_field( 
			$datestamp_field,
			$last_month."-" );
	}

	my $settings_url = $self->{session}->get_repository->get_conf( "perl_url" ).
		"/users/home?screen=Workflow::Edit&dataset=saved_search&dataobj=".$self->get_id;
	my $freqphrase = $self->{session}->html_phrase(
		"lib/saved_search:".$freq );

	my $fn = sub {
		my( $session, $dataset, $item, $info ) = @_;

		my $p = $session->make_element( "p" );
		$p->appendChild( $item->render_citation_link( $session->config( "saved_search_citation" )));
		$info->{matches}->appendChild( $p );
#		$info->{matches}->appendChild( $session->make_text( $item->get_url ) );
	};


	my $list = $searchexp->perform_search;
	my $mempty = $self->get_value( "mailempty" );
	$mempty = 0 unless defined $mempty;

	my @additional_recipients;
	if( $self->{session}->config( "saved_search_additional_recipients" ) )
	{
		my $additional_recipients_str = $self->get_value( "additional_recipients" );
		if($additional_recipients_str)
		{
			foreach my $ar (split(/, ?/, $additional_recipients_str))
			{
				next unless $ar =~ /\@/;
				push @additional_recipients, $ar;
			}
		}
	}

	if( $list->count > 0 || $mempty eq 'TRUE' )
	{
		my $info = {};
		$info->{matches} = $self->{session}->make_doc_fragment;
		$list->map( $fn, $info );

		my $mail = $self->{session}->html_phrase( 
				"lib/saved_search:mail",
				howoften => $freqphrase,
				n => $self->{session}->make_text( $list->count ),
				search => $searchdesc,
				matches => $info->{matches},
				url => $self->{session}->render_link( $settings_url ) );
		if( $self->{session}->get_noise >= 2 )
		{
			print "Sending out alert #".$self->get_id." to ".$user->get_value( "email" )."\n";
		}
		$user->mail( 
			"lib/saved_search:sub_subj",
			$mail,
			undef,
			undef,
			\@additional_recipients # cc_list
		);

		EPrints::XML::dispose( $mail );
	}
	elsif ( $self->{session}->get_noise >= 2 )
	{
		print STDERR "Not sending out alert #".$self->get_id." to ".$user->get_value( "email" )." because saved search states not to send email if no results are found.\n"; 
	}
	$list->dispose;
}


######################################################################
=pod

=item $boolean = $saved_search->has_owner( $possible_owner )

Returns C<true> if C<$possible_owner> is the same as the owner of this
saved search. Otherwise, returns C<false>.

=cut
######################################################################

sub has_owner
{
    my( $self, $possible_owner ) = @_;

    if( $possible_owner->get_value( "userid" ) == $self->get_value( "userid" ) )
    {
        return 1;
    }

    return 0;
}


######################################################################
=pod

=item $parent = $saved_search->parent

Returns the parent data object for this saved search. I.e. the user 
who owns this saved search.  This is similar to L</get_user> but is 
not as fault tolerant and does set instance variable: 

 $self->{user}

=cut
######################################################################

sub parent
{
    my( $self ) = @_;

    return $self->{session}->user( $self->value( "userid" ) );
}


######################################################################
=pod

=item $url = $saved_search->get_url( [ $staff ] )

Gets the URL for this saved search.  Currently C<$staff> will not 
effect the URL but in future this may return a specialised URL for 
staff only.

=cut
######################################################################

sub get_url
{
    my( $self, $staff ) = @_;

    my $searchexp = $self->{session}->plugin( "Search" )->thaw( $self->value( "spec" ) );
    return undef if !defined $searchexp;

    return $searchexp->search_url;
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

=item EPrints::DataObj::SavedSearch::process_set( $session, $frequency );

Static method. 

Calls C<send_out_alert> on every saved search with a frequency 
matching C<$frequency>.

Also saves a file logging that the alerts for this frequency was sent 
out at the current time.

=cut
######################################################################

sub process_set
{
	my( $session, $frequency ) = @_;

	if( $frequency ne "daily" && 
		$frequency ne "weekly" && 
		$frequency ne "monthly" )
	{
		$session->get_repository->log( "EPrints::DataObj::SavedSearch::process_set called with unknown frequency: ".$frequency );
		return;
	}

	my $subs_ds = $session->dataset( "saved_search" );

	my $searchexp = EPrints::Search->new(
		session => $session,
		dataset => $subs_ds );

	$searchexp->add_field(
		$subs_ds->get_field( "frequency" ),
		$frequency );

	my $fn = sub {
		my( $session, $dataset, $item, $info ) = @_;

		$item->send_out_alert;
	};

	my $list = $searchexp->perform_search;
	$list->map( $fn, {} );

	my $statusfile = $session->config( "variables_path" ).
		"/alert-".$frequency.".timestamp";

	unless( open( TIMESTAMP, ">$statusfile" ) )
	{
		$session->get_repository->log( "EPrints::DataObj::SavedSearch::process_set failed to open\n$statusfile\nfor writing." );
	}
	else
	{
		print TIMESTAMP <<END;
# This file is automatically generated to indicate the last time
# this repository successfully completed sending the *$frequency* 
# alerts. It should not be edited.
END
		print TIMESTAMP EPrints::Time::human_time()."\n";
		close TIMESTAMP;
	}
}


######################################################################
=pod

=item $timestamp = EPrints::DataObj::SavedSearch::get_last_timestamp( $session, $frequency );

Static method.

Return sthe timestamp of the last time this C<$frequency> of alert was 
sent.

=cut
######################################################################

sub get_last_timestamp
{
	my( $session, $frequency ) = @_;

	if( $frequency ne "daily" && 
		$frequency ne "weekly" && 
		$frequency ne "monthly" )
	{
		$session->get_repository->log( "EPrints::DataObj::SavedSearch::get_last_timestamp called with unknown\nfrequency: ".$frequency );
		return;
	}

	my $statusfile = $session->config( "variables_path" ).
		"/alert-".$frequency.".timestamp";

	unless( open( TIMESTAMP, $statusfile ) )
	{
		# can't open file. Either an error or file does not exist
		# either way, return undef.
		return;
	}

	my $timestamp = undef;
	while(<TIMESTAMP>)
	{
		next if m/^\s*#/;	
		next if m/^\s*$/;	
		s/\015?\012?$//s;
		$timestamp = $_;
		last;
	}
	close TIMESTAMP;

	return $timestamp;
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

Copyright 2023 University of Southampton.
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

