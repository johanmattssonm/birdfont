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

[SimpleType]
[CCode (has_type_id = false)]
extern struct FcConfig {
}

[CCode (cname = "FcInitLoadConfigAndFonts")]
extern FcConfig* FcInitLoadConfigAndFonts ();

[CCode (cname = "find_font")]
extern string? find_font (FcConfig* font_config, string characters);

[CCode (cname = "find_font_file")]
extern string? find_font_file (FcConfig* font_config, string font_name);

namespace BirdFont {

// TODO: use font config
public class FallbackFont : GLib.Object {
	Gee.ArrayList<File> font_directories;
	
	FcConfig* font_config;

	public FallbackFont () {
		string home = Environment.get_home_dir ();
		
		font_directories = new Gee.ArrayList<File> ();
		font_config = FcInitLoadConfigAndFonts ();

		add_font_folder ("/usr/share/fonts/");
		add_font_folder ("/usr/local/share/fonts/");
		add_font_folder (home + "/.local/share/fonts");
		add_font_folder (home + "/.fonts");
		add_font_folder ("C:\\Windows\\Fonts");	
		//FIXME: MAC
	}
	
	void add_font_folder (string f) {
		File folder = File.new_for_path (f);
		FileInfo? file_info;
		string fn;
		string file_attributes;
		try {
			if (folder.query_exists ()) {
				font_directories.add (folder);
				
				file_attributes = FileAttribute.STANDARD_NAME;
				file_attributes += ",";
				file_attributes += FileAttribute.STANDARD_TYPE;
				var enumerator = folder.enumerate_children (file_attributes, 0);
				
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

	File search_font_file (string font_file) {
		File d, f;
		
		for (int i = font_directories.size - 1; i >= 0; i--) {
			d = font_directories.get (i);
			f = get_child (d, font_file);
			
			if (f.query_exists ()) {
				return f;
			}
		}
		
		warning (@"The font $font_file not found");
		return File.new_for_path (font_file);
	}
			
	public Font get_single_glyph_font (unichar c) {
		string? font_file;
		BirdFontFile bf_parser;
		Font bf_font;
		StringBuilder? glyph_data;
		FontFace* font;
		File roboto;

		bf_font = new Font ();
		font_file = null;
		glyph_data = null;

		// don't use fallback font for private use area
		if (0xe000 <= c <= 0xf8ff) {
			return bf_font;
		}
		
		// control characters
		if (c <= 0x001f) {
			return bf_font;
		}
		
		// check if glyph is available in roboto
		if (font_file == null) {
			roboto = SearchPaths.search_file (null, "Roboto-Regular.ttf");
			
			if (roboto.query_exists ()) {
				font_file = (!) roboto.get_path ();
			} else {
				roboto = search_font_file ("Roboto-Regular.ttf");
		
				if (roboto.query_exists ()) {
					font_file = (!) roboto.get_path ();
				} else {
					font_file = find_font_file (font_config, "Roboto");
				}
			}
		}
		
		if (font_file != null) {
			font = open_font ((!) font_file);
			glyph_data = get_glyph_in_font (font, c);
			close_font (font);
		}
		
		// use fontconfig to find a fallback font
		if (glyph_data == null) {
			font_file = find_font (font_config, (!) c.to_string ());
			if (font_file != null) {
				font = open_font ((!) font_file);
				glyph_data = get_glyph_in_font (font, c);
				close_font (font);
			}
		}
		
		if (glyph_data != null) {
			bf_parser = new BirdFontFile (bf_font);
			bf_parser.load_data (((!) glyph_data).str);
		}

		return bf_font;		
	}

	public StringBuilder? get_glyph_in_font (FontFace* font, unichar c) {
		StringBuilder? glyph_data = null;
		GlyphCollection gc;

		gc = new GlyphCollection (c, (!)c.to_string ());		
		glyph_data = load_glyph (font, (uint) c);

		return glyph_data;
	}
}

}
