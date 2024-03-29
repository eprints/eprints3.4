######################################################################
#
# EPrints::BackCompatibility
#
######################################################################
#
#
######################################################################


=pod

=for Pod2Wiki

=head1 NAME

B<EPrints::BackCompatibility> - Provide compatibility for older 
versions of the API.

=head1 DESCRIPTION

A number of EPrints packages have been moved or renamed. This module
provides stub versions of these packages under there old names so that
existing code will require few or no changes.

It also sets a flag in Perl to think the packages have been loaded from
their original locations. This causes calls such as:

 use EPrints::Document;

to do nothing as they know the module is already loaded.

=head2 Superseded Classes or Methods

The following classes have been fully superseded or have methods that 
have been superseded by methods for different classes.

=over 4

=item L<EPrints::Document>

Superseded by L<EPrints::DataObj::Document>.

=item L<EPrints::EPrint>

Superseded by L<EPrints::DataObj::EPrint>.

=item L<EPrints::Subject>

Superseded by L<EPrints::DataObj::Subject>.

=item L<EPrints::Subscription>

Superseded by L<EPrints::DataObj::SavedSearch>.

=item L<EPrints::User>

Superseded by L<EPrints::DataObj::User>.

=item L<EPrints::DataObj::User>

The following methods are deprecated and replaced by other methods in 
the class:

 can_edit
 get_owned_eprints
 get_editable_eprints
 get_eprints

=item L<EPrints::Utils>

The following methods are deprecated and replaced by other methods in
the L<EPrints::Email>, L<EPrints::XML::EPC>, L<EPrints::Time> and
L<EPrints::Platform> (subsequently superseded by L<EPrints::System>):

 send_mail 
 send_mail_via_smtp 
 send_mail_via_sendmail 
 collapse_conditions 
 render_date 
 render_short_date 
 datestring_to_timet 
 gmt_off 
 get_month_label 
 get_month_label_short 
 get_date 
 get_date_array 
 get_datestamp 
 get_iso_date 
 get_timestamp 
 human_time 
 human_delay 
 get_iso_timestamp
 df_dir
 mkdir
 join_path

=item L<EPrints::Archive>

Superseded by L<EPrints::Repository>.

=item L<EPrints::SearchExpression>

Superseded by L<EPrints::Search>.

=item L<EPrints::SearchField>

Superseded by L<EPrints::Search::Field>.

=item L<EPrints::SearchCondition>

Superseded by L<EPrints::Search::Condition>.

=item L<EPrints::AnApache>

Superseded by L<EPrints::Apache::AnApache>.

=item L<EPrints::Auth>

Superseded by L<EPrints::Apache::Auth>.

=item L<EPrints::DataSet>

The following methods are deprecated:

 get_page_fields
 get_type_pages
 get_type_fields
 get_required_type_fields
 is_valid_type
 get_types
 get_type_names
 get_type_name
 render_type_name
 load_workflows

=item L<EPrints::Index>

The following methods are superseded by methods in
L<EPrints::Index::Tokenizer>:

 split_words
 apply_mapping

=item L<EPrints::Session>

Superseded by L<EPrints::Repository>.

=item L<EPrints::Platform>

Superseded by L<EPrints::System>.

=item L<EPrints::Repository>

The following methods are superseded by methods in other classes:

 render_toolbar
 freshen_citation
 get_citation_spec
 get_citation_type

=cut
######################################################################

use EPrints;

use strict;

######################################################################
=pod

=back

=cut
######################################################################

package EPrints::Document;

our @ISA = qw/ EPrints::DataObj::Document /;

$INC{"EPrints/Document.pm"} = "EPrints/BackCompatibility.pm";

sub create { EPrints::deprecated; return EPrints::DataObj::Document::create( @_ ); }

sub docid_to_path { EPrints::deprecated; return EPrints::DataObj::Document::docid_to_path( @_ ); }

######################################################################

package EPrints::EPrint;

our @ISA = qw/ EPrints::DataObj::EPrint /;

$INC{"EPrints/EPrint.pm"} = "EPrints/BackCompatibility.pm";

