######################################################################
#
# EPrints::Apache::REST
#
######################################################################
#
#
######################################################################

=pod

=for Pod2Wiki

=head1 NAME

EPrints::Apache::REST - Representational state transfer

=head1 DESCRIPTION

REST API for EPrints

=head1 METHODS

=cut

package EPrints::Apache::REST;

use EPrints::Apache::AnApache; # exports apache constants

use strict;
use warnings;

######################################################################
=pod

=over 4

=item $rc = EPrints::Apache::REST::handler( $r )

Handler for EPrints' REST API

=cut
######################################################################

sub handler
{
	my( $r ) = @_;

	my $repository = $EPrints::HANDLE->current_repository;

	my $uri = $r->uri;
	my $urlpath = $repository->config( "rel_path" );
	$uri =~ s! ^$urlpath !!x;
	$uri =~ s/^\/rest//;

	if( $uri eq "" )
	{
		return redir_add_slash( $repository );
	}

	if( $uri !~ m/^\// )
	{
		return NOT_FOUND;
	}
	
	my @path = split( '/', $uri );
	shift @path;
	if( $uri =~ m/\/$/ ) { push @path, ""; }

	return serve_top_level( $repository, @path );
}


######################################################################
=pod

=item $rc = EPrints::Apache::REST::redir_add_slash( $repository )

Redirect to the current request for the C<$repository> with an added 
slash C</> at the end of the path.

=cut
######################################################################

sub redir_add_slash
{
	my( $repository ) = @_;

	return $repository->redirect( $repository->get_uri."/" );
}


######################################################################
=pod

=item $rc = EPrints::Apache::REST::serve_top_level( $repository, @path )

Serve top level list of datasets (i.e. C<eprint>, C<user> and 
C<subject>) or pass onto L</serve_dataset>. dependent of C<@path>.

=cut
######################################################################

sub serve_top_level
{
	my( $repository, @path ) = @_;

	# /
	if( @path == 1 && $path[0] eq "" )
	{
		#my @ds_ids = $repository->get_dataset_ids;
		my @ds_ids = qw/ eprint user subject /;
		my $h = "<ul>\n";
		foreach my $ds_id ( @ds_ids )
		{
			my $dataset = $repository->dataset( $ds_id );
			next if $dataset->confid ne $ds_id;
			$h .= "<li><a href='$ds_id/'>".EPrints::XML::to_string( $dataset->render_name( $repository ) )."</a></li>\n";
		}
		$h .= "</ul>\n";

		return send_html( $repository, $h, "Datasets" );
	}

	# /eprint
	if( @path == 1 )
	{
		return redir_add_slash( $repository );
	}

	# /eprint/
	my $dataset_id = shift @path;

	my $dataset = $repository->dataset( $dataset_id ); 
	if( !defined $dataset )
	{
		return 404;
	}

	return serve_dataset( $repository, $dataset, @path );
}


######################################################################
=pod

=item $rc = EPrints::Apache::REST::serve_dataset( $repository, $dataset, @path )

Serve listing of data objects for a particular dataset, pass onto
L</serve_dataobj>, L</get_dataobj_xml> or L</put_dataobj_xml> or
return an appropriate HTTP error code.

=cut
######################################################################

sub serve_dataset
{
	my( $repository, $dataset, @path ) = @_;

	my $file = shift @path;

	if( scalar @path == 0 )
	{
		# /
		if( $file eq "" )
		{
			return unless allowed_methods( $repository, "GET" );
			my $sortfn = sub { $a <=> $b };
			if( $dataset->id eq "subject" )
			{
				$sortfn = sub { $a cmp $b };
			}
			my $ul = "<ul>\n";
			foreach my $id ( sort $sortfn @{$dataset->get_item_ids( $repository )} )
			{
				$ul .= "<li><a href='$id/'>$id/</a></li>\n";
				$ul .= "<li><a href='$id.xml'>$id.xml</a></li>\n";
			}
			$ul .= "</ul>\n";
		
			my $title = EPrints::XML::to_string( $dataset->render_name( $repository ) )." DataSet";
			return send_html( $repository, $ul, $title );
		}

		# /23
		if( $file =~ m/^\d+$/ )
		{
			return redir_add_slash( $repository );
		}

		my( $item_id, $format) = split( /\.(?=[^.]+$)/, $file, 2 );
		my $object = $dataset->get_object( $repository, $item_id );
		if( !defined $object )
		{
			return 404;
		}

		if( defined $format && $format eq "xml" )
		{
			return unless allowed_methods( $repository, "GET","PUT" );
			my $method = $ENV{REQUEST_METHOD};
			if( $method eq "GET" )
			{
				return get_dataobj_xml( $repository, $object, $object );
			}
			if( $method eq "PUT" )
			{
				return put_dataobj_xml( $repository, $object, $object );
			}
			return 500; # should not happen!
		}
	
		return 404;
	}

	# /23/	
	my $object = $dataset->get_object( $repository, $file );

	# /abc/
	if( !defined $object && $dataset->id eq "user" )
	{
		$object = $repository->user_by_username( $file );
	}

	if( !defined $object )
	{
		return 404;
	}

	return serve_dataobj( $repository, $object, $object, @path );
}

######################################################################
=pod

=item $rc = EPrints::Apache::REST::serve_dataobj( $repository, $object, $rights_object, @path )

Serve HTML, XML or text version of data object from C<GET> or C<PUT> 
request. Pass onto L</serve_field> or otherwise return an appropriate 
HTTP error code.

=cut
######################################################################

sub serve_dataobj
{
	my( $repository, $object, $rights_object, @path ) = @_;

	return DONE unless allow_priv( $rights_object->dataset->confid."/rest/get", $repository, $rights_object );

	my $file = shift @path;
	
	if( scalar @path == 0 )
	{
		# /
		if( $file eq "" )
		{
			return unless allowed_methods( $repository, "GET" );
			my $c = "<ul>\n";
			foreach my $field ( $object->dataset->get_fields )
			{
				next if( $field->get_property( "sub_name" ) );
				next if( $field->isa( "EPrints::MetaField::Secret" ) );
				my $name = $field->get_name;
				$c.="<li><a href='$name.xml'>$name.xml</a></li>";
				if( $field->get_property( "multiple" )
		 		 || $field->is_type( "compound","subobject","name" ) )
				{
					$c.="<li><a href='$name/'>$name/</a></li>\n";
				}
				else
				{
					$c.="<li><a href='$name.txt'>$name.txt</a></li>\n";
				}
			}
			$c.= "</ul>\n";
			return send_html( $repository, $c );
		}

		my( $field_name, $format) = split( /\./, $file, 2 );
		my $field = $object->dataset->get_field( $field_name );	
		return 404 if( !defined $format );
		return 404 if( !defined $field );
		return 404 if( $field->get_property( "sub_name" ));
		return 403 if( $field->isa( "EPrints::MetaField::Secret" ) );

		if( $field->get_property( "multiple" )
 		 || $field->is_type( "compound","subobject","name" ) )
		{
			if( $file eq $field_name ) # ie no . in it
			{
				return redir_add_slash( $repository );
			}
		}
		else
		{
			if( $format eq "txt" )
			{
				# /title.txt
				return unless allowed_methods( $repository, "GET","PUT" );
				my $method = $ENV{REQUEST_METHOD};
				if( $method eq "GET" )
				{
					return get_field_txt( $repository, $object, $rights_object, $field );
				}
				if( $method eq "PUT" )
				{
					return put_field_txt( $repository, $object, $rights_object, $field );
				}
				return 500; # never happens
			}	
		}

		if( $format eq "xml" )
		{
			# /title.xml
			return unless allowed_methods( $repository, "GET","PUT" );
			my $method = $ENV{REQUEST_METHOD};
			if( $method eq "GET" )
			{
				return get_field_xml( $repository, $object, $rights_object, $field );
			}
			if( $method eq "PUT" )
			{
				return put_field_xml( $repository, $object, $rights_object, $field );
			}
			return 500;
		}	

		return 404;
	}

	# /title/
	my $field = $object->dataset->get_field( $file );	
	return 404 if( !defined $field );

	my $v = $object->get_value( $file );

	return serve_field( $repository, $object, $rights_object, $field, $v, @path );
}

######################################################################
=pod

=item $rc = EPrints::Apache::REST::serve_field( $repository, $object, $rights_object, $field, $value, @path )

Serve HTML, XML or text version of data object from C<GET> requests.
Pass on field requests onto L</serve_field_single> or otherwise return 
an appropriate HTTP error code.

=cut
######################################################################

sub serve_field
{
	my( $repository, $object, $rights_object, $field, $value, @path ) = @_;

	if( !$field->get_property( "multiple" ) )
	{
		return serve_field_single( $repository, $object, $rights_object, $field, $value, @path );
	}

	my $file = shift @path;

	if( scalar @path == 0 )
	{
		# /
		if( $file eq "" )
		{
			return unless allowed_methods( $repository, "GET" );
			my $c = "<ul>\n";
			$c.= "<li><a href='size.txt'>size.txt</a></li>\n";
			for( my $i=0; $i<scalar @{$value}; ++$i )
			{
				my $n = $i + 1;
 				if( $field->is_type( "subobject" ) )
				{
					$c.="<li><a href='$n/'>$n/</a></li>\n";
					$c.="<li><a href='$n.xml'>$n.xml/</a></li>\n";
				}
 				elsif( $field->is_type( "compound","name" ) )
				{
					$c.="<li><a href='$n/'>$n/</a></li>\n";
				}
				else
				{
					$c.="<li><a href='$n.txt'>$n.txt</a></li>\n";
				}
			}
			$c.="</ul>\n";
			return send_html( $repository, $c );
		}

		if( $file eq "size.txt" )
		{
			return unless allowed_methods( $repository, "GET" );
			return send_plaintext( $repository, scalar( @{$value} ) );
		}
	
		my( $n, $format ) = split( /\./, $file, 2 );

		if( $format eq "xml" && $field->is_type( "subobject" ) )
		{
			return unless allowed_methods( $repository, "GET" );
			return send_xml( $repository, $object->export( "XML" ) );
		}

		if( !EPrints::Utils::is_set( $value->[$n-1] ) )
		{
			return 404;
		}

		if( $field->is_type( "compound","subobject","name" ) )
		{
			if( $file eq $n ) # ie no . in it
			{
				return redir_add_slash( $repository );
			}
		}
		else
		{
			if( $format eq "txt" )
			{
				# /3.txt
				return unless allowed_methods( $repository, "GET" );
				return send_plaintext( $repository, $value->[$n-1] );
			}
		}
		return 404;
	}

	if( $file !~ m/^\d+$/ )
	{
		return 404;
	}	

	my $i = $file-1;
	if( !EPrints::Utils::is_set( $value->[$i] ) )
	{
		return 404;
	}

	# /3/
	return serve_field_single( $repository, $object, $rights_object, $field, $value->[$i], @path );
}

######################################################################
=pod

=item $rc = EPrints::Apache::REST::serve_field_single( $repository, $object, $rights_object, $field, $value, @path )

Serve single field representation by passing onto L</serve_subobject>,
L</serve_compound> or C</serve_name>
base on type of field.

=cut
######################################################################

sub serve_field_single
{
	my( $repository, $object, $rights_object, $field, $value, @path ) = @_;

	if( $field->is_type( "subobject" ) )
	{
		return serve_subobject( $repository, $object, $rights_object, $field, $value, @path );
	}
	if( $field->is_type( "compound" ) )
	{
		return serve_compound( $repository, $object, $rights_object, $field, $value, @path );
	}
	if( $field->is_type( "name" ) )
	{
		return serve_name( $repository, $object, $rights_object, $field, $value, @path );
	}
	
	$repository->log( "REST: Unknown field type in serve_field_single()" );
	return 500;
}

######################################################################
=pod

=item $rc = EPrints::Apache::REST::serve_suboject( $repository, $object, $rights_object, $field, $value, @path )

Serves sub-object by passing onto L</serve_dataobj>.

=cut
######################################################################

sub serve_subobject
{
	my( $repository, $object, $rights_object, $field, $value, @path ) = @_;

	my $ds = $repository->dataset( $field->get_property('datasetid') );

	return serve_dataobj( $repository, $value, $rights_object, @path );
}

######################################################################
=pod

=item $rc = EPrints::Apache::REST::serve_compound( $repository, $object, $rights_object, $field, $value, @path )

Serves compound field by iterating over sub-field, calling 
L</serve_field_single> where appropriate.

=cut
######################################################################

sub serve_compound
{
	my( $repository, $object, $rights_object, $field, $value, @path ) = @_;

	my $file = shift @path;

	my $f = $field->get_property( "fields_cache" );
	my %fieldname_to_alias = $field->get_fieldname_to_alias;
	my %alias_to_fieldname = $field->get_alias_to_fieldname;

	if( scalar @path == 0 )
	{
		if( $file eq "")
		{
			# /
			return unless allowed_methods( $repository, "GET" );
			my $c = "<ul>\n";
			foreach my $sub_field ( @{$f} )
			{
				my $fieldname = $sub_field->get_name;
				my $alias = $fieldname_to_alias{$fieldname};
				if( $sub_field->is_type( "compound","subobject","name" ) )
				{
					$c.="<li><a href='$alias/'>$alias/</a></li>\n";
				}
				else
				{
					$c.="<li><a href='$alias.txt'>$alias.txt</a></li>\n";
				}
			
			}
			$c .= "</ul>\n";
			return send_html( $repository, $c );
		}

		my( $part, $format ) = split( /\./, $file, 2 );

		my $fieldname = $alias_to_fieldname{$part};
		return 404 if( !defined $fieldname );
		my $sub_field = $object->dataset->get_field( $fieldname );

		if( $part eq $file )
		{
			return redir_add_slash( $repository );
		}

		# /foo.txt
		if( !$sub_field->is_type( "compound","subobject","name" ) && $format eq "txt" )
		{
			return unless allowed_methods( $repository, "GET" );
			return send_plaintext( $repository, $value->{$part} );
		}

		return 404;
	}

	my $fieldname = $alias_to_fieldname{$file};
	if( !defined $fieldname )
	{
		return 404;
	}
	my $sub_field = $object->dataset->get_field( $fieldname );

	# /foo/
	if( $sub_field->is_type( "compound","subobject","name" ) )
	{
		return serve_field_single( $repository, $object, $rights_object, $sub_field, $value->{$file}, @path );
	}
	
	return 404;
}

######################################################################
=pod

=item $rc = EPrints::Apache::REST::serve_compound( $repository, $object, $rights_object, $field, $value, @path )

Serves name field.

=cut
######################################################################


sub serve_name
{
	my( $repository, $object, $rights_object, $field, $value, @path ) = @_;

	my $file = shift @path;

	if( scalar @path == 0 )
	{
		# /
		if( $file eq "" )
		{
			return unless allowed_methods( $repository, "GET" );
			my $c = <<END;
<ul>
<li><a href='honourific.txt'>honourific.txt</a></li>
<li><a href='given.txt'>given.txt</a></li>
<li><a href='family.txt'>family.txt</a></li>
<li><a href='lineage.txt'>lineage.txt</a></li>
</ul>
END
			return send_html( $repository, $c );
		}

		if( $file =~ m/^(honourific|given|family|lineage)\.txt$/ )
		{
			# /given.txt
			return unless allowed_methods( $repository, "GET" );
			return send_plaintext( $repository, $value->{$1} || "");
		}
	}

	return 404;
}

########
# END OF serve_


######################################################################
=pod

=item $rc = EPrints::Apache::REST::render_html( $html, $title )

Renders HTML for REST request.

=cut
######################################################################

sub render_html
{
	my( $html, $title ) = @_;

	if( defined $title )
	{	
		$title = "EPrints REST: $title";
	}
	else
	{	
		$title = "EPrints REST";
	}

	return <<END;
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <title>$title</title>
  <style type="text/css">
    body { font-family: sans-serif; }
  </style>
</head>
<body>
  <h1>$title</h1>
$html
</body>
</html>
END
}

######################################################################
=pod

=item $rc = EPrints::Apache::REST::send_html( $repository, $html, $title )

Sends HTML response for REST request.

=cut
######################################################################

sub send_html
{
	my( $repository, $html, $title ) = @_;
	
	binmode( *STDOUT, ":utf8" );
	$repository->send_http_header( "content_type"=>"text/html; charset=UTF-8" );

	print render_html( $html, $title );

	return DONE;
}

######################################################################
=pod

=item $rc = EPrints::Apache::REST::send_xml( $repository, $xmldata )

Sends XML response for REST request.

=cut
######################################################################

sub send_xml
{
	my( $repository, $xmldata ) = @_;

	binmode( *STDOUT, ":utf8" );
		
	$repository->send_http_header( "content_type"=>"text/xml; charset=UTF-8" );

	# the dataobj XML generator now includes the XML header. This isn't ideal, but
	# it's a quick way to ensure we only send one.
	if( substr( $xmldata,0,5 ) ne "<?xml" )
	{
		print "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n";
	}

	print $xmldata;

	return DONE;
}

######################################################################
=pod

=item $rc = EPrints::Apache::REST::send_plaintext( $repository, $content )

Sends plain text response for REST request.

=cut
######################################################################

sub send_plaintext
{
	my( $repository, $content ) = @_;

	binmode( *STDOUT, ":utf8" );
	$repository->send_http_header( "content_type"=>"text/plain; charset=UTF-8" );
	if( defined $content )
	{
		print $content;
	}

	return DONE;
}

######################################################################
=pod

=item $allowed = EPrints::Apache::REST::allowed_methods( $repository, @methods )

Checks if method for request is contained with the C<@methods> array 
of allowed methods.  Setting and sending HTTP response headers and
code as appropriate.

Returns boolean depending on whether the request method is allowed.

=cut
######################################################################

sub allowed_methods
{
	my( $repository, @methods ) = @_;

	my $method = $ENV{REQUEST_METHOD};
	if( $method eq "OPTIONS" )
	{
		EPrints::Apache::AnApache::header_out( 
			$repository->get_request,
			"Content-Length" => 0 );
		EPrints::Apache::AnApache::header_out( 
			$repository->get_request,
			"Allow" => "OPTIONS,".join( ",", @methods ) );
		EPrints::Apache::AnApache::send_http_header( $repository->get_request );
		return 0;
	}

	foreach my $m ( @methods ) { return 1 if $m eq $method; }

	EPrints::Apache::AnApache::send_status_line( 
			$repository->get_request,
			501,
			"Method $method Not Implemented" );
	EPrints::Apache::AnApache::send_http_header( $repository->get_request );

	return 0;
}

######################################################################
=pod

=item $allowed = EPrints::Apache::REST::allowed_methods( $priv $repository, $rights_object )

Checks is privilege C<$priv> is permitted for the current user and sets
HTTP response code as appropriate.

Returns boolean depending on whether current user has permitted 
privilege.

=cut
######################################################################

sub allow_priv
{
	my( $priv, $repository, $rights_object ) = @_;

	if( $priv =~ m/^eprint\// )
	{
		my $status = $rights_object->get_value( "eprint_status" );
		$priv =~ s/^eprint\//eprint\/$status\//;	
	}

	return 1 if( $repository->allow_anybody( $priv ) );

	my $r = $repository->get_request;
	$r->auth_type( "Basic" );
	$r->auth_name( "EPrintsREST" );
	my ($status, $password) = $r->get_basic_auth_pw;
	my $username = $r->user;

	my $real_username = $repository->valid_login( $username, $password );
	if( !$real_username )
	{
		$r->note_basic_auth_failure;
		EPrints::Apache::AnApache::send_status_line( $r, 401, "Auth Required" );
		send_html( $repository, "<p>Auth Required</p>", "Auth Required" );
		return 0;
	}

	my $user = $repository->user_by_username( $real_username );
	if( !defined $user )
	{
		EPrints::Apache::AnApache::send_status_line( $r, 403, "Forbidden" );
		send_html( $repository, "<p>Forbidden</p>", "No such user" );
		return 0;
	}

	if( !$user->allow( $priv, $rights_object ) )
	{
		EPrints::Apache::AnApache::send_status_line( $r, 403, "Forbidden" );
		send_html( $repository, "<p>Forbidden</p>", "Forbidden" );
		return 0;
	}

	return 1;
}

######################################################################
=pod

=item $rc = EPrints::Apache::REST::get_dataobj_xml( $repository, $object, $rights_object )

Returns XML for REST request to C<GET> a data object.

=cut
######################################################################

sub get_dataobj_xml
{
	my( $repository, $object, $rights_object ) = @_;

	return DONE unless allow_priv( $rights_object->dataset->confid."/rest/get", $repository, $rights_object );

	return send_xml( $repository, $object->export( "XML" ) );
}

######################################################################
=pod

=item $rc = EPrints::Apache::REST::put_dataobj_xml( $repository, $object, $rights_object )

Returns XML for REST request to (non-implemented) C<PUT> a data
object.

=cut
######################################################################

sub put_dataobj_xml
{
	my( $repository, $object, $rights_object ) = @_;

	return DONE unless allow_priv( $rights_object->dataset->confid."/rest/put", $repository, $rights_object );

	my $put = $repository->xml->create_element( "put", result=>"not-implemented" );
	return send_xml( $repository, EPrints::XML::to_string( $put ) );
}

######################################################################
=pod

=item $rc = EPrints::Apache::REST::get_field_text( $repository, $object, $rights_object, $field )

Returns text for REST request to C<GET> a field.

=cut
######################################################################

sub get_field_txt
{
	my( $repository, $object, $rights_object, $field ) = @_;

	return DONE unless allow_priv( $rights_object->dataset->confid."/rest/get", $repository, $rights_object );

	my $v = $object->get_value( $field->get_name );
	$v = "" if !defined $v;
	return send_plaintext( $repository, $v );
}

######################################################################
=pod

=item $rc = EPrints::Apache::REST::get_field_xml( $repository, $object, $rights_object, $field )

Returns XML for REST request to C<GET> a field.

=cut
######################################################################

sub get_field_xml
{
	my( $repository, $object, $rights_object, $field ) = @_;

	return DONE unless allow_priv( $rights_object->dataset->confid."/rest/get", $repository, $rights_object );

	my $v = $object->get_value( $field->get_name );
	my $xml_dom = $field->to_xml( $v, show_empty=>1 );
	my $xml_str = EPrints::XML::to_string( $xml_dom );
	return send_xml( $repository, $xml_str."\n" );
}

######################################################################
=pod

=item $rc = EPrints::Apache::REST::put_field_xml( $repository, $object, $rights_object, $field )

Returns XML for REST request to C<PUT> a field.

=cut
######################################################################

sub put_field_xml
{
	my( $repository, $object, $rights_object, $field ) = @_;

	if( $field->get_name eq $object->dataset->get_key_field->get_name || $field->get_name eq "rev_number" )
	{
		return 403;
	}
	return DONE unless allow_priv( $rights_object->dataset->confid."/rest/put", $repository, $rights_object );

	my $data = join( "", <STDIN> );
	if( $data eq "" )
	{
		my $put = $repository->xml->create_element( "put", result=>"no-data" );
		$put->appendChild( $repository->xml->create_text_node( "No data" ) );
		return send_xml( $repository, EPrints::XML::to_string( $put ) );
	}

	my $doc;
	eval { $doc = $repository->xml->parse_string( $data ); };
	if( $@ )
	{
		my $put = $repository->xml->create_element( "put", result=>"parse-error" );
		$put->appendChild( $repository->xml->create_text_node( $@ ) );
		return send_xml( $repository, EPrints::XML::to_string( $put ) );
	}
	
	my $docel = $doc->getDocumentElement;
	my $fieldname = $docel->nodeName();
	
	if( $fieldname ne $field->name ) 
	{
		my $put = $repository->xml->create_element( "put", result=>"wrong-field" );
		$put->appendChild( $repository->xml->create_text_node( "XML describes wrong field ($fieldname)" ) );
		return send_xml( $repository, EPrints::XML::to_string( $put ) );
	}

	my $value = $field->xml_to_epdata( $repository, $docel );
	$object->set_value( $field->name, $value );
	$object->commit;
	my $put = $repository->xml->create_element( "put", result=>"ok" );
	return send_xml( $repository, EPrints::XML::to_string( $put ) );
}

######################################################################
=pod

=item $rc = EPrints::Apache::REST::put_field_txt( $repository, $object, $rights_object, $field )

Returns text for REST request to C<PUT> a field.

=cut
######################################################################

sub put_field_txt
{
	my( $repository, $object, $rights_object, $field ) = @_;

	if( $field->get_name eq $object->dataset->get_key_field->get_name || $field->get_name eq "rev_number" )
	{
		return 403;
	}
	return DONE unless allow_priv( $rights_object->dataset->confid."/rest/put", $repository, $rights_object );

	my $data = join( "", <STDIN> );
	$object->set_value( $field->get_name, $data );
	$object->commit;

	return send_plaintext( $repository, "OK" );
}

# end of GET and PUT methods

1;

######################################################################
=pod

=back

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

