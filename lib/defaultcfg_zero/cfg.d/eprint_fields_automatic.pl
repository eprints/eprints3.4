
$c->{set_eprint_automatic_fields} = sub
{
	my( $eprint ) = @_;

 	# This is a handy place to set default
    #unless( $eprint->is_set( "institution" ) )
    #{
    #    $eprint->set_value( "institution", "University of Southampton" );
    #}
	
#	my @docs = $eprint->get_all_documents();
#	my $textstatus = "none";
#	if( scalar @docs > 0 )
#	{
#		$textstatus = "public";
#		foreach my $doc ( @docs )
#		{
#			if( !$doc->is_public )
#			{
#				$textstatus = "restricted";
#				last;
#			}
#		}
#	}
#	$eprint->set_value( "full_text_status", $textstatus );
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

