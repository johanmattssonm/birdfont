/*
    Copyright (C) 2012 Johan Mattsson

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

/** Kerning context. */
public class KerningDisplay : FontDisplay {

	public bool suppress_input = false;
	
	List <GlyphSequence> row;
	int active_handle = -1;
	int selected_handle = -1;
	bool moving = false;
	
	double begin_handle_x = 0;
	double begin_handle_y = 0;
	
	double last_handle_x = 0;

	bool parse_error = false;
	
	public KerningDisplay () {
		GlyphSequence w = new GlyphSequence ();
		row = new List <GlyphSequence> ();
		row.append (w);
	}

	public override string get_label () {
		return _("Kerning");
	}
	
	public override string get_name () {
		return "Kerning";
	}

	public void show_parse_error () {
		parse_error = true;
	}
	
	public override void draw (WidgetAllocation allocation, Context cr) {
		if (parse_error) {
			draw_error_message (allocation, cr);
		} else {
			draw_kerning_pairs (allocation, cr);
		}
	}
	
	public void draw_error_message (WidgetAllocation allocation, Context cr) {
		string line1 = _("The current kerning class is malformed.");
		string line2 = _("Add single characters separated by space and ranges on the form A-Z.");
		string line3 = _("Type “space” to kern the space character and “divis” to kern -.");
		
		cr.save ();
		cr.set_source_rgba (1, 1, 1, 1);
		cr.rectangle (0, 0, allocation.width, allocation.height);
		cr.fill ();
		
		cr.set_font_size (18);
		cr.set_source_rgba (0.3, 0.3, 0.3, 1);
		cr.move_to (30, 40);
		cr.show_text (line1);
		
		cr.set_font_size (14);
		cr.move_to (30, 60);
		cr.show_text (line2);

		cr.set_font_size (14);
		cr.move_to (30, 80);
		cr.show_text (line3);
							
		cr.restore ();
	}
	
	public void draw_kerning_pairs (WidgetAllocation allocation, Context cr) {
		Glyph glyph;
		double x, y, w, kern, alpha;
		double x2;
		int i, wi;
		Glyph? prev;
		GlyphSequence word_with_ligatures;
		GlyphRange? gr_left, gr_right;
		bool first_row = true;
		i = 0;
		
		// bg color
		cr.save ();
		cr.set_source_rgba (1, 1, 1, 1);
		cr.rectangle (0, 0, allocation.width, allocation.height);
		cr.fill ();
		cr.restore ();
	
		alpha = 1;
		y = 100;
		x = 20;
		w = 0;
		prev = null;
		
		foreach (GlyphSequence word in row) {
			wi = 0;
			word_with_ligatures = word.process_ligatures ();
			gr_left = null;
			gr_right = null;
			foreach (Glyph? g in word_with_ligatures.glyph) {
				if (g == null) {
					continue;
				}
				
				if (prev == null || wi == 0) {
					kern = 0;
				} else {
					return_if_fail (wi < word_with_ligatures.ranges.length ());
					return_if_fail (wi - 1 >= 0);
					
					gr_left = word_with_ligatures.ranges.nth (wi - 1).data;
					gr_right = word_with_ligatures.ranges.nth (wi).data;

					kern = get_kerning_for_pair (((!)prev).get_name (), ((!)g).get_name (), gr_left, gr_right);
				}
						
				// draw glyph
				if (g == null) {
					w = 50;
					alpha = 1;
				} else {
					alpha = 0;
					glyph = (!) g;
					Svg.draw_svg_path (cr, glyph.get_svg_data (), x + kern, y);
					w = glyph.get_width ();
				}

				// handle
				if (first_row && (active_handle == i || selected_handle == i)) {
					x2 = x + kern / 2.0;
					
					cr.save ();
					
					if (selected_handle == i) {
						cr.set_source_rgba (0, 0, 0, 1);
					} else { 
						cr.set_source_rgba (123/255.0, 123/255.0, 123/255.0, 1);
					}
					
					cr.move_to (x2 - 5, y + 20);
					cr.line_to (x2 + 0, y + 20 - 5);
					cr.line_to (x2 + 5, y + 20);
					cr.fill ();
					
					if (gr_left != null || gr_right != null) {
						cr.move_to (x2 - 5, y + 22 - 2);
						cr.line_to (x2 + 5, y + 22 - 2);
						cr.line_to (x2 + 5, y + 22 + 2);
						cr.line_to (x2 - 5, y + 22 + 2);
						cr.fill ();
					}
					
					cr.set_font_size (10);
					cr.show_text (((!)g).get_name ());
					cr.restore ();
				}	
				
				x += w + kern;
	
				// caption
				if (g == null || ((!)g).is_empty ()) {
					cr.save ();
					cr.set_source_rgba (153/255.0, 153/255.0, 153/255.0, alpha);
					cr.move_to (x - w / 2.0 - 5, y + 20);
					cr.set_font_size (10);
					cr.show_text ("?"); // ?
					cr.restore ();
				}
							
				prev = g;
				
				wi++;
				i++;
			}
			
			if (y > allocation.height && i > 10) {
				row.remove (word);
			}
						
			y += MainWindow.get_current_glyph ().get_height () + 20;
			x = 20;
			first_row = false;	
		}
	}

