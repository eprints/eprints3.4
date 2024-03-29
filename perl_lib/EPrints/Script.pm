######################################################################
#
# EPrints::Script
#
######################################################################
#
#
######################################################################

=pod

=head1 NAME

B<EPrints::Script> - Mini-scripting language for use in workflow and citations.

=head1 DESCRIPTION

This module processes simple eprints mini-scripts.

 my $result = execute( "$eprint.type = 'article'", { eprint=>$eprint } );

The syntax is

 $var := dataobj or string or datastructure
 "string" := string
 'string' := string
 !boolean := boolean 
 string = string := boolean
 string := string := boolean
 boolean or boolean := boolean
 boolean and boolean := boolean
 dataobj{property} := string or datastructure

Selected functions

 dataobj.is_set( fieldname ) := boolean
 string.one_of( string, string, string... ) := boolean
 string.reverse() := string ( foobar=>raboof ) 
 ?.length() := integer

The full list of functions (as of 3.2.0-alpha-1)

 citation_link
 citation
 yesno
 one_of
 as_item 
 as_string
 strlen
 length
 today
 datemath
 dataset 
 related_objects
 url
 doc_size
 is_public
 thumbnail_url
 preview_link
 icon
 human_filesize
 control_url
 contact_email
 uri
 action_list
 action_button
 action_icon
 action_description
 action_title

=cut

package EPrints::Script;

use strict;

sub execute
{
	my( $code, $state ) = @_;

#foreach( keys %{$state} ) { print STDERR "$_: ".$state->{$_}."\n"; }
	$state->{repository} = $state->{session}->get_repository;
	$state->{config} = $state->{session}->get_repository->{config};

	# might be undefined
	$state->{current_user} = $state->{session}->current_user; 
	$state->{current_lang} = [$state->{session}->get_langid, "STRING" ]; 

	my $compiled = EPrints::Script::Compiler->new()->compile( $code, $state->{in} );

#print STDERR $compiled->debug;

	return $compiled->run( $state );
}

sub print
{
	my( $code, $state, $opts ) = @_;

	my $result = execute( $code, $state );	
#	print STDERR  "IFTEST:::".$expr." == $result\n";

	if( $result->[1] eq "XHTML"  )
	{
		return $state->{session}->clone_for_me( $result->[0], 1 );
	}
	if( $result->[1] eq "BOOLEAN"  )
	{
		return $state->{session}->make_text( $result->[0]?"TRUE":"FALSE" );
	}
	if( $result->[1] eq "STRING"  )
	{
		return $state->{session}->make_text( $result->[0] );
	}
	if( $result->[1] eq "DATE"  )
	{
		return $state->{session}->make_text( $result->[0] );
	}
	if( $result->[1] eq "INTEGER"  )
	{
		return $state->{session}->make_text( $result->[0] );
	}

	my $field = $result->[1];

	# apply any render opts
	if( defined $opts && $opts ne "" )
	{
		$field = $field->clone;
		
		foreach my $opt ( split( /;/, $opts ) )
		{
			my( $k, $v ) = split( /=/, $opt );
			$v = 1 unless defined $v;
			$field->set_property( "render_$k", $v );
		}
	}
#print STDERR "(".$result->[0].",".$result->[1].")\n";

	if( !defined $field )
	{
		return $state->{session}->make_text( "[No type for value '$result->[0]' from '$code']" );
	}

	if( !UNIVERSAL::isa( $field, "EPrints::MetaField" ) )
	{
		EPrints->abort( "Expected MetaField but got '$field'" );
	}
	return $field->render_value( $state->{session}, $result->[0], 0, 0, $result->[2] );
}

sub error
{
	my( $msg, $in, $pos, $code ) = @_;
#print STDERR "msg:$msg\n";
#print STDERR "POS:$pos\n";
	
	my $error = "Script in ".(defined $in?$in:"unknown").": ".$msg;
	if( defined $pos ) { $error.= " at character ".$pos; }
	if( defined $code ) { $error .= "\n".$code; }
	if( defined $code && defined $pos ) {  $error .=  "\n".(" "x$pos). "^ here"; }
	die $error; # aimed to be caught
}

1;

=head1 COPYRIGHT

=for COPYRIGHT BEGIN

Copyright 2022 University of Southampton.
EPrints 3.4 is supplied by EPrints Services.

http://www.eprints.org/eprints-3.4/

=for COPYRIGHT END

=for LICENSE BEGIN

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

=for LICENSE END

