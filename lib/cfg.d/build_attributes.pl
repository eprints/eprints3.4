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
#       4. Finally it will add any extra attributes that are found within the config hash
#
# Examples:
# - A class addition, useful for adding framework css classes
#       $c->{config_class}->{"ep_something"} = { _class => "new-class", _action => "add" };
#
# - A change to the elements id attribute, useful for overwriting layered css
#       $c->{config_id}->{"ep_phraseedit_addbar"} = { _id => "my_new_id", _change_action => "replace" };
#
# - Adding a new data attribute, useful for addding in accessibility attributes
#       $c->{config_class}->{"ep_inaccessibile"} = { data-accessibility => "value" };
#
# - Creating a classname based on user account type
#	$c->{config_class}->{"ep_page_thing"} = { _class => sub {
#                                        my $repo = shift @_;
#
#                                        if ( defined $repo->current_user && $repo->current_user->is_staff )
#                                        {
#                                                return "staff-member-class";
#                                        }
#                                        else
#                                        {
#                                                return "non-staff-class";
#                                        }
#                                },
#                                _change_action => "replace" };
#
######################################################################

=pod
$c->{build_node_attributes} = sub
{
        my ($repo, $name, $node, @attrs) = @_;

        my @new_attrs = ();

	sub resolve_value {
		my ( $repo, $val ) = @_;

		return( 0 ) if( !defined $val );

		ref( $val ) eq "CODE" ? return $val->( $repo ) : return $val;
	}

        while(my( $key, $value ) = splice(@attrs,0,2))
        {
		if ( defined $value && $value ne "" )
		{
                        my $build_value = "";
                        for my $core_value ( split(" ", $value) )
                        {
                                my $config_attribute = $repo->config( "config_$key", $core_value );
                                if ( defined $config_attribute->{"_$key"} )
                                {
					my $resolved_value = resolve_value( $repo, $config_attribute->{"_$key"} );
                                        if ( $config_attribute->{_change_action} eq "replace" )
                                        {
                                                $core_value = $resolved_value;
                                        }
                                        elsif ( $config_attribute->{_change_action} eq "add" )
                                        {
                                                $core_value = $core_value." ".$resolved_value;
                                        }
                                }
                                $build_value = $build_value." ".$core_value;

                                # Any extra attributes in the config should be added here	
                                while( my( $config_key, $config_value ) = each %$config_attribute )
                                {
					$config_value = resolve_value( $repo, $config_value );
                                        push @new_attrs, ( $config_key, $config_value ) if !( $config_key =~ m/^_{1}/ );
                                }
                        }
                        $build_value =~ s/^\s{1}//;
			push @new_attrs, ( $key, $build_value );
		}
		else
		{
			push @new_attrs, ( $key, $value );
		}
        }

        return @new_attrs;
};
=cut

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
