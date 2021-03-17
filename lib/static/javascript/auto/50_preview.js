function EPJS_ShowPreview( e, preview_id, position = 'right' ) 
{
	var box = $(preview_id);

	box.style.display = 'block';
	box.style.zIndex = 1000;

	var img = $(preview_id+'_img');
        box.style.width = img.width + 'px';

	// Note can find triggering element using findElement
	var elt = Event.findElement( e );

	if ( position == 'left' )
	{
		Element.clonePosition( box, elt, { setWidth:false, offsetLeft: -(Element.getWidth( box )) } );
	}
	else
	{
		Element.clonePosition( box, elt, { setWidth:false, offsetLeft: (Element.getWidth( elt )) } );
	}
}

function EPJS_HidePreview( e, preview_id )
{
	$(preview_id).style.display = 'none';
}
