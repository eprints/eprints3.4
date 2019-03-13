# EPrints Services package
# split field value into paragraphs
$c->{render_paras} = sub {
	my( $session, $field, $value, $object ) = @_;

	my $frag = $session->make_doc_fragment;

	# normalise newlines
	$value =~ s/(\r\n|\n|\r)/\n/gs;

	my @paras = split( /\n\n/, $value );
	foreach my $para( @paras )
	{
		$para =~ s/^\s*\n?//;
		$para =~ s/\n?\s*$//;
		next if $para eq "";

		#my $p = $session->make_element( "p", style=>"text-align: left; margin: 1em auto 0em auto" );
		#	ADB: Commented out the above and added below. 1em top margin results in field not aligning vertically with field name.
    #	Better to replace inline style with a class. Default seems OK in any case.
		my $p = $session->make_element( "p", class=>"ep_field_para" ); 

		my @lines = split( /\n/, $para );
		for( my $i=0; $i<scalar( @lines ); $i++ )
		{
			$p->appendChild( $session->make_text( $lines[$i] ) );
			$p->appendChild( $session->make_element( "br" ) ) unless $i == $#lines;
		}

		$frag->appendChild( $p );
	}

	return $frag;
};

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

