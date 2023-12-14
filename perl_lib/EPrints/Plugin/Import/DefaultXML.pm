=head1 NAME

EPrints::Plugin::Import::DefaultXML

=cut

package EPrints::Plugin::Import::DefaultXML;

use strict;

our @ISA = qw/ EPrints::Plugin::Import /;


# This reads in all the second level XML elements and passes them
# as DOM to xml_to_dataobj.

# maybe needs an input_dataobj method which parses the XML from
# a single record.


$EPrints::Plugin::Import::DISABLE = 1;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	$self->{name} = "Default XML";
	$self->{visible} = "";
	#$self->{produce} = [ 'list/*', 'dataobj/*' ];

	return $self;
}




# if this is defined then it is used to check that the top
# level XML element is correct.

sub top_level_tag
{
	my( $plugin, $dataset ) = @_;

	return undef;
}

sub unknown_start_element
{
	my( $self, $found, $expected ) = @_;

	$self->error("Unexpected tag: expected <$expected> found <$found>\n");
	die "\n"; # Break out of the parsing
}

=item $class = $import->handler_class

Returns the class to use as the SAX handler for parsing.

This class provides two handlers:

	::DOMHandler - calls xml_to_epdata with a DOM of the complete object
	::Handler - calls dataobj class with SAX events

=cut

sub handler_class { __PACKAGE__ . "::Handler" }

sub input_fh
{
	my( $self, %opts ) = @_;

	my $handler = $self->handler_class->new(
		dataset => $opts{dataset},
		plugin => $self,
		depth => 0,
		imported => [],
	);

	eval { EPrints::XML::event_parse( $opts{fh}, $handler ) };
	die $@ if $@ and "$@" ne "\n";

	return EPrints::List->new(
			dataset => $opts{dataset},
			session => $self->{session},
			ids => $handler->{imported} );
}

sub xml_to_dataobj
{
	my( $self, $dataset, $xml ) = @_;

	my $epdata = $self->xml_to_epdata( $dataset, $xml );
	return $self->epdata_to_dataobj( $dataset, $epdata );
}

sub xml_to_text
{
	my( $plugin, $xml ) = @_;

	my @list = $xml->childNodes;
	my $xml_ok = 1;
	my $element_ok = 1;
	my @banned_elements = ();
	my @v = ();
	my $permitted_tags = [ qw/ b big blockquote br code dd div dl dt em h1 h2 h3 h4 h5 h6 hr i li ol p pre s small span strike strong sub sup table tbody td th tr tt u ul / ];
	if ( $plugin->{session}->config( "import_xml_permitted_tags" ) )
	{
		$permitted_tags = $plugin->{session}->config( "import_xml_permitted_tags" );
	}

	foreach my $node ( @list ) 
	{  
		if( EPrints::XML::is_dom( $node,
			"Text",
			"CDATASection",
			"EntityReference" ) ) 
		{
			push @v, $node->nodeValue;
		}
		elsif( EPrints::XML::is_dom( $node, "Element" ) )
		{
			if ( $node->nodeName !~ m/^\w+$/ )
			{
				my $field = $xml->nodeName =~ m/^\w+$/ ? $xml->nodeName : "REDACTED";
				$plugin->warning( $plugin->{session}->phrase( "Plugin/Import/DefaultXML:invalid_xml_element", field => $field ) );
				return "";
			}

			if ( grep { $_ eq $node->nodeName } @$permitted_tags )
			{
				push @v, $node;
			}
			else
			{
				$element_ok = 0;
				unless ( grep { $_ eq $node->nodeName } @banned_elements )
				{
					push @banned_elements, $node->nodeName;
				}
			}
		}
		else
		{
			$xml_ok = 0;
		}
	}

	unless ( $xml_ok )
	{
		$plugin->warning( $plugin->{session}->phrase( "Plugin/Import/DefaultXML:unexpected_xml", xml => $xml->toString ) );
	}

	unless ( $element_ok )
    {
		$plugin->warning( $plugin->{session}->phrase( "Plugin/Import/DefaultXML:unexpected_xml_elements", elements => join( "&gt; &lt;", @banned_elements ) , field => $xml->nodeName ) );
	}


	return join( "", @v );
}