	private void display_kerning_value (double k) {
		string kerning_label = _("Kerning:");
		MainWindow.get_tool_tip ().show_text (@"$kerning_label $(k)");
	}
	
	private void set_active_handle_index (int h) {
		double kern = get_kerning_for_handle (h);
		active_handle = h;
		
		if (1 <= active_handle < row.first ().data.glyph.length ()) {
			display_kerning_value (kern);
		}
	}
	
	private double get_kerning_for_handle (int handle) {
		string a, b;
		Font font;
		GlyphRange? gr_left, gr_right;
		bool got_pair;
		
		font = BirdFont.get_current_font ();
		font.touch ();

		got_pair = get_kerning_pair (handle, out a, out b, out gr_left, out gr_right);
		
		if (got_pair) {
			return get_kerning_for_pair (a, b, gr_left, gr_right);
		}
		
		return 0;
	}

	private bool get_kerning_pair (int handle, out string left, out string right, 
		out GlyphRange? range_left, out GlyphRange? range_right) {
		string a, b;
		Font font;
		int wi = 0;
		GlyphSequence word_with_ligatures;
		int ranges_index = 0;
		GlyphRange? gr_left, gr_right;
		int row_index = 0;
		
		font = BirdFont.get_current_font ();

		font.touch ();

		a = "";
		b = "";
		
		left = "";
		right = "";
		range_left = null;
		range_right = null;
		
		if (handle <= 0) {
			return false;
		}
		
		foreach (GlyphSequence word in row) {
			word_with_ligatures = word.process_ligatures ();
			ranges_index = 0;
			foreach (Glyph? g in word_with_ligatures.glyph) {
				
				if (g == null) {
					continue;
				}
				
				b = ((!) g).get_name ();
				
				if (handle == wi && row_index == 0) {
					if (wi >= word_with_ligatures.ranges.length ()) {
						warning (@"$wi > $(word_with_ligatures.ranges.length ()) Number of glyphs: $(word_with_ligatures.glyph.length ())");
						return false;
					}
					return_val_if_fail (wi - 1 >= 0, false);
					
					if (word_with_ligatures.ranges.length () != word_with_ligatures.glyph.length ()) {
						warning (@"ranges and glyphs does not match. $(word_with_ligatures.ranges.length ()) != $(word_with_ligatures.glyph.length ())");
						return false;
					}
					
					gr_left = word_with_ligatures.ranges.nth (wi - 1).data;
					gr_right = word_with_ligatures.ranges.nth (wi).data;
					
					left = a;
					right = b;
					range_left = gr_left;
					range_right = gr_right;
					
					return true;
				}
				
				wi++;
				
				a = b;
			}
			
			row_index++;
		}
		
		return false;	
	}

	private void set_kerning (int handle, double val) {
		string a, b;
		Font font;
		GlyphRange? gr_left, gr_right;
		
		font = BirdFont.get_current_font ();
		font.touch ();

		get_kerning_pair (handle, out a, out b, out gr_left, out gr_right);
		set_kerning_pair (a, b, ref gr_left, ref gr_right, val);
	}

