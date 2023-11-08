if ( defined $c->{export_privacy} && $c->{export_privacy} )
{
	$c->{plugins}->{"Export::JSON"}->{params}->{visible} = "staff";
	$c->{plugins}->{"Export::XML"}->{params}->{visible} = "staff";
	$c->{plugins}->{"Export::RDFN3"}->{params}->{visible} = "staff";
	$c->{plugins}->{"Export::RDFNT"}->{params}->{visible} = "staff";
	$c->{plugins}->{"Export::RDFXML"}->{params}->{visible} = "staff";
	$c->{plugins}->{"Export::CSV"}->{params}->{visible} = "staff";
	$c->{plugins}->{"Export::Simple"}->{params}->{visible} = "staff";
}
