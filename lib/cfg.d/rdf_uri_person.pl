
# creators_uri
$c->{rdf}->{person_uri} = sub {
	my( $eprint, $person ) = @_;

	my $repository = $eprint->repository;
	if( EPrints::Utils::is_set( $person->{id} ) )
	{
		# If you want to use hashed ID's to prevent people reverse engineering
		# them from the URI, uncomment the following line and edit SECRET to be 
		# something unique and unguessable. 
		#
		# return "epid:person/ext-".md5_hex( utf8::encode( $person->{id}." SECRET" ));
		
		return "epid:person/ext-".$person->{id};
	}
			
	my $name = $person->{name};	
	my $code = "eprintsrdf/".$eprint->get_id."/".($name->{family}||"")."/".($name->{given}||"");
	utf8::encode( $code ); # md5 takes bytes, not characters
	return "epid:person/ext-".md5_hex( $code );
};


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

