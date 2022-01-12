######################################################################
#
# EPrints::Apache::Rewrite
#
######################################################################
#
#
######################################################################

=pod

=for Pod2Wiki

=head1 NAME

B<EPrints::Apache::Rewrite> - rewrite cosmetic URL's to internally useful ones.

=head1 DESCRIPTION

This rewrites the URL apache receives based on certain things, such
as the current language.

Expands 
/archive/00000123/*
to 
/archive/00/00/01/23/*

and so forth.

This should only ever be called from within the mod_perl system.

This also causes some pages to be regenerated on demand, if they are stale.

=head1 METHODS

=cut

package EPrints::Apache::Rewrite;

use EPrints::Apache::AnApache; # exports apache constants

use Data::Dumper;

use strict;

######################################################################
=pod

=over 4

=item $rc = EPrints::Apache::Rewrite::handler( $r )

Handler for managing EPrints rewrite requests.

=cut
######################################################################
  
sub handler 
{
	my( $r ) = @_;

	my $repoid = $r->dir_config( "EPrints_ArchiveID" );
	return DECLINED if !$repoid;


	my $conf = $EPrints::SystemSettings::conf;
	if ($conf->{perl_module_isolation})
	{
		EPrints->post_config_handler_module_isolation($repoid);
	}

	if( defined $EPrints::HANDLE )
	{
		$EPrints::HANDLE->init_from_request( $r );
	}
	else
	{
		EPrints->abort( __PACKAGE__."::handler was called before EPrints was initialised (you may need to re-run generate_apacheconf)" );
	}

	my $repository = $EPrints::HANDLE->current_repository();
	if( !defined $repository )
	{
		EPrints->abort( "'$repoid' is not a valid repository identifier:\nPerlSetVar EPrints_ArchiveID $repoid" );
	}

	my $esec = $r->dir_config( "EPrints_Secure" );
	my $secure = (defined $esec && $esec eq "yes" );
	my $urlpath = $repository->get_conf( "rel_path" );
	my $cgipath = $repository->get_conf( "http_cgiroot" );

	my $uri = $r->uri;
	{
		$uri = eval { Encode::decode_utf8( $uri ) };
		$uri = Encode::decode( "iso-8859-1", $uri ) if $@; # utf-8 failed
	}

	# Not an EPrints path (only applies if we're in a non-standard path)
	if( $uri !~ /^(?:$urlpath)|(?:$cgipath)/ )
	{
		return DECLINED;
	}

	# Non-EPrints paths within our tree
	my $exceptions = $repository->config( 'rewrite_exceptions' );
	$exceptions = [] if !defined $exceptions;
	foreach my $exppath ( @$exceptions )
	{
		next if $exppath eq '/cgi/'; # legacy
		next if $exppath eq '/archive/'; # legacy
		return DECLINED if( $uri =~ m/^$exppath/ );
	}

	# database needs updating
	if( $r->is_initial_req && !$repository->get_database->is_latest_version )
	{
		my $msg = "Database schema is out of date: ./bin/epadmin upgrade ".$repository->get_id;
		$repository->log( $msg );
		EPrints::Apache::AnApache::send_status_line( $r, 500, "EPrints Database schema is out of date" );
		return 500;
	}

	# 404 handler
	$r->custom_response( Apache2::Const::NOT_FOUND, $repository->current_url( path => "cgi", "handle_404" ) );

	my $args = $r->args;
	$args = "" if !defined $args;
	$args = "?$args" if length($args);

	my $lang = EPrints::Session::get_session_language( $repository, $r );

	my $rc = undef;
	$repository->run_trigger( EPrints::Const::EP_TRIGGER_URL_REWRITE,
		request => $r,
		   lang => $lang,    # en
		   args => $args,    # "" or "?foo=bar"
		urlpath => $urlpath, # "" or "/subdir"
		cgipath => $cgipath, # /cgi or /subdir/cgi
		    uri => $uri,     # /foo/bar
		 secure => $secure,  # boolean
            return_code => \$rc,     # set to trigger a return
	);
	# if the trigger has set an return code
	return $rc if defined $rc;

	# /archive/ redirect
	if( $uri =~ m! ^$urlpath/archive/+(.*) !x )
	{
		return redir( $r, "$urlpath/$1$args" );
	}

	# don't respond to anything containing '/.'
	if( $uri =~ /\/\./ )
	{
		return DECLINED;
	}

	# /perl/ redirect
	my $perlpath = $cgipath;
	$perlpath =~ s! /cgi\b ! /perl !x;
	if( $uri =~ s! ^$perlpath !!x )
	{
		return redir( $r, "$cgipath$uri$args" );
	}

	# this could be built from inspecting if and how get_login_url has been set
	my $login_url = $repository->get_conf( "login_required_url" );
	my $user = $repository->current_user(); # may well be null

	# CGI
	if( $uri =~ s! ^$cgipath !!x )
	{
		# Allow CGI pages to have their access restricted to specific users
		# If login_required_for_cgi is enabled and uri is not in the exceptions, and if user is not logged in, redir to login page
		{
			my $v = $repository->get_conf( "login_required_for_cgi", "enable" );

			# print STDERR "** CGI ** no current user ($v) '$uri'\n" unless $user;
			# print STDERR "** CGI ** current user is " . $user->get_value("username") . "\n" if $user;

			if( !$user && $v && $v eq "1" )
			{
				my $exceptions = $repository->get_conf( "login_required_for_cgi", "exceptions" );
				my $exception_found = 0;
				if( $exceptions )
				{
					foreach my $e ( @$exceptions )
					{
						$exception_found = 1 if $uri =~ m|^/$e|;
					}
				}

				if( $exception_found == 0)
				{
					my $redir_url = "${login_url}?target=${cgipath}${uri}";
					return redir( $r, $redir_url );
				}
			}
		}

		# redirect secure stuff
		if( $repository->config( "securehost" ) && !$secure && $uri =~ s! ^/(
			(?:users/)|
			(?:change_user)|
			(?:confirm)|
			(?:register)|
			(?:reset_password)|
			(?:set_password)
			) !!x )
		{
			my $https_redirect = $repository->current_url(
				scheme => "https", 
				host => 1,
				path => "cgi",
				"$1$uri" ) . $args;
			return redir( $r, $https_redirect );
		}

		if( $repository->config( "use_mimetex" ) && $uri eq "mimetex.cgi" )
		{
			$r->handler('cgi-script');
			$r->filename( $repository->config( "executables", "mimetex" ) );
			return OK;
		}

		$r->filename( EPrints::Config::get( "cgi_path" ).$uri );

		# !!!Warning!!!
		# If path_info is defined before the Response stage Apache will
		# attempt to find the file identified by path_info using an internal
		# request (presumably to get the content-type). We don't want that to
		# happen so we delay setting path_info until just before the response
		# is generated.
		my $path_info;
		# strip the leading '/'
		my( undef, @parts ) = split m! /+ !x, $uri;

        ##cgi path loaded earlier takes priority.

        my $flavour = $repository->get_conf( "flavour" );

        my @lib_order = reverse(@{  $repository->config('flavours')->{$flavour}   });


        my @paths = $repository->config( "cgi_path" ); ##archive cgi path
        foreach (@lib_order)
        {
            push @paths, $repository->config( "base_path" ) . "/$_/cgi";
        }
        push @paths, EPrints::Config::get( "cgi_path" ); ##system cgi path

		PATH: foreach my $path (@paths)
		{
			for(my $i = $#parts; $i >= 0; --$i)
			{
				my $filename = join('/', $path, @parts[0..$i]);
				if( -f $filename )
				{
					$r->filename( $filename );
					$path_info = join('/', @parts[$i+1..$#parts]);
					$path_info = '/' . $path_info if length($path_info);
					last PATH;
				}
			}
		}

		if( $uri =~ m! ^/users\b !x )
		{
			$r->push_handlers(PerlAccessHandler => [
				\&EPrints::Apache::Auth::authen,
				\&EPrints::Apache::Auth::authz
				] );
		}

		$r->handler('perl-script');

		$r->set_handlers(PerlResponseHandler => [
			# set path_info for the CGI script
			sub { $_[0]->path_info( $path_info ); DECLINED },
			'ModPerl::Registry'
			]);

		return OK;
	}

	# SWORD-APP
	if( $uri =~ s! ^$urlpath/sword-app/servicedocument$ !!x )
	{
		$r->handler( 'perl-script' );

		$r->set_handlers( PerlMapToStorageHandler => sub { OK } );

		$r->push_handlers(PerlAccessHandler => [
			\&EPrints::Apache::Auth::authen,
			\&EPrints::Apache::Auth::authz
			] );

		my $crud = EPrints::Apache::CRUD->new(
				repository => $repository,
				request => $r,
				dataset => $repository->dataset( "eprint" ),
				scope => EPrints::Apache::CRUD::CRUD_SCOPE_SERVICEDOCUMENT(),
			);
		return $r->status if !defined $crud;

		$r->set_handlers( PerlResponseHandler => [
				sub { $crud->servicedocument }
			] );

		return OK;
	}

	# robots.txt (nb. only works if site is in root / of domain.)
	if( $uri =~ m! ^$urlpath/robots\.txt$ !x )
	{
		$r->handler( 'perl-script' );

	 	$r->set_handlers(PerlResponseHandler => \&EPrints::Apache::RobotsTxt::handler );

		return OK;
	}

	# sitemap.xml (nb. only works if site is in root / of domain.)
	if( $uri =~ m! ^$urlpath/sitemap(?:-sc)?\.xml$ !x )
	{
		$r->handler( 'perl-script' );

	 	$r->set_handlers(PerlResponseHandler => \&EPrints::Apache::SiteMap::handler );

		return OK;
	}


	# REST
	if( $uri =~ m! ^$urlpath/rest\b !x )
	{
		$r->handler( 'perl-script' );

		$r->set_handlers( PerlMapToStorageHandler => sub { OK } );

	 	$r->set_handlers(PerlResponseHandler => \&EPrints::Apache::REST::handler );
		return OK;
	}

	# URI redirection
	if( $uri =~ m! ^$urlpath/id/(repository|dump)$ !x )
	{
		my $file = $1;
		my $accept = EPrints::Apache::AnApache::header_in( $r, "Accept" );
		$accept = "application/rdf+xml" unless defined $accept;
		my $can_accept = "list/triple";

		my $plugin = content_negotiate_best_plugin( 
			$repository, 
			accept_header => $accept,
			consider_summary_page => 0,
			plugins => [$repository->get_plugins(
				type => "Export",
				is_visible => "all",
				can_accept => $can_accept )]
		);
	
		if( !defined $plugin )  { return NOT_FOUND; }

		my $url = $repository->config( "perl_url" )."/export/$file/".
			$plugin->get_subtype."/".$repository->get_id.$plugin->param("suffix");

		return redir_see_other( $r, $url );
	}

	# Custom Handlers
	if ( defined $repository->config( "custom_handlers" ) && keys %{$repository->config( "custom_handlers" )} )
	{
		while ( my ($ch, $custom_handler) = each ( %{ $repository->config( "custom_handlers" ) } ) )
		{
			my $ch_regex = $custom_handler->{regex};
			$ch_regex =~ s/URLPATH/$urlpath/;
			if ( $uri =~ m! $ch_regex !x )
			{
				return $custom_handler->{function}->( $r );
			}
		}
	}

	if( $uri =~ m! ^$urlpath/id/([^\/]+)/(ext-.*)$ !x )
	{
		my $exttype = $1;
		my $id = $2;
		my $accept = EPrints::Apache::AnApache::header_in( $r, "Accept" );
		$accept = "application/rdf+xml" unless defined $accept;

		my $plugin = content_negotiate_best_plugin( 
			$repository, 
			accept_header => $accept,
			consider_summary_page => 0,
			plugins => [$repository->get_plugins(
				type => "Export",
				is_visible => "all",
				can_accept => "list/triple" )]
		);

		if( !defined $plugin )  { return NOT_FOUND; }

		my $fn = $id;
		$fn=~s/\//_/g;
		my $url = $repository->config( "perl_url" )."/export/$exttype/".
			$id."/".$plugin->get_subtype."/$fn".$plugin->param("suffix");

		return redir_see_other( $r, $url );
	}

	if ($repository->config("use_long_url_format"))
	{
    		# /XX/ redirect to /id/eprint/XX
    		if( $uri =~ s! ^$urlpath/(0*)([1-9][0-9]*)\b !!x )  # ignore leading 0s
    		{   
        		my $eprintid = $2;

        		if( $uri =~ s! ^/(0*)([1-9][0-9]*)\b !!x )  ##this would match /234/3/test.pdf or thumbnail: /234/1.hassmallThumbnailVersion/paper.pdf
        		{   
            			##redirect to /id/eprint/234/3/test.pdf
            			# It's a document....           
            			my $pos = $2; 
            			return redir( $r, "$urlpath/id/eprint/$eprintid/$pos$uri$args" );
        		}   
        		else
        		{   
            			my $url = "/id/eprint/".$eprintid;
            			return redir_see_other( $r, $url );
        		}   
        		return OK; 
    		}   

		#this will serve a document, static files(.include files) or abstract page. 
    		my $accept = EPrints::Apache::AnApache::header_in( $r, "Accept" );
    		my $method = eval {$r->method} || "";
    		if ( ( $method eq "GET" || $method eq "HEAD" ) ## request method must be GET or HEAD
        		&&  (index(lc($accept), "text/html") != -1 || index(lc($accept), "text/*") != -1 || index(lc($accept),"*/*") != -1 || $accept eq ""  )   ## header must be text/html, text/*, */* or undef
        		&&  ($uri !~ m!^${urlpath}/id/eprint/0*[1-9][0-9]*/contents$! )   ## uri must not be id/eprint/XX/contents
        		&&  ($uri =~ s! ^${urlpath}/id/eprint/(0*)([1-9][0-9]*)\b !!x )     ## uri must be id/eprint/XX
        	)
    		{
        		{
            			# It's an eprint...
            			my $eprintid = $2;

				# Allow abstract pages to have their access restricted to logged in users
	                        # If login_required_for_eprints is enabled and if user is not logged in, redir to login page
        	                {
                	                my $v = $repository->get_conf( "login_required_for_eprints", "enable" );
                                	if( !$user && defined $v && $v == 1 )
	                                {
        	                                my $redir_url = "${login_url}?target=${uri}id/eprint/${eprintid}";
                        	                return redir( $r, $redir_url );
                                	}
                        	}

			        my $eprint = $repository->dataset( "eprint" )->dataobj( $eprintid );
            			if( !defined $eprint )
            			{
                			return NOT_FOUND;
            			}

            			# redirect to canonical path - /XX/
            			if( !length($uri) )
            			{
                			return redir( $r, "$urlpath/id/eprint/$eprintid/$args" );
            			}
            			elsif( length($1) ) ##remove leading 0s
            			{
                			return redir( $r, "$urlpath/id/eprint/$eprintid$uri$args" );
            			}

			        if( $uri =~ s! ^/(0*)([1-9][0-9]*)\b !!x )  ##this would match /234/3/test.pdf or thumbnail: /234/1.hassmallThumbnailVersion/paper.pdf
            			{
                    			# It's a document....           

		                	my $pos = $2;
                    			my $doc = EPrints::DataObj::Document::doc_with_eprintid_and_pos( $repository, $eprintid, $pos );
                    			if( !defined $doc )
                    			{
                        			return NOT_FOUND;
                    			}
                    			if( !length($uri) )
                    			{
                        			return redir( $r, "$urlpath/$eprintid/$pos/$args" );
                    			}
                    			elsif( length($1) )
                    			{
                        			return redir( $r, "$urlpath/$eprintid/$pos$uri$args" );
                    			}
                    			$uri =~ s! ^([^/]*)/ !!x;
                    			my @relations = grep { length($_) } split /\./, $1;

                    			my $filename = $uri;

			                $r->pnotes( eprint => $eprint );
                    			$r->pnotes( document => $doc );
                    			$r->pnotes( dataobj => $doc );
                    			$r->pnotes( filename => $filename );

                    			$r->handler('perl-script');

                    			# no real file to map to
                    			$r->set_handlers(PerlMapToStorageHandler => sub { OK } );

                    			$r->push_handlers(PerlAccessHandler => [
                        			\&EPrints::Apache::Auth::authen_doc,
                        			\&EPrints::Apache::Auth::authz_doc
                        		] );
                    			$r->set_handlers(PerlResponseHandler => \&EPrints::Apache::Storage::handler );

                    			$r->pool->cleanup_register(\&EPrints::Apache::LogHandler::document, $r);

                    			my $rc = undef;
                    			$repository->run_trigger( EPrints::Const::EP_TRIGGER_DOC_URL_REWRITE,
                        			# same as for URL_REWRITE
                        			request => $r,
                           			lang => $lang,    # en
                           			args => $args,    # "" or "?foo=bar"
                        			urlpath => $urlpath, # "" or "/subdir"
                        			cgipath => $cgipath, # /cgi or /subdir/cgi
                            			uri => $uri,     # /foo/bar
                         			secure => $secure,  # boolean
                        			return_code => \$rc,     # set to trigger a return
                        			# extra bits
                         			eprint => $eprint,
                           			document => $doc,
                           			filename => $filename,
                          			relations => \@relations,
                    			);

                    			# if the trigger has set an return code
                    			return $rc if defined $rc;

                    			# This way of getting a status from a trigger turns out to cause 
                    			# problems and is included as a legacy feature only. Don't use it, 
                    			# set ${$opts->{return_code}} = 404; or whatever, instead.
                    			return $r->status if $r->status != 200;
		    
		    			# Disable JavaScript if accessing whilst logged in to avoid malicious HTML files doing nasty things as the user.
		    			$r->headers_out->{'Content-Security-Policy'} = "script-src 'none';" if $user && !$repository->param( "allow_uploaded_doc_js" );
                		}
                		# OK, It's the EPrints abstract page (or something whacky like /23/fish)
                		# ## can't let CRUD to use accept header todo content nego because we have files like .title, .page etc, so just redirect  /8 to /id/eprint/8 
                		# this would match [/23/, /23/index.html; /23/any.file]
                		else
                		{
                    			my $path = "/archive/" . $eprint->store_path();
                    			EPrints::Update::Abstract::update( $repository, $lang, $eprint->id, $path );
                    			if( $uri =~ m! /$ !x )
                    			{
                        			$uri .= "index.html";
                    			}
                    			$r->filename( $eprint->_htmlpath( $lang ) . $uri );
                    			if( $uri =~ /\.html$/ )
                    			{
                        			$r->pnotes( eprint => $eprint );

                        			$r->handler('perl-script');
                        			$r->set_handlers(PerlResponseHandler => [ 'EPrints::Apache::Template' ] );

                        			# log abstract hits
                        			$r->pool->cleanup_register(\&EPrints::Apache::LogHandler::eprint, $r);
                    			}
                		}
            			return OK; ## /id/eprint/XX
        		}
		}
	}##if use_long_url_format

	if( $uri =~ s! ^$urlpath/id/(?:
			contents | ([^/]+)(?:/([^/]+)(?:/([^/]+))?)?
		)$ !!x )
	{
		my( $datasetid, $dataobjid, $fieldid ) = ($1, $2, $3);

		my $crud = EPrints::Apache::CRUD->new(
				repository => $repository,
				request => $r,
				datasetid => $datasetid,
				dataobjid => $dataobjid,
				fieldid => $fieldid,
			);
		return $r->status if !defined $crud;

		$r->handler( 'perl-script' );

		$r->set_handlers( PerlMapToStorageHandler => sub { OK } );

		$r->push_handlers(PerlAccessHandler => [
				sub { $crud->authen },
				sub { $crud->authz },
			] );

		$r->set_handlers( PerlResponseHandler => [
				sub { $crud->handler },
			] );

		return OK;
	}

