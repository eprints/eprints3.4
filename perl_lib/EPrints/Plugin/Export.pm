=for Pod2Wiki

=head1 NAME

EPrints::Plugin::Export

=cut

=head1 METHODS

=over 4

=cut

package EPrints::Plugin::Export;

use strict;

our @ISA = qw/ EPrints::Plugin /;

$EPrints::Plugin::Export::DISABLE = 1;

=item $plugin = EPrints::Plugin::Export->new( %params )

Creates a new Export plugin. In addition to those parameters defined by L<EPrints::Plugin>:

=over 4

=item accept

Array reference of object types this plugin can accept.

=item advertise

Boolean for whether to advertise this plugin to users.

=item arguments

Hash reference of supported arguments/default values.

=item mimetype

The MIME type to set when outputting to an HTTP response.

=item produce

Array reference of MIME types this plugin can output. By default includes B<application/x-eprints-export-XXX>, where I<XXX> is the case-insensitive id of the plugin.

=item qs

Score used to determine which plugin to use, if all else is equal, where 0 is least likely and 1 is most likely.

=item suffix

File name extension to use when outputting to file.

=item visible

"staff" (staff only) or "all" (anyone).

=back

=cut

sub new
{
	my( $class, %params ) = @_;

	$params{suffix} = exists $params{suffix} ? $params{suffix} : ".txt";
	$params{visible} = exists $params{visible} ? $params{visible} : "all";
	$params{advertise} = exists $params{advertise} ? $params{advertise} : 1;
	$params{arguments} = exists $params{arguments} ? $params{arguments} : {};

	# q is used to describe quality. Use it to increase or decrease the 
	# desirability of using this plugin during content negotiation.
	$params{qs} = exists $params{qs} ? $params{qs} : 0.5; 

	$params{accept} = exists $params{accept} ? $params{accept} : [];
	$params{mimetype} = exists $params{mimetype} ? $params{mimetype} : undef;
	$params{produce} = exists $params{produce} ? $params{produce} : [$class->mime_type];

	return $class->SUPER::new(%params);
}

# Return an array of the ID's of arguemnts this plugin accepts
sub arguments
{
	my( $self ) = @_;

	return keys %{$self->{arguments}};
}

# Return true if this plugin accepts the given argument ID
sub has_argument
{
	my( $self, $arg ) = @_;

	return exists $self->{arguments}->{$arg};
}

sub render_name
{
	my( $plugin ) = @_;

	return $plugin->{session}->make_text( $plugin->param("name") );
}

sub param
{
	my( $self, $id ) = @_;

	if( $id eq "produce" )
	{
		my $mimetype = $self->SUPER::param( "mimetype" );
		return [
				(defined $mimetype ? $mimetype : ()),
				@{$self->SUPER::param( $id )}
			];
	}

	return $self->SUPER::param( $id );
}

sub matches 
{
	my( $self, $test, $param ) = @_;

	if( $test eq "is_tool" )
	{
		return( $self->is_tool() );
	}
	if( $test eq "is_feed" )
	{
		return( $self->is_feed() );
	}
	if( $test eq "is_visible" )
	{
		return( $self->is_visible( $param ) );
	}
	if( $test eq "can_accept" )
	{
		return( $self->can_accept( $param ) );
	}
	if( $test eq "can_produce" )
	{
		return( $self->can_produce( $param ) );
	}
	if( $test eq "has_xmlns" )
	{
		return( $self->has_xmlns( $param ) );
	}
	if( $test eq "is_advertised" )
	{
		return( $self->param( "advertise" ) == $param );
	}
	if( $test eq "metadataPrefix" )
	{
		no warnings;
		return $param eq "*" ?
				defined($self->param( "metadataPrefix" )) :
				$self->param( "metadataPrefix" ) eq $param;
	}

	# didn't understand this match 
	return $self->SUPER::matches( $test, $param );
}

sub is_tool
{
	my( $self ) = @_;

	return 0;
}


sub is_feed
{
	my( $self ) = @_;

	return 0;
}

sub render_export_icon
{
	my( $plugin, $type, $url ) = @_;

	my $session = $plugin->{session};
	
	my $span = $session->make_element( "span", class=>"ep_search_$type" );
	my $a1 = $session->render_link( $url );

	my $icon = $session->make_element( "img", src=>$plugin->icon_url(), alt=>"[$type]", border=>0 );
	$a1->appendChild( $icon );
        my $a2 = $session->render_link( $url );
	$a2->appendChild( $plugin->render_name );

	$span->appendChild( $a1 );
        $span->appendChild( $session->make_text( " " ) );
        $span->appendChild( $a2 );

	return $span;
}

