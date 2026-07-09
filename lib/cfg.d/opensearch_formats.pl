# This config option can be used to restrict which Export formats are offered/allowed in the opensearchdescription and opensearch interface.
# If the option isn't defined, all export plugins that are visible to 'all' (if no user is present) or 'staff' (if an appropriate user is 
# present) will be listed/supported.
# Please include all formats that public or staff should have access to. The all/staff filters will still be used to refine which are offered.
# 
# At a minimum, the default 'Atom' format should be offered.
# $c->{opensearch}->{formats} = [qw( Atom BibTeX DC EndNote HTML METS )];
#
#
# OpenSearch search configuration
# If your 'simple search' doesn't include a config with:
#     id => 'q'
# the OpenSearch interface will fall back to the first defined simple search definition.
# If you want a specific search config to be used, you can specify the id in the following
# config option:
# $c->{opensearch}->{simple_search_id} = 'metadata';
#
# The above example would use a search defined in
# $c->{search}->{simple}->{search_fields} 
# with an id of 'metadata'.
