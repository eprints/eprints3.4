#!/usr/bin/perl -w

my $dh;
my @files = ();
opendir( $dh, "/opt/eprints3/lib/defaultcfg/cfg.d" ) || die "Dammit";
while( my $file = readdir( $dh ) )
{
	push @files, $file;
}
closedir( $dh );

my $byfile = {};
my $byopt = {};

foreach my $file ( @files )
{
	my $fn = "/opt/eprints3/lib/defaultcfg/cfg.d/$file";
	open( F, $fn ) || die "dang $fn : $!";
	foreach my $line ( <F> )
	{
		chomp $line;
		if( $line =~ m/^\s*\$c->{([^}]+)}/ )
		{
			$byfile->{$file}->{$1} = 1;
			$byopt->{$1}->{$file} = 1;
		} 
	}	
	close F;
}

foreach my $file ( sort keys %$byfile )
{
	print "== $file ==\n";
	foreach my $opt ( sort keys %{$byfile->{$file}} )
	{
		print "* $opt\n";
	}
}
print "\n\n\n";

foreach my $opt ( sort keys %$byopt )
{
	print "* $opt = [[".join( "]], [[", sort keys %{$byopt->{$opt}})."]]\n";
}

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