# all, staff or ""
sub is_visible
{
	my( $plugin, $vis_level ) = @_;

	return( 1 ) unless( defined $vis_level );

	my $visible = $plugin->param("visible");
	return( 0 ) unless( defined $visible );

	if( $vis_level eq "all" && $visible ne "all" ) {
		return 0;
	}

	if( $vis_level eq "staff" && $visible ne "all" && $visible ne "staff" ) 
	{
		return 0;
	}

	return 1;
}

sub can_accept
{
	my( $plugin, $format ) = @_;

	my $accept = $plugin->param( "accept" );
	foreach my $a_format ( @{$accept} ) {
		if( $a_format =~ m/^(.*)\*$/ ) {
			my $base = $1;
			return( 1 ) if( substr( $format, 0, length $base ) eq $base );
		}
		else {
			return( 1 ) if( $format eq $a_format );
		}
	}

	return 0;
}

sub can_produce
{
	my( $self, $format ) = @_;

	for(@{$self->param( "produce" )}, $self->mime_type)
	{
		return 1 if (split /;/, $_)[0] eq $format;
	}

	return 0;
}

sub has_xmlns
{
	my( $plugin, $unused ) = @_;

	return 1 if( defined $plugin->param("xmlns") );
}


sub output_list
{
	my( $plugin, %opts ) = @_;

	my $r = [];
	$opts{list}->map( sub {
		my( $session, $dataset, $item ) = @_;

		my $part = $plugin->output_dataobj( $item, %opts );
		if( defined $opts{fh} )
		{
			binmode(STDOUT, ":utf8");
			print {$opts{fh}} $part;
		}
		else
		{
			push @{$r}, $part;
		}
	} );

	if( defined $opts{fh} )
	{
		return undef;
	}

	return join( '', @{$r} );
}

#stub.
sub output_dataobj
{
	my( $plugin, $dataobj ) = @_;
	
	EPrints->abort( "output_dataobj not subclassed on $plugin" );
}

sub xml_dataobj
{
	my( $plugin, $dataobj ) = @_;
	
	my $r = "error. xml_dataobj not subclassed";

	$plugin->{session}->get_repository->log( $r );

	return $plugin->{session}->make_text( $r );
}

# if this an output plugin can output results for a single dataobj then
# this routine returns a URL which will export it. This routine does not
# check that it's actually possible.
sub dataobj_export_url
{
	my( $plugin, $dataobj, $staff ) = @_;

	my $dataset = $dataobj->get_dataset;

	my $pluginid = $plugin->{id};

	unless( $pluginid =~ m# ^Export::(.*)$ #x )
	{
		$plugin->{session}->get_repository->log( "Bad pluginid in dataobj_export_url: ".$pluginid );
		return undef;
	}
	my $format = $1;

	my $url = $plugin->{session}->get_repository->get_conf( "http_cgiurl" );
	$url .= '/export/' . join('/', map { URI::Escape::uri_escape($_) }
		$dataobj->get_dataset->base_id,
		$dataobj->get_id,
		$format,
		join('-',
			$plugin->{session}->get_id,
			$dataobj->get_dataset->base_id,
			$dataobj->get_id,
		).$plugin->param( "suffix" )
	);

	return $url;
}

# if this an output plugin can output results for a list of dataobjs (defined
# as the contents as the parent object then this routine returns a URL which 
# will export it. This routine does not check that it's actually possible.
sub list_export_url
{
	my( $plugin, $dataobj, $staff ) = @_;

	my $dataset = $dataobj->get_dataset;

	my $pluginid = $plugin->{id};

	unless( $pluginid =~ m# ^Export::(.*)$ #x )
	{
		$plugin->{session}->get_repository->log( "Bad pluginid in dataobj_export_url: ".$pluginid );
		return undef;
	}
	my $format = $1;

	my $url = $plugin->{session}->get_repository->get_conf( "http_cgiurl" );
	$url .= '/export/' . join('/', map { URI::Escape::uri_escape($_) }
		$dataobj->get_dataset->base_id,
		$dataobj->get_id,
		'contents',
		$format,
		join('-',
			$plugin->{session}->get_id,
			$dataobj->get_dataset->base_id,
			$dataobj->get_id,
			'contents',
		).$plugin->param( "suffix" )
	);

	return $url;
}

=item $plugin->initialise_fh( FH )

Initialise the file handle FH for writing. This may be used to manipulate the Perl IO layers in effect.

Defaults to setting the file handle to binary semantics.

=cut

sub initialise_fh
{
	my( $plugin, $fh ) = @_;

	binmode($fh);
}

=item $bom = $plugin->byte_order_mark

If writing a file the byte order mark will be written before any other content. This may be necessary to write plain-text Unicode-encoded files.

Defaults to empty string.

=cut

sub byte_order_mark
{
	"";
}

1;

=back

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

