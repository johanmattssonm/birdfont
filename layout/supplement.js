function call (command) {
	document.title=command;
	document.title='done';
}

function update_export_settings () {
	mess = 'export_name:';
	mess += document.getElementById('fontname').value;
	call (mess);
}
