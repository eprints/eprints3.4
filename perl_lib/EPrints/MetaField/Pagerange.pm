######################################################################
#
# EPrints::MetaField::Pagerange
#
######################################################################
#
#
######################################################################

=pod

=for Pod2Wiki

=head1 NAME

B<EPrints::MetaField::Pagerange> - no description

=head1 DESCRIPTION

not done

=over 4

=cut

package EPrints::MetaField::Pagerange;

use EPrints::MetaField::Text;
@ISA = qw( EPrints::MetaField::Text );

use strict;

# note that this renders pages ranges differently from
# eprints 3.4.6
sub render_single_value
{
	my( $self, $session, $value ) = @_;

	my $frag = $session->make_doc_fragment;

	my( $from, $to ) = split_range( $value );

	if( defined $from && !defined $to ) {
		$frag->appendChild( $session->html_phrase( "lib/metafield/pagerange:from_page",
			from => $session->make_text( $from ),
			pagerange => $session->make_text( $value ),
		));
	} elsif( defined $from && defined $to ) {
		if( $from eq $to ) {
			$frag->appendChild( $session->html_phrase( "lib/metafield/pagerange:same_page",
				from => $session->make_text( $from ),
				to => $session->make_text( $to ),
				pagerange => $session->make_text( $value ),
			));
		} else {
			$frag->appendChild( $session->html_phrase( "lib/metafield/pagerange:range",
				from => $session->make_text( $from ),
				to => $session->make_text( $to ),
				pagerange => $session->make_text( $value ),
			));
		}
	} else {
		$frag->appendChild( $session->html_phrase( "lib/metafield/pagerange:other",
			pagerange => $session->make_text( $value )
		));
	}

	return $frag;
}

sub get_basic_input_elements
{
	my( $self, $session, $value, $basename, $staff, $obj, $one_field_component ) = @_;

	my @pages = undef;
	if( defined $value )
	{
		@pages = split /-/, $value;
		if ( $#pages > 2 )
		{
			use POSIX;
			my $middle = ceil( $#pages / 2 );
			@pages = $value =~ m{\A((?:[^-]+-){$middle})(.+)\z};
			$pages[0] =~ s/-\z//;
		}
	}
 	my $fromid = $basename."_from";
 	my $toid = $basename."_to";
		
	my $frag = $session->make_doc_fragment;

	$frag->appendChild( $session->render_noenter_input_field(
		class => "ep_form_text",
		name => $fromid,
		id => $fromid,
		value => $pages[0],
		size => 6,
		maxlength => 120,
		'aria-labelledby' => $self->get_labelledby( $basename ),
		'aria-describedby' => $self->get_describedby( $basename, $one_field_component ) ) );

	$frag->appendChild( $session->make_text(" ") );
	$frag->appendChild( $session->html_phrase( 
		"lib/metafield:to" ) );
	$frag->appendChild( $session->make_text(" ") );

	$frag->appendChild( $session->render_noenter_input_field(
		class => "ep_form_text",
		name => $toid,
		id => $toid,
		value => $pages[1],
		size => 6,
		maxlength => 120,
		'aria-labelledby' => $self->get_labelledby( $basename ),
                'aria-describedby' => $self->get_describedby( $basename, $one_field_component ) ) );

	return [ [ { el=>$frag } ] ];
}

sub get_basic_input_ids
{
	my( $self, $session, $basename, $staff, $obj ) = @_;

	return( $basename."_from", $basename."_to" );
}

sub is_browsable
{
	return( 1 );
}

sub form_value_basic
{
	my( $self, $session, $basename ) = @_;

	my $from = $self->EPrints::MetaField::form_value_basic( $session, $basename."_from" );	
	my $to = $self->EPrints::MetaField::form_value_basic( $session, $basename."_to" );

	if( !defined $to || $to eq "" )
	{
		return( $from );
	}
		
	return( $from . "-" . $to );
}

sub ordervalue_basic
{
	my( $self , $value ) = @_;

	unless( EPrints::Utils::is_set( $value ) )
	{
		return "";
	}

	my( $from, $to ) = split /-/, $value;

	$to = $from unless defined $to;

	# remove non digits
	$from =~ s/[^0-9]//g;
	$to =~ s/[^0-9]//g;

	# set to zero if undef
	$from = 0 if $from eq "";
	$to = 0 if $to eq "";

	return sprintf( "%08d-%08d", $from, $to );
}

sub render_search_input
{
	my( $self, $session, $searchfield ) = @_;
	
	return $session->render_input_field(
				class => "ep_form_text",
				name=>$searchfield->get_form_prefix,
				value=>$searchfield->get_value,
				size=>9,
				maxlength=>100,
				'aria-labelledby' => $searchfield->get_form_prefix . "_label" );
}

=item ( $from, $to ) = Pagerange::split_range( $range )

Splits the given C<$range> into its first page and last page. If either of
these values cannot be gleaned from this eprint they will instead return
C<undef>.

=cut
sub split_range
{
	my( $range ) = @_;
	return( undef, undef ) unless defined $range;

	# If there are leading zeros it's probably electronic (so unsplit)
	if( $range =~ /^([1-9]\d*)$/ ) {
		return( $1, undef );
	} elsif( my( $from, $to ) = $range =~ m/^([^-]+)-(.+)$/ ) {
		# If there are multiple '-' we assume that the one which defines the
		# range is in the middle of the string and split on that one.
		my $count = $range =~ tr/-//;
		if( $count > 1 ) {
			my $middle = int( ($count - 1) / 2 );
			# Capture `$middle` instances of '<text>-' followed by '<text>' as
			# the first group, with everything after the following hyphen in
			# the second group.
			( $from, $to ) = $range =~ m/^((?:[^-]+-){$middle}[^-]+)-(.+)$/;
		}

		return( $from, $to );
	} else {
		return( undef, undef );
	}
}

######################################################################
1;

=back

=head1 COPYRIGHT

=begin COPYRIGHT

Copyright 2023 University of Southampton.
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

