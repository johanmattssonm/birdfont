/*
	Copyright (C) 2012 Johan Mattsson

	This library is free software; you can redistribute it and/or modify 
	it under the terms of the GNU Lesser General Public License as 
	published by the Free Software Foundation; either version 3 of the 
	License, or (at your option) any later version.

	This library is distributed in the hope that it will be useful, but 
	WITHOUT ANY WARRANTY; without even the implied warranty of 
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
	Lesser General Public License for more details.
*/

using Math;

namespace BirdFont {

class EotWriter : GLib.Object {
	
	string ttf_file_name;
	string eot_file_name;
	
	public EotWriter (string ttf_file, string eot_file) {
		ttf_file_name = ttf_file;
		eot_file_name = eot_file;
	}
	
	public void write () throws Error {
		FontData fd = new FontData ();
		FontData ttf_data = new FontData ();
		OpenFontFormatReader input; 
		uint32 ttf_length;
		File ttf_file;
		File eot_file;
		FileInfo file_info;
		OtfInputStream dis;
		DataOutputStream os;
		uint8* data;
		uint32 l;
		NameTable names;
		string tn;
		
		ttf_file = File.new_for_path (ttf_file_name);
		
		if (!ttf_file.query_exists ()) {
			warning (@"EotWriter: file does not exist. $((!) ttf_file.get_path ())");
			return;
		}

		eot_file = File.new_for_path (eot_file_name);
		
		if (eot_file.query_exists ()) {
			warning ("EOT file exists in eot export.");
			eot_file.delete ();
		}
		
		os = new DataOutputStream(eot_file.create (FileCreateFlags.REPLACE_DESTINATION));

		file_info = ttf_file.query_info ("*", FileQueryInfoFlags.NONE);
		ttf_length = (uint32) file_info.get_size ();
		 
		if (ttf_length == 0) {
			warning ("TTF file is of zero length.");
			return;
		}

		dis = new OtfInputStream (ttf_file.read ());
		ttf_data.write_table (dis, 0, ttf_length);

		// parse file to find head checksum
		input = new OpenFontFormatReader ();
		input.parse_index (ttf_file_name);
 
		names = input.directory_table.name_table;
		
		fd.add_littleendian_u32 (0); // table length
		fd.add_littleendian_u32 (ttf_length);
	
		fd.add_littleendian_u32 (0x00020001); // table format version
		fd.add_littleendian_u32 (0); // flags
		
		// panose
		for (int i = 0; i < 10; i++) {
			fd.add (0);
		}
		
		// according to specification should charset and italic be added the 
		// other way around, but it does not work
				
		fd.add (1); // default charset
		fd.add (0); // italic set to regular
				
		fd.add_littleendian_u32 (400); // weight
		fd.add_littleendian_u16 (0); // 0 drm, designer must be notified
		fd.add_littleendian_u16 (0x504C); // magic number

		// FIXME:
		// unicode ranges 
		fd.add_littleendian_u32 (0);
		fd.add_littleendian_u32 (0);
		fd.add_littleendian_u32 (0);
		fd.add_littleendian_u32 (0);
		
		// FIXME:
		// code page range
		fd.add_littleendian_u32 (0);
		fd.add_littleendian_u32 (0);
		
		fd.add_littleendian_u32 (input.get_head_checksum ()); // head checksum adjustment
		
		// reserved
		fd.add_littleendian_u32 (0);
		fd.add_littleendian_u32 (0);
		fd.add_littleendian_u32 (0);
		fd.add_littleendian_u32 (0);
	
		fd.add_littleendian_u16 (0); // padding
		
		tn = names.get_name (NameTable.FONT_NAME);
		fd.add_littleendian_u16 ((uint16) (2 * tn.char_count ())); // strlen of family name
		fd.add_str_littleendian_utf16 (tn);
		
		fd.add_littleendian_u16 (0); // padding
		
		tn = names.get_name (NameTable.SUBFAMILY_NAME);
		fd.add_littleendian_u16 ((uint16) (2 * tn.char_count ())); // strlen of family name
		fd.add_str_littleendian_utf16 (tn);

		fd.add_littleendian_u16 (0); // padding
		
		// FIXA version or name + version
		tn = names.get_name (NameTable.VERSION);
		fd.add_littleendian_u16 ((uint16) (2 * tn.char_count ())); // strlen of family name
		fd.add_str_littleendian_utf16 (tn);
		
		fd.add_littleendian_u16 (0); // padding
		
		tn = names.get_name (NameTable.FULL_FONT_NAME);
		fd.add_littleendian_u16 ((uint16) (2 * tn.char_count ())); // strlen of family name
		fd.add_str_littleendian_utf16 (tn);
		
		fd.add_littleendian_u16 (0); // padding
		
		fd.add_littleendian_u16 (0); // length of root string
		// the root string goes here.
		
		// update length of this table
		fd.seek (0);
		fd.add_littleendian_u32 (fd.length () + ttf_length);
		
		l = fd.length_with_padding ();
		data = fd.table_data;
		for (int i = 0; i < l; i++) {
			os.put_byte (data[i]);
		}

		l = ttf_data.length_with_padding ();
		data = ttf_data.table_data;
		for (int i = 0; i < l; i++) {
			os.put_byte (data[i]);
		}
		
		dis.close ();
		os.close ();
		input.close ();
	}
	
}
		
}