sub create { EPrints::deprecated; return EPrints::DataObj::EPrint::create( @_ ); }
sub eprintid_to_path { EPrints::deprecated; return EPrints::DataObj::EPrint::eprintid_to_path( @_ ); }

######################################################################

package EPrints::Subject;

our @ISA = qw/ EPrints::DataObj::Subject /;

$INC{"EPrints/Subject.pm"} = "EPrints/BackCompatibility.pm";

$EPrints::Subject::root_subject = "ROOT";
sub remove_all { EPrints::deprecated; return EPrints::DataObj::Subject::remove_all( @_ ); }
sub create { EPrints::deprecated; return EPrints::DataObj::Subject::create( @_ ); }
sub get_all { EPrints::deprecated; return EPrints::DataObj::Subject::get_all( @_ ); }
sub valid_id { EPrints::deprecated; return EPrints::DataObj::Subject::valid_id( @_ ); }
sub children { EPrints::deprecated; return EPrints::DataObj::Subject::get_children( $_[0] ); }

######################################################################

package EPrints::Subscription;

our @ISA = qw/ EPrints::DataObj::SavedSearch /;

$INC{"EPrints/Subscription.pm"} = "EPrints/BackCompatibility.pm";

sub process_set { EPrints::deprecated; return EPrints::DataObj::SavedSearch::process_set( @_ ); }
sub get_last_timestamp { EPrints::deprecated; return EPrints::DataObj::SavedSearch::get_last_timestamp( @_ ); }

######################################################################

package EPrints::User;

our @ISA = qw/ EPrints::DataObj::User /;

$INC{"EPrints/User.pm"} = "EPrints/BackCompatibility.pm";

sub create { EPrints::deprecated; return EPrints::DataObj::User::create( @_ ); }
sub user_with_email { EPrints::deprecated; return EPrints::DataObj::User::user_with_email( @_ ); }
sub user_with_username { EPrints::deprecated; return EPrints::DataObj::User::user_with_username( @_ ); }
sub process_editor_alerts { EPrints::deprecated; return EPrints::DataObj::User::process_editor_alerts( @_ ); }
sub create_user { EPrints::deprecated; return EPrints::DataObj::User::create( @_ ); }

package EPrints::DataObj::User;

sub can_edit { EPrints::deprecated; return $_[1]->in_editorial_scope_of( $_[0] ); }
sub get_owned_eprints { EPrints::deprecated; return $_[0]->owned_eprints_list( dataset => $_[1] ); }
sub get_editable_eprints
{
	EPrints::deprecated;
	return $_[0]->editable_eprints_list(
			dataset => $_[0]->{session}->dataset( "buffer" )
		);
}
sub get_eprints
{
	EPrints::deprecated;
	return $_[1]->search(
			filters => [
				{ meta_fields => ["userid"], value => $_[0] },
			],
		);
}


######################################################################

package EPrints::Utils;