package EPrints::Plugin::Import::DefaultXML::Handler;

use strict;

sub new
{
	my( $class, %self ) = @_;

	return bless \%self, $class;
}

sub AUTOLOAD {}

sub start_element
{
	my( $self, $info ) = @_;

#print STDERR "start_element: ".Data::Dumper::Dumper( $info )."\n";
	++$self->{depth};

	if( defined(my $handler = $self->{handler}) )
	{
		$handler->start_element( $info, $self->{epdata}, $self->{state} );
	}
	elsif( $self->{depth} == 1 )
	{
		my $tlt = $self->{plugin}->top_level_tag( $self->{dataset} );
		if( defined $tlt && $tlt ne $info->{Name} )
		{
			$self->{plugin}->unknown_start_element( $info->{Name}, $tlt ); #dies
		}
	}
	elsif( $self->{depth} == 2 )
	{
		$self->{epdata} = {};
		$self->{state} = {
				dataset => $self->{dataset},
				Handler => $self->{plugin}->{Handler},
			};

		my $class = $self->{dataset}->get_object_class;
		$self->{handler} = $class;

		$class->start_element( $info, $self->{epdata}, $self->{state} );
	}
}

sub end_element
{
	my( $self, $info ) = @_;

	if( defined(my $handler = $self->{handler}) )
	{
		$handler->end_element( $info, $self->{epdata}, $self->{state} );

		if( $self->{depth} == 2 )
		{
			delete $self->{state};
			delete $self->{handler};

			my $epdata = delete $self->{epdata};
			my $dataobj = $self->{plugin}->epdata_to_dataobj( $self->{dataset}, $epdata );
			push @{$self->{imported}}, $dataobj->id if defined $dataobj;
		}
	}

	--$self->{depth};
}

sub characters
{
	my( $self, $info ) = @_;

	if( defined(my $handler = $self->{handler}) )
	{
		$handler->characters( $info, $self->{epdata}, $self->{state} );
	}
}

package EPrints::Plugin::Import::DefaultXML::DOMHandler;

use strict;

sub new
{
	my( $class, %self ) = @_;

	return bless \%self, $class;
}

sub AUTOLOAD {}

sub start_element
{
	my( $self, $info ) = @_;

	++$self->{depth};

	if( defined(my $handler = $self->{handler}) )
	{
		$handler->start_element( $info, $self->{epdata}, $self->{state} );
	}
	elsif( $self->{depth} == 1 )
	{
		my $tlt = $self->{plugin}->top_level_tag( $self->{dataset} );
		if( defined $tlt && $tlt ne $info->{Name} )
		{
			$self->{plugin}->unknown_start_element( $info->{Name}, $tlt ); #dies
		}
	}
	elsif( $self->{depth} == 2 )
	{
		$self->{handler} = EPrints::XML::SAX::Builder->new(
			repository => $self->{plugin}->{session}
		);
		$self->{handler}->start_document;
		$self->{handler}->start_element( $info );
	}
}

sub end_element
{
	my( $self, $info ) = @_;

	if( defined(my $handler = $self->{handler}) )
	{
		$handler->end_element( $info, $self->{epdata}, $self->{state} );
		if( $self->{depth} == 2 )
		{
			delete $self->{handler};

			$handler->end_document;

			my $xml = $handler->result;
			MAKE_OBJECT: {
				my $epdata = $self->{plugin}->xml_to_epdata( $self->{dataset}, $xml );
				last MAKE_OBJECT if !defined $epdata;

				my $dataobj = $self->{plugin}->epdata_to_dataobj( $self->{dataset}, $epdata );
				last MAKE_OBJECT if !defined $dataobj;

				push @{$self->{imported}}, $dataobj->id;
			}
		}
	}

	--$self->{depth};
}

sub characters
{
	my( $self, $info ) = @_;

	if( defined(my $handler = $self->{handler}) )
	{
		$handler->characters( $info, $self->{epdata}, $self->{state} );
	}
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

