function call (command) {
	document.title=command;
	document.title='done';
}

function update_export_settings () {

	var mess = 'export_svg:';
	
	var cb = document.getElementById('svg');
	
	if(cb.checked) {
		mess += 'true';
	} else {
		mess += 'false';
	}
	call (mess);
			
	mess = 'export_ttf:';			
	if(document.getElementById('ttf').checked) {
		mess += 'true';
	} else {
		mess += 'false';
	}
	call (mess);

	mess = 'export_name:';
	mess += document.getElementById('fontname').value;
	call (mess);
}
