/*
    Copyright (C) 2014 Johan Mattsson

    This library is free software; you can redistribute it and/or modify 
    it under the terms of the GNU Lesser General Public License as 
    published by the Free Software Foundation; either version 3 of the 
    License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful, but 
    WITHOUT ANY WARRANTY; without even the implied warranty of 
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
    Lesser General Public License for more details.
*/

using Cairo;

namespace BirdFont {

/** Test implementation of a birdfont rendering engine. */
public class TextArea {
	
	FontCache font_cache;
	Font font;
	string text;
	GlyphSequence glyph_sequence;
	double line_gap = 20;
	public delegate void Iterator (Glyph glyph, double kerning);
	
	public TextArea () {
		font = new Font ();
		text = "";
		glyph_sequence = new GlyphSequence ();
		font_cache = FontCache.get_default_cache ();
	}

	public void set_font_cache (FontCache font_cache) {
		this.font_cache = font_cache;
	}
	
	public void set_text (string text) {	
		int index;
		unichar c;
		string name;
		Glyph? g;
		
		this.text = text;
		glyph_sequence = new GlyphSequence ();
		
		index = 0;
		while (text.get_next_char (ref index, out c)) {
			name = font.get_name_for_character (c);
			g = font.get_glyph_by_name (name);
			glyph_sequence.glyph.add (g);
		}	
	}

	public void iterate (Iterator iter) {
		Glyph glyph;
		double w, kern;
		int wi;
		Glyph? prev;
		GlyphSequence word_with_ligatures;
		GlyphRange? gr_left, gr_right;
		double row_height;
		GlyphSequence word;
		
		row_height = get_row_height ();
		
		glyph = new Glyph ("", '\0');

		w = 0;
		prev = null;
		kern = 0;
		
		word = glyph_sequence;
		wi = 0;
		word_with_ligatures = word.process_ligatures ();
		gr_left = null;
		gr_right = null;
		foreach (Glyph? g in word_with_ligatures.glyph) {
			if (prev == null || wi == 0) {
				kern = 0;
			} else {
				return_if_fail (wi < word_with_ligatures.ranges.size);
				return_if_fail (wi - 1 >= 0);
				
				gr_left = word_with_ligatures.ranges.get (wi - 1);
				gr_right = word_with_ligatures.ranges.get (wi);

				kern = KerningDisplay.get_kerning_for_pair (((!)prev).get_name (), ((!)g).get_name (), gr_left, gr_right);
			}
					
			// process glyph
			glyph = (g == null) ? font.get_not_def_character ().get_current () : (!) g;
			iter (glyph, kern);
			
			prev = g;
			wi++;
		}
	}

	public double get_max_extent_x (double font_size_in_pixels) {
		double x = 0;
		
		iterate ((glyph, kerning) => {
			x += glyph.get_width () + kerning;
		});
		
		return x;
	}
	
	public bool load_font (string file) {
		Font? f = font_cache.get_font (file);
		
		if (f != null) {
			font = (!) f;
		}
		
		return f != null;
	}
	
	public void draw (Context cr, int px, int py, int width, int height, double font_size_in_pixels) {
		double x, y;
		double row_height, ratio;

		row_height = get_row_height ();		
		ratio = font_size_in_pixels / row_height;
		
		cr.save ();
		cr.scale (ratio, ratio);

		y = get_row_height () + font.base_line + py;
		x = px;
		
		iterate ((glyph, kerning) => {
			double center_x = glyph.allocation.width / 2.0;
			double center_y = glyph.allocation.height / 2.0;

			cr.save ();
			glyph.add_help_lines ();
			cr.translate (kerning + x - center_x - glyph.get_lsb (), y - center_y + glyph.get_baseline ());
			glyph.draw_paths (cr);
			cr.restore ();
			
			x += glyph.get_width () + kerning;
		});
		
		cr.restore ();	
	}	

	double get_row_height () {
		return font.top_limit - font.bottom_limit;
	}
	
	internal static void test () {
		MainWindow.get_tab_bar ().add_tab (new TextTab ());
	}
}

}
