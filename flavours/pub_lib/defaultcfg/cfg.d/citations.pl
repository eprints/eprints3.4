##List Dataset and Fields##
$c->{datasets}->{citation} = {
        class => "EPrints::DataObj::Citation",
        sqlname => "citation",
        index => 0,
};
$c->{citation_caching}->{enabled} = 0;
