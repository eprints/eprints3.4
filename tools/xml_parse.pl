#!/usr/bin/perl -w 

my $file = join( '', <> );

while( $file ne "" )
{
	if( $file =~ s/^([^<]+)//s )
	{
		text( $1 );
		next;
	}

	if( $file =~ s/^<\?(.*)\?>//s )
	{
		pdir( $1 ); 
		next;
	}
	if( $file =~ s/^<!--(.*)-->//s )
	{
		comment( $1 );
		next;
	}

	if( $file =~ s/<(([^>'"]*|"[^"]*"|'[^']*')+)>//s )
	{
		tag( $1 );
		next;
	}

	print "DAMN:$file\n";
	exit;
}


sub text
{
	my( $val ) = @_;
	$val = "\U$val";

	print $val;
}
		
sub pdir
{
	print "<?".$_[0]."?>";
}

sub comment
{
	print "<!--".$_[0]."-->";
}

sub tag
{
	my $tag = $_[0];
	if( $tag =~ m/^\// )
	{
		print "<$tag>";
		return;
	}	

	print "<";
	$tag =~ s/^([^\s>]+)//;
	print $1;
	while( $tag ne "" )
	{
		next if( $tag=~s/^\s// );
		if( $tag=~s/^([^\s=]+)\s*=\s*'([^']+)'// )
		{
			sattr( $1, $2 );
			next;
		}
		if( $tag=~s/^([^\s=]+)\s*=\s*"([^"]+)"// )
		{
			dattr( $1, $2 );
			next;
		}
		if( $tag=~s/^\/// )
		{
			print "/";
			next;
		}
		print "DAMN! --($tag)--\n";
		exit;
	}
	print ">";
}

sub sattr
{
	my( $name, $val ) = @_;

	$val = "\U$val";

	print " ".$name."='(".$val.")'";
}
sub dattr
{
	my( $name, $val ) = @_;

	$val = "\U$val";

	print " ".$name.'="('.$val.')"';
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

