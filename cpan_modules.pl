#!/usr/bin/perl
 
use CPAN;

#
# Set the umask so nothing goes odd on systems which
# change it.
#
umask( 0022 );


print "Attempting to install PERL modules required by GNU EPrints...\n";

install( 'Data::ShowTable' ); # used by DBD::mysql
install( 'DBI' ); # used by DBD::mysql
install( 'DBD::mysql' );
install( 'MIME::Base64' );
install( 'XML::Parser' );
install( 'Net::SMTP' );
install( 'TeX::Encode' );

# not required since 2.3.7
#foreach $mod_name ( "Apache::Test", "Apache::Request" )
#{
#	( $mod ) = expand( "Module",$mod_name );
#	if( $mod->uptodate ) { print "$mod_name is up to date.\n"; next; }
#	print "Installing $mod_name (without test)\n";
#	$mod->force; 
#	$mod->install;
#}


=head1 COPYRIGHT

=for COPYRIGHT BEGIN

Copyright 2019 University of Southampton.
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