if(not $repository->config("use_long_url_format"))
{
	# /XX/ eprints
	if( $uri =~ s! ^$urlpath/(0*)([1-9][0-9]*)\b !!x )  # ignore leading 0s
	{
		# It's an eprint...
		my $eprintid = $2;

		# Allow abstract pages to have their access restricted to logged in users
		# If login_required_for_eprints is enabled and if user is not logged in, redir to login page
		{
			my $v = $repository->get_conf( "login_required_for_eprints", "enable" );

			# print STDERR "** EPRINT ** no current user, uri is '$uri' args are '$args' eprintid is '$eprintid' ($v)\n" unless $user;
			# print STDERR "** EPRINT ** current user is " . $user->get_value("username") . "\n" if $user;

			if( !$user && defined $v && $v == 1 )
			{
				my $redir_url = "${login_url}?target=${uri}${eprintid}"; 
				return redir( $r, $redir_url );
			}
		}

		my $eprint = $repository->dataset( "eprint" )->dataobj( $eprintid );
		if( !defined $eprint )
		{
			return NOT_FOUND;
		}

		# Only allow specific users to access abstract pages.
		{
			my $v = $repository->get_conf( "login_required_for_eprints", "enable" );
			if( defined $v && $v == 1 )
			{
				# if we are here then access to abstracts etc are restricted, and we are logged in as a user
				my $fn = $repository->get_conf( "eprints_access_restrictions_callback" );
				if( defined $fn )
				{
					my $rv = &{$fn}( $eprint, $user );
					return NOT_FOUND if $rv == 0; # perhaps 403 rather than 404
				}

			}
		}

		# redirect to canonical path - /XX/
		if( !length($uri) )
		{
			return redir( $r, "$urlpath/$eprintid/$args" );
		}
		elsif( length($1) )
		{
			return redir( $r, "$urlpath/$eprintid$uri$args" );
		}

		if( $uri =~ s! ^/(0*)([1-9][0-9]*)\b !!x )
		{
			# It's a document....			

			my $pos = $2;
			my $doc = EPrints::DataObj::Document::doc_with_eprintid_and_pos( $repository, $eprintid, $pos );
			if( !defined $doc )
			{
				return NOT_FOUND;
			}

			if( !length($uri) )
			{
				return redir( $r, "$urlpath/$eprintid/$pos/$args" );
			}
			elsif( length($1) )
			{
				return redir( $r, "$urlpath/$eprintid/$pos$uri$args" );
			}

			$uri =~ s! ^([^/]*)/ !!x;
			my @relations = grep { length($_) } split /\./, $1;

			my $filename = $uri;

			$r->pnotes( eprint => $eprint );
			$r->pnotes( document => $doc );
			$r->pnotes( dataobj => $doc );
			$r->pnotes( filename => $filename );

			$r->handler('perl-script');

			# no real file to map to
			$r->set_handlers(PerlMapToStorageHandler => sub { OK } );

			$r->push_handlers(PerlAccessHandler => [
				\&EPrints::Apache::Auth::authen_doc,
				\&EPrints::Apache::Auth::authz_doc
				] );

		 	$r->set_handlers(PerlResponseHandler => \&EPrints::Apache::Storage::handler );

			$r->pool->cleanup_register(\&EPrints::Apache::LogHandler::document, $r);

			my $rc = undef;
			$repository->run_trigger( EPrints::Const::EP_TRIGGER_DOC_URL_REWRITE,
				# same as for URL_REWRITE
				request => $r,
				   lang => $lang,    # en
				   args => $args,    # "" or "?foo=bar"
				urlpath => $urlpath, # "" or "/subdir"
				cgipath => $cgipath, # /cgi or /subdir/cgi
				    uri => $uri,     # /foo/bar
				 secure => $secure,  # boolean
			    return_code => \$rc,     # set to trigger a return
				# extra bits
				 eprint => $eprint,
			       document => $doc,
			       filename => $filename,
			      relations => \@relations,
			);

			# if the trigger has set an return code
			return $rc if defined $rc;
	
			# This way of getting a status from a trigger turns out to cause 
			# problems and is included as a legacy feature only. Don't use it, 
			# set ${$opts->{return_code}} = 404; or whatever, instead.
			return $r->status if $r->status != 200;

			# Disable JavaScript if accessing whilst logged in to avoid malicious HTML files doing nasty things as the user.
                    	$r->headers_out->{'Content-Security-Policy'} = "script-src 'none';" if $user && !$repository->param( "allow_uploaded_doc_js" );
		}
		# OK, It's the EPrints abstract page (or something whacky like /23/fish)
		else
		{
			my $path = "/archive/" . $eprint->store_path();
			EPrints::Update::Abstract::update( $repository, $lang, $eprint->id, $path );

			if( $uri =~ m! /$ !x )
			{
				$uri .= "index.html";
			}
			$r->filename( $eprint->_htmlpath( $lang ) . $uri );

			if( $uri =~ /\.html$/ )
			{
				$r->pnotes( eprint => $eprint );

				$r->handler('perl-script');
				$r->set_handlers(PerlResponseHandler => [ 'EPrints::Apache::Template' ] );

				# log abstract hits
				$r->pool->cleanup_register(\&EPrints::Apache::LogHandler::eprint, $r);
			}
		}

		return OK;
	}
} ##if long url format is not enabled

	# apache 2 does not automatically look for index.html so we have to do it ourselves
	my $localpath = $uri;
	$localpath =~ s! ^$urlpath !!x;
	if( $uri =~ m! /$ !x )
	{
		$localpath.="index.html";
	}
	$r->filename( $repository->get_conf( "htdocs_path" )."/".$lang.$localpath );

	if( $uri =~ m! ^$urlpath/view(/|$) !x )
	{
		# Allow view pages to have their access restricted to specific users
		# If login_required_for_views is enabled and if user is not logged in, redir to login page
		{
			my $v = $repository->get_conf( "login_required_for_views", "enable" );

			# print STDERR "** VIEW ** no current user ($v)\n" unless $user;
			# print STDERR "** VIEW ** current user is " . $user->get_value("username") . "\n" if $user;

			if( !$user && $v && $v eq "1" )
			{
				my $redir_url = "${login_url}?target=${urlpath}${uri}"; 
				return redir( $r, $redir_url );
			}
		}

		$uri =~ s! ^$urlpath !!x;
		# redirect /foo to /foo/ 
		if( $uri eq "/view" || $uri =~ m! ^/view/[^/]+$ !x )
		{
			return redir( $r, "$urlpath$uri/" );
		}

		local $repository->{preparing_static_page} = 1;
		my $filename = EPrints::Update::Views::update_view_file( $repository, $lang, $localpath );
		return NOT_FOUND if( !defined $filename );

		$r->filename( $filename );
	}
	elsif( $uri =~ m! ^$urlpath/javascript/(secure_)?auto(?:-\d+\.\d+\.\d+)?\.js$ !x )
	{
		my $f = $1 ?
			\&EPrints::Update::Static::update_secure_auto_js :
			\&EPrints::Update::Static::update_auto_js;
		my $filename = &$f(
			$repository,
			$repository->config( "htdocs_path" )."/$lang",
			[$repository->get_static_dirs( $lang )]
		);
		return NOT_FOUND if( !defined $filename );

		$r->filename( $filename );
	}
	elsif( $uri =~ m! ^$urlpath/style/auto(?:-\d+\.\d+\.\d+)?\.css$ !x )
	{
		my $filename = EPrints::Update::Static::update_auto_css(
			$repository,
			$repository->config( "htdocs_path" )."/$lang",
			[$repository->get_static_dirs( $lang )]
		);
		return NOT_FOUND if( !defined $filename );

		$r->filename( $filename );
	}
	else
	{
		# redirect /foo to /foo/ if foo is a static directory  #github:https://github.com/eprints/eprints/commit/834d56bc30679631349febe582195361301d8970
		if( $localpath !~ m/\/$/ )
		{
			foreach my $dir ( $repository->get_static_dirs( $lang ) )
			{
				if( -d $dir.$localpath )
				{
					return redir( $r, "$uri/" );
				}
			}
		}
		local $repository->{preparing_static_page} = 1;
		EPrints::Update::Static::update_static_file( $repository, $lang, $localpath );
	}

	# set all static files to +1 month expiry
	$r->headers_out->{Expires} = Apache2::Util::ht_time(
		$r->pool,
		time + 30 * 86400
	);
	# let Firefox cache secure, static files
	if( $repository->get_secure )
	{
		$r->headers_out->{'Cache-Control'} = 'public';
	}

	if( $r->filename =~ /\.html$/ )
	{
		my $ua = $r->headers_in->{'User-Agent'};
		if( $ua && $ua =~ /MSIE ([0-9]{1,}[\.0-9]{0,})/ && $1 >= 8.0 )
		{
			$r->headers_out->{'X-UA-Compatible'} = "IE=9";
		}
		$r->handler('perl-script');
		$r->set_handlers(PerlResponseHandler => [ 'EPrints::Apache::Template' ] );
	}

	return OK;
}

