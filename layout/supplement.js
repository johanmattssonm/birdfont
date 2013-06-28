function call (command) {
	document.title=command;
	document.title='done';
}

// MenuTab text fields
function update_text_fields () {
	mess = 'glyph_sequence:';
	mess += document.getElementById('glyph_sequence').value;
	call (mess);	
}

// DescriptionTab text fields
function update_name_fields () {
	mess = 'postscript_name:';
	mess += document.getElementById('postscript_name').value;
	call (mess);
	
	mess = 'name:';
	mess += document.getElementById('name').value;
	call (mess);
	
	mess = 'subfamily:';
	mess += document.getElementById('subfamily').value;
	call (mess);

	mess = 'full_name:';
	mess += document.getElementById('full_name').value;
	call (mess);

	mess = 'unique_identifier:';
	mess += document.getElementById('unique_identifier').value;
	call (mess);
	
	mess = 'version:';
	mess += document.getElementById('version').value;
	call (mess);

	mess = 'description:';
	mess += document.getElementById('description').value;
	call (mess);
	
	mess = 'copyright:';
	mess += document.getElementById('copyright').value;
	call (mess);
	
}
