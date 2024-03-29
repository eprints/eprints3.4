=head1 NAME

EPrints::Plugin::Event::Indexer

=cut

package EPrints::Plugin::Event::Indexer;

@ISA = qw( EPrints::Plugin::Event );

use strict;

sub index
{
	my( $self, $dataobj, @fieldnames ) = @_;

	return if !defined $dataobj;
	my $dataset = $dataobj->get_dataset;

	my @fields;
	for(@fieldnames)
	{
		next unless $dataset->has_field( $_ );
		push @fields, $dataset->get_field( $_ );
	}

	return $self->_index_fields( $dataobj, \@fields );
}

sub index_all
{
	my( $self, $dataobj ) = @_;

	return if !defined $dataobj;
	my $dataset = $dataobj->get_dataset;

	return $self->_index_fields( $dataobj, [$dataset->get_fields] );
}

sub removed
{
	my( $self, $datasetid, $id ) = @_;

	my $dataset = $self->{session}->dataset( $datasetid );
	return if !defined $dataset;

	my $rc = $self->{session}->run_trigger( EPrints::Const::EP_TRIGGER_INDEX_REMOVED,
		dataset => $dataset,
		id => $id,
	);
	return if defined $rc && $rc eq EPrints::Const::EP_TRIGGER_DONE;

	foreach my $field ($dataset->fields)
	{
		EPrints::Index::remove( $self->{session}, $dataset, $id, $field->name );
	}

	return;
}

sub _index_fields
{
	my( $self, $dataobj, $fields ) = @_;

	my $session = $self->{session};
	my $dataset = $dataobj->get_dataset;

	my $rc = $session->run_trigger( EPrints::Const::EP_TRIGGER_INDEX_FIELDS,
		dataobj => $dataobj,
		fields => $fields,
	);
	return if defined $rc && $rc eq EPrints::Const::EP_TRIGGER_DONE;

	EPrints::Index::remove( $session, $dataset, $dataobj->get_id,
		[map { $_->name } @$fields]
	);

	foreach my $field (@$fields)
	{
		next unless( $field->get_property( "text_index" ) );

		my $value = $field->get_value( $dataobj );
		next unless EPrints::Utils::is_set( $value );	

		EPrints::Index::add( $session, $dataset, $dataobj->get_id, $field->get_name, $value );
	}

	return;
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

