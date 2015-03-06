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

	double height = 44 * MainWindow.units;
	double character_height = 20 * MainWindow.units;
		
	public SpacingTab () {
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

		// background
		cr.save ();
		cr.set_source_rgba (1, 1, 1, 1);
		cr.rectangle (0, allocation.height - height, allocation.width, height);
		cr.fill ();
		cr.restore ();
		
		// character bar
		cr.save ();
		cr.set_source_rgba (0.5, 0.5, 0.5, 1);
		cr.set_line_width (0.8);
		cr.move_to (0, allocation.height - height);
		cr.line_to (allocation.width, allocation.height - height);
		cr.stroke ();
		
		cr.move_to (0, allocation.height - height + character_height);
		cr.line_to (allocation.width, allocation.height - height + character_height);
		cr.stroke ();
		cr.restore ();
		
		// TODO: add button for processing ligatures
		row = get_first_row ().process_ligatures ();
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
		double box_size;
		unichar c;
		
		box_size = 122 * MainWindow.units;
		
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
			cap.set_source_rgba (72 / 255.0, 72 / 255.0, 72 / 255.0, 1);
			cap.widget_x = middle - cap.get_extent () / 2.0;
			cap.widget_y = allocation.height - height + character_height - 4 * MainWindow.units;
			cap.draw_at_baseline (cr, cap.widget_x, cap.widget_y);			
			
			l = g.get_left_side_bearing ();
			left = new Text (truncate (l, 5), 17);
			left.set_source_rgba (72 / 255.0, 72 / 255.0, 72 / 255.0, 1);
			left.widget_x = middle - box_size / 2.0 + (box_size / 2.0 - left.get_extent ()) / 2.0;
			left.widget_y = allocation.height - 7 * MainWindow.units;
			left.draw_at_baseline (cr, left.widget_x, left.widget_y);

			r = g.get_right_side_bearing ();
			right = new Text (truncate (r, 5), 17);
			right.set_source_rgba (72 / 255.0, 72 / 255.0, 72 / 255.0, 1);
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
}

}
