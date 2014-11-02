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
public class Text {

	Font font {
		get {
			if (current_font == null) {
				current_font = new Font ();
				if (!load_font ("testfont.bf")) {
					current_font =  new Font ();
				}
			}
			
			return (!) current_font;
		}
		
		set {
			current_font = value;
		}
	}
	
	FontCache font_cache;
	Font? current_font;
	string text;
	GlyphSequence glyph_sequence;
	double line_gap = 20;
	public delegate void Iterator (Glyph glyph, double kerning);
	
	public Text () {
		current_font = null;
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

				kern = font.get_kerning_classes ().get_kerning_for_pair (((!)prev).get_name (), ((!)g).get_name (), gr_left, gr_right);
			}
					
			// process glyph
			glyph = (g == null) ? font.get_not_def_character ().get_current () : (!) g;
			iter (glyph, kern);
			
			prev = g;
			wi++;
		}
	}

	public double get_extent (double font_size_in_pixels) {
		double x = 0;
		double ratio = font_size_in_pixels / get_row_height ();
		
		iterate ((glyph, kerning) => {
			x += (glyph.get_width () + kerning) * ratio;
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
	
	public void draw (Context cr, double px, double py, double font_size_in_pixels) {
		double x, y;
		double row_height, ratio;

		row_height = get_row_height ();		
		ratio = font_size_in_pixels / row_height;
		
		cr.save ();

		y = ratio * (get_row_height () + font.base_line) + py;
		x = px;
					
		iterate ((glyph, kerning) => {
			double lsb = glyph.left_limit;
			
			glyph.add_help_lines ();
			
			x += kerning * ratio;
			cr.save ();
			cr.new_path ();
			foreach (Path path in glyph.path_list) {
				draw_path (cr, path, lsb, x, y, ratio);
			}
			cr.fill ();
			cr.restore ();
			
			x += glyph.get_width () * ratio;
		});
		
		cr.set_source_rgba (0, 0, 0, 1);
		cr.fill ();

		cr.restore ();	
	}	

	void draw_path (Context cr, Path path, double lsb, double x, double y, double scale) {
		EditPoint e, prev;
		double xa, ya, xb, yb, xc, yc, xd, yd;
			
		if (path.points.size > 0) {

			prev = path.points.get (0);
			xa = (prev.x - lsb) * scale + x;
			ya = y - prev.y * scale;
			cr.move_to (xa, ya);
			
			for (int i = 1; i < path.points.size; i++) {
				e = path.points.get (i).copy ();
				PenTool.convert_point_segment_type (prev, e, PointType.CUBIC);
				
				xb = (prev.get_right_handle ().x - lsb) * scale + x;
				yb = y - prev.get_right_handle ().y * scale;

				xc = (e.get_left_handle ().x - lsb) * scale + x;
				yc = y - e.get_left_handle ().y * scale;
					
				xd = (e.x - lsb) * scale + x;
				yd = y - e.y * scale;
				
				cr.curve_to (xb, yb, xc, yc, xd, yd);
				cr.line_to (xd, yd);
				
				prev = e;
			}
			
			// close path
			e = path.points.get (0);
			
			xb = (prev.get_right_handle ().x - lsb) * scale + x;
			yb = y - prev.get_right_handle ().y * scale;

			xc = (e.get_left_handle ().x - lsb) * scale + x;
			yc = y - e.get_left_handle ().y * scale;
				
			xd = (e.x - lsb) * scale + x;
			yd = y - e.y * scale;
			
			cr.curve_to (xb, yb, xc, yc, xd, yd);
		}
	}

	double get_row_height () {
		return font.top_limit - font.bottom_limit;
	}
	
	internal static void test () {
		MainWindow.get_tab_bar ().add_tab (new TextTab ());
	}
}

}
