
push @{$c->{fields}->{user}},

{
	name => 'name',
	type => 'name',
	render_order => 'gf',
},

{
	name => 'dept',
	type => 'text',
},

{
	name => 'org',
	type => 'text',
},

{
	name => 'address',
	type => 'longtext',
	input_rows => 5,
},

{
	name => 'country',
	type => 'text',
},

{
	name => 'hideemail',
	input_style => 'radio',
	type => 'boolean',
},

{
	name => 'url',
	type => 'url',
},
; 

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

