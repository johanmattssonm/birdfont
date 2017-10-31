/*
	Copyright (C) 2012, 2014 Johan Mattsson

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

class SvgFontFormatWriter : Object  {

	DataOutputStream os;

	public SvgFontFormatWriter () {
	}

	public void open (File file) throws Error {
		if (file.query_exists ()) {
			throw new FileError.EXIST ("SvgFontFormatWriter: file exists.");
		}
		
		os = new DataOutputStream (file.create(FileCreateFlags.REPLACE_DESTINATION));
	}

	public void close () throws Error {
		os.close ();
	}
	
	public void write_font_file (Font font) throws Error {
		string font_name = font.get_full_name ();
		
		int units_per_em = 100;
		
		int ascent = 80;
		int descent = -20;
		
		StringBuilder b;
		
		Glyph? g;
		Glyph glyph;
		unichar index = 0;
		
		string uni;
		
		KerningClasses classes;
		
		put ("""<?xml version="1.0" standalone="no"?>""");
		put ("""<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd" >""");
		put ("""<svg>""");

		// (metadata goes here)
		
		string font_id = font_name.replace (" ", "-");
		font_id = BirdFontFile.encode (font_id); 
		
		Glyph space = font.get_space ().get_current ();
		double space_width = space.get_width ();
		
		put (@"<font id=\"$font_id\" horiz-adv-x=\"$(to_float (space_width))\" >");
		put (@"<font-face units-per-em=\"$(to_float (units_per_em))\" ascent=\"$(to_float (ascent))\" descent=\"$(to_float (descent))\" />");

		// (missing-glyph goes here)

		// regular glyphs 
		while (true) {
			g = font.get_glyph_index (index++);
			
			if (g == null) {
				break;
			}
			
			glyph = (!) g;
			
			b = new StringBuilder ();
			b.append_unichar (glyph.get_unichar ());

			if (glyph.get_unichar () >= ' ' && b.str.validate ()) {
				if (b.str == "\"" || b.str == "&" || b.str == "<" || b.str == ">") {
					uni = Font.to_hex_code (glyph.get_unichar ());
					put (@"<glyph unicode=\"&#x$(uni);\" horiz-adv-x=\"$(to_float (glyph.get_width ()))\" d=\"$(glyph.get_svg_data ())\" />");			
				} else {
					put (@"<glyph unicode=\"$(b.str)\" horiz-adv-x=\"$(to_float (glyph.get_width ()))\" d=\"$(glyph.get_svg_data ())\" />");
				}
			}
		}
		
		// FIXME: ligatures
		classes = BirdFont.get_current_font ().get_kerning_classes ();
		classes.all_pairs ((kerning) => {
			string l, r;
			
			foreach (Kerning k in kerning.kerning) {
				try {
					if (k.glyph != null) {
						l = Font.to_hex_code (kerning.character.unichar_code);
						r = Font.to_hex_code (((!)k.glyph).unichar_code);	
						os.put_string (@"<hkern u1=\"&#x$l;\" u2=\"&#x$r;\" k=\"$(to_float (-k.val))\"/>\n");
					} else {
						warning ("No glyph.");
					}
				} catch (GLib.Error e) {
					warning (e.message);
				}
			}
		});	

		put ("</font>");
		put ("</svg>");
	}

	string to_float (double d) {
		string s = @"$d";
		if (s.index_of ("e") != -1) {
			return "0".dup ();
		}
		return s.replace (",", ".");
	}

	/** Write a new line */
	private void put (string line) throws Error {
		os.put_string (line);
		os.put_string ("\n");
	}

}


}
