
# creators_uri
$c->{rdf}->{publication_uri} = sub {
	my( $eprint ) = @_;

	my $repository = $eprint->repository;
	if( $eprint->dataset->has_field( "issn" ) && $eprint->is_set( "issn" ) )
	{
		my $issn = $eprint->get_value( "issn" );
		$issn =~ s/[^0-9X]//g;
		
		return "epid:publication/ext-$issn";
	}

	return if( !$eprint->is_set( "publication" ) );
			
	my $code = "eprintsrdf/".$eprint->get_value( "publication" );
	utf8::encode( $code ); # md5 takes bytes, not characters
	return "epid:publication/ext-".md5_hex( $code );
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

