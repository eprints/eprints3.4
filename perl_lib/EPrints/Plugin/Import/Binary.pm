=head1 NAME

EPrints::Plugin::Import::Binary

=cut

package EPrints::Plugin::Import::Binary;

use strict;

our @ISA = qw/ EPrints::Plugin::Import /;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new( %params );

	$self->{name} = "Binary file (Internal)";
	$self->{visible} = "";
	$self->{advertise} = 0;
	$self->{produce} = [qw()];
	$self->{accept} = [qw()];

	$self->{arguments}->{filename} = undef;
	$self->{arguments}->{mime_type} = undef;

	return $self;
}

sub input_fh
{
	my( $self, %opts ) = @_;

	my $fh = $opts{fh};
	my $dataset = $opts{dataset};
	my $filename = $opts{filename};
	my $mime_type = $opts{mime_type};
	my( $format ) = split /[;,]/, $mime_type;
	
	EPrints->abort( "Requires filename argument" ) if !defined $filename;

	my $rc = 0;

	my $epdata = {
		documents => [{
			main => $filename,
			format => $format,
			files => [{
				filename => $filename,
				mime_type => $format,
				filesize => -s $fh,
				_content => $fh,
			}],
		}],
	};

	if( $dataset->base_id eq "eprint" )
	{
	}
	elsif( $dataset->base_id eq "document" )
	{
		$epdata = $epdata->{documents}->[0];
	}
	elsif( $dataset->base_id eq "file" )
	{
		$epdata = $epdata->{documents}->[0]->{files}->[0];
	}
	
	my @ids;

	my $dataobj = $self->epdata_to_dataobj( $dataset, $epdata );
	push @ids, $dataobj->id if defined $dataobj;

	return EPrints::List->new(
		session => $self->{repository},
		dataset => $dataset,
		ids => \@ids );
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

