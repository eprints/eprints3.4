=head1 NAME

EPrints::Plugin::Export::JSON

=cut

package EPrints::Plugin::Export::JSON;

use EPrints::Plugin::Export::TextFile;

@ISA = ( "EPrints::Plugin::Export::TextFile" );

use strict;

sub new
{
	my( $class, %opts ) = @_;

	my( $self ) = $class->SUPER::new( %opts );

	$self->{name} = "JSON";
	$self->{accept} = [ 'list/*', 'dataobj/*' ];
	$self->{visible} = "all";
	$self->{suffix} = ".js";
	$self->{mimetype} = "application/json; charset=utf-8";
	$self->{arguments}->{json} = undef;
	$self->{arguments}->{jsonp} = undef;
	$self->{arguments}->{callback} = undef;
	$self->{arguments}->{hide_volatile} = 1;

	return $self;
}


sub _header
{
	my( $self, %opts ) = @_;

	my $jsonp = $opts{json} || $opts{jsonp} || $opts{callback};
	if( EPrints::Utils::is_set( $jsonp ) )
	{
		$jsonp =~ s/[^=A-Za-z0-9_]//g;
		return "$jsonp(";
	}

	return "";
}

sub _footer
{
	my( $self, %opts ) = @_;

	my $jsonp = $opts{json} || $opts{jsonp} || $opts{callback};
	if( EPrints::Utils::is_set( $jsonp ) )
	{
		return ");\n";
	}
	return "";
}

sub output_list
{
	my( $self, %opts ) = @_;

	my $r = [];
	my $part;
	$part = $self->_header(%opts)."[\n";
	if( defined $opts{fh} )
	{
		print {$opts{fh}} $part;
	}
	else
	{
		push @{$r}, $part;
	}

	$opts{json_indent} = 1;
	my $first = 1;
	$opts{list}->map( sub {
		my( $session, $dataset, $dataobj ) = @_;
		my $part = "";
		if( $first ) { $first = 0; } else { $part = ",\n"; }
		$part .= $self->_epdata_to_json( $dataobj, 1, 0, %opts );
		if( defined $opts{fh} )
		{
			print {$opts{fh}} $part;
		}
		else
		{
			push @{$r}, $part;
		}
	} );

	$part= "\n]\n\n".$self->_footer(%opts);
	if( defined $opts{fh} )
	{
		print {$opts{fh}} $part;
	}
	else
	{
		push @{$r}, $part;
	}


	if( defined $opts{fh} )
	{
		return;
	}

	return join( '', @{$r} );
}

sub output_dataobj
{
	my( $self, $dataobj, %opts ) = @_;

	return $self->_header( %opts ).$self->_epdata_to_json( $dataobj, 1, 0, %opts ).$self->_footer( %opts );
}

sub _epdata_to_json
{
	my( $self, $epdata, $depth, $in_hash, %opts ) = @_;

	my $pad = "  " x $depth;
	my $pre_pad = $in_hash ? "" : $pad;
	

	if( !ref( $epdata ) )
	{
		
		if( !defined $epdata )
		{
			return "null"; # part of a compound field
		}
	
		if( $epdata =~ /^-?[0-9]*\.?[0-9]+(?:e[-+]?[0-9]+)?$/i )
		{
			return $pre_pad . ($epdata + 0);
		}
		else
		{
			return $pre_pad . EPrints::Utils::js_string( $epdata );
		}
	}
	elsif( ref( $epdata ) eq "ARRAY" )
	{
		return "$pre_pad\[\n" . join(",\n", grep { length $_ } map {
			$self->_epdata_to_json( $_, $depth + 1, 0, %opts )
		} @$epdata ) . "\n$pad\]";
	}
	elsif( ref( $epdata ) eq "HASH" )
	{
		return "$pre_pad\{\n" . join(",\n", map {
			$pad . "  \"" . $_ . "\": " . $self->_epdata_to_json( $epdata->{$_}, $depth + 1, 1, %opts )
		} keys %$epdata) . "\n$pad\}";
	}
	elsif( $epdata->isa( "EPrints::DataObj" ) )
	{
		my $subdata = {};

		return "" if(
			$opts{hide_volatile} &&
			$epdata->isa( "EPrints::DataObj::Document" ) &&
			$epdata->has_relation( undef, "isVolatileVersionOf" )
		  );

		my $export_fieldlist = $self->repository->export_fieldlist_for_dataset( $self->repository->dataset( 'eprint' ) );
		foreach my $field ($epdata->get_dataset->get_fields)
		{
			next unless $field->repository->in_export_fieldlist( $export_fieldlist, $field->name );
			next if !$field->get_property( "export_as_xml" );	 
			next if defined $field->{sub_name};
			my $value = $field->get_value( $epdata );

			# filter out sub_values with export_as_xml=>0, such as creators_id
			my $nmax = ( defined $field->{fields} ) ? length($field->{fields})-1 : 0;
			for my $n ( 0 .. $nmax )
			{
				if( $field->{fields}[$n] )
				{
					my $export_as_xml = $field->{fields}[$n]{export_as_xml};
					if( defined $export_as_xml && $export_as_xml eq 0 )
					{
                                                my $sub_name = $field->{fields}[$n]{sub_name}; # probably ID
						if ( ref( $value ) eq "ARRAY" )
						{
							for my $v ( 0 .. length( $value )-1 )
							{
								delete $value->[$v]->{$sub_name} if defined $value->[$v];
							}
						}
						else
						{
							delete $value->{$sub_name};
						}
					}
				}
			}

			next if !EPrints::Utils::is_set( $value );
			$subdata->{$field->get_name} = $value;
		}

		$subdata->{uri} = $epdata->uri;

		return $self->_epdata_to_json( $subdata, $depth + 1, 0, %opts );
	}
}


1;

=head1 COPYRIGHT

=for COPYRIGHT BEGIN

Copyright 2021 University of Southampton.
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

