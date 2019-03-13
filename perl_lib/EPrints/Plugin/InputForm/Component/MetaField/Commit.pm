=head1 NAME

EPrints::Plugin::InputForm::Component::MetaField::Commit

=cut

package EPrints::Plugin::InputForm::Component::MetaField::Commit;

use EPrints::Plugin::InputForm::Component;

@ISA = ( "EPrints::Plugin::InputForm::Component" );

use strict;

sub new
{
	my( $class, %opts ) = @_;

	my $self = $class->SUPER::new( %opts );

	$self->{name} = "MetaField::Commit";
	$self->{visible} = "all";

	return $self;
}

sub update_from_form
{
	my( $self, $processor ) = @_;

	my $repo = $self->{session};
	my $workflow = $self->{workflow};
	my $dataobj = $workflow->{item};

	if( $repo->internal_button_pressed )
	{
		my $internal = $self->get_internal_button;

		if( $internal eq "save" )
		{
			$processor->{screenid} = "MetaField::View";
		}
		elsif( $internal eq "commit" )
		{
			$dataobj->add_to_repository();
			my $plugin = $self->{session}->plugin( "Screen::Admin::Reload",
				processor => $processor
			);
			if( defined $plugin )
			{
				local $self->{processor}->{screenid};
				$plugin->action_reload_config;
			}
			$dataobj->remove();
			$processor->{screenid} = "MetaField::Listing";
			$processor->{notes}->{dataset} = $self->{session}->dataset( $dataobj->value( "mfdatasetid" ) );
		}
	}

	return;
}

=item $content = $component->render_content()

Returns the DOM for the content of this component.

=cut

sub render_content
{
	my( $self ) = @_;

	my $repo = $self->{session};
	my $xml = $repo->xml;
	my $workflow = $self->{workflow};
	my $dataobj = $workflow->{item};

	my $frag = $xml->create_document_fragment;

	my @problems = @{$dataobj->validate()};

	for(@problems)
	{
		$frag->appendChild( $repo->render_message( "error", $_ ) );
	}

	if( !@problems )
	{
		my $pre = $xml->create_element( "pre" );
		$frag->appendChild( $pre );
		$pre->appendChild( $xml->create_text_node( $dataobj->dump ) );
	}

	my %buttons = ( _order=>[], _class=>"ep_form_button_bar" );

	my $name = $self->{prefix}."_save";
	$buttons{$name} = $repo->phrase( "lib/submissionform:action_save" );
	push @{$buttons{_order}}, $name;

	if( !@problems )
	{
		my $name = $self->{prefix} . "_commit";
		$buttons{$name} = $repo->phrase( "metafield:workflow:stage:commit:title" );
		push @{$buttons{_order}}, $name;
	}

	$frag->appendChild( $repo->render_internal_buttons( %buttons ) );

	return $frag;
}

1;

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

