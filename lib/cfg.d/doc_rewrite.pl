# handle relation-based document redirects
$c->add_trigger( EP_TRIGGER_DOC_URL_REWRITE, sub {
	my( %args ) = @_;

	my( $request, $doc, $relations, $filename ) = @args{qw( request document relations filename )};

	foreach my $r (@$relations)
	{
		$r =~ s/^has(.+)$/is$1Of/;
		$doc = $doc->search_related( $r )->item( 0 );
		if( !defined $doc )
		{
			$request->status( 404 );
			return EP_TRIGGER_DONE;
		}
		$filename = $doc->get_main;
	}

	$request->pnotes( dataobj => $doc );
	$request->pnotes( filename => $filename );
}, priority => 100 );

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

