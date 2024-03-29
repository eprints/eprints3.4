=head1 NAME

EPrints::Plugin::Screen::Admin::Config::Edit::XML

=cut

package EPrints::Plugin::Screen::Admin::Config::Edit::XML;

use EPrints::Plugin::Screen::Admin::Config::Edit;

@ISA = ( 'EPrints::Plugin::Screen::Admin::Config::Edit' );

use strict;

sub can_be_viewed
{
	my( $self ) = @_;

	return $self->allow( "config/edit/xml" );
}

sub validate_config_file
{
	my( $self, $data ) = @_;

	my $clean_data;
	if( EPrints::Utils::require_if_exists( 'HTML::Entities' ) )
	{
		$clean_data = HTML::Entities::encode_numeric( HTML::Entities::decode( $data ), '^\n\x20-\x25\x27-\x7e\xc0-\xff' );
	}
	else
	{	
		# can't help!
		$clean_data = $data;
	}

	my @issues = $self->SUPER::validate_config_file( $clean_data );

	my $tmpfile = "/tmp/tmp_ep_config_file.$$";
	open( TMP, ">$tmpfile" );
	binmode( TMP, ":utf8" );
	print TMP $clean_data;
	close TMP;
	eval {
		my $doc = EPrints::XML::parse_xml( 
			$tmpfile, 
			$self->{session}->get_repository->get_conf( "variables_path" )."/",
			1 );
	};
	my $xml_parse_issues = $@;
	unlink( $tmpfile );
	if( $xml_parse_issues )
	{
		my $pre = $self->{session}->make_element( "pre" );
		$pre->appendChild( $self->{session}->make_text( $xml_parse_issues ) );
		push @issues, $pre;
	}

	return @issues;
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

