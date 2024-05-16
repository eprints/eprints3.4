=for Pod2Wiki

=head1 NAME

EPrints - Institutional Repository software

=head1 SYNOPSIS

	use EPrints qw();

	# don't check current user (CLI only)
	use EPrints qw( no_check_user );

	$eprints = EPrints->new;

	# CLI
	$repo = $eprints->repository( "demoprints" );

	# CGI
	$repo = $eprints->current_repository;

	if( EPrints->VERSION() gt v3.2.0 )
	{
		...
	}

=head1 DESCRIPTION

See http://www.eprints.org/.

=head2 Available Symbols

You can pass options to the EPrints package that effect the EPrints initialisation e.g.

	use EPrints qw( no_check_user );

=over 4

=item no_check_user

Do not check the current user/group is the same as the user/group in SystemSettings.

=back

=begin InternalDoc

=head2 Debugging Slow Processes

This module installs a signal handler that will print a stack trace if given a USR2 signal (if your system supports this signal). To print a stack trace to the error log execute:

 $ kill -USR2 PID

Where PID is the id number of the stalled process.

A shell script will print the stack trace to the console.

=end InternalDoc

=head1 METHODS

=over 4

=cut

package EPrints;

my $conf;
		
use Cwd;

BEGIN
{
	# SystemSettings can be overridden by loading it before EPrints, which is
	# used by some unit tests
	if( !defined($EPrints::SystemSettings::conf) )
	{
		$EPrints::SystemSettings::conf = {};
		eval "use EPrints::SystemSettings;";
	}

	$conf = $EPrints::SystemSettings::conf;

	# set default global configuration values
	if( !defined $conf->{base_path} )
	{
		my $base_path = Cwd::realpath( $INC{'EPrints.pm'} );
		$base_path =~ s/.perl_lib.EPrints\.pm$//; # ignore / \
		$conf->{base_path} = $base_path;
	}


	unshift @INC, $conf->{base_path} . "/lib/plugins";
	unshift @INC, $conf->{base_path} . "/site_lib/plugins";

    # @INC looks like:[ site_lib/plugins ; lib/plugins; perl_lib ].  Searching of a module start from the head.
    # Flavour libs can NOT overwrite core modules (core modules are loaded in the list of "use" statements below)
    # To override core modules (hacking the core, not recommended), put them in the site_lib/plugins/.
    # NOTE: overridden core modules are loaded in all repositories on the same server.
    # 
    # Flavour/ingredient libs can ADD perl modules outside the EPrints/Plugin (e.g. plugins/EPrints/Xapian.pm), and adding and overriding perl modules inside the EPrints/Plugin 
    #    (e.g. plugins/EPrints/Plugin/Screen/myscreen.pm)
    # Archive level plugin folder can only make changes inside the EPrints/Plugin level (adding and overriding), and it has the highest priority.


#    print STDERR "[EPrints.pm::begin]:[ INC:",join("\n",@INC), "]\n";
}

use Data::Dumper;
use Scalar::Util;
use File::Temp;
use JSON qw();
eval { require Digest::SHA; 1 } || eval { require Compat::Digest::SHA; 1 };

use Carp;

use strict;

our $VERSION = v3.4.5;
$conf->{version} = "EPrints ".EPrints->human_version;
$conf->{versionid} = "eprints-".EPrints->human_version;

=item $version = EPrints->VERSION()

Returns the version of EPrints in 'v' format (this is the UNIVERSAL method).

=item EPrints->human_version()

Returns the EPrints version in a human-readable form.

=cut