sub send_mail { EPrints::deprecated(); return EPrints::Email::send_mail( @_ ); }
sub send_mail_via_smtp { EPrints::deprecated(); return EPrints::Email::send_mail_via_smtp( @_ ); }
sub send_mail_via_sendmail { EPrints::deprecated(); return EPrints::Email::send_mail_via_sendmail( @_ ); }
sub collapse_conditions { EPrints::deprecated(); return EPrints::XML::EPC::process( @_ ); }
sub render_date { EPrints::deprecated(); return EPrints::Time::render_date( @_ ); }
sub render_short_date { EPrints::deprecated(); return EPrints::Time::render_short_date( @_ ); }
sub datestring_to_timet { EPrints::deprecated(); return EPrints::Time::datestring_to_timet( @_ ); }
sub gmt_off { EPrints::deprecated(); return EPrints::Time::gmt_off( @_ ); }
sub get_month_label { EPrints::deprecated(); return EPrints::Time::get_month_label( @_ ); }
sub get_month_label_short { EPrints::deprecated(); return EPrints::Time::get_month_label_short( @_ ); }
sub get_date { EPrints::deprecated(); return EPrints::Time::get_date( @_ ); }
sub get_date_array { EPrints::deprecated(); return EPrints::Time::get_date_array( @_ ); }
sub get_datestamp { EPrints::deprecated(); return EPrints::Time::get_iso_date( @_ ); }
sub get_iso_date { EPrints::deprecated(); return EPrints::Time::get_iso_date( @_ ); }
sub get_timestamp { EPrints::deprecated(); return EPrints::Time::human_time( @_ ); }
sub human_time { EPrints::deprecated(); return EPrints::Time::human_time( @_ ); }
sub human_delay { EPrints::deprecated(); return EPrints::Time::human_delay( @_ ); }
sub get_iso_timestamp { EPrints::deprecated(); return EPrints::Time::get_iso_timestamp( @_ ); }
sub df_dir{my( $dir ) = @_;EPrints::deprecated();return EPrints::Platform::free_space( $dir );}
sub mkdir{my( $full_path, $perms ) = @_;EPrints::abort("EPrints::Utils::mkdir is deprecated: use EPrints::Platform::mkdir");	return 1;}
sub join_path { EPrints::deprecated(); return EPrints::Platform::join_path(@_); }



######################################################################

package EPrints::Archive;

our @ISA = qw/ EPrints::Repository /;

$INC{"EPrints/Archive.pm"} = "EPrints/BackCompatibility.pm";

######################################################################

package EPrints::SearchExpression;

our @ISA = qw/ EPrints::Search /;

@EPrints::SearchExpression::OPTS = (
	"session", 	"dataset", 	"allow_blank", 	"satisfy_all", 	
	"fieldnames", 	"staff", 	"order", 	"custom_order",
	"keep_cache", 	"cache_id", 	"prefix", 	"defaults",
	"citation", 	"page_size", 	"filters", 	"default_order",
	"preamble_phrase", 		"title_phrase", "search_fields",
	"controls" );

$EPrints::SearchExpression::CustomOrder = "_CUSTOM_";

$INC{"EPrints/SearchExpression.pm"} = "EPrints/BackCompatibility.pm";

######################################################################

package EPrints::SearchField;

our @ISA = qw/ EPrints::Search::Field /;

$INC{"EPrints/SearchField.pm"} = "EPrints/BackCompatibility.pm";

######################################################################

package EPrints::SearchCondition;

our @ISA = qw/ EPrints::Search::Condition /;

$EPrints::SearchCondition::operators = {
	'CANPASS'=>0, 'PASS'=>0, 'TRUE'=>0, 'FALSE'=>0,
	'index'=>1, 'index_start'=>1,
	'='=>2, 'name_match'=>2, 'AND'=>3, 'OR'=>3,
	'is_null'=>4, '>'=>4, '<'=>4, '>='=>4, '<='=>4, 'in_subject'=>4,
	'grep'=>4	};

$INC{"EPrints/SearchCondition.pm"} = "EPrints/BackCompatibility.pm";

######################################################################

package EPrints::AnApache;

sub upload_doc_file { EPrints::deprecated; return EPrints::Apache::AnApache::upload_doc_file( @_ ); }
sub upload_doc_archive { EPrints::deprecated; return EPrints::Apache::AnApache::upload_doc_archive( @_ ); }
sub send_http_header { EPrints::deprecated; return EPrints::Apache::AnApache::send_http_header( @_ ); }
sub header_out { EPrints::deprecated; return EPrints::Apache::AnApache::header_out( @_ ); }
sub header_in { EPrints::deprecated; return EPrints::Apache::AnApache::header_in( @_ ); }
sub get_request { EPrints::deprecated; return EPrints::Apache::AnApache::get_request( @_ ); }
sub cookie { EPrints::deprecated; return EPrints::Apache::AnApache::cookie( @_ ); }

$INC{"EPrints/AnApache.pm"} = "EPrints/BackCompatibility.pm";

######################################################################

package EPrints::Auth;

sub authz { EPrints::deprecated; return EPrints::Apache::Auth::authz( @_ ); }
sub authen { EPrints::deprecated; return EPrints::Apache::Auth::authen( @_ ); }

