/*
	Copyright (C) 2012 2013 2014 Johan Mattsson

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

public class NameTable : OtfTable {

	public static const uint16 COPYRIGHT_NOTICE = 0;
	public static const uint16 FONT_NAME = 1;
	public static const uint16 SUBFAMILY_NAME = 2;
	public static const uint16 UNIQUE_IDENTIFIER = 3;
	public static const uint16 FULL_FONT_NAME = 4; // name + subfamily
	public static const uint16 VERSION = 5;
	public static const uint16 POSTSCRIPT_NAME = 6;
	public static const uint16 TRADE_MARK = 7;
	public static const uint16 MANUFACTURER = 8;
	public static const uint16 DESIGNER = 9;
	public static const uint16 DESCRIPTION = 10;
	public static const uint16 VENDOR_URL = 11;
	public static const uint16 DESIGNER_URL = 12;
	public static const uint16 LICENSE = 13;
	public static const uint16 LICENSE_URL = 14;
	public static const uint16 PREFERED_FAMILY = 16;
	public static const uint16 PREFERED_SUB_FAMILY = 17;

	
	Gee.ArrayList<uint16> identifiers;
	Gee.ArrayList<string> text;
			
	public NameTable () {
		id = "name";
		text = new Gee.ArrayList<string> ();
		identifiers = new Gee.ArrayList<uint16> ();
	}
	
	public string get_name (uint16 identifier) {
		int i = 0;
		
		foreach (uint16 n in identifiers) {
			if (n == identifier) {
				return text.get (i);
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
		
		Gee.ArrayList<uint16> strlen = new Gee.ArrayList<uint16> ();
		Gee.ArrayList<uint16> off = new Gee.ArrayList<uint16> ();
		Gee.ArrayList<uint16> name_id = new Gee.ArrayList<uint16> ();
		Gee.ArrayList<uint16> encoding_id = new Gee.ArrayList<uint16> ();
		Gee.ArrayList<uint16> platform = new Gee.ArrayList<uint16> ();
		Gee.ArrayList<uint16> lang = new Gee.ArrayList<uint16> ();
				
		count = dis.read_ushort ();
		storage_offset = dis.read_ushort ();
		
		for (int i = 0; i < count; i++) {
			platform.add (dis.read_ushort ());
			encoding_id.add (dis.read_ushort ());
			lang.add (dis.read_ushort ());
			name_id.add (dis.read_ushort ());
			strlen.add (dis.read_ushort ());
			off.add (dis.read_ushort ());
			
			identifiers.add (name_id.get (name_id.size - 1));	
		}

		int plat;
		StringBuilder str;
		for (int i = 0; i < count; i++) {
			plat = platform.get (i);
			dis.seek (offset + storage_offset + off.get (i));
			str = new StringBuilder ();
			
			switch (plat) {
				case 1:
					for (int j = 0; j < strlen.get (i); j++) {
						char c = dis.read_char ();
						str.append_c (c);
					}
					break;
					
				case 3:
					for (int j = 0; j < strlen.get (i); j += 2) {
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
			
			text.add (str.str);
		}
	}

	/** Create a valid PostScript name. */
	public string validate_ps_name (string s) {
		return name_validation (s, false);
	}

	public string validate_name (string s) {
		return name_validation (s, true);
	}

	public string validate_full_name (string s) {
		string n = name_validation (s, true);
		string regular_suffix = " Regular";

		n = n.replace ("-Regular", " Regular");
		n = n.replace ("-Bold", " Bold");
		n = n.replace ("-Italic", " Italic");

		if (n.has_suffix (regular_suffix)) {
			n = n.substring (0, n.length - regular_suffix.length);
		}
		
		return n;
	}
			
	public static string name_validation (string s, bool allow_space,
		int max_length = 27) {
			
		string n;
		int ccount;
		unichar c;
		StringBuilder name = new StringBuilder ();
		
		n = s.strip ();
		ccount = n.char_count ();
		// truncate strings longer than 28 characters
		for (int i = 0; i < ccount && i < max_length; i++) {
			c = n.get_char (n.index_of_nth_char (i));
			
			if (allow_space && c == ' ') {
				name.append_unichar (' ');
			} else if (is_valid_ps_name_char (c)) {
				name.append_unichar (c);
			} else {
				name.append_unichar ('_');
			}
		}
		
		return name.str;	
	}		
	
	static bool is_valid_ps_name_char (unichar c) {
		switch (c) {
			case '[':
				return false;
			case ']':
				return false;
			case '(':
				return false;
			case ')':
				return false;
			case '{':
				return false;
			case '}':
				return false;
			case '<':
				return false;
			case '>':
				return false;
			case '/':
				return false;
			case '%':
				return false;
							
			default:
				break;
		}

		if (33 <= c <= 126) {
			return true;
		}
		
		return false;
	}
	
	public void process () throws GLib.Error {
		FontData fd = new FontData ();
		Font font = OpenFontFormatWriter.get_current_font ();
		uint16 len = 0;
		string t;
		uint16 p;
		uint16 l;
		uint16 num_records;

		Gee.ArrayList<uint16> type = new Gee.ArrayList<uint16> ();
		Gee.ArrayList<string> text = new Gee.ArrayList<string> ();

		text.add (font.copyright);
		type.add (COPYRIGHT_NOTICE);
		
		text.add (validate_name (font.name));
		type.add (FONT_NAME);

		text.add (validate_name (font.subfamily));
		type.add (SUBFAMILY_NAME);

		text.add (validate_name (font.unique_identifier));
		type.add (UNIQUE_IDENTIFIER);

		text.add (validate_full_name (font.full_name));
		type.add (FULL_FONT_NAME);
		
		text.add (font.version);
		type.add (VERSION);
		
		text.add (validate_ps_name (font.postscript_name));
		type.add (POSTSCRIPT_NAME);

		text.add (font.trademark);
		type.add (TRADE_MARK);
		
		text.add (font.manufacturer);
		type.add (MANUFACTURER);

		text.add (font.designer);
		type.add (DESIGNER);
			
		text.add (font.description);
		type.add (DESCRIPTION);

		text.add (font.vendor_url);
		type.add (VENDOR_URL);

		text.add (font.designer_url);
		type.add (DESIGNER_URL);
				
		text.add (font.license);
		type.add (LICENSE);
		
		text.add (font.license_url);
		type.add (LICENSE_URL);
		
		num_records = (uint16) text.size;
		
		fd.add_ushort (0); // format 1
		fd.add_ushort (2 * num_records); // nplatforms * nrecords 
		fd.add_ushort (6 + 12 * 2 * num_records); // string storage offset

		for (int i = 0; i < num_records; i++) {
			t = (!) text.get (i);
			p = (!) type.get (i);
			l = (uint16) FontData.macroman_strlen (t);
			
			fd.add_ushort (1); // platform
			fd.add_ushort (0); // encoding id
			fd.add_ushort (0); // language
			fd.add_ushort (p); // name id 
			fd.add_ushort (l); // strlen
			fd.add_ushort (len); // offset from beginning of string storage
			len += l;				
		}	

		for (int i = 0; i < num_records; i++) {
			t = (!) text.get (i);
			p = (!) type.get (i);
			l = (uint16) FontData.utf16_strlen (t); 

			fd.add_ushort (3); // platform
			fd.add_ushort (1); 	// encoding id
			fd.add_ushort (0x0409); // language
			fd.add_ushort (p); // name id 
			fd.add_ushort (l); // strlen
			fd.add_ushort (len); // offset from beginning of string storage
			len += l;
		}

		// platform 1
		foreach (string s in text) {
			fd.add_macroman_str (s);
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
