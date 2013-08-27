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

using Gee;

namespace BirdFont {

public class CharDatabase {
	
	static HashMap<string, string> entries;
	static HashMultiMap<string, string> index;

	static GlyphRange full_unicode_range;
	static bool database_is_loaded = false;
	
	static double lines_in_ucd = 38876;
	
	public CharDatabase () {
		entries = new HashMap<string, string> ();
		index = new HashMultiMap<string, string> ();
	
		full_unicode_range = new GlyphRange ();

		IdleSource idle = new IdleSource ();
		idle.set_callback (() => {
			show_loading_message ();
			parse_all_entries ();
			database_is_loaded = true;
			return false;
		});
		idle.attach (null);
	}

	public static GlyphRange search (string s) {
		GlyphRange result = new GlyphRange ();
		GlyphRange ucd_result = new GlyphRange ();
		unichar c;
		string i;
		string? iv;
		
		if (!database_is_loaded) {
			show_loading_message ();
		}
		
		return_if_fail (result.get_length () == 0);
		
		if (s.has_prefix ("U+") || s.has_prefix ("u+")) {
			c = Font.to_unichar (s.down ());
			
			if (c != '\0') {
				result.add_single (c);
			}
		}
		
		if (s.char_count () == 1) {
			result.add_single (s.get_char ()); 
		}
		
		var it = index.get (s).iterator ();
		for (var has_next = it.first (); has_next; has_next = it.next ()) {
			iv = it.get ();
			if (iv != null) {
				i = (string) iv;
				c = Font.to_unichar ("U+" + i.down ());
				ucd_result.add_single (c);
			}
		}
		
		try {
			if (ucd_result.get_length () > 0) {
				ucd_result.sort ();
				result.parse_ranges (ucd_result.get_all_ranges ());
			}
		} catch (MarkupError e) {
			warning (e.message);
		}
		
		return result;
	}

	private void add_entry (string data) {
		string[] e;
		string[] r;
		string[] d;
		string index_values;
		unichar ch;
		
		string unicode_hex;
		
		if (data.has_prefix ("@")) { // ignore comments
			return;
		}
		
		index_values = data.down ();
		index_values = index_values.replace ("\tx", "");
		index_values = index_values.replace ("\t*", "");
		index_values = index_values.replace ("\t=", "");
		index_values = index_values.replace ("\t#", "");
		index_values = index_values.replace (" - ", " ");
		index_values = index_values.replace ("(", "");
		index_values = index_values.replace (")", "");
		index_values = index_values.replace ("<font>", "");
		index_values = index_values.replace (" a ", " ");
		index_values = index_values.replace (" is ", " ");
		index_values = index_values.replace (" the ", " ");
		
		e = index_values.split ("\t");

		return_if_fail (e.length > 0);
		
		unicode_hex = e[0].up ();
		
		ch = Font.to_unichar ("U+" + unicode_hex.down ());
		full_unicode_range.add_single (ch);
		Tool.yield ();

		entries.set (unicode_hex, data);
				
		foreach (string s in e) {
			r = s.split ("\n");
			foreach (string t in r) {  
				d = t.split (" ");
				foreach (string token in d) {
					if (token != "") {
						index.set (token, unicode_hex);
						Tool.yield ();
					}
				}
			}
		}
		
		Tool.yield ();
	}

	private void parse_all_entries () {
		FileInputStream fin;
		DataInputStream din;
		string? line;
		string data;
		string description = "";
		File file;
		int line_number = 0;

		file = get_unicode_database ();
		
		try {
			fin = file.read ();
			din = new DataInputStream (fin);
			
			line = din.read_line (null);
			while (true) {
				data = (!) line;
				description = data;
				
				while ((line = din.read_line (null)) != null) {
					data = (!) line;
					if (data.has_prefix ("\t")) {
						description += "\n";
						description += data;
					} else {
						if (description.index_of ("<not a character>") == -1) {
							add_entry (description);
						}
						break;
					}
					
					ProgressBar.set_progress (++line_number / lines_in_ucd);
					
					Tool.yield ();
				}
				
				if (line == null) {
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
			warning ("In %s", (!) get_unicode_database ().get_path ());
		}
	}

	public static bool has_ascender (unichar c) {
		if (!c.islower()) return true;
		
		switch (c) {
			case 'b': return true;
			case 'd': return true;
			case 'f': return true;
			case 'h': return true;
			case 'k': return true;
			case 'l': return true;	
		}

		return false;
	}

	public static bool has_descender (unichar c) {
		switch (c) {
			case 'g': return true;
			case 'j': return true;
			case 'p': return true;
			case 'q': return true;
			case 'y': return true;
		}
		
		return false;		
	}
	
	/** Convert from the U+xx form to the unicode database hex value. */ 
	static string to_database_hex (unichar c) {
		string hex_char = Font.to_hex (c).replace ("U+", "");

		if (hex_char.char_count () == 2) {
			hex_char = "00" + hex_char;
		}
		
		if (hex_char.char_count () == 6 && hex_char.has_prefix ("0")) {
			hex_char = hex_char.substring (1);
		}
		
		hex_char = hex_char.up ();		
		return hex_char;
	}
	
	public static string get_unicode_database_entry (unichar c) {
		string description;
		string? d;
		
		d = entries.get (to_database_hex (c));
		
		if (d == null) {
			description = Font.to_hex (c).replace ("U+", "") + "\tUNICODE CHARACTER";
		} else {
			description = (!) d;
		}
		
		return description;		
	}
	
	static void show_loading_message () {
		MainWindow.set_status (_("Loading the unicode character database") + " ...");
	}
	
	public static void get_full_unicode (GlyphRange glyph_range) {
		if (!database_is_loaded) {
			show_loading_message ();
		}
		
		try {
			glyph_range.parse_ranges (full_unicode_range.get_all_ranges ());
		} catch (MarkupError e) {
			warning (e.message);
		}
	}
	
	static File get_unicode_database () {
		return SearchPaths.get_char_database ();
	}
}

}
