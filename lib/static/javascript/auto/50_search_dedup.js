document.addEventListener('DOMContentLoaded', () => {
	// Make all search buttons auto-disable when they are pressed to prevent
	// multiple repeated requests being sent when the user isn't sure whether
	// their click went through and tries again, exacerbating DDOS attacks.
	document.getElementsByName('_action_search').forEach((element) => {
		element.addEventListener('click', () => {
			// By only disabling the element after 0 ticks it allows the current
			// press to go through while still blocking future presses.
			setTimeout(() => { element.disabled = true }, 0);
		});
	});
});

// Make sure we remove the `disabled` tag every time we load the page
//
// This is required because when you use the back arrow the browser just uses a
// cached version of the previous page so will included the `disabled` tag in
// it. This does however trigger `pageshow` so we can remove them once it loads.
window.addEventListener('pageshow', () => {
	document.getElementsByName('_action_search').forEach((element) => {
		element.disabled = false;
	});
});

