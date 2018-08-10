/*
	Copyright (C) 2012 2014 Johan Mattsson

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

static void print_import_help (string[] arg) {
	stdout.printf (t_("Usage:"));
	stdout.printf (arg[0]);
	stdout.printf (" " + t_("BF-FILE") + " " + t_("SVG-FILES ...") +"\n");
	stdout.printf ("\n");
}

public static int run_import (string[] arg) {
	string bf_file = "";
	Gee.ArrayList<string> svg_files = new Gee.ArrayList<string> ();
	File bf;
	File svg;
	Font font;
	bool imported;
	
	Theme.set_default_colors ();
	Preferences.load ();
	BirdFont.args = new Argument ("");
	BirdFont.current_font = new Font ();
	BirdFont.current_glyph_collection = new GlyphCollection.with_glyph ('\0', "");
	MainWindow.init ();

	if (arg.length < 3) {
		print_import_help (arg);
		return -1;
	}
	
	bf_file = build_absoulute_path (arg[1]);
	
	for (int i = 2; i < arg.length; i++) {
		svg_files.add (arg[i]);
	}
	
	bf = File.new_for_path (bf_file);
	foreach (string f in svg_files) {
		svg = File.new_for_path (f);
		
		if (!svg.query_exists ()) {
			stdout.printf (@"$f " + t_("does not exist.") + "\n");
			return -1;
		}
	}
	
	font = BirdFont.get_current_font ();

	if (!bf.query_exists ()) {
		stdout.printf (@"$bf_file " + t_("does not exist.") + " ");
		stdout.printf (t_("A new font will be created.") + "\n");
		font.set_file (bf_file);
	} else {
		font.set_file (bf_file);
		if (!font.load ()) {
			warning (@"Failed to load font $bf_file.\n");
			
			if (!bf_file.has_suffix (".bf") && !bf_file.has_suffix (".birdfont")) {
				warning (@"Is it a .bf file?\n");
			}
			
			return -1;
		}
	}

	font.save_backup ();

	foreach (string f in svg_files) {
		svg = File.new_for_path (f);
		imported = import_svg_file (font, svg);
		
		if (!imported) {
			stdout.printf (t_("Failed to import") + " " + f + "\n");
			stdout.printf (t_("Aborting") + "\n");
			return -1;
		}
	}
	
	font.save_bf ();
	
	return 0;
}

public static bool import_svg_file (Font font, File svg_file) {
	string file_name = (!) svg_file.get_basename ();
	string glyph_name;
	StringBuilder n;
	Glyph glyph;
	GlyphCollection? gc = null;
	GlyphCollection glyph_collection;
	unichar character;
	GlyphCanvas canvas;
	
	glyph_name = file_name.replace (".svg", "");
	glyph_name = glyph_name.replace (".SVG", "");
	
	if (glyph_name.char_count () > 1) {
		if (glyph_name.has_prefix ("U+")) {
			n = new StringBuilder ();
			n.append_unichar (Font.to_unichar (glyph_name));
			glyph_name = n.str;
			gc = font.get_glyph_collection (glyph_name);
		} else {
			gc = font.get_glyph_collection_by_name (glyph_name);
			
			if (gc == null) {
				stdout.printf (file_name + " " + t_("is not the name of a glyph or a Unicode value.") + "\n");
				stdout.printf (t_("Unicode values must start with U+.") + "\n");
				return false;
			}
		}		
	} else {
		gc = font.get_glyph_collection (glyph_name);
	}

	if (gc != null) {
		glyph_collection = (!) gc;
		character = glyph_collection.get_unicode_character ();
		glyph = new Glyph (glyph_collection.get_name (), character);
		glyph.version_id = glyph_collection.get_last_id () + 1;
		glyph_collection.insert_glyph (glyph, true);
	} else {
		return_val_if_fail (glyph_name.char_count () == 1, false);
		character = glyph_name.get_char (0);
		glyph_collection = new GlyphCollection (character, glyph_name);
		glyph = new Glyph (glyph_name, character);
		glyph_collection.insert_glyph (glyph, true);
		font.add_glyph_collection (glyph_collection);
	}

	canvas = MainWindow.get_glyph_canvas ();
	canvas.set_current_glyph_collection (glyph_collection);

	stdout.printf (t_("Adding"));
	stdout.printf (" ");
	stdout.printf ((!) svg_file.get_basename ());
	stdout.printf (" ");
	stdout.printf (t_("to"));
	stdout.printf (" ");
	stdout.printf (t_("Glyph"));
	stdout.printf (": ");
	stdout.printf (glyph.get_name ());
	stdout.printf (" ");
	stdout.printf (t_("Version"));
	stdout.printf (": ");
	stdout.printf (@"$(glyph.version_id)");
	stdout.printf ("\n");
	
	SvgParser.import_svg ((!) svg_file.get_path ());
	
	return true;
}

}
