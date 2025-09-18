=head1 NAME

EPrints::Plugin::Export::Urls

=cut

package EPrints::Plugin::Export::Urls;

use EPrints::Plugin::Export;

@ISA = ( "EPrints::Plugin::Export" );

use strict;

sub new
{
	my( $class, %opts ) = @_;

	my $self = $class->SUPER::new( %opts );

	$self->{name} = 'Document URLs';
	$self->{accept} = [ 'list/*' ];
	$self->{visible} = 'all';
	$self->{suffix} = '.html';
	$self->{mimetype} = 'text/html; charset=utf-8';
	
	return $self;
}

sub output_list
{
	my( $plugin, %opts ) = @_;

	my $fh = $opts{fh};
	my $value = undef;
	open $fh, '>', \$value unless defined $fh;

	for my $eprint ($opts{list}->get_records) {
		for my $document ($eprint->get_all_documents) {
			next unless $document->is_public;
			print {$fh} '<a href="' . $document->get_url . '">' . $document->get_url . '</a><br />';
		}
	}

	return $value;
}

1;

=head1 COPYRIGHT

=for COPYRIGHT BEGIN

Copyright 2025 University of Southampton.
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

