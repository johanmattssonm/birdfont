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
	FcConfig* font_config;

	public FallbackFont () {	
		font_config = FcInitLoadConfigAndFonts ();
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
			font_file = (!) SearchPaths.find_file (null, "Roboto-Regular.ttf").get_path ();
		}
		
		file = (!) font_file;

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

	public StringBuilder? get_glyph_in_font (FontFace* font, unichar c) {
		StringBuilder? glyph_data = null;
		GlyphCollection gc;

		gc = new GlyphCollection (c, (!)c.to_string ());		
		glyph_data = load_glyph (font, (uint) c);

		return glyph_data;
	}
}

}
