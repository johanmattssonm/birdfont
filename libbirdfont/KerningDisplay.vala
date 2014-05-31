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

using Cairo;

namespace BirdFont {

/** Kerning context. */
public class KerningDisplay : FontDisplay {

	public bool suppress_input = false;
	
	Gee.ArrayList <GlyphSequence> row;
	int active_handle = -1;
	int selected_handle = -1;
	bool moving = false;
	
	double begin_handle_x = 0;
	double begin_handle_y = 0;
	
	double last_handle_x = 0;

	bool parse_error = false;
	bool text_input = false;
	
	public KerningDisplay () {
		GlyphSequence w = new GlyphSequence ();
		row = new Gee.ArrayList <GlyphSequence> ();
		row.add (w);
	}

	public override string get_label () {
		return t_("Kerning");
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
		string line1 = t_("The current kerning class is malformed.");
		string line2 = t_("Add single characters separated by space and ranges on the form A-Z.");
		string line3 = t_("Type “space” to kern the space character and “divis” to kern -.");
		
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
	
	double get_row_height () {
		Font font = BirdFont.get_current_font ();
		return font.top_limit - font.bottom_limit;
	}
	
	public void draw_kerning_pairs (WidgetAllocation allocation, Context cr) {
		Glyph glyph;
		double x, y, w, kern, alpha;
		double x2;
		double caret_y;
		int i, wi;
		Glyph? prev;
		GlyphSequence word_with_ligatures;
		GlyphRange? gr_left, gr_right;
		bool first_row = true;
		double row_height;
		Font font;
		double item_size = 1.0 / KerningTools.font_size;
		
		font = BirdFont.get_current_font ();
		i = 0;
		
		// bg color
		cr.save ();
		cr.set_source_rgba (1, 1, 1, 1);
		cr.rectangle (0, 0, allocation.width, allocation.height);
		cr.fill ();
		cr.restore ();
		
		cr.save ();
		cr.scale (KerningTools.font_size, KerningTools.font_size);
		
		glyph = MainWindow.get_current_glyph ();
		
		row_height = get_row_height ();
	
		alpha = 1;
		y = get_row_height () + font.base_line + 20;
		x = 20;
		w = 0;
		prev = null;
		kern = 0;
		
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
					return_if_fail (wi < word_with_ligatures.ranges.size);
					return_if_fail (wi - 1 >= 0);
					
					gr_left = word_with_ligatures.ranges.get (wi - 1);
					gr_right = word_with_ligatures.ranges.get (wi);

					kern = get_kerning_for_pair (((!)prev).get_name (), ((!)g).get_name (), gr_left, gr_right);
				}
						
				// draw glyph
				if (g == null) {
					w = 50;
					alpha = 1;
				} else {
					alpha = 0;
					glyph = (!) g;

					cr.save ();
					glyph.add_help_lines ();
					cr.translate (kern + x - glyph.get_lsb () - Glyph.xc (), glyph.get_baseline () + y  - Glyph.yc ());
					glyph.draw_paths (cr);
					cr.restore ();
					
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
					
					cr.move_to (x2 - 5 * item_size, y + 20 * item_size);
					cr.line_to (x2 + 0, y + 20 * item_size - 5 * item_size);
					cr.line_to (x2 + 5 * item_size, y + 20* item_size);
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
					cr.set_font_size (10 * item_size);
					cr.show_text ("?");
					cr.restore ();
				}
							
				prev = g;
				
				wi++;
				i++;
			}
			
			// draw caret
			if (first_row) {
				x2 = x;
				caret_y = get_row_height () + font.base_line + 20;
				cr.save ();
				cr.set_line_width (1.0 / KerningTools.font_size);
				cr.set_source_rgba (0, 0, 0, 0.5);
				cr.move_to (x2, caret_y + 20);
				cr.line_to (x2, 20);
				cr.stroke ();
				cr.restore ();
			}
			
			if (y * KerningTools.font_size > allocation.height && i > 10) {
				row.remove (word);
			}
						
			y += row_height + 20;
			x = 20;
			first_row = false;	
		}
		
