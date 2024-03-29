=head1 NAME

EPrints::Plugin::InputForm::Component::Error

=cut

package EPrints::Plugin::InputForm::Component::Error;

use EPrints::Plugin::InputForm::Component;

@ISA = ( "EPrints::Plugin::InputForm::Component" );

use strict;

sub new
{
	my( $class, %opts ) = @_;

	my $self = $class->SUPER::new( %opts );

	$self->{name} = "Error";
	$self->{visible} = "all";

	return $self;
}

sub is_collapsed { 0 }

sub render_content
{
	my( $self ) = @_;

	my $repo = $self->{repository};
	my $xml = $repo->xml;

	my $frag = $xml->create_document_fragment;

	my @problems = $self->problems;

	if( @problems == 1 )
	{
		$frag->appendChild( $problems[0] );
	}
	elsif( @problems > 1 )
	{
		my $ul = $frag->appendChild( $xml->create_element( "ul" ) );
		foreach my $problem (@problems)
		{
			my $li = $ul->appendChild( $xml->create_element( "li" ) );
			$li->appendChild( $problem );
		}
	}

	return $repo->render_message( "warning", $frag );
}

sub render_help
{
	my( $self, $surround ) = @_;
	
	return $self->html_phrase( "help" );
}

sub render_title
{
	my( $self, $surround ) = @_;

	my $workflow = $self->{workflow};
	my $datasetid = $workflow->{dataset}->base_id;
	my $workflowid = $workflow->{workflow_id};
	my $filename = $self->{repository}{workflows}{$datasetid}{$workflowid}{file};

	return $self->html_phrase( "title",
		filename => $self->{repository}->xml->create_text_node( $filename ),
	);
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

