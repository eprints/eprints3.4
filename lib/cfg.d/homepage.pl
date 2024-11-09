$c->{homepage}->{menu} = {
	#nav_attrs => { id => 'ep-homepage-menu', 'aria-label' => 'Homepage Menu' },
	#ul_attrs => { class => "ep_block_menu", role => "menu" },
	options => [
		{ id => 'latest', appears => 100, url => '/cgi/latest' },
		{ id => 'search', appears => 200, url => '/cgi/search/advanced' },
		{ id => 'browse', appears => 300, url => '/view/subjects/' },
		{ id => 'about', appears => 400, url => '/information.html' },
		{ id => 'policies', appears => 500, url => '/policies.html' },
	],
};
