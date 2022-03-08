######################################################################
#
# EPrints::CLIProcessor
#
######################################################################
#
#
######################################################################

=pod

=for Pod2Wiki

=head1 NAME

B<EPrints::CLIProcessor> - utility module supporting command-line 
scripts.

=head1 DESCRIPTION

Currently this module is just a 'handler' for import scripts. In 
future it may do more things to support the CLI (Command-Line 
Interface) to EPrints.

=head1 METHODS

=cut

package EPrints::CLIProcessor;

use strict;

use vars qw( %COLORS );

eval "use Term::ANSIColor qw()";
unless( $@ )
{
	%COLORS = (
		reset => "reset",
		error => "bold red on_black",
		warning => "bold yellow on_black",
	);
}

######################################################################
=pod

=over 4

=item EPrints::CLIProcessor::color( $type )

Returns boolean depending on whether $type is a permitted setting for 
the L<EPrints::CLIProcessor>.

=cut
######################################################################

sub color
{
	my( $type ) = @_;

	return exists $COLORS{$type} ? Term::ANSIColor::color( $COLORS{$type} ) : "";
}


######################################################################
=pod

=item $processor = EPrints::CLIProcessor->new( session => $session, %opts )

Create a new processor object. Supported options:

  scripted - backwards compatibility for import scripted interface
  epdata_to_dataobj - replace L</epdata_to_dataobj>
  message - replace L</message>

=cut
######################################################################

sub new
{
    my( $class, %self ) = @_;

    $self{wrote} = 0;
    $self{parsed} = 0;
	$self{ids} = [];

    bless \%self, $class;
}

######################################################################
=pod

=item $processor->add_message( $type, $msg )

Add a message for the user. C<$type> is C<error>, C<warning> or 
C<message>. C<$msg> is an XHTML fragment.

=cut
######################################################################

*add_message = \&message;
sub message
{
    my( $self, $type, $msg ) = @_;

	return $self->{message}( $type, $msg ) if defined $self->{message};

	print STDERR color($type);
	$msg = EPrints::Utils::tree_to_utf8( $msg );
	print STDERR "\u$type! $msg\n";
	print STDERR color('reset');
}

######################################################################
=pod

=item $dataobj = $processor->epdata_to_dataobj( $epdata, %opts )

Requests the handler create the new object from C<$epdata>.

=cut
######################################################################

sub epdata_to_dataobj
{
	my( $self, $epdata, %opts ) = @_;

	return $self->{epdata_to_dataobj}( $epdata, %opts ) if defined $self->{epdata_to_dataobj};

	return $opts{dataset}->create_dataobj( $epdata );
}

######################################################################
=pod

=item $processor->parsed( [ $epdata ] )

Register a parsed event, optionally with C<$epdata>.

=cut
######################################################################

sub parsed
{
    my( $self, $epdata ) = @_;

    $self->{parsed}++;

	if( $self->{scripted} )
	{
		print "EPRINTS_IMPORT: ITEM_PARSED\n";
	}
}

######################################################################
=pod

=item $processor->object( $dataset, $dataobj )

Register a new object event in C<$dataset> with new object 
C<$dataobj>.

=cut
######################################################################

sub object
{
    my( $self, $dataset, $dataobj ) = @_;

    $self->{wrote}++;

	push @{$self->{ids}}, $dataobj->get_id;

	if( $self->{session}->get_noise > 1 )
	{
		print STDERR "Imported ".$dataset->id." ".$dataobj->get_id."\n";
	}

	if( $self->{scripted} )
	{
		print "EPRINTS_IMPORT: ITEM_IMPORTED ".$dataobj->get_id."\n";
	}
}

1;

=back

=head1 COPYRIGHT

=begin COPYRIGHT

Copyright 2022 University of Southampton.
EPrints 3.4 is supplied by EPrints Services.

http://www.eprints.org/eprints-3.4/

=end COPYRIGHT

=begin LICENSE

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

=end LICENSE