$INC{"EPrints/Auth.pm"} = "EPrints/BackCompatibility.pm";

######################################################################

package EPrints::DataSet;

sub get_page_fields
{
	my( $self, $type, $page, $staff ) = @_;

	EPrints::deprecated;

	$self->load_workflows();

	my $mode = "normal";
	$mode = "staff" if $staff;

	my $fields = $self->{types}->{$type}->{pages}->{$page}->{$mode};
	if( !defined $fields )
	{
		$self->{repository}->log( "No fields found in get_page_fields ($type,$page)" );
		return ();
	}
	return @{$fields};
}

sub get_type_pages
{
	my( $self, $type ) = @_;

	EPrints::deprecated;

	$self->load_workflows();

	my $l = $self->{types}->{$type}->{page_order};

	return () unless( defined $l );

	return @{$l};
}

sub get_type_fields
{
	my( $self, $type, $staff ) = @_;

	EPrints::deprecated;

	$self->load_workflows();

	my $mode = "normal";
	$mode = "staff" if $staff;

	my $fields = $self->{types}->{$type}->{fields}->{$mode};
	if( !defined $fields )
	{
		$self->{repository}->log( "Unknown type in get_type_fields ($type)" );
		return ();
	}
	return @{$fields};
}

sub get_required_type_fields
{
	my( $self, $type ) = @_;
	# Can't do this any more without loading lots of workflow gubbins
	EPrints::deprecated;

	return(); 


}

sub is_valid_type
{
	my( $self, $type ) = @_;
	EPrints::deprecated;
	return( defined $self->{repository}->{types}->{$self->confid}->{$type} );
}

sub get_types
{
	my( $self ) = @_;

	EPrints::deprecated;

	return( $self->{repository}->{types}->{$self->confid} );
}

sub get_type_names
{
	my( $self, $session ) = @_;
		
	EPrints::deprecated;

	my %names = ();
	foreach( @{$self->get_types} )
	{
		$names{$_} = $self->get_type_name( $session, $_ );
	}
	return( \%names );
}

sub get_type_name
{
	my( $self, $session, $type ) = @_;

	EPrints::deprecated;

        return $session->phrase( $self->confid()."_typename_".$type );
}

sub render_type_name
{
	my( $self, $session, $type ) = @_;
	
	EPrints::deprecated;

	if( $self->{confid} eq "language"  || $self->{confid} eq "arclanguage" )
	{
		return $session->make_text( $self->get_type_name( $session, $type ) );
	}
        return $session->html_phrase( $self->confid()."_typename_".$type );
}

sub load_workflows
{
	my( $self ) = @_;

	return if $self->{workflows_loaded};

	my $mini_session = EPrints::Session->new( 1, $self->{repository}->get_id );
	foreach my $typeid ( @{$self->{type_order}} )
	{
		my $tdata = {};
		my $data = {};
		if( $self->{confid} eq "user" ) 
		{
			$data = {usertype=>$typeid};
		}
		if( $self->{confid} eq "eprint" ) 
		{
			$data = {type=>$typeid,eprint_status=>"buffer"};
		}
		my $item = $self->make_object( $mini_session, $data );
		my $workflow = EPrints::Workflow->new( $mini_session, "default", item=> $item );
		my $s_workflow = EPrints::Workflow->new( $mini_session, "default", item=> $item, "STAFF_ONLY"=>["TRUE","BOOLEAN"] );
		$tdata->{page_order} = [$workflow->get_stage_ids];
		$tdata->{fields} = { staff=>[], normal=>[] };
		$tdata->{req_field_map} = {};
		$tdata->{req_fields} = [];
		foreach my $page_id ( @{$tdata->{page_order}} )
		{
			my $stage = $workflow->get_stage( $page_id );
			my @components = $stage->get_components;
			foreach my $component ( @components )
			{
				next unless ref( $component ) eq "EPrints::Plugin::InputForm::Component::Field";
				my $field = $component->get_field;
				push @{$tdata->{fields}->{normal}}, $field;	
				push @{$tdata->{pages}->{$page_id}->{normal}}, $field;
				if( $field->get_property( "required" ) )
				{
					push @{$tdata->{req_fields}}, $field;	
					$tdata->{req_field_map}->{$field->get_name} = 1;
				}
			}

			my $s_stage = $s_workflow->get_stage( $page_id );
			my @s_components = $s_stage->get_components;
			foreach my $s_component ( @s_components )
			{
				next unless ref( $s_component ) eq "EPrints::Plugin::InputForm::Component::Field";
				my $field = $s_component->get_field;
				push @{$tdata->{pages}->{$page_id}->{staff}}, $field;
				push @{$tdata->{fields}->{staff}}, $field;
			}
		}
		$self->{types}->{$typeid} = $tdata;


	}
	$mini_session->terminate;

	$self->{workflows_loaded} = 1;
}

