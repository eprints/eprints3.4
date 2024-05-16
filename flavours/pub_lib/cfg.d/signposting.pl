# Specify export plugins that can be used in Signposting
$c->{plugins}->{"Export::BibTeX"}->{params}->{signposting} = 1;
$c->{plugins}->{"Export::DC"}->{params}->{signposting} = 1;
$c->{plugins}->{"Export::JSON"}->{params}->{signposting} = 1;
$c->{plugins}->{"Export::XML"}->{params}->{signposting} = 1;
