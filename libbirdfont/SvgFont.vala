/*
    Copyright (C) 2013 Johan Mattsson

    This library is free software; you can redistribute it and/or modify 
    it under the terms of the GNU Lesser General Public License as 
    published by the Free Software Foundation; either version 3 of the 
    License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful, but 
    WITHOUT ANY WARRANTY; without even the implied warranty of 
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
    Lesser General Public License for more details.
*/

using Bird;

namespace BirdFont {

class SvgFont : GLib.Object {
	Font font;
	double units = 1; // 1000 is default in svg spec.
	double font_advance = 0;
	
	public SvgFont (Font f) {
		this.font = f;
	}
	
	/** Load svg font from file. */
	public void load (string path) {
		string data;
		XmlParser xml_parser;
		try {
			FileUtils.get_contents (path, out data);
			xml_parser = new XmlParser (data);
			parse_svg_font (xml_parser.get_next_tag ());
		} catch (GLib.Error e) {
			warning (e.message);
		}
	}
	
	void parse_svg_font (Tag tag) {
		Tag t;
		
		tag.reparse ();
		while (tag.has_more_tags ()) {
			t = tag.get_next_tag ();
			
			if (t.get_name () == "defs") {
				parse_svg_font (t);
			}
			
			if (t.get_name () == "font") {
				parse_font_tag (t);
				parse_svg_font (t);
			}

			if (t.get_name () == "font-face") {
				parse_font_limits (t);
			}

			if (t.get_name () == "hkern") {
				parse_hkern (t);
			}
									
			if (t.get_name () == "glyph") {
				parse_glyph (t);
			}
		}		
	}

	void parse_hkern (Tag tag) {
		string left = "";
		string right = "";
		string left_name = "";
		string right_name = "";
		double kerning = 0;
		unichar l, r;
		StringBuilder sl, sr;
		GlyphRange grr, grl;
		Attribute attr;
		
		tag.reparse ();
		while (tag.has_more_attributes ()) {
			attr = tag.get_next_attribute ();
			
			// left
			if (attr.get_name () == "u1") {
				left = attr.get_content ();
			}	
					
			// right	
			if (attr.get_name () == "u2") {
				right = attr.get_content ();
			}

			if (attr.get_name () == "g1") {
				left_name = attr.get_content ();
			}
			
			if (attr.get_name () == "g2") {
				right_name = attr.get_content ();
			}
				
			// kerning
			if (attr.get_name () == "k") {
				kerning = double.parse (attr.get_content ()) * units;
			}
		}
				
		// FIXME: ranges and sequences for u1 & u2 + g1 & g2
		foreach (string lk in left.split (",")) {
			foreach (string rk in right.split (",")) {
				l = get_unichar (lk);
				r = get_unichar (rk);
				
				sl = new StringBuilder ();
				sl.append_unichar (l);
				
				sr = new StringBuilder ();
				sr.append_unichar (r);
				
				try {
					grl = new GlyphRange ();
					grl.parse_ranges (sl.str);
					
					grr = new GlyphRange ();
					grr.parse_ranges (sr.str);
				
					KerningClasses.get_instance ().set_kerning (grl, grr, -kerning);
				} catch (MarkupError e) {
					warning (e.message);
				}		
			}
		}
	}

	void parse_font_limits (Tag tag) {
		double top_limit = 0;
		double bottom_limit = 0;
		Attribute attr;
		
		tag.reparse ();
		while (tag.has_more_attributes ()) {
			attr = tag.get_next_attribute ();
			
			if (attr.get_name () == "units-per-em") {
				units = 100.0 / double.parse (attr.get_content ());
			}	
		}

		tag.reparse ();
		while (tag.has_more_attributes ()) {
			attr = tag.get_next_attribute ();
					
			if (attr.get_name () == "ascent") {
				top_limit = double.parse (attr.get_content ());
			}
			
			if (attr.get_name () == "descent") {
				bottom_limit = double.parse (attr.get_content ());
			}		
		}
		
		top_limit *= units;
		bottom_limit *= units;
		
		font.bottom_limit = bottom_limit;
		font.top_limit = top_limit;
	}
	
	void parse_font_tag (Tag tag) {
		Attribute attr;
		
		tag.reparse ();
		while (tag.has_more_attributes ()) {
			attr = tag.get_next_attribute ();
			
			if (attr.get_name () == "horiz-adv-x") {
				font_advance = double.parse (attr.get_content ());
			}
						
			if (attr.get_name () == "id") {
				font.set_name (attr.get_content ());
			}
		}
	}
	
	/** Obtain unichar value from either a character, a hex representation of
	 *  a character or series of characters (f, &#x6d; or ffi).
	 */
	static unichar get_unichar (string val) {
		string v = val;
		unichar unicode_value;
		
		if (val == "&") {
			return '&';
		}
		
		// TODO: parse ligatures
		if (v.has_prefix ("&")) {
			// parse hex value
			v = v.substring (0, v.index_of (";"));
			v = v.replace ("&#x", "U+");
			v = v.replace (";", "");
			unicode_value = Font.to_unichar (v);
		} else {
			// obtain unicode value
			
			if (v.char_count () > 1) {
				warning ("font contains ligatures");
				return '\0';
			}
			
			unicode_value = v.get_char (0);
		}
		
		return unicode_value;	
	}
	
	bool is_ligature (string v) {
		if (v.has_prefix ("&")) {
			return false;
		}
		
		return v.char_count () > 1;
	}
	
	void parse_glyph (Tag tag) {
		unichar unicode_value = 0;
		string glyph_name = "";
		string svg = "";
		Glyph glyph;
		GlyphCollection glyph_collection;
		double advance = font_advance;
		string ligature = "";
		SvgParser parser = new SvgParser ();
		Attribute attr;

		parser.set_format (SvgFormat.INKSCAPE);

		tag.reparse ();
		while (tag.has_more_attributes ()) {
			attr = tag.get_next_attribute ();

			if (attr.get_name () == "unicode") {
				unicode_value = get_unichar (attr.get_content ());
				
				if (glyph_name == "") {
					glyph_name = attr.get_content ();
				}
				
				if (is_ligature (attr.get_content ())) {
					ligature = attr.get_content ();
				}
			}
			
			// svg data
			if (attr.get_name () == "d") {
				svg = attr.get_content ();
			}
			
			if (attr.get_name () == "glyph-name") {
				glyph_name = attr.get_content ();
			}

			if (attr.get_name () == "horiz-adv-x") {
				advance = double.parse (attr.get_content ());
			}
		}

		glyph = new Glyph (glyph_name, unicode_value);
		parser.add_path_to_glyph (svg, glyph, true, units);			
		glyph.right_limit = glyph.left_limit + advance * units;
		
		if (ligature != "") {
			glyph.set_ligature_substitution (ligature);
		}
		
		glyph_collection = new GlyphCollection (unicode_value, glyph_name);
		glyph_collection.insert_glyph (glyph, true);
		
		font.add_glyph_collection (glyph_collection);
	}
}

}
