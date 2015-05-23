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
using Bird;

[SimpleType]
[CCode (has_type_id = false)]
extern struct FcConfig {
}

[CCode (cname = "FcInitLoadConfigAndFonts")]
extern FcConfig* FcInitLoadConfigAndFonts ();

[CCode (cname = "find_font")]
extern string? find_font (FcConfig* font_config, string characters);

namespace BirdFont {

// TODO: use font config
public class FallbackFont : GLib.Object {
	static unowned Database db;
	static Database? database = null;

	Gee.ArrayList<File> fallback_fonts;
	Gee.ArrayList<File> font_directories;

	FcConfig* font_config;

	public FallbackFont () {	
		string home = Environment.get_home_dir ();
		
		fallback_fonts = new Gee.ArrayList<File> ();
		font_directories = new Gee.ArrayList<File> ();
		
		font_config = FcInitLoadConfigAndFonts ();
		
		open_database ();
		
		add_font_folder ("/usr/share/fonts/");
		add_font_folder ("/usr/local/share/fonts/");
		add_font_folder (home + "/.local/share/fonts");
		add_font_folder (home + "/.fonts");
		add_font_folder ("C:\\Windows\\Fonts");	
		//FIXME: MAC
		
		add_fallback_fonts ();
	}
	
	void add_fallback_fonts () {
		add_font ("times.ttf");
		add_font ("arial.ttf");
		add_font ("verdana.ttf");
		add_font ("calibri.ttf");

		add_font ("DejaVuSans.ttf");
		add_font ("Ubuntu-R.ttf");
		
		add_font ("DroidKufi.ttf");
		add_font ("DroidSansGeorgian.ttf");
		add_font ("DroidSansHebrew.ttf");
		add_font ("DroidNaskh.ttf");
		add_font ("DroidSansJapanese.ttf");
		add_font ("DroidSansArabic.ttf");
		add_font ("DroidSansArmenian.ttf");
		add_font ("DroidSans.ttf");
		add_font ("DroidSansEthiopic.ttf");
		add_font ("DroidSansFallbackFull.ttf");

		add_font ("Roboto-Regular.ttf");
	}

	void add_font (string font) {
		File f = find_font_file (font);
		
		if (f.query_exists ()) {
			fallback_fonts.add (f);
		}
	}

	File find_font_file (string font_file) {
		File d, f;
		
		for (int i = font_directories.size - 1; i >= 0; i--) {
			d = font_directories.get (i);
			f = get_child (d, font_file);
			
			if (f.query_exists ()) {
				return f;
			}
		}
		
		return File.new_for_path (font_file);
	}
		
	void add_font_folder (string f) {
		File folder = File.new_for_path (f);
		FileInfo? file_info;
		string fn;
		
		try {
			if (folder.query_exists ()) {
				font_directories.add (folder);
				
				var enumerator = folder.enumerate_children (FileAttribute.STANDARD_NAME + "," + FileAttribute.STANDARD_TYPE, 0);
				
				while ((file_info = enumerator.next_file ()) != null) {
					fn = ((!) file_info).get_name ();

					if (((!)file_info).get_file_type () == FileType.DIRECTORY) {
						add_font_folder ((!) get_child (folder, fn).get_path ());
					}
				}
			}
		} catch (GLib.Error e) {
			warning (e.message);
		}
	}
	
	public Font get_single_glyph_font (unichar c) {
		string? font_file;
		string file;
		BirdFontFile bf_parser;
		Font bf_font;
		StringBuilder? glyph_data;
		FontFace* font;

		font_file = find_font (font_config, (!) c.to_string ());
		
		if (font_file == null) {
			warning ("No font returned from fontconfig.");
			return get_single_glyph_font_without_font_config (c);
		}
		
		file = (!) font_file;
		print (@"font_file: $(file)\n");
		
		print (@"Load from TTF $((!) c.to_string ())\n");

		font = open_font (file);
		glyph_data = get_glyph_in_font (font, c);
		close_font (font);
		
		bf_font = new Font ();
		if (glyph_data != null) {
			bf_parser = new BirdFontFile (bf_font);
			bf_parser.load_data (((!) glyph_data).str);
		}

		return bf_font;		
	}
	
