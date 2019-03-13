# Any changes made here will be lost!
#
# Copy this file to:
# archives/[archiveid]/cfg/cfg.d/
#
# And then make any changes.

$c->{datasets}->{eprint}->{search}->{staff} =
{
	search_fields => [
		{ meta_fields => [qw( eprintid )] },
		{ meta_fields => [qw( userid.username )] },
		{ meta_fields => [qw( userid.name )] },
		{ meta_fields => [qw( eprint_status )], default=>"archive buffer" },
		{ meta_fields => [qw( dir )] },
		@{$c->{search}{advanced}{search_fields}},
	],
	preamble_phrase => "Plugin/Screen/Staff/EPrintSearch:description",
	title_phrase => "Plugin/Screen/Staff/EPrintSearch:title",
	citation => "result",
	page_size => 20,
	order_methods => {
		"byyear" 	 => "-date/creators_name/title",
		"byyearoldest"	 => "date/creators_name/title",
		"byname"  	 => "creators_name/-date/title",
		"bytitle" 	 => "title/creators_name/-date"
	},
	default_order => "byyear",
	show_zero_results => 1,
	staff => 1,
};

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

