use EPrints::DataObj::EPM;
use EPrints::EPM::Source;

$c->{datasets}->{epm} = {
        sqlname => "epm",
        class => "EPrints::DataObj::EPM",
        virtual => 1,
};



# EPM Configuration File
$c->{epm}->{sources} = [] if !defined $c->{epm}->{sources};

# Define the EPM sources
push @{$c->{epm}->{sources}}, {
                name => "EPrints Bazaar",
                base_url => "https://bazaar.eprints.org",
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

