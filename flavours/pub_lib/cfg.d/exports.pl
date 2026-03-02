$c->{export}->{publication_status_type_override} = 1;

$c->{export}->{staff_check} = sub {

	my ( $session, $user ) = @_;

	return $user->get_type eq "editor" || $user->get_type eq "admin" || $user->get_type eq "local_admin"; 
};
