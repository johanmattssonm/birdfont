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
	
	public static HashMap<string, string> entries;
	public static HashMultiMap<string, string> index;

	public static GlyphRange full_unicode_range;
	public static bool database_is_loaded = false;

	public CharDatabase () {
		entries = new HashMap<string, string> ();
		index = new HashMultiMap<string, string> ();
	
		full_unicode_range = new GlyphRange ();
	}

	public static GlyphRange search (string s) {
		GlyphRange result = new GlyphRange ();
		GlyphRange ucd_result = new GlyphRange ();
		unichar c;
		
		return_val_if_fail (!is_null (index), result);		
		return_val_if_fail (result.get_length () == 0, result);
		
		if (s.has_prefix ("U+") || s.has_prefix ("u+")) {
			c = Font.to_unichar (s.down ());
			
			if (c != '\0') {
				result.add_single (c);
			}
		}
		
		if (s.char_count () == 1) {
			result.add_single (s.get_char ()); 
		}
		
		foreach (string i in index.get (s)) {
			c = Font.to_unichar ("U+" + i.down ());
			ucd_result.add_single (c);
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
	
	public static void get_full_unicode (GlyphRange glyph_range) {
		try {
			if (!is_null (full_unicode_range)) {
				glyph_range.parse_ranges (full_unicode_range.get_all_ranges ());
			}
		} catch (MarkupError e) {
			warning (e.message);
		}
	}
}

}
