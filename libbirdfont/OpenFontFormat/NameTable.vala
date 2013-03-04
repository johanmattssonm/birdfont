/*
    Copyright (C) 2012, 2013 Johan Mattsson

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

namespace BirdFont {

class NameTable : Table {

	public static const uint16 COPYRIGHT_NOTICE = 0;
	public static const uint16 FONT_NAME = 1;
	public static const uint16 SUBFAMILY_NAME = 2;
	public static const uint16 UNIQUE_IDENTIFIER = 3;
	public static const uint16 FULL_FONT_NAME = 4; // name + subfamily
	public static const uint16 VERSION = 5;
	public static const uint16 DESCRIPTION = 10;
	public static const uint16 PREFERED_FAMILY = 16;
	public static const uint16 PREFERED_SUB_FAMILY = 17;
	
	List<uint16> identifiers;
	List<string> text;
			
	public NameTable () {
		id = "name";
		text = new List<string> ();
		identifiers = new List<uint16> ();
	}
	
	public string get_name (uint16 identifier) {
		int i = 0;
		
		foreach (uint16 n in identifiers) {
			if (n == identifier) {
				return text.nth (i).data;
			}
			i++;
		}
		
		return "";
	}

	public override void parse (FontData dis) throws Error {
		uint16 format;

		dis.seek (offset);
		
		format = dis.read_ushort ();
		
		switch (format) {
			case 0:
				parse_format0 (dis);
				break;
				
			case 1:
				warning ("name table format 1 is not implemented yet");
				break;
			
			default:
				warning (@"unknown format $format in name table");
				break;
		}
	}
	
	public void parse_format0 (FontData dis) throws Error {
		uint16 count;
		uint16 storage_offset;
		
		List<uint16> strlen = new List<uint16> ();
		List<uint16> off = new List<uint16> ();
		List<uint16> name_id = new List<uint16> ();
		List<uint16> encoding_id = new List<uint16> ();
		List<uint16> platform = new List<uint16> ();
		List<uint16> lang = new List<uint16> ();
				
		count = dis.read_ushort ();
		storage_offset = dis.read_ushort ();
		
		for (int i = 0; i < count; i++) {
			platform.append (dis.read_ushort ());
			encoding_id.append (dis.read_ushort ());
			lang.append (dis.read_ushort ());
			name_id.append (dis.read_ushort ());
			strlen.append (dis.read_ushort ());
			off.append (dis.read_ushort ());
			
			identifiers.append (name_id.last ().data);	
		}

		int plat;
		StringBuilder str;
		for (int i = 0; i < count; i++) {
			plat = platform.nth (i).data;
			dis.seek (offset + storage_offset + off.nth (i).data);
			str = new StringBuilder ();
			
			switch (plat) {
				case 1:
					for (int j = 0; j < strlen.nth (i).data; j++) {
						char c = dis.read_char ();
						str.append_c (c);
					}
					break;
					
				case 3:
					for (int j = 0; j < strlen.nth (i).data; j += 2) {
						unichar c;
						char c0 = dis.read_char ();
						char c1 = dis.read_char ();
												
						c = c0 << 8;
						c += c1;
						
						str.append_unichar (c);
					}
					break;
				
				default:
					break;
			} 
			
			text.append (str.str);
			printd (@"Name id: $(name_id.nth (i).data) platform:  $(platform.nth (i).data) enc: $(encoding_id.nth (i).data) lang: $(lang.nth (i).data) len: $(strlen.nth (i).data) str: \"$(str.str)\"\n");		
		}
	}
	
	public void process () throws GLib.Error {
		FontData fd = new FontData ();
		Font font = OpenFontFormatWriter.get_current_font ();
		uint16 len = 0;
		string t;
		uint16 p;
		uint16 l;
		uint16 num_records;

		List<uint16> type = new List<uint16> ();
		List<string> text = new List<string> ();
		
		text.append ("Copyright");
		type.append (COPYRIGHT_NOTICE);
		
		text.append (font.get_name ());
		type.append (FONT_NAME);

		text.append ("Regular");
		type.append (SUBFAMILY_NAME);

		text.append (font.get_name ()); // TODO: validate
		type.append (UNIQUE_IDENTIFIER);

		text.append (font.get_name ());
		type.append (FULL_FONT_NAME);
		
		// This does for some reason cause an internal error in ms fontvalidatior utility.
		// Head table can't parse integer from string.
		text.append ("Version 1.0");
		type.append (VERSION);		
		
		text.append ("");
		type.append (DESCRIPTION);
				
		text.append (font.get_name ());
		type.append (PREFERED_FAMILY);
		
		text.append ("Regular");
		type.append (PREFERED_SUB_FAMILY);
			
		num_records = (uint16) text.length ();
		
		fd.add_ushort (0); // format 1
		fd.add_ushort (2 * num_records); // nplatforms * nrecords 
		fd.add_ushort (6 + 12 * 2 * num_records); // string storage offset

		for (int i = 0; i < num_records; i++) {
			t = (!) text.nth (i).data;
			p = (!) type.nth (i).data;
			l = (uint16) t.length;
			
			fd.add_ushort (1); // platform
			fd.add_ushort (0); // encoding id
			fd.add_ushort (0); // language
			fd.add_ushort (p); // name id 
			fd.add_ushort (l); // strlen
			fd.add_ushort (len); // offset from begining of string storage
			len += l;				
		}	

		for (int i = 0; i < num_records; i++) {
			t = (!) text.nth (i).data;
			p = (!) type.nth (i).data;
			l = (uint16) (2 * t.char_count ());

			fd.add_ushort (3); // platform
			fd.add_ushort (1); 	// encoding id
			fd.add_ushort (0x0409); // language
			fd.add_ushort (p); // name id 
			fd.add_ushort (l); // strlen
			fd.add_ushort (len); // offset from begining of string storage
			len += l;
		}

		// platform 1
		foreach (string s in text) {
			fd.add_str (s); 
		}
		
		// platform 3
		foreach (string s in text) {
			fd.add_str_utf16 (s); 
		}

		fd.pad ();
		
		this.font_data = fd;
	}
}

}
