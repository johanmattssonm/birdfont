function call (command) {
	document.title=command;
	document.title='done';
}

function update_text_fields () {
	mess = 'export_name:';
	mess += document.getElementById('fontname').value;
	call (mess);
	
	mess = 'glyph_sequence:';
	mess += document.getElementById('glyph_sequence').value;
	call (mess);	
}
