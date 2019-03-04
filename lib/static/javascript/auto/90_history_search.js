function validateHistorySearch()
{
	//reset warning div
	var warning = document.getElementById('ep_messages');
	var warning_content = document.getElementById('warning_content');
	warning.className = "history_warning";
	warning_content.innerHTML = "";

	var problems = [];

	var start_date_string = document.getElementById('start_date').value;
	var end_date_string = document.getElementById('end_date').value;

	var date_re = /^(\d{4})-?(\d{1,2})?-?(\d{1,2})?$/;

	var start_date_result = date_re.test(start_date_string);
	var end_date_result = date_re.test(end_date_string);
	
	if( start_date_string != "" && !start_date_result )
	{
		problems.push("Invalid start date");
	}
	if( end_date_string != "" && !end_date_result )
	{
		problems.push("Invalid end date");
	}	

	var start_date = new Date(start_date_string);
	var end_date = new Date(end_date_string);
	if( end_date <= start_date )
	{
		problems.push("End date must be after start date");
	}

	if( problems.length == 0 )
	{
		return true;
	}
	else
	{
		warning.classList.add("show");
		var ul = document.createElement('ul');
		for( var i = 0; i < problems.length; i++)
		{
			var li = document.createElement('li');
			li.appendChild( document.createTextNode(problems[i]) );
			ul.appendChild(li);		
		}
		warning_content.appendChild(ul);

		return false;
	}

	
	
}
