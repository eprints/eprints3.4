######################################################################
#
# EP_TRIGGER_BEGIN replaces $c->{session_init}
#
#  Invoked each time a new repository is needed (generally one per
#  script invocation.) $repository is a repository object that can be used
#  to store any values you want. To prevent future clashes, prefix
#  all of the keys you put in the hash with repository.
#
#  If $offline is non-zero, the repository is an `off-line' repository, i.e.
#  it has been run as a shell script and not by the web server.
#
######################################################################

$c->add_trigger( EP_TRIGGER_BEGIN, 
	sub {
		my %params = @_;
		my $repo = $params{repository};
    	my $online = $params{online}; #is this session web-based

		my $old_conf_fn = "session_init";
		my $new_trigger = "EP_TRIGGER_BEGIN";
		if ( $repo->can_call( $old_conf_fn ) )  
		{
			$repo->log( "UPGRADE: configuration uses '$old_conf_fn'. Please review upgrade advice for triggers ($new_trigger)." );
			$repo->call(
				$old_conf_fn,
				$online,
			);
		}
	}, 
	priority => 1, 
	id => "UPGRADE" 
);


####################################################################
#
# EP_TRIGGER_END replaces $c->{session_close}
#
#  Invoked at the close of each repository. Here you should clean up
#  things you did in an EP_TRIGGER_BEGIN trigger,
#
######################################################################

$c->add_trigger( EP_TRIGGER_END,
    sub {
        my %params = @_;
        my $repo = $params{repository};

        my $old_conf_fn = "session_close";
        my $new_trigger = "EP_TRIGGER_END";
        if ( $repo->can_call( $old_conf_fn ) )
		{
            $repo->log( "UPGRADE: configuration uses '$old_conf_fn'. Please review upgrade advice for triggers ($new_trigger)." );
            $repo->call(
                $old_conf_fn,
            );
        }
    },
    priority => 1,
    id => "UPGRADE"
);

