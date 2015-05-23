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

namespace BirdFont {

public class FallbackFont : GLib.Object {
	static unowned Database db;
	static Database? database = null;

	Gee.ArrayList<File> fallback_fonts;
	Gee.ArrayList<File> font_directories;

	public FallbackFont () {	
		string home = Environment.get_home_dir ();
		
		fallback_fonts = new Gee.ArrayList<File> ();
		font_directories = new Gee.ArrayList<File> ();
		
		add_font_folder ("/usr/share/fonts/");
		add_font_folder ("/usr/local/share/fonts/");
		add_font_folder (home + "/.local/share/fonts");
		add_font_folder ("C:\\Windows\\Fonts");
		
		//FIXME: MAC
		
		open_fallback_fonts ();
	}
	
	void open_fallback_fonts () {
		add_font ("times.ttf");
		add_font ("arial.ttf");
		add_font ("verdana.ttf");
		add_font ("calibri.ttf");
		
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
		Font f = load_glyph_from_ttf (c);
		return f;
	}
	
	public Font load_glyph_from_ttf (unichar c) {
		Font? bf_font;
		File f;
		FontFace* font;
		
		bf_font = new Font ();

		for (int i = fallback_fonts.size - 1; i >= 0; i--) {
			f = fallback_fonts.get (i);
			
			font = open_font ((!) f.get_path ());
			bf_font = get_glyph_in_font ((!) font, c);
			
			close_font (font);
			
			if (bf_font != null) {
				return (!) bf_font;
			}
		}
		
		return bf_font != null ? (!) bf_font : new Font ();
	}
	
	public Font? get_glyph_in_font (FontFace font, unichar c) {
		StringBuilder? glyph_data = null;
		GlyphCollection gc;
		BirdFontFile bf_parser;
		Font bf_font = new Font ();
		
		gc = new GlyphCollection (c, (!)c.to_string ());		
		glyph_data = load_glyph (font, (uint) c);

		if (glyph_data == null) {
			return null;
		}

		bf_parser = new BirdFontFile (bf_font);
		bf_parser.load_data (((!) glyph_data).str);
				
		return bf_font;
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
			stderr.printf ("Add a list of fonts to use as fallback to the \"--fonts\" argument.\n");
			stderr.printf ("Separate each font file with \":\"\n");
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

/* //FIXME:DELETE
	public void add_font (string font_file) {
		Font font;
		Glyph g;
		BirdFontFile bf;
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
	} */

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
