/*
    Copyright (C) 2015 Johan Mattsson

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

public class FallbackFont : GLib.Object {
	public static unowned Database db;
	public static Database? database = null;

	public FallbackFont () {	
	}

	public File get_database_file () {
		return SearchPaths.find_file (null, "fallback-font.sqlite");
	}
	
	public File get_new_database_file () {
		string? fn = BirdFont.get_argument ("--fallback-font");
		
		if (fn != null && ((!) fn) != "") {
			return File.new_for_path ((!) fn);
		}
		
		return File.new_for_path ("fallback-font.sqlite");
	}
		
	public void generate_fallback_font () {
		File f = get_new_database_file ();
		string? fonts = BirdFont.get_argument ("--fonts");
		string fallback;
		
		if (fonts == null) {
			stderr.printf ("Add a list of fonts to use as fallback in the --fonts parameter.\n");
			stderr.printf ("Separate each path with \":\"\n");
			return;
		}
		
		fallback = (!) fonts;
		
		stdout.printf ("Generating fallback font: %s\n", (!) f.get_path ());
		
		try {
			if (f.query_exists ()) {
				f.delete ();
			}
			
			open_database (f);
			create_tables ();
			
			foreach (string font in fallback.split (":")) {
				add_font (font);
			}		
		} catch (GLib.Error e) {
			warning (e.message);
		}
		
	}

	public void add_font (string font_file) {
		Font font;
		Glyph g;
		BirdFontFile bf;
		DataOutputStream os;
		File single_glyph_font;
		
		font = new Font ();
		single_glyph_font = File.new_for_path ("/tmp/fallback_glyph.bf");
		
		font.set_file (font_file);
		if (!font.load ()) {
			stderr.printf ("Failed to load font: " + font_file);
			return;
		}
		
		for (int i = 0; i < font.length (); i++) {
			g = (!) font.get_glyph_indice (i);
			bf = new BirdFontFile (font);
		}
	}

	public void open_database (File db_file) {
		int rc = Database.open ((!) db_file.get_path (), out database);

		db = (!) database;

		if (rc != Sqlite.OK) {
			stderr.printf ("Can't open database: %d, %s\n", rc, db.errmsg ());
		}
	}

	public void create_tables () {
		int ec;
		string? errmsg;
		string create_font_table = """
			CREATE TABLE FallbackFont (
				unicode        INTEGER     PRIMARY KEY    NOT NULL,
				font_data      TEXT                       NOT NULL
			);
		""";

		ec = db.exec (create_font_table, null, out errmsg);
		if (ec != Sqlite.OK) {
			warning ("Error: %s\n", (!) errmsg);
		}
	}
}

}
