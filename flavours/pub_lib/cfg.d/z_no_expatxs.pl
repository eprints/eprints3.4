# If XML::SAX::ExpatXS is not installed disable XML import. 
use Module::Load::Conditional qw(check_install);
if ( !check_install(module => "XML::SAX::ExpatXS") ) 
{
    $c->{plugins}->{"Import::XML"}->{params}->{disable} = 1;
	$c->{plugins}->{"Import::ISIWoKXML"}->{params}->{disable} = 1;
	$c->{plugins}->{"Import::PubMedID"}->{params}->{disable} = 1;
    $c->{plugins}->{"Import::PubMedXML"}->{params}->{disable} = 1;
    $c->{plugins}->{"Import::DefaultXML"}->{params}->{disable} = 1;
}
