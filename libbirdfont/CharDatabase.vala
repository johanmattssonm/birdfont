/*
	Copyright (C) 2012 2015 Johan Mattsson

	All rights reserved.
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
		int rc = Database.open_v2 ((!) f.get_path (), out database, OPEN_READONLY);

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
		string query = s.strip ();
		
		if (query.has_prefix ("U+") || query.has_prefix ("u+")) {
			c = Font.to_unichar (query.down ());
			
			if (c != '\0') {
				result.add_single (c);
			}
		}

		if (query.char_count () == 1) {
			result.add_single (s.get_char (0));
		}

		string[] terms = query.split (" ");
		
		bool first = true;
		select = "";
		
		foreach (string term in terms) {
			if (first) {
				select = "SELECT unicode FROM Words "
					 + "WHERE word GLOB '" + term.replace ("'", "''") + "' ";
			} else {
				select += "OR word GLOB '" + term.replace ("'", "''") + "' ";
			}
			
			first = false;
		}
		select += ";";
		
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
					
					if (has_all_terms (c, query)) {
						ucd_result.add_single (c);
					}
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

	static bool has_term (unichar c, string term) {
		Statement statement;
		string select = "SELECT unicode FROM Words "
			+ "WHERE word GLOB '" + term.replace ("'", "''") + "' "
			+ @"AND unicode = $((int64) c);";
		
		int rc = db.prepare_v2 (select, select.length, out statement, null);

		if (rc == Sqlite.OK) {
			rc = statement.step ();
			
			if (rc == Sqlite.DONE) {
				return false;
			} else if (rc == Sqlite.ROW) {
				c = (unichar) statement.column_int64 (0);
				return true;
			}
		} else {
			warning ("Error: %d, %s\n", rc, db.errmsg ());
			return false;
		}
			
		return false;
	}
	
	static bool has_all_terms (unichar c, string query) {
		string[] terms = query.split (" ");
		
		foreach (string term in terms) {
			if (!has_term (c, term)) {
				return false;
			}
		}
		
		return true;
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
