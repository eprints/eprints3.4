# Priorities for event_queue tasks.  Higher the number the more likely a task will run before other tasks.

# Generic priority to set for a event_queue tasks create as a result of a web requests (e.g. workflow edit).
$c->{event_queue}->{web_priority} = 10;

# Priorities for calls to the CRUD API.  More likely these will be in bulk so should be deprioritsied.
$c->{event_queue}->{priority_paths} = {
	6 => '/id/contents',
	5 => '/id/\w+/\d+',
};
