=head1 NAME

EPrints::Plugin::Export::COinS

=cut

package EPrints::Plugin::Export::COinS;

use EPrints::Plugin::Export::TextFile;

@ISA = ( "EPrints::Plugin::Export::TextFile" );

use URI::OpenURL;

use strict;

our %TYPES = (
	article => {
		namespace => "info:ofi/fmt:kev:mtx:journal",
		plugin => "Export::ContextObject::Journal",
	},
	book => {
		namespace => "info:ofi/fmt:kev:mtx:book",
		plugin => "Export::ContextObject::Book"
	},
	book_section => {
		namespace => "info:ofi/fmt:kev:mtx:book",
		plugin => "Export::ContextObject::Book"
	},
	conference_item => {
		namespace => "info:ofi/fmt:kev:mtx:book",
		plugin => "Export::ContextObject::Book",
	},
	thesis => {
		namespace => "info:ofi/fmt:kev:mtx:dissertation",
		plugin => "Export::ContextObject::Dissertation",
	},
	other => {
		namespace => "info:ofi/fmt:kev:mtx:dc",
		plugin => "Export::ContextObject::DublinCore",
	},
);

sub new
{
	my( $class, %opts ) = @_;

	my( $self ) = $class->SUPER::new( %opts );

	$self->{name} = "OpenURL ContextObject in Span";
	$self->{accept} = [ 'dataobj/eprint' ];
	$self->{visible} = "all";

	return $self;
}

sub output_dataobj
{
	my( $plugin, $dataobj ) = @_;

	my $dataset = $dataobj->get_dataset;

	my $s = URI::OpenURL->new("");

	my $type = $dataobj->get_value( "type" );
	$type = "other" unless exists $TYPES{$type};

	my $rft_plugin = $TYPES{$type}->{plugin};
	$rft_plugin = $plugin->{session}->plugin( $rft_plugin );

	if( $dataset->has_field( "id_number" ) && $dataobj->is_set( "id_number" ) )
	{
		$s->referent( id => $dataobj->get_value( "id_number" ) );
	}

	$rft_plugin->kev_dataobj( $dataobj, scalar($s->referent) );

	return "$s";
}

1;

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

