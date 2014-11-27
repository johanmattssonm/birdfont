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
				load_default_font ();
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
	
	GlyphSequence glyph_sequence {
		get {
			if (gs == null) {
				gs = generate_glyphs ();
			}
			
			return (!) gs;
		}
	}
	
	GlyphSequence? gs = null;
	
	public delegate void Iterator (Glyph glyph, double kerning, bool last);
	public double font_size;
	public double sidebearing_extent = 0;

	double r = 0;
	double g = 0;
	double b = 0;
	double a = 1;
			
	public Text (string text = "", double size = 17, double margin_bottom = 0) {
		current_font = null;
		this.margin_bottom = margin_bottom;
		font_cache = FontCache.get_default_cache ();
		
		set_font_size (size);
		set_text (text);
	}

	public static void load_default_font () {
		File path = SearchPaths.find_file (null, "roboto.bf");
		if (FontCache.get_default_cache ().get_font ((!) path.get_path ()) == null) {
			warning ("Default font not found.");
		}
	}

	public void set_font_size (double height_in_pixels) {
		font_size = height_in_pixels;
		sidebearing_extent = 0;
	}

	public void set_font_cache (FontCache font_cache) {
		this.font_cache = font_cache;
	}
	
	public void set_text (string text) {	
		this.text = text;
		gs = null;
	}

	private GlyphSequence generate_glyphs () {
		int index;
		unichar c;
		string name;
		Glyph? g;
		GlyphSequence gs;
		
		gs = new GlyphSequence ();
		
		index = 0;
		while (text.get_next_char (ref index, out c)) {
			name = font.get_name_for_character (c);
			g = font.get_glyph_by_name (name);
			gs.glyph.add (g);
		}
		
		return gs;
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
		KerningClasses kc;
		
		glyph = new Glyph ("", '\0');

		w = 0;
		prev = null;
		kern = 0;
		
		word = glyph_sequence;
		wi = 0;

		word_with_ligatures = word.process_ligatures ();
		
		gr_left = null;
		gr_right = null;
		kc = font.get_kerning_classes ();
		for (int i = 0; i < word_with_ligatures.glyph.size; i++) {

			g = word_with_ligatures.glyph.get (i);
			
			if (g == null || prev == null || wi == 0) {
				kern = 0;
			} else {
				return_if_fail (wi < word_with_ligatures.ranges.size);
				return_if_fail (wi - 1 >= 0);
				
				gr_left = word_with_ligatures.ranges.get (wi - 1);
				gr_right = word_with_ligatures.ranges.get (wi);

				kern = kc.get_kerning_for_pair (((!) prev).get_name (), ((!) g).get_name (), gr_left, gr_right);
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
		double x ;
		double ratio;
		
		if (likely (sidebearing_extent > 0)) {
			return sidebearing_extent;
		}
		
		x = 0;
		ratio = get_scale ();

		if (unlikely (ratio == 0)) {
			warning ("No scale.");
		}
				
		iterate ((glyph, kerning, last) => {
			double lsb;
			lsb = glyph.left_limit;
			x += (glyph.get_width () + kerning) * ratio;
		});
		
		sidebearing_extent = x;
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
	
	public void draw_at_top (Context cr, double px, double py, int64 cacheid = -1) {
		double s = get_scale ();
		double y = py + s * (font.top_limit - font.base_line);
		draw_at_baseline (cr, px, y, cacheid);
	}
	
	public void set_source_rgba (double r, double g, double b, double a) {
		this.r = r;
		this.g = g;
		this.b = b;
		this.a = a;
	}
	
	public int64 get_cache_id () {
		int64 s = (((int64) font_size) << 32) 
			| (((int64) (r * 255)) << 24)
			| (((int64) (g * 255)) << 16)
			| (((int64) (b * 255)) << 8)
			| (((int64) (a * 255)) << 0);
		return s;
	}
	
	public void draw_at_baseline (Context cr, double px, double py, int64 cacheid = -1) {
		double x, y;
		double ratio;
		double cc_y;
		int64 cache_id = (cacheid < 0) ? get_cache_id () : cacheid;
			
		ratio = get_scale ();
		cc_y = (font.top_limit - font.base_line) * ratio;

		y = py;
		x = px;
					
		iterate ((glyph, kerning, last) => {
			double lsb;
			Surface cache;
			Context cc;
			
			if (unlikely (!glyph.has_cache (cache_id))) {
				glyph.add_help_lines ();
				
				cache = new Surface.similar (cr.get_target (), Cairo.Content.COLOR_ALPHA, (int) (glyph.get_width () * ratio) + 1, (int) font_size + 1);
				cc = new Context (cache);
				
				lsb = glyph.left_limit;

				cc.save ();
				cc.set_source_rgba (r, g, b, a);
				cc.new_path ();

				foreach (Path path in glyph.path_list) {
					draw_path (cc, path, lsb, 0, cc_y, ratio);
				}
				
				cc.fill ();
				cc.restore ();

				glyph.set_cache (cache_id, cache);
			}

			x += kerning * ratio;
			cr.set_source_surface (glyph.get_cache (cache_id), x, y - cc_y);
			x += glyph.get_width () * ratio;
			
			cr.paint ();
		});
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

	public double get_baseline_to_bottom () {
		return get_scale () * (-font.base_line - font.bottom_limit);
	}

	public double get_scale () {
		return font_size / (font.top_limit - font.bottom_limit);
	}
}

}
