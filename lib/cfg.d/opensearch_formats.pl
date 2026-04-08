# This config option can be used to restrict which Export formats are offered/allowed in the opensearchdescription and opensearch interface.
# If the option isn't defined, all export plugins that are visible to 'all' (if no user is present) or 'staff' (if an appropriate user is 
# present) will be listed/supported.
# Please include all formats that public or staff should have access to. The all/staff filters will still be used to refine which are offered.
# 
# At a minimum, the default 'Atom' format should be offered.
# $c->{opensearch}->{formats} = [qw( Atom BibTeX DC EndNote HTML METS )];
