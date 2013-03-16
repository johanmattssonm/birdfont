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

namespace BirdFont {

class CharDatabase {

	public CharDatabase () {
	}

	public static bool has_ascender (unichar c) {
		if (!c.islower()) return true;
		
		// todo: their derrivatives
		switch (c) {
			case 'b': return true;
			case 'd': return true;
			case 'f': return true;
			case 'h': return true;
			case 'i': return true;
			case 'j': return true;
			case 'k': return true;
			case 'l': return true;	
		}
		
		if ('à' <= c <= 'å') return true;
		if ('è' <= c <= 'ö') return true;
		if ('ù' <= c <= 'ă') return true;
		if ('ć' <= c <= 'ė') return true;

		return false;
	}

	public static bool has_descender (unichar c) {
		// todo: their derrivatives
		switch (c) {
			case 'g': return true;
			case 'j': return true;
			case 'p': return true;
			case 'q': return true;
			case 'y': return true;
		}
		
		return false;		
	}
	
	public static string get_unicode_database_entry (unichar c) {
		FileInputStream fin;
		DataInputStream din;
		string? line;
		string data;
		string hex_char;
		string description = "";
		File file;
				
		file = (!) File.new_for_path ("/usr/share/unicode/NamesList.txt"); // FIXME
		hex_char = Font.to_hex (c).replace ("U+", "");
		
		if (hex_char.char_count () == 2) {
			hex_char = "00" + hex_char;
		}
		
		if (hex_char.char_count () == 6 && hex_char.has_prefix ("0")) {
			hex_char = hex_char.substring (1);
		}
		
		hex_char += "\t";
		hex_char = hex_char.up ();
		
		try {
			fin = file.read ();
			din = new DataInputStream (fin);
			
			while ((line = din.read_line (null)) != null) {
				data = (!) line;
				if (data.has_prefix (hex_char)) {
					description = data;
					
					while ((line = din.read_line (null)) != null) {
						data = (!) line;
						if (data.has_prefix ("\t")) {
							description += "\n";
							description += data;
						} else {
							break;
						}
					}
					
					break;
				}
			}
			
			if (description == "") {
				warning ("no description found");
			}
			
			fin.close ();
			din.close ();
		} catch (GLib.Error e) {
			warning (e.message);
		}
		
		return description;		
	}
	
	public static void get_full_unicode (GlyphRange glyph_range) {
		File file;
		FileInputStream fin;
		DataInputStream din;
		DataOutputStream os;
		string? line;
		string data;
		string[] range;
		
		try {		
			file = BirdFont.get_settings_directory ().get_child ("full_unicode_range");
			
			if (file.query_exists ()) {
				// read cached glyph ranges
				fin = file.read ();
				din = new DataInputStream (fin);
				while ((line = din.read_line (null)) != null) {
					data = (!) line;
					
					if (data == "") {
						break;
					}
					
					range = data.split (" - ");
					return_if_fail (range.length == 2);
					
					glyph_range.add_range (Font.to_unichar ("U+" + range[0]), Font.to_unichar ("U+" + range[1]));
				}
				fin.close ();
				din.close ();					
			} else {
				parse_full_unicode_database (glyph_range);
				
				// write cache
				os = new DataOutputStream(file.create (FileCreateFlags.REPLACE_DESTINATION));
				os.put_string (glyph_range.get_all_ranges ());
				os.close ();
			}
		} catch (GLib.Error e) {
			warning (e.message);
		}
	}
	
	/** Obtain full unicode range from unicode database. */
	public static void parse_full_unicode_database (GlyphRange glyph_range) {
		FileInputStream fin;
		DataInputStream din;
		string? line;
		string data;
		string hex_char;
		File file;
		unichar ch;
		
		file = get_unicode_database ();
		
		if (!file.query_exists ()) {
			warning ("Can not find unicode database.");
			return;
		}

		try {
			fin = file.read ();
			din = new DataInputStream (fin);
			
			while ((line = din.read_line (null)) != null) {
				data = (!) line;
				
				if (data.has_prefix ("\t") || data.has_prefix (";") || data.has_prefix ("@")) {
					continue;
				}
				
				if (data.index_of ("<not a character>") != -1) {
					continue;
				}
				
				hex_char = "U+" + data.substring (0, data.index_of ("\t")).down ();
				
				ch = Font.to_unichar (hex_char);
				glyph_range.add_single (ch);
			}
			
			fin.close ();
			din.close ();
		} catch (GLib.Error e) {
			warning (e.message);
		}	
	}
	
	static File get_unicode_database () {
		File f;

		f = (!) File.new_for_path (PREFIX + "/share/unicode/NamesList.txt");
		if (f.query_exists ()) {
			return f;
		}
		
		f = (!) File.new_for_path (".\\NamesList.txt");
		if (f.query_exists ()) {
			return f;
		}
			
		f = (!) File.new_for_path ("/usr/share/unicode/NamesList.txt");
		return f;
	}
}

}
