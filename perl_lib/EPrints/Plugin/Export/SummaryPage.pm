=head1 NAME

EPrints::Plugin::Export::SummaryPage

=cut

package EPrints::Plugin::Export::SummaryPage;

use EPrints::Plugin::Export::HTMLFile;

@ISA = ( "EPrints::Plugin::Export::HTMLFile" );

use strict;

sub new
{
	my( $class, %opts ) = @_;

	my( $self ) = $class->SUPER::new( %opts );

	$self->{name} = "Summary Page";
	$self->{accept} = [];
	$self->{visible} = "all";
	$self->{advertise} = 0;
	$self->{qs} = 0.9;
	$self->{produce} = [
			"text/html;charset=utf-8",
			"application/xhtml+xml;charset=utf-8",
			$self->mime_type,
		];

	return $self;
}

sub output_dataobj
{
	my( $self, $dataobj, %opts ) = @_;

	my $repo = $self->{session};

	return "" if !$repo->get_online;

	my $title = $dataobj->render_citation( "summary_title" );
	my $page = $dataobj->render_citation( "summary_page" );
	$repo->build_page( $title, $page, "export" );
	$repo->send_page;

	return "";
}

sub output_list
{
	my( $self, %opts ) = @_;

	my $repo = $self->{session};

	return "" if !$repo->get_online;

	my $page = $repo->xml->create_document_fragment;
	$opts{list}->map(sub {
		(undef, undef, my $dataobj) = @_;

		my $para = $page->appendChild( $repo->xml->create_element( "p" ) );
		$para->appendChild( $dataobj->render_citation_link );
	});

	$repo->build_page( undef, $page, "export" );
	$repo->send_page;

	return "";
}

1;

=head1 COPYRIGHT

=for COPYRIGHT BEGIN

Copyright 2018 University of Southampton.
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

