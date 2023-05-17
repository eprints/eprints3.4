######################################################################
#
#  Manipulate attributes for create_element
#
###################################################################### 
#
# An example subroutine for maniputlating attributes before elements are created
# This function is called from perl_lib/EPrints/XML.pm sub create_element if present in config
#
# The function example below will allow for attributes to be manipulated with the following structure
#       1. Look for the attribute value in config i.e. $c
#       2. Apply any changes to that specific value i.e. either replace or add to it
#       3. If there are multiple attribute values it will cycle through them and repeat the above
#
# Examples:
# - A class addition, useful for adding framework css classes
#	push @{$c->{config_attrs}->{class}->{"ep_search_controls"}}, ({ class => "framework-class", _change_action => "replace" });
#
# - A change to the elements id attribute, useful for overwriting layered css
#	push @{$c->{config_attrs}->{id}->{"ep_id_for_elem"}}, ({ id => "new_id", _change_action => "replace" });
#
# - Adding a new data attribute, useful for adding in accessibility attributes
#	push @{$c->{config_attrs}->{id}->{"ep_id_for_elem"}}, ({ "data_info" => "data-info" });
#
# - Creating a classname based on user account type
#	push @{$c->{config_attrs}->{class}->{"ep_page_thing"}}, ({ class => sub {
#		my $repo = shift @_;
#
#		if ( defined $repo->current_user && $repo->current_user->is_staff )
#		{
#			return "staff-member-class";
#		}
#		else
#		{
#			return "non-staff-class";
#		}
#		}, _change_action => "replace" });
#
######################################################################

$c->{build_node_attributes} = sub
{
	no warnings qw{ redefine };

	my ($repo, $name, $node, @attrs) = @_;

	my %attrs_in = @attrs;

	sub resolve_value {
		my ( $repo, $val ) = @_;

		return( 0 ) if( !defined $val );

		ref( $val ) eq "CODE" ? return $val->( $repo ) : return $val;
	}
	
	for my $key_in ( keys %attrs_in )
	{
		my $value_in = $attrs_in{$key_in};
		if ( EPrints::Utils::is_set( $value_in ) )
		{
			for my $value_in_single ( split(" ", $value_in) )
			{
				my $attrs_config = $repo->config( "config_attrs", "$key_in", $value_in_single );
				if ( defined $attrs_config )
				{
					for ( @$attrs_config )
					{
						my %attr_config = %$_;
						for my $key_config ( keys %attr_config )
						{
							next if ( $key_config =~ m/^_{1}/ );

							my $value_config = resolve_value( $repo, $attr_config{$key_config} );
							if ( exists $attrs_in{$key_config} && EPrints::Utils::is_set( $attr_config{_change_action} ) && $attr_config{_change_action} eq "add" )
							{
								$attrs_in{$key_config} = $attrs_in{$key_config}." ".$value_config;
							}
							else
							{
								$attrs_in{$key_config} = $value_config;
							}
						}
					}
				}
			}
		}
	}

	@attrs = %attrs_in;
	return @attrs;
};

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
