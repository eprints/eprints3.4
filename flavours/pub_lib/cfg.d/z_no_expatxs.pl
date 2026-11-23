# If XML::SAX::ExpatXS is not installed disable these imports. (Imports that
# use EPrints::XML::event_parse do not need it: it falls back to a hardened
# XML::LibXML::SAX parser.)
use Module::Load::Conditional qw(check_install);
if ( !check_install(module => "XML::SAX::ExpatXS") ) 
{
	$c->{plugins}->{"Import::PubMedID"}->{params}->{disable} = 1;
}
