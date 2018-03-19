/* ===============
   RicksACCOrdiON v2 
   =============== */
   
jQuery(document).ready(function(){
	jQuery('.content_opener').not('.content_open').hide();
	racoon();
});
var racoon = function(){
	jQuery('.heading_opener').click(function(){
	var current_content = jQuery(this).next('.content_opener');
	var current_heading = jQuery(this).find('.heading_title');
	var heading_opener = jQuery(this);
		jQuery('.heading_title').not(current_heading).removeClass('raccopen');
		current_heading.toggleClass('raccopen');
		if(!heading_opener.hasClass('alt')){heading_opener.toggleClass('alt');current_content.slideToggle('fast');}
		else{current_content.slideToggle('fast', function(){
			heading_opener.toggleClass('alt');
		});
		}
		return false;
	});
}
//end accordion//