		cr.restore ();
	}

	private void display_kerning_value (double k) {
		string kerning_label = t_("Kerning:");
		TooltipArea.show_text (@"$kerning_label $(k)");
	}
	
	private void set_active_handle_index (int h) {
		double kern = get_kerning_for_handle (h);
		active_handle = h;
		
		if (1 <= active_handle < row.get (0).glyph.size) {
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
					if (wi >= word_with_ligatures.ranges.size) {
						warning (@"$wi > $(word_with_ligatures.ranges.size) Number of glyphs: $(word_with_ligatures.glyph.size)");
						return false;
					}
					return_val_if_fail (wi - 1 >= 0, false);
					
					if (word_with_ligatures.ranges.size != word_with_ligatures.glyph.size) {
						warning (@"ranges and glyphs does not match. $(word_with_ligatures.ranges.size) != $(word_with_ligatures.glyph.size)");
						return false;
					}
					
					gr_left = word_with_ligatures.ranges.get (wi - 1);
					gr_right = word_with_ligatures.ranges.get (wi);
					
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

	public void set_absolute_kerning (int handle, double val) {
		double kern;
		
		if (MenuTab.suppress_event) {
			return;
		}
		
		kern = get_kerning_for_handle (handle);
		set_kerning (handle, val - kern);
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
		
		KeyBindings.set_require_modifier (true);
		
		g = MainWindow.get_current_glyph ();
		s.append_unichar (g.get_unichar ());

		if (row.size == 0) {
			append_char = true;
		}
		
		if (append_char) {
			w = new GlyphSequence ();
			row.add (w);
			w.glyph.insert (0, font.get_glyph (s.str));
		}		
	}
	
	public void add_kerning_class (int index) {
		add_range (KerningTools.get_kerning_class (index));
	}
	
	public void add_range (GlyphRange range) {
		Font font = BirdFont.get_current_font ();
		Glyph? glyph;
		
		glyph = font.get_glyph_by_name (range.get_char (0));
		
		if (glyph == null) {
			warning ("Kerning range is not represented by a valid glyph.");
			return;
		}
		
		row.get (0).glyph.add ((!) glyph);
		row.get (0).ranges.add (range);
		
		GlyphCanvas.redraw ();
	}

	void set_selected_handle (int handle) {
		selected_handle = handle;
		
		if (selected_handle <= 0) {
			selected_handle = 1;
		}
		
		if (selected_handle >= row.get (0).glyph.size) {
			selected_handle = (int) row.get (0).glyph.size - 1;
		}
		
		GlyphCanvas.redraw ();
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
		unichar c;
		
		if (MenuTab.suppress_event) { // don't update kerning while saving font
			return;
		}
		
		c = (unichar) keyval;
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
			if (keyval == Key.BACK_SPACE && row.size > 0 && row.get (0).glyph.size > 0) {
				row.get (0).glyph.remove_at (row.get (0).glyph.size - 1);
				row.get (0).ranges.remove_at (row.get (0).ranges.size - 1);
			}
			
			if (row.size == 0 || c == Key.ENTER) {
				new_line ();
			}
			
			add_character (c);
		}
		
		GlyphCanvas.redraw ();
	}
	
	public void new_line () {
		row.insert (0, new GlyphSequence ());
	}
	
	void add_character (unichar c) {
		Glyph? g;
		string name;
		Font f = BirdFont.get_current_font ();

		if (MenuTab.suppress_event) {
			return;
		}
		
		if (!is_modifier_key (c) && c.validate ()) {
			name = f.get_name_for_character (c);
			g = f.get_glyph_by_name (name);
			if (g != null) {
				row.get (0).glyph.add (g);
				row.get (0).ranges.add (null);
				
				selected_handle = (int) row.get (0).glyph.size - 1;
				set_active_handle_index (selected_handle);
			}
		}
	}
	
	public override void motion_notify (double ex, double ey) {
		double k, y;

		if (MenuTab.suppress_event) {
			return;
		}
				
		if (!moving) {
			set_active_handle (ex, ey);
		} else {	
			y = 1;
			
			if (Math.fabs (ey - begin_handle_y) > 20) {
				y = ((Math.fabs (ey - begin_handle_y) / 100) + 1);
			}
			
			k = (ex - last_handle_x) / y; // y-axis is for variable precision
			k /= KerningTools.font_size;
			set_kerning (selected_handle, k);
			GlyphCanvas.redraw ();
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
		double fs = KerningTools.font_size;
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
					return_if_fail (col_index < word_with_ligatures.ranges.size);
					return_if_fail (col_index - 1 >= 0);
					
					gr_left = word_with_ligatures.ranges.get (col_index - 1);
					gr_right = word_with_ligatures.ranges.get (col_index);

					kern = get_kerning_for_pair (((!)prev).get_name (), ((!)g).get_name (), gr_left, gr_right);
				}
								
				d = Math.pow (fs * (x + kern) - ex, 2) + Math.pow (y - ey, 2);
				
				if (d < min) {
					min = d;
					
					if (active_handle != i - row_index) {
						set_active_handle_index (i - row_index);
						GlyphCanvas.redraw ();
					}
					
					if (col_index == word.glyph.size || col_index == 0) {
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
		
		if (button == 3 || text_input) {
			set_kerning_by_text ();
		}
	}
	
	public void set_kerning_by_text () {
		TextListener listener;
		string kerning = @"$(get_kerning_for_handle (selected_handle))";

		if (MenuTab.suppress_event) {
			return;
		}
				
		if (selected_handle == -1) {
			selected_handle = 0;
		}
		
		listener = new TextListener (t_("Kerning"), kerning, t_("Close"));
		
		listener.signal_text_input.connect ((text) => {
			string submitted_value;
			double parsed_value;
			
			if (MenuTab.suppress_event) {
				return;
			}
		
			submitted_value = text.replace (",", ".");
			parsed_value = double.parse (submitted_value);
			set_absolute_kerning (selected_handle, parsed_value);
			GlyphCanvas.redraw ();
		});
		
		listener.signal_submit.connect (() => {
			MainWindow.native_window.hide_text_input ();
			text_input = false;
			suppress_input = false;
		});
		
		suppress_input = true;
		text_input = true;
		MainWindow.native_window.set_text_listener (listener);
		
		GlyphCanvas.redraw ();		
	}
	
	public override void button_press (uint button, double ex, double ey) {
		if (MenuTab.suppress_event) {
			return;
		}
		
		set_active_handle (ex, ey);
		selected_handle = active_handle;
		begin_handle_x = ex;
		begin_handle_y = ey;
		last_handle_x = ex;
		moving = true;
	}
	
	/** Insert text form clipboard. */
	public void add_text (string t) {
		int c;
		
		if (MenuTab.suppress_event) {
			return;
		}
		
		c = t.char_count ();
		for (int i = 0; i < c; i++) {
			add_character (t.get_char (i));
		}
		GlyphCanvas.redraw ();
	}
}

}