	/** Class based gpos kerning. */
	public void set_kerning_pair (string a, string b, ref GlyphRange? gr_left, ref GlyphRange? gr_right, double val) {
		double kern;
		GlyphRange grl, grr;
		
		kern = get_kerning_for_pair (a, b, gr_left, gr_right);
		
		try {
			if (gr_left == null) {
				grl = new GlyphRange ();
				grl.parse_ranges (a);
				gr_left = grl; // update the range list
			} else {
				grl = (!) gr_left;
			}

			if (gr_right == null) {
				grr = new GlyphRange ();
				grr.parse_ranges (b);
				gr_right = grr;
			} else {
				grr = (!) gr_right;
			}
			
			KerningClasses.get_instance ().set_kerning (grl, grr, kern + val);
			display_kerning_value (kern + val);
		} catch (MarkupError e) {
			// FIXME: unassigned glyphs and ligatures
			warning (e.message);
		}
	}

	/** Class based gpos kerning. */
	public double get_kerning_for_pair (string a, string b, GlyphRange? gr_left, GlyphRange? gr_right) {
		GlyphRange grl, grr;
		try {
			if (gr_left == null) {
				grl = new GlyphRange ();
				grl.parse_ranges (a);
			} else {
				grl = (!) gr_left;
			}

			if (gr_right == null) {
				grr = new GlyphRange ();
				grr.parse_ranges (a);
			} else {
				grr = (!) gr_right;
			}
			
			if (gr_left != null && gr_right != null) {
				return KerningClasses.get_instance ().get_kerning_for_range (grl, grr);
			}

			if (gr_left != null && gr_right == null) {
				return KerningClasses.get_instance ().get_kern_for_range_to_char (grl, b);
			}
			
			if (gr_left == null && gr_right != null) {
				return KerningClasses.get_instance ().get_kern_for_char_to_range (a, grr);
			}
			
			if (gr_left == null && gr_right == null) {
				return KerningClasses.get_instance ().get_kerning (a, b);
			}			
		} catch (MarkupError e) {
			// FIXME: unassigned glyphs and ligatures
			warning (e.message);
		}
		
		warning ("no kerning found");
		
		return 0;
	}
	public override void selected_canvas () {
		Glyph g;
		GlyphSequence w;
		unowned List<GlyphSequence>? r;
		StringBuilder s = new StringBuilder ();
		bool append_char = false;
		Font font = BirdFont.get_current_font ();
		
		KeyBindings.singleton.set_require_modifier (true);
		
		g = MainWindow.get_current_glyph ();
		s.append_unichar (g.get_unichar ());

		r = row;
		return_if_fail (r != null);

		if (row.length () == 0) {
			append_char = true;
		}
		
		if (append_char) {
			w = new GlyphSequence ();
			row.append (w);
			w.glyph.prepend (font.get_glyph (s.str));
		}		
	}
	
	public void add_range (GlyphRange range) {
		Font font = BirdFont.get_current_font ();
		Glyph? glyph;
		
		glyph = font.get_glyph_by_name (range.get_char (0));
		
		if (glyph == null) {
			warning ("Kerning range is not represented by a valid glyph.");
			return;
		}
		
		row.first ().data.glyph.append ((!) glyph);
		row.first ().data.ranges.append (range);
		
		MainWindow.get_glyph_canvas ().redraw ();
	}

	void set_selected_handle (int handle) {
		selected_handle = handle;
		
		if (selected_handle <= 0) {
			selected_handle = 1;
		}
		
		if (selected_handle >= row.first ().data.glyph.length ()) {
			selected_handle = (int) row.first ().data.glyph.length () - 1;
		}
		
		MainWindow.get_glyph_canvas ().redraw ();
	}

	public static void previous_pair () {
		KerningDisplay d = MainWindow.get_kerning_display ();
		d.set_selected_handle (d.selected_handle - 1);
	}
	
	public static void next_pair () {
		KerningDisplay d = MainWindow.get_kerning_display ();
		d.set_selected_handle (d.selected_handle + 1);
	}
	
