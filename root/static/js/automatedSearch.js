document.onmouseup = mouse_up;
var prev_selected = '';

function mouse_up()
{
	var txt = '';

	var newWindow;

	if (window.getSelection)
	{
		txt = window.getSelection();
	}
	else if (document.getSelection)
	{
		txt = document.getSelection();
	}
	else if (document.selection)
	{
		txt = document.selection.createRange().text;
	}
	else return;

	if(txt != "" && txt.toString().length > 2 && txt.toString().length < 101 && prev_selected != txt.toString())
	{
		prev_selected = txt.toString();
		dm_popup(0, 1000, event);
//newWindow = window.open('http://www.google.com/search?hl=en&lr=&q=definition: '+txt.toString()+' &btnI=745');	}
	}
}

