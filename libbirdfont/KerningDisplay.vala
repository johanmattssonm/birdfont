/*
	Copyright (C) 2012 2014 2015 Johan Mattsson

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
	
	Gee.ArrayList <GlyphSequence> first_row;
	Gee.ArrayList <GlyphSequence> rows;
	
	int active_handle = -1;
	int selected_handle = -1;
	bool moving = false;
	Glyph left_active_glyph = new Glyph ("null", '\0');
	Glyph right_active_glyph = new Glyph ("null", '\0');
	
	double begin_handle_x = 0;
	double begin_handle_y = 0;
	
	double last_handle_x = 0;
	
	public bool text_input = false;

	Gee.ArrayList<UndoItem> undo_items;
	Gee.ArrayList<UndoItem> redo_items;
	bool first_update = true;

	Text kerning_label = new Text ();
	
	public bool adjust_side_bearings = false;
	public bool right_side_bearing = true;

	public static bool right_to_left = false; 	
	
	WidgetAllocation allocation = new WidgetAllocation ();
	
	public KerningDisplay () {
		GlyphSequence w = new GlyphSequence ();
		rows = new Gee.ArrayList <GlyphSequence> ();
		first_row = new Gee.ArrayList <GlyphSequence> ();
		undo_items = new Gee.ArrayList <UndoItem> ();
		redo_items = new Gee.ArrayList <UndoItem> ();
		w.set_otf_tags (KerningTools.get_otf_tags ());
		first_row.add (w);
	}

	public GlyphSequence get_first_row () {
		GlyphSequence first = new GlyphSequence ();
		Font font = BirdFont.get_current_font ();
		
		foreach (GlyphSequence s in first_row) {
			first.append (s.process_ligatures (font));
		}
		
		return first;
	}

	public void new_segment () {
		GlyphSequence s = new GlyphSequence ();
		s.set_otf_tags (KerningTools.get_otf_tags ());
		first_row.add (s);
	}

	public GlyphSequence get_last_segment () {
		if (first_row.size == 0) {
			new_segment ();
		}
		
		return first_row.get (first_row.size - 1);
	}
	
	Gee.ArrayList <GlyphSequence> get_all_rows () {
		Gee.ArrayList <GlyphSequence> r;
		
		r = new Gee.ArrayList <GlyphSequence> ();
		r.add (get_first_row ());
		foreach (GlyphSequence s in rows) {
			r.add (s);
		}
		
		return r;
	}

	public override string get_label () {
		return t_("Kerning");
	}
	
	public override string get_name () {
		return "Kerning";
	}

	public void show_parse_error () {
		string line1 = t_("The current kerning class is malformed.");
		string line2 = t_("Add single characters separated by space and ranges on the form A-Z.");
		string line3 = t_("Type “space” to kern the space character and “divis” to kern -.");
				
		MainWindow.show_dialog (new MessageDialog (line1 + " " + line2 + " " + line3));
	}
	
	public override void draw (WidgetAllocation allocation, Context cr) {
		draw_kerning_pairs (allocation, cr);
	}
	
	public double get_row_height () {
		Font current_font = BirdFont.get_current_font ();
		return current_font.top_limit - current_font.bottom_limit;
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
		Font font = BirdFont.get_current_font ();
		double item_size = 1.0 / KerningTools.font_size;
		double item_size2 = 2.0 / KerningTools.font_size;

		this.allocation = allocation;

		i = 0;
		
		// bg color
		cr.save ();
		Theme.color (cr, "Background 1");
		cr.rectangle (0, 0, allocation.width, allocation.height);
		cr.fill ();
		cr.restore ();
		
		cr.save ();
		cr.scale (KerningTools.font_size, KerningTools.font_size);
		
		glyph = MainWindow.get_current_glyph ();
		
		row_height = get_row_height ();
	
		alpha = 1;
		y = get_row_height () - font.base_line + 20;
		x = 20;
		w = 0;
		prev = null;
		kern = 0;
		
		if (right_to_left) {
			x = (allocation.width - 20) / KerningTools.font_size;
		}
				
		foreach (GlyphSequence word in get_all_rows ()) {
			wi = 0;
			word_with_ligatures = word.process_ligatures (font);
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

					if (right_to_left) {
						cr.translate (-kern + x - glyph.get_lsb () - glyph.get_width () - Glyph.xc (), glyph.get_baseline () + y  - Glyph.yc ());
					} else {						
						cr.translate (kern + x - glyph.get_lsb () - Glyph.xc (), glyph.get_baseline () + y  - Glyph.yc ());
					}
					
					glyph.draw_paths (cr);
					cr.restore ();
					
					w = glyph.get_width ();
				}
				
				// handle
				if (first_row && (active_handle == i || selected_handle == i)) {
					if (right_to_left) {
						x2 = x - kern / 2.0;
					} else {
						x2 = x + kern / 2.0;
					}
					
					cr.save ();
					
					if (selected_handle == i) {
						Theme.color (cr, "Foreground 1");
					} else { 
						cr.set_source_rgba (123/255.0, 123/255.0, 123/255.0, 1);
					}
					
					if (!adjust_side_bearings) {
						cr.move_to (x2 - 5 * item_size, y + 20 * item_size);
						cr.line_to (x2, y + 20 * item_size - 5 * item_size);
						cr.line_to (x2 + 5 * item_size, y + 20* item_size);
						cr.fill ();
						
						if (gr_left != null || gr_right != null) {
							cr.move_to (x2 - 5 * item_size, y + 20  * item_size);
							cr.line_to (x2 + 5 * item_size, y + 20  * item_size);
							cr.line_to (x2 + 5 * item_size, y + 24  * item_size);
							cr.line_to (x2 - 5 * item_size, y + 24  * item_size);
							cr.fill ();
						}
					} else {
						if (right_side_bearing) {
							cr.move_to (x2 - 5 * item_size2, y + 20 * item_size2);
							cr.line_to (x2, y + 20 * item_size2 - 5 * item_size2);
							cr.line_to (x2, y + 20* item_size2);
							cr.fill ();
						} else {
							cr.move_to (x2, y + 20 * item_size2);
							cr.line_to (x2, y + 20 * item_size2 - 5 * item_size2);
							cr.line_to (x2 + 5 * item_size2, y + 20* item_size2);
							cr.fill ();
						}
					}
					
					if (active_handle == i && !adjust_side_bearings) {
						cr.save ();
						cr.scale (1 / KerningTools.font_size, 1 / KerningTools.font_size);
						kerning_label.widget_x = x2 * KerningTools.font_size;
						kerning_label.widget_y = y * KerningTools.font_size + 40;
						kerning_label.draw (cr);
						cr.fill ();
						cr.restore ();
					}
					
					cr.restore ();
				}	
				
				if (right_to_left) {
					x -= w + kern;
				} else {
					x += w + kern;
				}
	
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
				caret_y = get_row_height () - font.base_line + 20;
				cr.save ();
				cr.set_line_width (1.0 / KerningTools.font_size);
				Theme.color_opacity (cr, "Foreground 1", 0.5);
				cr.move_to (x2, caret_y + 20);
				cr.line_to (x2, 20);
				cr.stroke ();
				cr.restore ();
				
				y += (50 / KerningTools.font_size);
			}
						
			y += row_height + 20;
			
			if (right_to_left) {
				x = (allocation.width - 20) / KerningTools.font_size;
			} else {				
				x = 20;
			}

			first_row = false;
			
			if (y > allocation.height) {
				break;
			}
		}
		
		for (int j = rows.size - 1; j > 30; j--) {
			rows.remove_at (j);
		}
		
		cr.fill ();
		cr.restore ();
	}

	private void display_kerning_value (double k) {
		string kerning = round (k);
		kerning_label = new Text (@"$(kerning)", 17);
	}
	
	private void set_active_handle_index (int h) {
		double kern = get_kerning_for_handle (h);
		active_handle = h;
		
		if (1 <= active_handle < get_first_row ().glyph.size) {
			display_kerning_value (kern);
		}
	}
	
	private double get_kerning_for_handle (int handle) {
		string a, b;
		GlyphRange? gr_left, gr_right;
		bool got_pair;

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
		
		word_with_ligatures = get_first_row ();
		ranges_index = 0;
		foreach (Glyph? g in word_with_ligatures.glyph) {
			
			if (g == null) {
				continue;
			}
			
			b = ((!) g).get_name ();
			
			if (handle == wi && row_index == 0) {
				if (wi >= word_with_ligatures.ranges.size) {
					return false;
				}
				return_val_if_fail (wi - 1 >= 0, false);
				
				if (word_with_ligatures.ranges.size != word_with_ligatures.glyph.size) {
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

		return false;	
	}

	public void set_absolute_kerning (int handle, double val) {
		double kern;
		
		if (MenuTab.has_suppress_event ()) {
			return;
		}
		
		if (!adjust_side_bearings) {
			kern = get_kerning_for_handle (handle);
			set_space (handle, val - kern);	
		}
	}


	/** Adjust kerning or right side bearing. */
	private void set_space (int handle, double val) {
		string a, b;
		Font font;
		GlyphRange? gr_left, gr_right;

		font = BirdFont.get_current_font ();
		font.touch ();

		if (!adjust_side_bearings) {
			get_kerning_pair (handle, out a, out b, out gr_left, out gr_right);
			set_kerning_pair (a, b, ref gr_left, ref gr_right, val);
		} else {
			if (right_side_bearing) {
				left_active_glyph.right_limit += val;
				left_active_glyph.remove_lines ();
				left_active_glyph.add_help_lines ();
				left_active_glyph.update_other_spacing_classes ();
			} else {
				right_active_glyph.left_limit -= val;
				right_active_glyph.remove_lines ();
				right_active_glyph.add_help_lines ();
				right_active_glyph.update_other_spacing_classes ();
			}
		}
	}

	/** Class based gpos kerning. */
	public void set_kerning_pair (string a, string b,
			ref GlyphRange? gr_left, ref GlyphRange? gr_right,
			double val) {
		double kern;
		GlyphRange grl, grr;
		KerningClasses classes;
		string n, f;
		bool has_kerning;
		Font font;
		
		font = BirdFont.get_current_font ();
		font.touch ();
		classes = font.get_kerning_classes ();
			
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
			
			if (first_update) {
				f = grl.get_all_ranges ();
				n = grr.get_all_ranges ();
				has_kerning = classes.has_kerning (f, n);
				undo_items.add (new UndoItem (f, n, kern, has_kerning));
				redo_items.clear ();
				first_update = false;
			}
			
			classes.set_kerning (grl, grr, kern + val);
			display_kerning_value (kern + val);
		} catch (MarkupError e) {
			// FIXME: unassigned glyphs and ligatures
			warning (e.message);
		}
	}

	public static double get_kerning_for_pair (string a, string b, GlyphRange? gr_left, GlyphRange? gr_right) {
		KerningClasses k = BirdFont.get_current_font ().get_kerning_classes ();
		return k.get_kerning_for_pair (a, b, gr_left, gr_right);
	}
	
	public override void selected_canvas () {
		KeyBindings.set_require_modifier (true);
	}
	
	public void add_kerning_class (int index) {
		add_range (KerningTools.get_kerning_class (index));
	}
	
	public void add_range (GlyphRange range) {
		Font font = BirdFont.get_current_font ();
		Glyph? glyph;
		GlyphSequence s;
		
		glyph = font.get_glyph_by_name (range.get_char (0));
		
		if (glyph == null) {
			warning ("Kerning range is not represented by a valid glyph.");
			return;
		}
		
		if (first_row.size == 0) {
			s = new GlyphSequence ();
			first_row.add (s);
		} else {
			s = first_row.get (first_row.size - 1);
		}
		
		s.glyph.add ((!) glyph);
		s.ranges.add (range);
		
		GlyphCanvas.redraw ();
	}

	void set_selected_handle (int handle) {
		Glyph? g;
		selected_handle = handle;
		GlyphSequence sequence_with_ligatures;

		sequence_with_ligatures = get_first_row ();
		
		if (selected_handle <= 0) {
			selected_handle = 1;
		}
		
		if (selected_handle >= sequence_with_ligatures.glyph.size) {
			selected_handle = (int) sequence_with_ligatures.glyph.size - 1;
		}
		
		set_active_handle_index (handle);
		
		if (0 <= selected_handle - 1 < sequence_with_ligatures.glyph.size) {
			g = sequence_with_ligatures.glyph.get (selected_handle - 1);
			if (g != null) {
				left_active_glyph = (!) g;
			}
		}

		if (0 <= selected_handle < sequence_with_ligatures.glyph.size) {
			g = sequence_with_ligatures.glyph.get (selected_handle);
			if (g != null) {
				right_active_glyph = (!) g;
			}
		}
		
		GlyphCanvas.redraw ();
	}

	public static void previous_pair () {
		KerningDisplay kd;
		FontDisplay fd;
		SpacingTab st;
		
		fd = MainWindow.get_current_display ();
		
		if (fd is SpacingTab) {
			st = (SpacingTab) fd;
			if (!st.right_side_bearing) {
				st.right_side_bearing = true;
			} else {
				st.right_side_bearing = false;
				st.set_selected_handle (st.selected_handle - 1);
			}
		} else if (fd is KerningDisplay) {
			kd = (KerningDisplay) fd;
			kd.set_selected_handle (kd.selected_handle - 1);	
		}
		
		GlyphCanvas.redraw ();
	}
	
	public static void next_pair () {
		KerningDisplay kd;
		FontDisplay fd;
		SpacingTab st;
		
		fd = MainWindow.get_current_display ();
		
		if (fd is SpacingTab) {
			st = (SpacingTab) fd;
	
			if (st.right_side_bearing) {
				st.right_side_bearing = false;
			} else {
				st.right_side_bearing = true;
				st.set_selected_handle (st.selected_handle + 1);
			}
		} else if (fd is KerningDisplay) {
			kd = (KerningDisplay) fd;
			kd.set_selected_handle (kd.selected_handle + 1);	
		}
		
		GlyphCanvas.redraw ();
	}

	private static string round (double d) {
		char[] b = new char [22];
		unowned string s = d.format (b, "%.2f");
		string n = s.dup ();

		n = n.replace (",", ".");

		if (n == "-0.00") {
			n = "0.00";
		}
		
		return n;
	}
		
	public override void key_press (uint keyval) {
		unichar c;
		
		if (MenuTab.has_suppress_event ()) { // don't update kerning while saving font
			return;
		}
		
		c = (unichar) keyval;

		if (suppress_input) {
			return;
		}

		if ((keyval == 'u' || keyval == 'U') && KeyBindings.has_ctrl ()) {
			insert_unichar ();
		} else {
			if (keyval == Key.LEFT && KeyBindings.modifier == NONE) {
				first_update = true;
				set_space (selected_handle, -1 / KerningTools.font_size);
			}
			
			if (keyval == Key.RIGHT && KeyBindings.modifier == NONE) {
				first_update = true;
				set_space (selected_handle, 1 / KerningTools.font_size);
			}

			if (KeyBindings.modifier == NONE 
				|| KeyBindings.modifier == SHIFT 
				|| KeyBindings.modifier == ALT) {		
				
				if (keyval == Key.BACK_SPACE) {
					remove_last_character ();
				}
				
				if (c == Key.ENTER) {
					new_line ();
				}
				
				add_character (c);
			}
		}
		
		GlyphCanvas.redraw ();
	}
	
	void remove_last_character () {
		if (first_row.size > 0) {
			GlyphSequence gs = first_row.get (first_row.size - 1);
			
			if (gs.glyph.size > 0) {
				gs.glyph.remove_at (gs.glyph.size - 1);
				return_if_fail (gs.ranges.size > 0);
				gs.ranges.remove_at (gs.ranges.size - 1);
			} else {
				first_row.remove_at (first_row.size - 1);
				remove_last_character ();
			}
		}		
	}
	
	public void insert_unichar () {
		TextListener listener;
		string submitted_value = "";
		string unicodestart;
		
		unicodestart = (KeyBindings.has_shift ()) ? "" : "U+";
		listener = new TextListener (t_("Unicode"), unicodestart, t_("Insert"));
		
		listener.signal_text_input.connect ((text) => {
			submitted_value = text;
			
			if (MenuTab.has_suppress_event ()) {
				return;
			}
			
			GlyphCanvas.redraw ();
		});
		
		listener.signal_submit.connect (() => {
			unichar c;
			TabContent.hide_text_input ();
			
			text_input = false;
			suppress_input = false;
			
			if (submitted_value.has_prefix ("u+") || submitted_value.has_prefix ("U+")) {
				c = Font.to_unichar (submitted_value);
				add_character (c);
			} else {
				add_text (submitted_value);
			}
		});
		
		suppress_input = true;
		text_input = true;
		TabContent.show_text_input (listener);
	}
	
	public void new_line () {
		rows.insert (0, get_first_row ());
		first_row = new Gee.ArrayList<GlyphSequence> ();
		GlyphSequence gs = new GlyphSequence ();
		gs.set_otf_tags (KerningTools.get_otf_tags ());
		first_row.add (gs);
	}
	
	void add_character (unichar c) {
		Glyph? g;
		string name;

		if (MenuTab.has_suppress_event ()) {
			return;
		}
		
		if (!is_modifier_key (c) && c.validate ()) {
			name = (!) c.to_string ();
			g = BirdFont.get_current_font ().get_glyph_by_name (name);
			inser_glyph (g);
		}
	}
	
	public void inser_glyph (Glyph? g) {
		int handle;
		
		if (first_row.size == 0) {
			GlyphSequence gs = new GlyphSequence ();
			gs.set_otf_tags (KerningTools.get_otf_tags ());
			first_row.add (gs);
		}
		
		if (g != null) {
			first_row.get (first_row.size - 1).glyph.add (g);
			first_row.get (first_row.size - 1).ranges.add (null);
			
			handle = get_first_row ().glyph.size - 1;
			set_selected_handle (handle);
			set_active_handle_index (handle);
		}
	}
	
	public override void motion_notify (double ex, double ey) {
		double k, y;

		if (MenuTab.has_suppress_event ()) {
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

			if (right_to_left) {
				k *= -1;
			}			
			
			set_space (selected_handle, k);
			GlyphCanvas.redraw ();
		}
		
		last_handle_x = ex;
	}
	
	public void set_active_handle (double ex, double ey) {
		double w = 0;
		double d, kern;
		double min = double.MAX;
		int i = 0;
		int row_index = 0;
		int col_index = 0;
		Glyph glyph = new Glyph.no_lines ("");
		double fs = KerningTools.font_size;
		double x = 20;

		if (right_to_left) {
			x = (allocation.width - 20) / KerningTools.font_size;
		}		
			
		GlyphRange? gr_left, gr_right;
		
		Glyph? prev = null;
		string gl_name = "";
		GlyphSequence word_with_ligatures;
		
		col_index = 0;
		
		word_with_ligatures = get_first_row ();
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
			
			if (right_to_left) {
				d = Math.pow (fs * (x - kern) - ex, 2);
			} else {				
				d = Math.pow (fs * (x + kern) - ex, 2);
			}
			
			if (d < min) {
				min = d;
				
				if (ex != fs * (x + kern)) {	// don't swap direction after button release
					right_side_bearing = ex < fs * (x + kern); // right or left side bearing handle
				}
				
				if (active_handle != i - row_index) {
					set_active_handle_index (i - row_index);
					GlyphCanvas.redraw ();
				}
				
				if (col_index == word_with_ligatures.glyph.size || col_index == 0) {
					set_active_handle_index (-1);
				} else {
					set_active_handle_index (active_handle + row_index);
				}
			}
			
			prev = g;
			
			if (right_to_left) {
				x -= w + kern;
			} else {
				x += w + kern;
			}
			
			i++;
			col_index++;
		}
		
		row_index++;
		x = 20;
	}
	
	public override void button_release (int button, double ex, double ey) {
		set_active_handle (ex, ey);
		moving = false;
		first_update = true;
		
		if (button == 3 || text_input) {
			set_kerning_by_text ();
		}
	}
	
	public void set_kerning_by_text () {
		TextListener listener;
		string kerning = @"$(get_kerning_for_handle (selected_handle))";

		if (MenuTab.has_suppress_event ()) {
			return;
		}
				
		if (selected_handle == -1) {
			set_selected_handle (0);
		}
		
		listener = new TextListener (t_("Kerning"), kerning, t_("Close"));
		
		listener.signal_text_input.connect ((text) => {
			string submitted_value;
			double parsed_value;
			
			if (MenuTab.has_suppress_event ()) {
				return;
			}
		
			submitted_value = text.replace (",", ".");
			parsed_value = double.parse (submitted_value);
			set_absolute_kerning (selected_handle, parsed_value);
			GlyphCanvas.redraw ();
		});
		
		listener.signal_submit.connect (() => {
			TabContent.hide_text_input ();
			text_input = false;
			suppress_input = false;
		});
		
		suppress_input = true;
		text_input = true;
		TabContent.show_text_input (listener);
		
		GlyphCanvas.redraw ();
	}
	
	public override void button_press (uint button, double ex, double ey) {
		set_active_handle (ex, ey);
		set_selected_handle (active_handle);
		begin_handle_x = ex;
		begin_handle_y = ey;
		last_handle_x = ex;
		moving = true;
	}
	
	/** Insert text form clipboard. */
	public void add_text (string t) {
		int c;
		
		if (MenuTab.has_suppress_event ()) {
			return;
		}
		
		c = t.char_count ();
		for (int i = 0; i <= c; i++) {
			add_character (t.get_char (t.index_of_nth_char (i)));
		}
		
		GlyphCanvas.redraw ();
	}

	public override void undo () {
		UndoItem ui;
		UndoItem redo_state;
		
		if (MenuTab.has_suppress_event ()) {
			return;
		}
		
		if (undo_items.size == 0) {
			return;
		}
		
		ui = undo_items.get (undo_items.size - 1);
		
		redo_state = apply_undo (ui);
		redo_items.add (redo_state);
		
		undo_items.remove_at (undo_items.size - 1);
	}

	public override void redo () {
		UndoItem ui;
		
		if (MenuTab.has_suppress_event ()) {
			return;
		}
		
		if (redo_items.size == 0) {
			return;
		}
		
		ui = redo_items.get (redo_items.size - 1);
		apply_undo (ui);
		redo_items.remove_at (redo_items.size - 1);
	}
	
	/** @return redo state. */
	public UndoItem apply_undo (UndoItem ui) {
		KerningClasses classes = BirdFont.get_current_font ().get_kerning_classes ();
		GlyphRange glyph_range_first, glyph_range_next;
		Font font = BirdFont.get_current_font ();
		string l, r;
		UndoItem redo_state = new UndoItem ("", "", 0, false);
		double? k;
		
		l = GlyphRange.unserialize (ui.first);
		r = GlyphRange.unserialize (ui.next);
				
		try {
			glyph_range_first = new GlyphRange ();
			glyph_range_next = new GlyphRange ();
			
			glyph_range_first.parse_ranges (ui.first);
			glyph_range_next.parse_ranges (ui.next);
				
			if (!ui.has_kerning) {
				if (glyph_range_first.is_class () || glyph_range_next.is_class ()) {
					redo_state.first = glyph_range_first.get_all_ranges ();
					redo_state.next = glyph_range_next.get_all_ranges ();
					redo_state.has_kerning = true;
					redo_state.kerning = classes.get_kerning_for_range (glyph_range_first, glyph_range_next);
					
					classes.delete_kerning_for_class (ui.first, ui.next);
				} else {
					
					redo_state.first = ui.first;
					redo_state.next = ui.next;
					redo_state.has_kerning = true;
					k = classes.get_kerning_for_single_glyphs (ui.first, ui.next);
					
					if (k != null) {
						redo_state.kerning = (!) k;
					} else {
						warning ("No kerning");
					}
					
					classes.delete_kerning_for_pair (ui.first, ui.next);
				}
			} else if (glyph_range_first.is_class () || glyph_range_next.is_class ()) {
				glyph_range_first = new GlyphRange ();
				glyph_range_next = new GlyphRange ();
				
				glyph_range_first.parse_ranges (ui.first);
				glyph_range_next.parse_ranges (ui.next);

				redo_state.first = glyph_range_first.get_all_ranges ();
				redo_state.next = glyph_range_next.get_all_ranges ();
				k = classes.get_kerning_for_range (glyph_range_first, glyph_range_next);
				
				if (k != null) {
					redo_state.kerning = (!) k;
					redo_state.has_kerning = true;
				} else {
					redo_state.has_kerning = false;
				}
									
				classes.set_kerning (glyph_range_first, glyph_range_next, ui.kerning);
			} else {
				redo_state.first = ui.first;
				redo_state.next = ui.next;
				redo_state.has_kerning = true;
				k = classes.get_kerning_for_single_glyphs (ui.first, ui.next);
				
				if (k != null) {
					redo_state.kerning = (!) k;
					redo_state.has_kerning = true;
				} else {
					redo_state.has_kerning = false;
				}
					
				classes.set_kerning_for_single_glyphs (ui.first, ui.next, ui.kerning);
			}
		} catch (MarkupError e) {
			warning (e.message);
		}
		
		font.touch ();
		GlyphCanvas.redraw ();
		
		return redo_state;
	}

	public override void zoom_in () {
		KerningTools.font_size += 0.1;
		
		if (KerningTools.font_size > 3) {
			KerningTools.font_size = 3;
		}

		KerningTools.zoom_bar.set_zoom (KerningTools.font_size / 3);
		GlyphCanvas.redraw ();
	}

	public override void zoom_out () {
		KerningTools.font_size -= 0.1;
		
		if (KerningTools.font_size < 0.3) {
			KerningTools.font_size = 0.3;
		}
		
		KerningTools.zoom_bar.set_zoom (KerningTools.font_size / 3);
		GlyphCanvas.redraw ();
	}

	public override bool needs_modifier () {
		return true;
	}

	public class UndoItem : GLib.Object {
		public string first;
		public string next;
		public double kerning;
		public bool has_kerning;
		
		public UndoItem (string first, string next, double kerning, bool has_kerning) {
			this.first = first;
			this.next = next;
			this.kerning = kerning;
			this.has_kerning = has_kerning;
		}
	}
}

}