	public override void key_press (uint keyval) {
		unichar c = (unichar) keyval;
		Glyph? g;
		Font f = BirdFont.get_current_font ();
		string name;
		
		parse_error = false;
		
		if (suppress_input) {
			return;
		}
		
		if (keyval == Key.LEFT && KeyBindings.modifier == NONE) {
			set_kerning (selected_handle, -1);
		}
		
		if (keyval == Key.RIGHT && KeyBindings.modifier == NONE) {
			set_kerning (selected_handle, 1);
		}

		if (KeyBindings.modifier == CTRL && (keyval == Key.LEFT || keyval == Key.RIGHT)) {
			if (keyval == Key.LEFT) { 
				selected_handle--;
			}
			
			if (keyval == Key.RIGHT) {
				selected_handle++;
			}
			
			set_selected_handle (selected_handle);
		}
		
		if (KeyBindings.modifier == NONE || KeyBindings.modifier == SHIFT) {		
			if (keyval == Key.BACK_SPACE && row.length () > 0) {	
				row.first ().data.glyph.remove_link (row.first ().data.glyph.last ());
				row.first ().data.ranges.remove_link (row.first ().data.ranges.last ());
			}
			
			if (row.length () == 0 || c == Key.ENTER) {
				row.prepend (new GlyphSequence ());
			}
			
			if (!is_modifier_key (c) && c.validate ()) {
				name = f.get_name_for_character (c);
				g = f.get_glyph_by_name (name);
				if (g != null) {
					row.first ().data.glyph.append (g);
					row.first ().data.ranges.append (null);
					
					selected_handle = (int) row.first ().data.glyph.length () - 1;
					set_active_handle_index (selected_handle);
				}
			}
		}
		
		MainWindow.get_glyph_canvas ().redraw ();
	}
	
	public override void motion_notify (double ex, double ey) {
		double k, y;
		
		if (!moving) {
			set_active_handle (ex, ey);
		} else {
			y = 1;
			
			if (Math.fabs (ey - begin_handle_y) > 20) {
				y = ((Math.fabs (ey - begin_handle_y) / 100) + 1);
			}
			
			k = (ex - last_handle_x) / y; // y-axis is for variable precision
			set_kerning (selected_handle, k);
			MainWindow.get_glyph_canvas ().redraw ();
		}
		
		last_handle_x = ex;
	}
	
	public void set_active_handle (double ex, double ey) {
		double y = 100;
		double x = 20;
		double w = 0;
		double d, kern;
		double min = double.MAX;
		int i = 0;
		int row_index = 0;
		int col_index = 0;
		Glyph glyph = new Glyph.no_lines ("");
		
		GlyphRange? gr_left, gr_right;
		
		Glyph? prev = null;
		string gl_name = "";
		GlyphSequence word_with_ligatures;
		
		foreach (GlyphSequence word in row) {
			col_index = 0;
			
			word_with_ligatures = word.process_ligatures ();
			foreach (Glyph? g in word_with_ligatures.glyph) {
				if (g == null) {
					w = 50;
					warning ("glyph does not exist");	
				} else {
					glyph = (!) g;
					w = glyph.get_width ();
				}
				
				gl_name = glyph.get_name ();
				
				if (prev == null && col_index != 0) {
					warning (@"previous glyph does not exist row: $row_index column: $col_index");
				}
				
				if (prev == null || col_index == 0) {
					kern = 0;
				} else {
					return_if_fail (col_index < word_with_ligatures.ranges.length ());
					return_if_fail (col_index - 1 >= 0);
					
					gr_left = word_with_ligatures.ranges.nth (col_index - 1).data;
					gr_right = word_with_ligatures.ranges.nth (col_index).data;

					kern = get_kerning_for_pair (((!)prev).get_name (), ((!)g).get_name (), gr_left, gr_right);
				}
								
				d = Math.pow (x + kern - ex, 2) + Math.pow (y - ey, 2);
				
				if (d < min) {
					min = d;
					
					if (active_handle != i - row_index) {
						set_active_handle_index (i - row_index);
						MainWindow.get_glyph_canvas ().redraw ();
					}
					
					if (col_index == word.glyph.length () || col_index == 0) {
						set_active_handle_index (-1);
					} else {
						set_active_handle_index (active_handle + row_index);
					}
				}
				
				prev = g;
				x += w + kern;
				i++;
				col_index++;
			}
			
			row_index++;
			y += MainWindow.get_current_glyph ().get_height () + 20;
			x = 20;
		}
	}
	
	public override void button_release (int button, double ex, double ey) {
		parse_error = false;
		set_active_handle (ex, ey);
		moving = false;
	}
	
	public override void button_press (uint button, double ex, double ey) {
		set_active_handle (ex, ey);
		selected_handle = active_handle;
		begin_handle_x = ex;
		begin_handle_y = ey;
		last_handle_x = ex;
		moving = true;
	}
}

}