sub redir_permanent
{
	my( $r, $url ) = @_;

	EPrints::Apache::AnApache::send_status_line( $r, 301, "Moved Permanently" );
	EPrints::Apache::AnApache::header_out( $r, "Location", $url );
	EPrints::Apache::AnApache::send_http_header( $r );
	return DONE;
}

sub redir
{
	my( $r, $url ) = @_;

	EPrints::Apache::AnApache::send_status_line( $r, 302, "Found" );
	EPrints::Apache::AnApache::header_out( $r, "Location", $url );
	EPrints::Apache::AnApache::send_http_header( $r );
	return DONE;
} 

sub redir_see_other
{
	my( $r, $url ) = @_;

	EPrints::Apache::AnApache::send_status_line( $r, 303, "See Other" );
	EPrints::Apache::AnApache::header_out( $r, "Location", $url );
	EPrints::Apache::AnApache::send_http_header( $r );
	return DONE;
} 

sub content_negotiate_best_plugin
{
	my( $repository, %o ) = @_;

	EPrints::Utils::process_parameters( \%o, {
		accept_header => "*REQUIRED*",
		consider_summary_page => 1, 
		plugins => "*REQUIRED*",
	 } );

	my $pset = {};
	if( $o{consider_summary_page} )
	{
		$pset->{"text/html"} = { qs=>0.99, DEFAULT_SUMMARY_PAGE=>1 };
	}

	foreach my $plugin ( @{$o{plugins}} )
	{
		my( $type, %params ) = split( /\s*[;=]\s*/, $plugin->{mimetype} );
	
		next if( defined $pset->{$type} && $pset->{$type}->{qs} >= $plugin->{qs} );
		$pset->{$type} = $plugin;
	}
	my @pset_order = sort { $pset->{$b}->{qs} <=> $pset->{$a}->{qs} } keys %{$pset};

	my $accepts = { "*/*" => { q=>0.000001 }};
	CHOICE: foreach my $choice ( split( /\s*,\s*/, $o{accept_header} ) )
	{
		my( $mime, %params ) = split( /\s*[;=]\s*/, $choice );
		$params{q} = 1 unless defined $params{q};
		my $match = $pset->{$mime};
		$params{q} *= defined $match ? $match->{qs} : 0;
		$accepts->{$mime} = \%params;
	}
	my @acc_order = sort { $accepts->{$b}->{q} <=> $accepts->{$a}->{q} } keys %{$accepts};

	my $match;
	CHOICE: foreach my $choice ( @acc_order )
	{
		if( $pset->{$choice} ) 
		{
			$match = $pset->{$choice};
			last CHOICE;
		}

		if( $choice eq "*/*" )
		{
			$match = $pset->{$pset_order[0]};
			last CHOICE;
		}

		if( $choice =~ s/\*[^\/]+$// )
		{
			foreach my $type ( @pset_order )
			{
				if( $choice eq substr( $type, 0, length $type ) )
				{
					$match = $pset->{$type};
					last CHOICE;
				}
			}
		}
	}

	if( $match->{DEFAULT_SUMMARY_PAGE} )
	{
		return "DEFAULT_SUMMARY_PAGE";
	}

	return $match; 
}


1;

=back

=head1 COPYRIGHT

=for COPYRIGHT BEGIN

Copyright 2021 University of Southampton.
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

