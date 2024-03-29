######################################################################
#
# EPrints::Update::Abstract
#
######################################################################
#
#
######################################################################


=pod

=head1 NAME

B<EPrints::Update::Abstract

=head1 DESCRIPTION

Update item summary web pages on demand.

=over 4

=cut

package EPrints::Update::Abstract;

use Data::Dumper;

use strict;
  
sub update
{
	my( $repository, $lang, $eprintid, $uri ) = @_;

	my $localpath = sprintf("%08d", $eprintid);
	$localpath =~ s/(..)/\/$1/g;
	$localpath = "/archive" . $localpath . "/index.html";

	my $targetfile = $repository->get_conf( "htdocs_path" )."/".$lang.$localpath;

	my $need_to_update = 0;

	if( !-e $targetfile ) 
	{
		$need_to_update = 1;
	}

	my $timestampfile = $repository->get_conf( "variables_path" )."/abstracts.timestamp";	
	if( -e $timestampfile && -e $targetfile )
	{
		my $poketime = (stat( $timestampfile ))[9];
		my $targettime = (stat( $targetfile ))[9];
		if( $targettime < $poketime ) { $need_to_update = 1; }
	}

	return unless $need_to_update;

	# There is an abstracts file, AND we're looking
	# at serving an abstract page, AND the abstracts timestamp
	# file is newer than the abstracts page...
	# so try and regenerate the abstracts page.

	my $eprint = $repository->eprint( $eprintid );
	return unless defined $eprint;

	$eprint->generate_static;
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

