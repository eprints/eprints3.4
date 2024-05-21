# Restrict paths is intended to allow certain IP addresses or subnets from being forbodden (i.e. 403 HTTP error code) from making requests to certain paths.  This is useful if you want to block a bot from access processor-intensive pages but don't want to block it outright as that may stop it usefully indexing your EPrints repository.
#$c->{restrict_paths} = [
#   Prevent access to exportview from 1.2.3.4 and 5.6.7.8
#	{
#		path => '/cgi/exportview/',
#		ips => [ '1.2.3.4', '5.6.7.8' ],
#	},
#   Prevent access to export from 9.10.11.0/24 subnet
#   {
#       path => '/cgi/export/',
#       ips => [ '9.10.11.' ],
#   },
#];
