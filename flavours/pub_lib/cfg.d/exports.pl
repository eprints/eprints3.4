$c->{export}->{publication_status_type_override} = 1;

# Below is an equivalent configuration function to $user->is_staff.  If you need to allow access to 'staff' restricted Export plugins to users other than admins and editors, then uncomment the configuration function below and edit as appropriate.
#c->{export}->{staff_check} = sub {
#
#   my ( $session, $user ) = @_;
#
#   return $user->has_role( "admin" ) || $user->has_role( "editor" );
#;
