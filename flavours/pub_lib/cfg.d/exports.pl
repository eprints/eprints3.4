$c->{export}->{publication_status_type_override} = 1;

# Same as $user->is_staff
#c->{export}->{staff_check} = sub {
#
#   my ( $session, $user ) = @_;
#
#   return $user->has_role( "admin" ) || $user->has_role( "editor" );
#;