sub human_version
{
	return EPrints->VERSION =~ /^v/ ?
		substr(EPrints->VERSION,1) :
		join('.', map { ord($_) } split(//, EPrints->VERSION));
}

=item EPrints->abort( $errmsg )

This subroutine is loaded before other modules so that it may be used to report errors when initialising modules.

When running under Mod_Perl this method is replaced.

=cut

sub abort
{
	my( $errmsg ) = pop @_; # last parameter

	use POSIX qw( strftime );
	my $timestamp = POSIX::strftime( '%Y-%m-%dT%H:%M:%SZ', gmtime(time()));

	print STDERR <<END;

------------------------------------------------------------------
----------- EPrints System Error $timestamp ------------
------------------------------------------------------------------
$errmsg
------------------------------------------------------------------
END
	$@="";
	Carp::cluck( "EPrints System Error inducing stack dump\n" );
	if( $EPrints::die_on_abort ) { die $errmsg; }
	exit( 1 );
}

sub deprecated
{
	my @c = caller(1);
	print STDERR "Called deprecated function $c[3] from $c[1] line $c[2]\n";
}

sub try
{
	my( $code ) = @_;

	my $r = eval { &$code };

	if( $@ ) { EPrints->abort( $@ ); }

	return $r;
}

=item EPrints->dump( $VAR1 [, $VAR2 ... ] )

Use L<Data::Dumper> to dump the passed variables to STDERR.

=cut

sub dump
{
	shift(@_) if $_[0] eq __PACKAGE__;

	warn Data::Dumper::Dumper( @_ );
}


=item EPrints->trace()

Short-cut to L<Carp::longmess> to show a (non-blocking) call-trace

=cut

sub trace
{
	print STDERR Carp::longmess();
}

=item EPrints->assert( CONDITION )

Evaluates a condition and shows a call trace if this condition is undef or false.

=cut

sub assert
{
	my $condition = pop @_;

        if( !defined $condition || !$condition )
        {
                my @caller = caller();

                my $assert_text_condition = undef;
                if( -e $caller[1] && open( CALLER, "$caller[1]" ) )
                {
                        my $line = $caller[2];
                        my $assert_text = undef;
                        while( <CALLER> )
                        {
                                last unless( defined $line );
                                next unless $. == $line;
                                $assert_text_condition = $_;
                                last;
                        }
                        close( CALLER );
                }

                my $actual_text = " <?unknown?> ";
                if( defined $assert_text_condition && $assert_text_condition =~ /EPrints\-\>assert\((.*)\)/  )
                {
                        $actual_text = $1;
                        $actual_text =~ s/^\s+//g;
                        $actual_text =~ s/\s+$//g;
                }

                print STDERR "\n>>>>>>>>>> '$actual_text' assertion failed <<<<<<<<<<\n";
                EPrints->trace();
        }

        return 1;
}
use EPrints::Plugin::Screen;

use EPrints::Const; # must be before any use of constants

use EPrints::Apache;
use EPrints::Apache::AnApache;
use EPrints::Apache::LogHandler;
use EPrints::Apache::Login;
use EPrints::Apache::Auth;
use EPrints::Apache::Rewrite;
# If someone really wants VLit they can enable it via Apache conf
# use EPrints::Apache::VLit;
use EPrints::Apache::Template;
use EPrints::Apache::Storage;
use EPrints::Apache::REST;
use EPrints::Apache::RobotsTxt;
use EPrints::Apache::SiteMap;
use EPrints::Apache::CRUD;

use EPrints::BackCompatibility;

use EPrints::Config;
use EPrints::System;
use EPrints::XML;
use EPrints::XSLT;
use EPrints::Time;

use EPrints::Box;
use EPrints::Database;
use EPrints::Storage;
use EPrints::Citation;
use EPrints::Citation::EPC;
use EPrints::Citation::XSL;
use EPrints::DataObj;
use EPrints::DataObj::SubObject;
use EPrints::DataObj::Access;
use EPrints::DataObj::Cachemap;
use EPrints::DataObj::CitationCache;
use EPrints::DataObj::Document;
use EPrints::DataObj::EPrint;
use EPrints::DataObj::File;
use EPrints::DataObj::History;
use EPrints::DataObj::Import;
use EPrints::DataObj::Import::XML;
use EPrints::DataObj::EventQueue;
use EPrints::DataObj::LoginTicket;
use EPrints::DataObj::Message;
use EPrints::DataObj::MetaField;
use EPrints::DataObj::Request;
use EPrints::DataObj::Subject;
use EPrints::DataObj::SavedSearch;
use EPrints::DataObj::SAX::Handler;
use EPrints::DataObj::Triple;
use EPrints::DataObj::UploadProgress;
use EPrints::DataObj::User;
use EPrints::DataObj::RichDataObj;
use EPrints::DataSet;
use EPrints::DOI;
use EPrints::Email;
use EPrints::Extras;
use EPrints::Index;
use EPrints::Index::Daemon;
use EPrints::Language;
use EPrints::Latex;
use EPrints::List;
use EPrints::MetaField;
use EPrints::NamedSet;
use EPrints::OpenArchives;
use EPrints::Page;
use EPrints::Page::DOM;
use EPrints::Paginate;
use EPrints::Paginate::Columns;
use EPrints::Plugin;
use EPrints::Plugin::Export;
use EPrints::Plugin::Import;
use EPrints::PluginFactory;
use EPrints::Probity;
use EPrints::RDFGraph;
use EPrints::Repository;
use EPrints::RepositoryConfig;
use EPrints::Search;
use EPrints::Search::Field;
use EPrints::Search::Condition;
use EPrints::CLIProcessor;
use EPrints::ScreenProcessor;
use EPrints::Script;
use EPrints::Script::Compiler;
use EPrints::Script::Compiled;
use EPrints::URL;
use EPrints::Paracite;
use EPrints::Update::Static;
use EPrints::Update::Views;
use EPrints::Update::Abstract;
use EPrints::Workflow;
use EPrints::Workflow::Stage;
use EPrints::XML::EPC;
use EPrints::XHTML;
use EPrints::Utils;
use EPrints::Signposting;

# SAX utilities
use EPrints::XML::SAX::Builder;
use EPrints::XML::SAX::Generator;
use EPrints::XML::SAX::PrettyPrint;
use EPrints::XML::SAX::Writer;

our $__loaded;
our $__cloned;

=pod

=item $ep = EPrints->new();

Construct a new EPrints system object.

=cut

sub new($%)
{
	my( $class, %opts ) = @_;

	# mod_perl
	return $EPrints::HANDLE if defined $EPrints::HANDLE;

	$opts{request} ||= undef;
	$opts{repository} ||= {};
	$opts{current_repository} ||= undef;

	return bless { opts=>\%opts }, $class;
}

=begin InternalDoc

=item $ep->init_from_request( $r )

Initialise the EPrints environment based on the request $r.

=end InternalDoc

=cut

sub init_from_request
{
	my( $self, $r ) = @_;

	$self->{request} = $r;

	# always check for cloned-ness
	if( $__cloned )
	{
		$__cloned = 0;
		foreach my $repo (values %{$EPrints::HANDLE->{repository}})
		{
			$repo->init_from_thread();
		}
	}

	if( $r->is_initial_req )
	{
		$r->pool->cleanup_register( \&cleanup, $self );

		# populate current_repository
		my $repoid = $r->dir_config( "EPrints_ArchiveID" );
		$self->{current_repository} = $self->{repository}->{$repoid};
	}

	# initialise the repository
	if( defined $self->{current_repository} )
	{
		$self->{current_repository}->init_from_request( $r );
	}
}

=begin InternalDoc

=item $ep->cleanup()

Cleanup the EPrints environment after the request is complete.

=end InternalDoc

=cut

sub cleanup
{
	my( $self ) = @_;

	undef $self->{request};
	undef $self->{current_repository};
}

sub CLONE
{
	my( $class ) = @_;

	$__cloned = 1;

	# we can't re-init here because Perl segfaults if we attempt to opendir()
	# during CLONE()
}






##When the perl_module_isolation is turned on, this is called from Rewrite.pm to initialise EPrints.
sub post_config_handler_module_isolation
{
	my( $class, $repoid ) = @_;
	# make carp verbose
	$Carp::Verbose = 1;

	if( Apache2::MPM->is_threaded )
	{
        print STDERR ( "Warning! Running EPrints under threads is experimental and liable to break" );

	}

	# check for configuration using methods removed from Apache2.4
 	my $check_security = !Apache2::Connection->can( 'remote_ip' );

	$EPrints::HANDLE = EPrints->new;
    
#    print STDERR "[EPrints.pm]: INC:",join("\n",@INC);



	$EPrints::HANDLE->load_repository($repoid);
	my @repos = values %{$EPrints::HANDLE->{repository}};

	# check the main apache configuration
	my $aconf = Apache2::Directive::conftree();
	my %aports = map { /\b([0-9]+)$/; $1 => 1 } $aconf->lookup( 'Listen' );
	my %named;
	my %ports;
	for($aconf->lookup( 'NameVirtualHost' ))
	{
		my( undef, $port ) = split /:/, $_;
		$named{$port} = 1;
	}

	# eg. "Apache/2.4.7 (Ubuntu)"
	my $apache_desc = Apache2::ServerUtil::get_server_description();
	my( $apache_version ) = ( $apache_desc =~ m!^Apache/(\d\.\d)! );

	foreach my $repo (@repos)
	{
		next if ($repo->get_id ne $repoid); ##skip if current repository isn't the one user is requesting.
		my $port = $repo->config( "port" );
		$ports{$port}++;
		if( !$aports{$port} )
		{
#			$s->warn( "EPrints Warning! '".$repo->get_id."' is configured for port $port but Apache has not been configured to listen on that port. To fix this add to your main Apache configuration file: Listen $port" );
			print STDERR ( "EPrints Warning! '".$repo->get_id."' is configured for port $port but Apache has not been configured to listen on that port. To fix this add to your main Apache configuration file: Listen $port" );
		}
		# NameVirtualHost not required since v2.3 - http://httpd.apache.org/docs/2.4/mod/core.html#namevirtualhost
		if( !$named{$port} && ( defined $apache_version && $apache_version < 2.3 ) )
		{
			my $hostname = $repo->config( "host" );
			$hostname ||= $repo->config( "securehost" );
			print STDERR ( "EPrints Warning! '".$repo->get_id."' is configured for port $port but Apache does not have NameVirtualHosts configured for that port. This may cause the wrong repository to respond to '$hostname:$port'. To fix this add to your main Apache configuration file: NameVirtualHost *:$port" );
		}
		if( $check_security && defined $repo->config( "can_request_view_document" ) )
		{
		 	local $Data::Dumper::Deparse=1;
			if( Dumper( $repo->config( "can_request_view_document" ) ) =~ /connection\S+remote_ip/i )
			{
				print STDERR "EPrints warning! '".$repo->get_id."' uses 'remote_ip' in the 'can_request_view_document' configuration, but this version of Apache does not have that method. This may lead to the security value for a document being ignored. Please check configuration.";
        		}
		}
	}

	{
		no warnings; # suppress the redef-warning
		eval '
sub abort
{
	my( $errmsg ) = (pop @_);

	use POSIX qw( strftime );
	my $timestamp POSIX::strftime( "%Y-%m-%dT%H:%M:%SZ", gmtime(time()));

	my $r = EPrints->request;
	$r->status( 500 );
	my $htmlerrmsg = $errmsg;
	$htmlerrmsg=~s/&/&amp;/g;
	$htmlerrmsg=~s/>/&gt;/g;
	$htmlerrmsg=~s/</&lt;/g;
	$htmlerrmsg=~s/\n/<br \/>/g;
	$htmlerrmsg = <<END;
<html>
<head>
<title>EPrints System Error</title>
</head>
<body>
<h1>EPrints System Error</h1>
<p><code>$htmlerrmsg</code></p>
</body>
</html>
END
	$r->custom_response( 500, $htmlerrmsg );

	print STDERR <<END;
------------------------------------------------------------------
----------- EPrints System Error $timestamp ------------
------------------------------------------------------------------
$errmsg
------------------------------------------------------------------
END
	print STDERR Carp::longmess();
	die __PACKAGE__."::abort()\n";
}';
	}
	return OK;
}









=begin InternalDoc

=item EPrints::post_config_handler(...)

Initialise the EPrints mod_perl environment.

=end InternalDoc

=cut

sub post_config_handler
{
	my( $conf_pool, $log_pool, $temp_pool, $s ) = @_;

	# make carp verbose
	$Carp::Verbose = 1;

	if( Apache2::MPM->is_threaded )
	{
		$s->log->notice( "Warning! Running EPrints under threads is experimental and liable to break" );
	}

	# check for configuration using methods removed from Apache2.4
	my $check_security = !Apache2::Connection->can( 'remote_ip' );

	$EPrints::HANDLE = __PACKAGE__->new;
	my @ids = $EPrints::HANDLE->load_repositories();
	my @repos = values %{$EPrints::HANDLE->{repository}};

	# check the main apache configuration
	my $aconf = Apache2::Directive::conftree();
	my %aports = map { /\b([0-9]+)$/; $1 => 1 } $aconf->lookup( 'Listen' );
	my %named;
	my %ports;
	for($aconf->lookup( 'NameVirtualHost' ))
	{
		my( undef, $port ) = split /:/, $_;
		$named{$port} = 1;
	}

	# eg. "Apache/2.4.7 (Ubuntu)"
	my $apache_desc = Apache2::ServerUtil::get_server_description();
	my( $apache_version ) = ( $apache_desc =~ m!^Apache/(\d\.\d)! );

	foreach my $repo (@repos)
	{
		 my $port = $repo->config( "port" );
		 $ports{$port}++;
		 if( !$aports{$port} )
		 {
			 $s->warn( "EPrints Warning! '".$repo->get_id."' is configured for port $port but Apache has not been configured to listen on that port. To fix this add to your main Apache configuration file: Listen $port" );
		 }
		 # NameVirtualHost not required since v2.3 - http://httpd.apache.org/docs/2.4/mod/core.html#namevirtualhost
		 if( !$named{$port} && ( defined $apache_version && $apache_version < 2.3 ) )
		 {
			 my $hostname = $repo->config( "host" );
			 $hostname ||= $repo->config( "securehost" );
			 $s->warn( "EPrints Warning! '".$repo->get_id."' is configured for port $port but Apache does not have NameVirtualHosts configured for that port. This may cause the wrong repository to respond to '$hostname:$port'. To fix this add to your main Apache configuration file: NameVirtualHost *:$port" );
		 }
		 if( $check_security && defined $repo->config( "can_request_view_document" ) )
		 {
		 	local $Data::Dumper::Deparse=1;
			if( Dumper( $repo->config( "can_request_view_document" ) ) =~ /connection\S+remote_ip/i )
			{
				$s->warn( "EPrints warning! '".$repo->get_id."' uses 'remote_ip' in the 'can_request_view_document' configuration, but this version of Apache does not have that method. This may lead to the security value for a document being ignored. Please check configuration.");
        		}
		 }
	}

	$s->log->notice( "EPrints archives loaded: ".join( ", ",  @ids ) );

	{
		no warnings; # suppress the redef-warning
		eval '
sub abort
{
	my( $errmsg ) = (pop @_);

	use POSIX qw( strftime );
	my $timestamp = POSIX::strftime( "%Y-%m-%dT%H:%M:%SZ", gmtime(time()));

	my $r = EPrints->request;
	$r->status( 500 );
	my $htmlerrmsg = $errmsg;
	$htmlerrmsg=~s/&/&amp;/g;
	$htmlerrmsg=~s/>/&gt;/g;
	$htmlerrmsg=~s/</&lt;/g;
	$htmlerrmsg=~s/\n/<br \/>/g;
	$htmlerrmsg = <<END;
<html>
<head>
<title>EPrints System Error</title>
</head>
<body>
<h1>EPrints System Error</h1>
<p><code>$htmlerrmsg</code></p>
</body>
</html>
END
	$r->custom_response( 500, $htmlerrmsg );

	print STDERR <<END;
------------------------------------------------------------------
----------- EPrints System Error $timestamp ------------
------------------------------------------------------------------
$errmsg
------------------------------------------------------------------
END
	print STDERR Carp::longmess();
	die __PACKAGE__."::abort()\n";
}';
	}

	return OK;
}

=pod

=item $repo = $ep->repository( $repository_id, [%options] );

Return the L<EPrints::Repository> with the given ID, or undef. Options are... optional.

Options noise=>1, etc.

=cut

sub repository($$%)
{
	my( $self, $repository_id, %options ) = @_;
	my $ok = 0;
	foreach my $an_id ( $self->repository_ids )
	{
		$ok = 1 if( $an_id eq $repository_id );
	}
	return undef if( !$ok );

	return EPrints::Repository->new( $repository_id, %options );
}	


=pod

=item $repo = $ep->current_repository();

Returns the current L<EPrints::Repository>. The current 
repository is determined by the apache request.

Returns undef if there is no current repository active.

=cut

sub current_repository
{
	my( $self ) = @_;

	return $self->{current_repository};
}

=begin InternalDoc

=item EPrints::import()

Takes following pragmas:

	no_check_user - don't verify effective UID is configured UID

=end InternalDoc

=cut

sub import
{
	my( $class, @args ) = @_;

	my %opts = map { $_ => 1 } @args;

	# mod_perl will probably be running as root for the main httpd.
	# The sub processes should run as the same user as the one specified
	# in $EPrints::SystemSettings
	# An exception to this is running as root (uid==0) in which case
	# we can become the required user.
	if( !$__loaded && !$opts{"no_check_user"} && !$ENV{MOD_PERL} && !$ENV{EPRINTS_NO_CHECK_USER} )
	{
		EPrints->system->test_uid();
	}

	$__loaded = 1;
}

=begin InternalDoc

=item @ids = $eprints->repository_ids

Returns a list of the active repository ids.

=end InternalDoc

=cut

sub repository_ids
{
	my( $self ) = @_;

	my @ids;

	return EPrints::Config::get_repository_ids();
}

## Perl module isolation. 
## Load a single repository
sub load_repository
{
	my( $self, $repoid ) = @_;

	my @ids;

	if (not defined $self->{repository}->{$repoid})
	{
		$self->{repository}->{$repoid} = $self->repository( $repoid, db_connect => 0 );
	}
#	else{
#		print STDERR ( "EPrints archives cache hit: ", $repoid,"\n" );
#	}

	return @ids;
}


=begin InternalDoc

=item $ep->load_repositories()

Loads and caches all repositories. These are used to make L</current_repository> fast.

=end InternalDoc

=cut

sub load_repositories
{
	my( $self ) = @_;

	my @ids;

	foreach my $id ( $self->repository_ids )
	{
		$self->{repository}->{$id} = $self->repository( $id, db_connect => 0 );
		push @ids, $id;
	}

	return @ids;
}

=begin InternalDoc

=item $r = $ep->request()

See $repo->request() in L<EPrints::Repository>.

Returns the current mod_perl request object (note: this might be a sub-request object).

Returns undef if there is no current request.

=end InternalDoc

=cut

sub request
{
	my( $self ) = @_;

	return $EPrints::HANDLE->{request};
}

=begin InternalDoc

=item $sys = $ep->system()

Returns the L<EPrints::System> object.

=end InternalDoc

=cut

sub system
{
	return $EPrints::SYSTEM;
}

sub sigusr2_cluck
{
	Carp::cluck( "caught SIGUSR2" );
	$SIG{'USR2'} = \&sigusr2_cluck;
}

# If the signal doesn't exist, it isn't critical so don't warn
{
	no warnings;
	$SIG{'USR2'} = \&sigusr2_cluck;
};

# Die with stack trace if Carp is verbose
$SIG{__DIE__} = \&Carp::croak if $Carp::Verbose;

umask( 0002 );

# create a system object
our $SYSTEM = EPrints::System->new();

# load the real XML module
EPrints::XML::init();

# load the configuration
EPrints::Config::init();

1;


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

