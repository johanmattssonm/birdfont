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
public class Text : Widget {

	public Font font {
		get {
			if (current_font == null) {
				File path = SearchPaths.find_file (null, "roboto.bf");
				current_font = new Font ();
				if (!load_font ((!) path.get_path ())) {
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
	public string text;
	GlyphSequence glyph_sequence;
	public delegate void Iterator (Glyph glyph, double kerning, bool last);
	double font_size;
	
	public Text (string text = "", double size = 17, double margin_bottom = 0) {
		current_font = null;
		this.margin_bottom = margin_bottom;
		glyph_sequence = new GlyphSequence ();
		font_cache = FontCache.get_default_cache ();
		
		set_text (text);
		set_font_size (size);
	}

	public void set_font_size (double height_in_pixels) {
		font_size = height_in_pixels;
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

	/** @param character a string with a single glyph or the name of the glyph if it is a ligature. */
	public bool has_character (string character) {
		return font.has_glyph (character);
	}

	public void iterate (Iterator iter) {
		Glyph glyph;
		double w, kern;
		int wi;
		Glyph? prev;
		GlyphSequence word_with_ligatures;
		GlyphRange? gr_left, gr_right;
		GlyphSequence word;
		Glyph? g;
		
		glyph = new Glyph ("", '\0');

		w = 0;
		prev = null;
		kern = 0;
		
		word = glyph_sequence;
		wi = 0;
		word_with_ligatures = word.process_ligatures ();
		gr_left = null;
		gr_right = null;
		for (int i = 0; i < word_with_ligatures.glyph.size; i++) {
			g = word_with_ligatures.glyph.get (i);
			
			if (g == null || prev == null || wi == 0) {
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
			iter (glyph, kern, i + 1 == word_with_ligatures.glyph.size);
			
			prev = g;
			wi++;
		}
	}

	// FIXME: some fonts doesn't have on curve extrema
	public double get_extent () {
		double x = 0;
		double ratio = get_scale ();

		iterate ((glyph, kerning, last) => {
			double x1, y1, x2, y2;
			double lsb;
			
			glyph.add_help_lines ();
			lsb = glyph.left_limit;
			
			if (!last) {
				x += (glyph.get_width () + kerning) * ratio;
			} else {
				glyph.boundaries (out x1, out y1, out x2, out y2);
				x += (x2 - lsb) * ratio;
			}
		});
		
		return x;
	}

	public double get_sidebearing_extent () {
		double x = 0;
		double ratio = get_scale ();

		iterate ((glyph, kerning, last) => {
			double lsb;
			
			glyph.add_help_lines ();
			lsb = glyph.left_limit;
			x += (glyph.get_width () + kerning) * ratio;
		});
		
		return x;
	}

	public override double get_height () {
		return font_size;
	}

	public double get_glyph_height () {
		double ratio = get_scale ();
		double max_height = 0;

		iterate ((glyph, kerning, last) => {
			double x1, y1, x2, y2;
			double h;
			glyph.boundaries (out x1, out y1, out x2, out y2);
			h = Math.fmax (y1, y2) - Math.fmin (y1, y2) ;
			if (h > max_height) {
				max_height = h;
			}
		});
		
		return max_height * ratio;
	}	

	public override double get_width () {
		double x = 0;
		double ratio = get_scale ();
		bool first = true;
		
		iterate ((glyph, kerning, last) => {
			double x1, y1, x2, y2;
			double lsb;
			
			glyph.add_help_lines ();
			lsb = glyph.left_limit;
			
			if (first) {
				glyph.boundaries (out x1, out y1, out x2, out y2);
				x += (glyph.get_width () + kerning - Math.fmin (x1, x2)) * ratio;
				first = false;
			} else if (!last) {
				x += (glyph.get_width () + kerning) * ratio;
			} else {
				glyph.boundaries (out x1, out y1, out x2, out y2);
				x += (x2 - lsb) * ratio;
			}
		});
		
		return x;
	}

	public double get_decender (double font_size_in_pixels) {
		double ratio = get_scale ();
		double min_y = 0;
		double decender;
		
		iterate ((glyph, kerning, last) => {
			double x1, y1, x2, y2;
			double y;
			glyph.boundaries (out x1, out y1, out x2, out y2);
			y = Math.fmin (y1, y2);
			if (y < min_y) {
				min_y = y;
			}
		});
		
		decender = font.base_line - (min_y * ratio);
		return decender > 0 ? decender : 0; 
	}		

	public bool load_font (string file) {
		Font? f = font_cache.get_font (file);
		
		if (f != null) {
			font = (!) f;
		}
		
		return f != null;
	}
	
	public override void draw (Context cr) {
		double y = widget_y + get_height () + get_scale () * (font.bottom_limit + font.base_line);
		draw_at_baseline (cr, widget_x, y);
	}
	
	public void draw_at_baseline (Context cr, double px, double py) {
		double x, y;
		double ratio;

		ratio = get_scale ();
		
		cr.save ();

		y = py;
		x = px;
					
		iterate ((glyph, kerning, last) => {
			double lsb;
			
			glyph.add_help_lines ();
			
			lsb = glyph.left_limit;
			
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
		double by;
		
		if (path.points.size > 0) {

			prev = path.points.get (0);
			xa = (prev.x - lsb) * scale + x;
			ya = y - prev.y * scale;
			cr.move_to (xa, ya);
			
			by = (y - font.base_line * scale);
			for (int i = 1; i < path.points.size; i++) {
				e = path.points.get (i).copy ();
				PenTool.convert_point_segment_type (prev, e, PointType.CUBIC);
				
				xb = (prev.get_right_handle ().x - lsb) * scale + x;
				yb = by - prev.get_right_handle ().y * scale;

				xc = (e.get_left_handle ().x - lsb) * scale + x;
				yc = by - e.get_left_handle ().y * scale;
					
				xd = (e.x - lsb) * scale + x;
				yd = by - e.y * scale;
				
				cr.curve_to (xb, yb, xc, yc, xd, yd);
				cr.line_to (xd, yd);
				
				prev = e;
			}
			
			// close path
			e = path.points.get (0);
			
			xb = (prev.get_right_handle ().x - lsb) * scale + x;
			yb = by - prev.get_right_handle ().y * scale;

			xc = (e.get_left_handle ().x - lsb) * scale + x;
			yc = by - e.get_left_handle ().y * scale;
				
			xd = (e.x - lsb) * scale + x;
			yd = by - e.y * scale;
			
			cr.curve_to (xb, yb, xc, yc, xd, yd);
		}
	}

	public double get_scale () {
		return font_size / (font.top_limit - font.bottom_limit);
	}
}

}
