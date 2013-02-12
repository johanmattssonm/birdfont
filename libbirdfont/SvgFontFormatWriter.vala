/*
    Copyright (C) 2012 Johan Mattsson

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
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
		string font_name = font.get_name ();
		
		int units_per_em = 100;
		
		int ascent = 80;
		int descent = -20;
		
		StringBuilder b;
		
		Glyph? g;
		Glyph glyph;
		unichar indice = 0;
		
		string uni;
		
		put ("""<?xml version="1.0" standalone="no"?>""");
		put ("""<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd" >""");
		put ("""<svg xmlns="http://www.w3.org/2000/svg">""");

		// (metadata goes here)

		put ("<defs>");

		put (@"<font id=\"$font_name\" horiz-adv-x=\"250\" >");
		put (@"<font-face units-per-em=\"$units_per_em\" ascent=\"$ascent\" descent=\"$descent\" />");

		// (missing-glyph goes here)

		while (true) {
			g = font.get_glyph_indice (indice++);
			
			if (g == null) {
				break;
			}
			
			glyph = (!) g;
			
			b = new StringBuilder ();
			b.append_unichar (glyph.get_unichar ());

			if (glyph.get_unichar () >= ' ' && b.str.validate ()) {
				if (b.str == "\"" || b.str == "&" || b.str == "<") {
					uni = Font.to_hex_code (glyph.get_unichar ());
					put (@"<glyph unicode=\"&#x$(uni);\" horiz-adv-x=\"$(glyph.get_width ())\" d=\"$(glyph.get_svg_data ())\" />");			
				} else {
					put (@"<glyph unicode=\"$(b.str)\" horiz-adv-x=\"$(glyph.get_width ())\" d=\"$(glyph.get_svg_data ())\" />");
				}
			}
		}

		indice = 0;
		while (true) {
			g = font.get_glyph_indice (indice++);
			
			if (g == null) {
				break;
			}
			
			glyph = (!) g;
			
			foreach (Kerning k in glyph.kerning) {
				string l, r;
				Font f = BirdFont.get_current_font ();
				Glyph? gr = f.get_glyph (k.glyph_right);
				Glyph glyph_right;
				
				if (gr == null) {
					warning ("kerning glyph that does not exist.");
					continue;
				}
				
				glyph_right = (!) gr;
				
				l = Font.to_hex_code (glyph.unichar_code);
				r = Font.to_hex_code (glyph_right.unichar_code);
								
				os.put_string (@"<hkern u1=\"&#x$l;\" u2=\"&#x$r;\" k=\"$(-k.val)\"/>\n");
			}
		}		

		put ("</font>");
		put ("</defs>");
		put ("</svg>");
	}

	/** Write a new line */
	private void put (string line) throws Error {
		os.put_string (line);
		os.put_string ("\n");
	}

}


}
