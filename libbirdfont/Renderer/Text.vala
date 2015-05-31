/*
    Copyright (C) 2014 2015 Johan Mattsson

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
	FontCache font_cache;
	public CachedFont cached_font;
	
	public string text;
	
	GlyphSequence glyph_sequence {
		get {
			if (gs == null) {
				gs = generate_glyphs ();
			}
			
			return (!) gs;
		}
	}
	
	Gee.ArrayList<string> glyph_names;
	GlyphSequence? gs = null;
	
	public delegate void Iterator (Glyph glyph, double kerning, bool last);
	public double font_size;
	public double sidebearing_extent = 0;

	double r = 0;
	double g = 0;
	double b = 0;
	double a = 1;
	
	bool use_cached_glyphs = true;
	double truncated_width = -1;
	
	public Text (string text = "", double size = 17, double margin_bottom = 0) {
		this.margin_bottom = margin_bottom;
		font_cache = FontCache.get_default_cache ();
		cached_font = font_cache.get_fallback ();
		
		set_text (text);
		set_font_size (size);
	}
	
	public void use_cache (bool cache) {
		use_cached_glyphs = cache;
	}
	
	/** Set font for this text area.
	 * @param font_absolute path to the font file or a file name for one of the font files in search paths.
	 * @return true if the font was found
	 */
	public bool load_font (string font_file) {
		File path;
		File f;
		FontCache fc;
		
		f = File.new_for_path (font_file);
		path = (f.query_exists ()) ? f : SearchPaths.find_file (null, font_file);
		
		fc = FontCache.get_default_cache ();
		cached_font = fc.get_font ((!) path.get_path ());
		gs = generate_glyphs ();
		
		return cached_font.font != null;
	}
	
	public void set_font_size (double height_in_pixels) {
		font_size = height_in_pixels;
		sidebearing_extent = 0;
		
		if (gs == null) { // ensure height is loaded for the font
			gs = generate_glyphs ();
		}
	}

	public void set_font_cache (FontCache font_cache) {
		this.font_cache = font_cache;
	}
	
	public void set_text (string text) {	
		this.text = text;
		gs = null;
		sidebearing_extent = 0;
	}

	private GlyphSequence generate_glyphs () {
		int index;
		unichar c;
		string name;
		Glyph? g;
		GlyphSequence gs;
		
		gs = new GlyphSequence ();
		
		glyph_names = new Gee.ArrayList<string> ();
		index = 0;
		while (text.get_next_char (ref index, out c)) {
			name = (!) c.to_string ();
			g = cached_font.get_glyph_by_name (name);
			
			gs.glyph.add (g);
			glyph_names.add (name);
		}
		
		return gs;
	}

	public void iterate (Iterator iter) {
		Glyph glyph;
		double w, kern;
		int wi;
		Glyph? prev;
		Glyph? g;
		GlyphSequence word_with_ligatures;
		GlyphRange? gr_left, gr_right;
		GlyphSequence word;
		KerningClasses kc;
		Font empty = new Font ();
		
		glyph = new Glyph.no_lines ("", '\0');

		w = 0;
		prev = null;
		kern = 0;
	
		word = glyph_sequence;
		wi = 0;
	
		if (cached_font.font != null) {
			word_with_ligatures = word.process_ligatures ((!) cached_font.font);
		} else {
			word_with_ligatures = word.process_ligatures (new Font ());
		}
		
		gr_left = null;
		gr_right = null;
		
		if (cached_font.font != null) {
			kc = ((!) cached_font.font).get_kerning_classes ();
		} else {
			kc = new KerningClasses (empty);
		}	

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
			if (g == null && (0 <= i < glyph_names.size)) {
				g = cached_font.get_glyph_by_name (glyph_names.get (i));
			}
			
			glyph = (g == null) ? new Glyph ("") : (!) g;
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

	public double get_acender () {
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
		
		return max_height * ratio - cached_font.base_line * ratio;
	}	

	public override double get_width () {
		double x = 0;
		double ratio = get_scale ();
		bool first = true;
		
		iterate ((glyph, kerning, last) => {
			double x1, y1, x2, y2;
			double lsb;
			
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

	public double get_decender () {
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
		
		decender = cached_font.base_line * ratio - min_y * ratio;
		return decender > 0 ? decender : 0; 
	}		
	
	public override void draw (Context cr) {
		double descender = cached_font.bottom_limit + cached_font.base_line;
		double y = widget_y + get_height () + get_scale () * descender;
		draw_at_baseline (cr, widget_x, y);
	}
	
	public void draw_at_top (Context cr, double px, double py, string cacheid = "") {
		double s = get_scale ();
		double y = py + s * (cached_font.top_limit - cached_font.base_line);
		draw_at_baseline (cr, px, y, cacheid);
	}
	
	public void set_source_rgba (double r, double g, double b, double a) {
		this.r = r;
		this.g = g;
		this.b = b;
		this.a = a;
	}
	
	public string get_cache_id (int offset_x, int offset_y) {
		string key;
		int64 c;
		
		c = (((int64) (r * 255)) << 24)
			| (((int64) (g * 255)) << 16)
			| (((int64) (b * 255)) << 8)
			| (((int64) (a * 255)) << 0);
		
		// FIXME: use binary key
		key = @"$font_size $c $offset_x $offset_y";
		
		return key;
	}
	
	public void draw_at_baseline (Context cr, double px, double py, string cacheid = "") {
		double x, y;
		double ratio;
		double cc_y;

		ratio = get_scale ();
		cc_y = (cached_font.top_limit - cached_font.base_line) * ratio;

		y = py;
		x = px;

		if (unlikely (cached_font.base_line != 0)) {
			warning ("Base line not zero.");
		}

		if (use_cached_glyphs) {
			iterate ((glyph, kerning, last) => {
				double end;
				
				x += kerning * ratio;
				end = x + glyph.get_width () * ratio;
				
				// truncation
				if (truncated_width > 0 && end - px > truncated_width) {
					return;
				}

				draw_chached (cr, glyph, kerning, last, x, y, cc_y, 
					ratio, cacheid);
				
				x = end;
			});
		} else {
			iterate ((glyph, kerning, last) => {
				double end;
				
				x += kerning * ratio;
				end = x + glyph.get_width () * ratio;
				
				// truncation
				if (truncated_width > 0 && end - px > truncated_width) {
					return;
				}
				
				draw_without_cache (cr, glyph, kerning, last, x, y, cc_y, ratio);
				x = end;
			});
		}
	}
	
	void draw_without_cache (Context cr, Glyph glyph, double kerning, bool last, 
		double x, double y, double cc_y, double ratio) {
	
		double lsb;
		
		cr.save ();
		cr.set_source_rgba (r, g, b, a);
		cr.new_path ();

		lsb = glyph.left_limit;

		foreach (Path path in glyph.path_list) {
			draw_path (cr, glyph, path, lsb, x, y, ratio);
		}

		cr.fill ();
		cr.restore ();
		
	}
	
	void draw_chached (Context cr, Glyph glyph, double kerning, bool last, 
		double x, double y, double cc_y, double ratio,
		string cacheid = "") {
		
		double lsb;
		Surface cache;
		Context cc;
		string cache_id;
		double xp = x;
		double yp = y - cc_y;
		int offset_x, offset_y;

		offset_x = (int) (10 * (xp - (int) xp));
		offset_y = (int) (10 * (yp - (int) yp));
		
		cache_id = (cacheid == "") ? get_cache_id (offset_x, offset_y) : cacheid;		
				
		if (unlikely (!glyph.has_cache (cache_id))) {
			cache = new Surface.similar (cr.get_target (), Cairo.Content.COLOR_ALPHA, (int) (glyph.get_width () * ratio) + 2, (int) font_size + 2);
			cc = new Context (cache);
			
			lsb = glyph.left_limit;

			cc.save ();
			cc.set_source_rgba (r, g, b, a);
			cc.new_path ();

			foreach (Path path in glyph.path_list) {
				draw_path (cc, glyph, path, lsb, offset_x / 10.0, cc_y + offset_y / 10.0, ratio);
			}
			
			cc.fill ();
			cc.restore ();

			glyph.set_cache (cache_id, cache);
		}

		cr.save ();
		cr.set_antialias (Cairo.Antialias.NONE);
		cr.set_source_surface (glyph.get_cache (cache_id), (int) xp, (int) yp);		
		cr.paint ();
		cr.restore ();
	}
	
	void draw_path (Context cr, Glyph glyph, Path path,
		double lsb, double x, double y, double scale) {
			
		EditPoint e, prev;
		double xa, ya, xb, yb, xc, yc, xd, yd;
		double by;
		double s = get_scale ();
		
		if (path.points.size > 0) {
			if (unlikely (path.is_open ())) {
				warning (@"Path is open in $(glyph.get_name ()).");
			}
			
			//path.add_hidden_double_points (); // FIXME: this distorts shapes
				
			prev = path.points.get (path.points.size - 1);
			xa = (prev.x - lsb) * s + x;
			ya = y - prev.y * s;
			cr.move_to (xa, ya);
			
			by = (y - cached_font.base_line * s);
			for (int i = 0; i < path.points.size; i++) {
				e = path.points.get (i).copy ();
				
				PenTool.convert_point_segment_type (prev, e, PointType.CUBIC);
				
				xb = (prev.get_right_handle ().x - lsb) * s + x;
				yb = by - prev.get_right_handle ().y * s;

				xc = (e.get_left_handle ().x - lsb) * s + x;
				yc = by - e.get_left_handle ().y * s;
					
				xd = (e.x - lsb) * s + x;
				yd = by - e.y * s;

				cr.curve_to (xb, yb, xc, yc, xd, yd);
				cr.line_to (xd, yd);
				
				prev = e;
			}
		}
	}

	public double get_baseline_to_bottom () {
		return get_scale () * (-cached_font.base_line - cached_font.bottom_limit);
	}

	public double get_scale () {
		return font_size / (cached_font.top_limit - cached_font.bottom_limit);
	}

	public void truncate (double max_width) {
		truncated_width = max_width;
	}
}

}
