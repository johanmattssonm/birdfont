/*
    Copyright (C) 2015 Johan Mattsson

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
public class SpacingTab : KerningDisplay {

	double box_size = 122 * MainWindow.units;
	double height = 44 * MainWindow.units;
	double character_height = 20 * MainWindow.units;
	
	WidgetAllocation allocation;
	
	Glyph text_input_glyph;
	
	public SpacingTab () {
		allocation = new WidgetAllocation ();
		adjust_side_bearings = true;
	}

	public override string get_label () {
		return t_("Spacing");
	}
	
	public override string get_name () {
		return "Spacing";
	}

	public override void draw (WidgetAllocation allocation, Context cr) {
		base.draw (allocation, cr);
		draw_spacing_metrix (allocation, cr);
	}
	
	void draw_spacing_metrix (WidgetAllocation allocation, Context cr) {
		GlyphSequence row;
		int index;
		Font font = BirdFont.get_current_font ();

		// background
		cr.save ();
		Theme.color (cr, "Background 1");
		cr.rectangle (0, allocation.height - height, allocation.width, height);
		cr.fill ();
		cr.restore ();
		
		// character bar
		cr.save ();
		Theme.color (cr, "Table Border");
		cr.set_line_width (0.8);
		cr.move_to (0, allocation.height - height);
		cr.line_to (allocation.width, allocation.height - height);
		cr.stroke ();
		
		cr.move_to (0, allocation.height - height + character_height);
		cr.line_to (allocation.width, allocation.height - height + character_height);
		cr.stroke ();
		cr.restore ();
		
		row = get_first_row ().process_ligatures (font);
		index = 0;
		foreach (Glyph? g in row.glyph) {
			draw_glyph_spacing (allocation, cr, g, index);
			index++;
		}
	}
	
	void draw_glyph_spacing (WidgetAllocation allocation, Context cr, Glyph? glyph, int index) {
		Glyph g;
		double end, middle;
		double l, r;
		Text left, right, cap;
		unichar c;
		
		this.allocation = allocation;
		
		// end mark
		end = (index + 1) * box_size;
		cr.save ();
		cr.set_source_rgba (0.5, 0.5, 0.5, 1);
		cr.set_line_width (2);
		cr.move_to (end, allocation.height - height);
		cr.line_to (end, allocation.height);
		cr.stroke ();
		cr.restore ();
		
		// boxes
		middle = end - box_size / 2.0;
		cr.save ();
		cr.set_source_rgba (0.5, 0.5, 0.5, 1);
		cr.set_line_width (0.8);
		cr.move_to (middle, allocation.height - height + character_height);
		cr.line_to (middle, allocation.height);
		cr.stroke ();
		cr.restore ();
		
		if (glyph != null) {
			g = (!) glyph;
			
			c = g.get_unichar ();
			cap = new Text ((!) c.to_string (), 17);
			Theme.text_color (cap, "Table Border");
			cap.widget_x = middle - cap.get_extent () / 2.0;
			cap.widget_y = allocation.height - height + character_height - 4 * MainWindow.units;
			cap.draw_at_baseline (cr, cap.widget_x, cap.widget_y);			
			
			l = g.get_left_side_bearing ();
			
			if (Math.fabs (l) < 0.001) {
				l = 0;
			}
			
			left = new Text (truncate (l, 5), 17);
			Theme.text_color (left, "Foreground 1");
			left.widget_x = middle - box_size / 2.0 + (box_size / 2.0 - left.get_extent ()) / 2.0;
			left.widget_y = allocation.height - 7 * MainWindow.units;
			left.draw_at_baseline (cr, left.widget_x, left.widget_y);

			r = g.get_right_side_bearing ();

			if (Math.fabs (r) < 0.001) {
				r = 0;
			}
			
			right = new Text (truncate (r, 5), 17);
			Theme.text_color (right, "Table Border");
			right.widget_x = end - (box_size / 2.0 - right.get_extent ()) / 2.0 - right.get_extent ();
			right.widget_y = allocation.height - 7 * MainWindow.units;
			right.draw_at_baseline (cr, right.widget_x, right.widget_y);					
		}
	}

	public string truncate (double f, int digits) {
		string t = @"$f";
		string s = "";
		
		int d = digits;
		int i;
		unichar c;
		
		if (t.index_of ("-") != -1) {
			d++;
		}

		if (t.index_of (".") != -1) {
			d++;
		}
				
		i = 0;
		while (t.get_next_char (ref i, out c)) {
			s = s + (!) c.to_string ();
			
			if (i >= d) {
				break;
			}
		}
		
		return s;
	}
	
	public override void button_press (uint button, double ex, double ey) {
		if (button == 3) {
			return;
		}
		
		if (!(ey >= allocation.height - height)) {
			base.button_press (button, ex, ey);
		}
	}
	
	public override void button_release (int button, double ex, double ey) {
		GlyphSequence row;
		double p;
		Font font = BirdFont.get_current_font ();
		
		if (button == 3) {
			return;
		}
		
		if (ey >= allocation.height - height) {
			
			TabContent.hide_text_input ();
			
			// TODO: add button for processing ligatures
			row = get_first_row ().process_ligatures (font);
			p = 0;
			foreach (Glyph? g in row.glyph) {
				if (p < ex < p + box_size / 2.0) {
					update_lsb (g);
				} 

				if (p + box_size / 2.0 < ex < p + box_size) {
					update_rsb (g);
				}
				
				p += box_size;
			}
		} else {
			base.button_release (button, ex, ey);
		}
	}
	
	void update_lsb (Glyph? g) {
		TextListener listener;
		string submitted_value = "";
		double l;
		
		if (g == null) {
			return;
		}
		
		text_input_glyph = (!) g;
		l = text_input_glyph.get_left_side_bearing ();

		if (Math.fabs (l) < 0.001) {
			l = 0;
		}
				
		listener = new TextListener (t_("Left"), @"$(l)", t_("Set"));
		
		listener.signal_text_input.connect ((text) => {
			submitted_value = text;
			
			if (MenuTab.suppress_event) {
				return;
			}
			
			GlyphCanvas.redraw ();
		});
		
		listener.signal_submit.connect (() => {
			double v;
			TabContent.hide_text_input ();
			
			text_input = false;
			suppress_input = false;
			
			v = double.parse (submitted_value);
			text_input_glyph.left_limit -= v - text_input_glyph.get_left_side_bearing ();
		});
		
		suppress_input = true;
		text_input = true;
		TabContent.show_text_input (listener);
	}
	
	void update_rsb (Glyph? g) {
		TextListener listener;
		string submitted_value = "";
		double r;

		if (g == null) {
			return;
		}
		
		text_input_glyph = (!) g;
		r = text_input_glyph.get_right_side_bearing ();

		if (Math.fabs (r) < 0.001) {
			r = 0;
		}

		listener = new TextListener (t_("Right"), @"$(r)", t_("Set"));
		
		listener.signal_text_input.connect ((text) => {
			submitted_value = text;
			
			if (MenuTab.suppress_event) {
				return;
			}
			
			GlyphCanvas.redraw ();
		});
		
		listener.signal_submit.connect (() => {
			double v;
			TabContent.hide_text_input ();
			
			text_input = false;
			suppress_input = false;
			
			v = double.parse (submitted_value);
			text_input_glyph.right_limit += v - text_input_glyph.get_right_side_bearing ();
		});
		
		suppress_input = true;
		text_input = true;
		TabContent.show_text_input (listener);
	}

	public override bool needs_modifier () {
		return true;
	}

}

}
