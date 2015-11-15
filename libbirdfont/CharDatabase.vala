/*
	Copyright (C) 2012 2015 Johan Mattsson

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
using Sqlite;

namespace BirdFont {

public class CharDatabase {
	public static GlyphRange full_unicode_range;

	static unowned Database db;
	static Database? database = null;

	public CharDatabase () {
		File f;
			
		full_unicode_range = new GlyphRange ();
		f = get_database_file ();
		open_database () ;
	}
	
	public static void open_database () {
		File f = get_database_file ();
		int rc = Database.open ((!) f.get_path (), out database);

		db = (!) database;

		if (rc != Sqlite.OK) {
			stderr.printf ("Can't open database: %d, %s\n", rc, db.errmsg ());
		}
	}
	
	public static File get_database_file () {
		return SearchPaths.find_file (null, "ucd.sqlite");
	}

	public static GlyphRange search (string s) {
		GlyphRange result = new GlyphRange ();
		GlyphRange ucd_result = new GlyphRange ();
		int rc, cols;
		Statement statement;
		string select;
		unichar c;
		
		if (s.has_prefix ("U+") || s.has_prefix ("u+")) {
			c = Font.to_unichar (s.down ());
			
			if (c != '\0') {
				result.add_single (c);
			}
		}

		if (s.char_count () == 1) {
			result.add_single (s.get_char (0));
		}

		select = "SELECT unicode FROM Words "
			 + "WHERE word GLOB '" + s.replace ("'", "''") + "';";
					
		rc = db.prepare_v2 (select, select.length, out statement, null);
		
		if (rc == Sqlite.OK) {
			cols = statement.column_count();
			
			if (cols != 1) {
				warning ("Expecting one column.");
				return result;
			}

			while (true) {
				rc = statement.step ();
				
				if (rc == Sqlite.DONE) {
					break;
				} else if (rc == Sqlite.ROW) {
					c = (unichar) statement.column_int64 (0);
					ucd_result.add_single (c);
				} else {
					warning ("Error: %d, %s\n", rc, db.errmsg ());
					break;
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
			
		} else {
			warning ("SQL error: %d, %s\n", rc, db.errmsg ());
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
	
	public static string get_unicode_database_entry (unichar c) {
		string description = "";
		int rc, cols;
		Statement statement;
		string select = "SELECT description FROM Description "
			+ @"WHERE unicode = $((int64) c)";
		
		rc = db.prepare_v2 (select, select.length, out statement, null);
		
		if (rc == Sqlite.OK) {
			cols = statement.column_count();
			
			if (cols != 1) {
				warning ("Expecting one column.");
				return description;
			}

			while (true) {
				rc = statement.step ();
				
				if (rc == Sqlite.DONE) {
					break;
				} else if (rc == Sqlite.ROW) {
					description = statement.column_text (0);
				} else {
					printerr ("Error: %d, %s\n", rc, db.errmsg ());
					break;
				}
			}
					
		} else {
			printerr ("SQL error: %d, %s\n", rc, db.errmsg ());
		}
		
		if (description == "") {
			description = Font.to_hex (c).replace ("U+", "") + "\tUNICODE CHARACTER";
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
