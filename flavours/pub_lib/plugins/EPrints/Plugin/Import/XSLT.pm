=head1 NAME

EPrints::Plugin::Import::XSLT

=cut

package EPrints::Plugin::Import::XSLT;

use EPrints::Plugin::Import;

@ISA = ( "EPrints::Plugin::Import" );

use strict;

our %SETTINGS; # class-specific settings

sub new
{
	my( $class, @args ) = @_;

	return $class->SUPER::new(
		%{$SETTINGS{$class}},
		@args
	);
}

sub init_xslt
{
	my( $class, $repo, $xslt ) = @_;

	my $stylesheet = XML::LibXSLT->new->parse_stylesheet( $xslt->{doc} );
	$xslt->{stylesheet} = $stylesheet;
	delete $xslt->{doc};

	$SETTINGS{$class} = $xslt;
}

sub input_fh
{
	my( $self, %opts ) = @_;

	my $fh = $opts{fh};
	my $session = $self->{session};

	my $dataset = $opts{dataset};
	my $class = $dataset->get_object_class;
	my $root_name = $dataset->base_id;

	# read the source XML
	# note: LibXSLT will only work with LibXML, so that's what we use here
	my $source = XML::LibXML->new->parse_fh( $fh );

	# transform it using our stylesheet
	my $result = $self->transform( $source );

	my @ids;

	my $root = $result->documentElement;

	foreach my $node ($root->getElementsByTagName( $root_name ))
	{
		my $epdata = $class->xml_to_epdata( $session, $node );
		my $dataobj = $self->epdata_to_dataobj( $dataset, $epdata );
		next if !defined $dataobj;
		push @ids, $dataobj->id;
	}

	$session->xml->dispose( $source );
	$session->xml->dispose( $result );

	return EPrints::List->new(
		session => $session,
		dataset => $dataset,
		ids => \@ids );
}

sub transform
{
	my( $self, $doc ) = @_;

	return $self->{stylesheet}->transform( $doc );
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

