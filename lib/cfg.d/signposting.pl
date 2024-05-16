# Specify export plugins that can be used in Signposting
$c->{plugins}->{"Export::JSON"}->{params}->{signposting} = 1;
$c->{plugins}->{"Export::XML"}->{params}->{signposting} = 1;
