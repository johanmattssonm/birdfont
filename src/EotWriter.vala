/*
    Copyright (C) 2012 Johan Mattsson

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

using Math;

namespace Supplement {

class EotWriter {
	
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
		
		ttf_file = File.new_for_path (ttf_file_name);
		
		if (!ttf_file.query_exists ()) {
			warning (@"EotWriter: file does not exist. $((!) ttf_file.get_path ())");
			return;
		}

		eot_file = File.new_for_path (eot_file_name);
		
		if (eot_file.query_exists ()) {
			warning ("File exists in eot export.");
			return;
		}
		
		os = new DataOutputStream(eot_file.create (FileCreateFlags.REPLACE_DESTINATION));

		file_info = ttf_file.query_info ("*", FileQueryInfoFlags.NONE);
		stdout.printf ("File size: %lld bytes\n", file_info.get_size ());

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
			
		fd.add_ulong (0); // table length
		fd.add_ulong (ttf_length);
	
		fd.add_ulong (0x00010000); // table format version
		fd.add_ulong (0); // flags
		
		// panose
		for (int i = 0; i < 10; i++) {
			fd.add (0);
		}
		
		fd.add (0); // italic		
		fd.add_ulong (400); // weight
		fd.add_ushort (0); // 0 drm, designer must be notified
		fd.add_ushort (0x504C); // magic number
 	
		// FIXA:
		// unicode ranges 
		fd.add_ulong (1);
		fd.add_ulong (0);
		fd.add_ulong (0);
		fd.add_ulong (0);
		
		// FIXA:
		// code page range
		fd.add_ulong (1);
		fd.add_ulong (0);
		
		fd.add_ulong (input.get_head_checksum ()); // head checksum adjustment
		
		// reserved
		fd.add_ulong (0);
		fd.add_ulong (0);
		fd.add_ulong (0);
		fd.add_ulong (0);
	
		// padding
		fd.add_ulong (0);
		
		fd.add_ushort ((uint16) (2 * "TEST".char_count ())); // strlen of family name
		fd.add_str_utf16 ("TEST");
		
		fd.add_ushort (0); // padding
		
		fd.add_ushort ((uint16) (2 * "Regular".char_count ())); // strlen of style name
		fd.add_str_utf16 ("Regular");
		
		fd.add_ushort (0); // padding
		
		fd.add_ushort ((uint16) (2 * "Version 1.0".char_count ()));
		fd.add_str_utf16 ("Version 1.0");
		
		fd.add_ushort (0); // padding
		
		fd.add_ushort ((uint16) (2 * "TEST-Regular".char_count ()));
		fd.add_str_utf16 ("TEST-Regular");
		
		// update length of this table
		fd.seek (0);
		fd.add_ulong (fd.length ());
		
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
	}
	
}
		
}
