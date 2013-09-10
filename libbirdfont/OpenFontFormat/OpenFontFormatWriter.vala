/*
    Copyright (C) 2012, 2013 Johan Mattsson

    This library is free software; you can redistribute it and/or modify 
    it under the terms of the GNU Lesser General Public License as 
    published by the Free Software Foundation; either version 3 of the 
    License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful, but 
    WITHOUT ANY WARRANTY; without even the implied warranty of 
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
    Lesser General Public License for more details.
*/

namespace BirdFont {

class OpenFontFormatWriter : Object  {

	DataOutputStream os;
	DirectoryTable directory_table;
	
	public static Font font;
	
	public OpenFontFormatWriter () {
		directory_table = new DirectoryTable ();
	}
	
	public static Font get_current_font () {
		return font;
	}
	
	public void open (File file) throws Error {
		assert (!is_null (file));
		
		if (file.query_exists ()) {
			warning ("File exists in export.");
			throw new FileError.EXIST("OpenFontFormatWriter: file exists.");
		}
		
		os = new DataOutputStream(file.create (FileCreateFlags.REPLACE_DESTINATION));
	}
	
	public void write_ttf_font (Font nfont) throws Error {
		long dl;
		uint8* data;
		unowned List<Table> tables;
		FontData fd;
		uint l;

		font = nfont;
				
		directory_table.process ();	
		tables = directory_table.get_tables ();

		dl = directory_table.get_font_file_size ();
		
		if (dl == 0) {
			warning ("font is of zero size.");
			return;
		}
		
		foreach (Table t in tables) {
			fd = t.get_font_data ();
			data = fd.table_data;
			l = fd.length_with_padding ();
			
			for (int j = 0; j < l; j++) {
				os.put_byte (data[j]);
			}
		}
	}
	
	public void close () throws Error {
		os.close ();
	}
}

}