	// FIXME: remove after fixing the windows version
	public Font get_single_glyph_font_without_font_config (unichar c) {
		BirdFontFile bf_parser;
		Font bf_font;
		StringBuilder? glyph_data;
		string data;
		
		glyph_data = find_cached_glyph (c);
		
		if (glyph_data == null) {
			print (@"Load from TTF $((!) c.to_string ())\n");
			glyph_data = load_glyph_from_ttf (c);
		} else print (@"Found cached gd $((!) c.to_string ())\n");
		
		bf_font = new Font ();
		
		if (glyph_data != null) {
			bf_parser = new BirdFontFile (bf_font);
			data = ((!) glyph_data).str;
			
			if (data != "") {
				bf_parser.load_data (data);
			}
		}

		return bf_font;
	}
	
	public StringBuilder? load_glyph_from_ttf (unichar c) {
		StringBuilder? glyph_data;
		
		glyph_data = load_glyph_data_from_ttf (c);
		
		if (glyph_data != null) {
			cache_glyph (c, ((!) glyph_data).str);
		} else {
			cache_glyph (c, "");
		}
		
		return glyph_data;
	}

	public StringBuilder? load_glyph_data_from_ttf (unichar c) {
		File f;
		FontFace* font;
		StringBuilder? data = null;
		
		for (int i = fallback_fonts.size - 1; i >= 0; i--) {
			f = fallback_fonts.get (i);
			
			font = open_font ((!) f.get_path ());
			data = get_glyph_in_font (font, c);
			close_font (font);
			
			if (data != null) {
				return data;
			}
		}
		
		return null;
	}
	
	public StringBuilder? get_glyph_in_font (FontFace font, unichar c) {
		StringBuilder? glyph_data = null;
		GlyphCollection gc;

		gc = new GlyphCollection (c, (!)c.to_string ());		
		glyph_data = load_glyph (font, (uint) c);

		return glyph_data;
	}
	
	File get_fallback_database () {
		File f = BirdFont.get_settings_directory ();
		return get_child (f, "fallback_font.sqlite");
	}
	
	public void open_database () {
		File db_file = get_fallback_database ();
		bool create_table = !db_file.query_exists ();
		int rc = Database.open ((!) db_file.get_path (), out database);

		db = (!) database;

		if (rc != Sqlite.OK) {
			stderr.printf ("Can't open database: %d, %s\n", rc, db.errmsg ());
		}

		if (create_table) {
			create_tables ();
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
	
	void cache_glyph (unichar c, string glyph_data) {
		int64 character;
		int ec;
		string? errmsg;
		string insert;
		
		character = (int64) c;
		insert = "INSERT INTO FallbackFont (unicode, font_data) "
			+ @"VALUES ('$character', '" + glyph_data.replace ("'", "''") + "');";
		
		ec = db.exec (insert, null, out errmsg);
		if (ec != Sqlite.OK) {
			warning ("Error: %s\n", (!) errmsg);
		}
	}

	StringBuilder? find_cached_glyph (unichar c) {
		int rc, cols;
		Statement statement;
		string select;
		StringBuilder? font_data = null;
		
		select = "SELECT font_data FROM FallbackFont "
			 + "WHERE unicode = '" + @"$((int64) c)" + "';";
					
		rc = db.prepare_v2 (select, select.length, out statement, null);
		
		if (rc == Sqlite.OK) {
			cols = statement.column_count();
			
			if (cols != 1) {
				warning ("Expecting one column.");
				return font_data;
			}

			while (true) {
				rc = statement.step ();
				
				if (rc == Sqlite.DONE) {
					break;
				} else if (rc == Sqlite.ROW) {
					font_data = new StringBuilder ();
					((!) font_data).append (statement.column_text (0));
				} else {
					warning ("Error: %d, %s\n", rc, db.errmsg ());
					break;
				}
			}			
		} else {
			warning ("SQL error: %d, %s\n", rc, db.errmsg ());
		}
		
		return font_data;
	}
}

}