######################################################################

package EPrints::Index;

sub split_words { &EPrints::Index::Tokenizer::split_words }
sub apply_mapping { &EPrints::Index::Tokenizer::apply_mapping }

######################################################################

package EPrints::Session;

use EPrints::Repository;
our @ISA = qw( EPrints::Repository );

sub get_session_language { EPrints::Repository::get_session_language( @_ ); }
sub best_language { EPrints::Repository::best_language( @_ ); }

sub EPrints::Session::new
{
	my( $class, $mode, $repository_id, $noise, $nocheckdb ) = @_;
	my %opts = ( noise=>0, cgi=>1 );
	if( $noise ) { $opts{noise} = $noise; }
	if( defined $mode && $mode == 1 ) { $opts{cgi} = 0; }
	if( defined $mode && $mode == 2 ) { $opts{cgi} = 1; $opts{consume_post} = 0; }
	if( $nocheckdb ) { $opts{check_db} = 0; }

	my $ep = EPrints->new( cleanup=>0 ); 
	if( $opts{cgi} )
	{
		return $EPrints::HANDLE->current_repository;
	}
	else
	{
		$ep->repository( $repository_id, %opts );
	}
}

$INC{"EPrints/Session.pm"} = "EPrints/BackCompatibility.pm";

package EPrints::Platform;

$INC{"EPrints/Platform.pm"} = "EPrints/BackCompatibility.pm";

sub chmod { EPrints->system->chmod( @_ ) }
sub chown { EPrints->system->chown( @_ ) }
sub getpwnam { EPrints->system->getpwnam( @_ ) }
sub getgrnam { EPrints->system->getgrnam( @_ ) }
sub test_uid { EPrints->system->test_uid( @_ ) }
sub mkdir { EPrints->system->mkdir( @_ ) }
sub exec { EPrints->system->exec( @_ ) }
sub read_exec { EPrints->system->read_exec( @_ ) }
sub read_perl_script { EPrints->system->read_perl_script( @_ ) }
sub get_hash_name { EPrints->system->get_hash_name( @_ ) }
sub free_space { EPrints->system->free_space( @_ ) }
sub proc_exists { EPrints->system->proc_exists( @_ ) }
sub join_path { EPrints->system->join_path( @_ ) }

package EPrints::Repository;

# phrase-based dynamic_templates.pl
sub render_toolbar {
	EPrints::ScreenProcessor->new(
			session => shift,
		)->render_toolbar;
}

sub freshen_citation
{
	my( $self, $dsid, $fileid ) = @_;
}

sub get_citation_spec
{
	my( $self, $dataset, $style ) = @_;

	my $citation = $dataset->citation( $style );
	return undef if !defined $citation;

	EPrints->abort( "get_citation_spec is deprecated and only works with EPC citations: ".$dataset->id.".".$style.": you should be calling render_citation()" )
		if !$citation->isa( "EPrints::Citation::EPC" );

	return $self->clone_for_me( $citation->{style}, 1 )
}

sub get_citation_type
{
	my( $self, $dataset, $style ) = @_;

	my $citation = $dataset->citation( $style );
	return undef if !defined $citation;

	return $citation->type;
}

1;

######################################################################
=pod

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

