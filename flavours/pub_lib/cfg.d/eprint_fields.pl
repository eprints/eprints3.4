
push @{$c->{fields}->{eprint}},

{
	name => 'creators',
	type => 'compound',
	multiple => 1,
	fields => [
		{
			sub_name => 'name',
			type => 'name',
			hide_honourific => 1,
			hide_lineage => 1,
			family_first => 1,
		},
		{
			sub_name => 'id',
			type => 'text',
			input_cols => 20,
			allow_null => 1,
		}
	],
	input_boxes => 4,
},

{
	name => 'contributors',
	type => 'compound',
	multiple => 1,
	fields => [
		{
			sub_name => 'type',
			type => 'namedset',
			set_name => "contributor_type",
		},
		{
			sub_name => 'name',
			type => 'name',
			hide_honourific => 1,
			hide_lineage => 1,
			family_first => 1,
		},
		{
			sub_name => 'id',
			type => 'text',
			input_cols => 20,
			allow_null => 1,
		},
	],
	input_boxes => 4,
},

{
	name => 'corp_creators',
	type => 'text',
	multiple => 1,
},

{
	name => 'title',
	type => 'longtext',
	input_rows => 3,
	make_single_value_orderkey => 'EPrints::Extras::english_title_orderkey',
},

{
	name => 'ispublished',
	type => 'set',
	options => [qw(
		pub
		inpress
		submitted
		unpub
	)],
	input_style => 'medium',
},

{
	name => 'subjects',
	type => 'subject',
	multiple => 1,
	top => 'subjects',
	browse_link => 'subjects',
},

{
	name => 'divisions',
	type => 'subject',
	multiple => 1,
	top => 'divisions',
	browse_link => 'divisions',
},

{
	name => 'keywords',
	type => 'longtext',
	input_rows => 2,
},

{
	name => 'note',
	type => 'longtext',
	input_rows => 3,
},

{
	name => 'suggestions',
	type => 'longtext',
	render_value => 'EPrints::Extras::render_highlighted_field',
	export_as_xml => 0, 
},

{
	name => 'abstract',
	type => 'longtext',
	input_rows => 10,
},

{
	name => 'date',
	type => 'date',
	min_resolution => 'year',
},

{
	name => 'date_type',
	type => 'set',
	options => [qw(
		published
		submitted
		completed
	)],
	input_style => 'medium',
},

{
	name => 'publisher',
	type => 'text',
},

{
        name => 'official_url',
        type => 'url',
        render_value => 'EPrints::Extras::render_url_truncate_end',
},

{
	name => 'id_number',
	type => 'text',
	render_value => 'EPrints::Extras::render_possible_doi',
},

{
	name => 'data_type',
	type => 'text',
},

{
	name => 'copyright_holders',
	type => 'text',
	multiple => 1,
	input_boxes => 1,
},

;

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

