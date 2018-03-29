
push @{$c->{fields}->{eprint}},

{
	name => 'full_text_status',
	type => 'set',
	options => [qw(
		public
		restricted
		none
	)],
	input_style => 'medium',
},

{
	name => 'monograph_type',
	type => 'set',
	options => [qw(
		technical_report
		project_report
		documentation
		manual
		working_paper
		discussion_paper
		other
	)],
	input_style => 'medium',
},

{
	name => 'pres_type',
	type => 'set',
	options => [qw(
		paper
		lecture
		speech
		poster
		keynote
		other
	)],
	input_style => 'medium',
},

{
	name => 'series',
	type => 'text',
},

{
	name => 'publication',
	type => 'text',
},

{
	name => 'volume',
	type => 'text',
	maxlength => 6,
},

{
	name => 'number',
	type => 'text',
	maxlength => 6,
},

{
	name => 'article_number',
	type => 'text',
	maxlength => 10,
},

{
	name => 'place_of_pub',
	type => 'text',
},

{
	name => 'pagerange',
	type => 'pagerange',
},

{
	name => 'pages',
	type => 'int',
	maxlength => 6,
	sql_index => 0,
},

{
	name => 'event_title',
	type => 'text',
},

{
	name => 'event_location',
	type => 'text',
},

{
	name => 'event_dates',
	type => 'text',
},

{
	name => 'event_type',
	type => 'set',
	options => [qw(
		conference
		workshop
		other
	)],
	input_style => 'medium',
},

{
	name => 'patent_applicant',
	type => 'text',
},

{
	name => 'institution',
	type => 'text',
},

{
	name => 'department',
	type => 'text',
},

{
	name => 'thesis_type',
	type => 'set',
	options => [qw(
		diploma
		masters
		doctoral
		postdoctoral
		other
	)],
	input_style => 'medium',
},

{
	name => 'thesis_name',
	type => 'set',
	options => [qw(
		mphil
		phd
		dphil
		other
	)],
	input_style => 'medium',
},

{
	name => 'refereed',
	type => 'boolean',
	input_style => 'radio',
},

{
	name => 'isbn',
	type => 'text',
},

{
	name => 'issn',
	type => 'text',
},

{
	name => 'book_title',
	type => 'text',
},

{
	name => 'edition',
	type => 'text',
},

{
	name => 'editors',
	type => 'compound',
	multiple => 1,
	fields => [
		{
			hide_honourific => 1,
			type => 'name',
			hide_lineage => 1,
			family_first => 1,
			sub_name => 'name',
		},
		{
			input_cols => 20,
			allow_null => 1,
			type => 'text',
			sub_name => 'id',
		}
	],
	input_boxes => 4,
},

{
	name => 'related_url',
	type => 'compound',
	multiple => 1,
	render_value => 'EPrints::Extras::render_related_url',
	fields => [
		{
			sub_name => 'url',
			type => 'url',
			input_cols => 40,
		},
		{
			sub_name => 'type',
			type => 'set',
			options => [qw(
				pub
				author
				org
			)],
		}
	],
	input_boxes => 1,
	input_ordered => 0,
},

{
	name => 'referencetext',
	type => 'longtext',
	input_rows => 15,
},

{
	name => 'funders',
	type => 'text',
	multiple => 1,
	input_boxes => 1,
},

{
	name => 'projects',
	type => 'text',
	multiple => 1,
	input_boxes => 1,
},

{
	name => 'output_media',
	type => 'text',
},

{
	name => 'num_pieces',
	type => 'int',
},

{
	name => 'composition_type',
	type => 'text',
},

{
	name => 'pedagogic_type',
	type => 'set',
	options => [qw(
		presentation
		activity
		case
		enquiry
		problem
		collaboration
		communication
	)],
},

{
	name => 'completion_time',
	type => 'text',
},

{
	name => 'task_purpose',
	type => 'longtext',
},

{
	name => 'skill_areas',
	type => 'text',
	multiple => 1,
	input_boxes => 1,
},

{
	name => 'learning_level',
	type => 'text',
},

{
	name => 'gscholar',
	type => 'compound',
	volatile => 1,
	fields => [
		{ sub_name => 'impact', type => 'int', },
		{ sub_name => 'cluster', type => 'id', },
		{ sub_name => 'datestamp', type => 'time', },
	],
	sql_index => 0,
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

