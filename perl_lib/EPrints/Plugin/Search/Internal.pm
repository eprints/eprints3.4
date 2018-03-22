=head1 NAME

EPrints::Plugin::Search::Internal

=cut

package EPrints::Plugin::Search::Internal;

@ISA = qw( EPrints::Search EPrints::Plugin::Search );

use strict;

sub new
{
	my( $class, %params ) = @_;

	# default to simple search
	if( !defined $params{search_fields} && defined $params{dataset} )
	{
		my $sconf;
		if( $params{dataset}->id eq "archive" )
		{
			$sconf = $params{repository}->config( "search", "simple" );
		}
		else
		{
			$sconf = $params{dataset}->_simple_search_config;
		}
		%params = (
			%$sconf,
			%params,
		);
	}

	# needs a bit of hackery to wrap EPrints::Search
	my $self = defined $params{dataset} ?
		$class->SUPER::new( %params ) :
		$class->EPrints::Plugin::Search::new( %params )
	;

	$self->{id} = $class;
	$self->{id} =~ s/^EPrints::Plugin:://;
	$self->{qs} = 0; # internal search is default
	$self->{search} = [qw( simple/* advanced/* )];
	$self->{session} = $self->{repository} = $self->{session} || $self->{repository};

	return $self;
}

sub can_search
{
	my( $self, $format ) = @_;

	return 1; # "probably"
}

sub from_form
{
	my( $self ) = @_;

	my @problems;

	foreach my $sf ($self->get_non_filter_searchfields)
	{
		my $problem = $sf->from_form;
		push @problems, $problem if defined $problem;
	}

	return @problems;
}

sub from_string
{
	my( $self, $exp ) = @_;

	$self->SUPER::from_string( $exp );

	return 1;
}

sub from_string_raw
{
	my( $self, $exp ) = @_;

	$self->SUPER::from_string_raw( $exp );

	return 1;
}

sub render_simple_fields
{
	my( $self, %opts ) = @_;

	return ($self->get_non_filter_searchfields)[0]->render( %opts );
}

sub execute { shift->perform_search( @_ ) }

sub describe
{
	my( $self ) = @_;

	return $self->get_conditions->describe . "\n" . $self->get_conditions->sql(
			session => $self->{session},
			dataset => $self->{dataset},
		);
}

1;

=head1 COPYRIGHT

=for COPYRIGHT BEGIN

Copyright 2018 University of Southampton.
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

