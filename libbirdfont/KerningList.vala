/*
    Copyright (C) 2013 Johan Mattsson

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
using Math;

namespace BirdFont {

public class KerningList : FontDisplay {
	
	int scroll = 0;
	int visible_rows = 0;
	WidgetAllocation allocation;
	
	public KerningList () {
		allocation = new WidgetAllocation ();
	}

	public override void draw (WidgetAllocation allocation, Context cr) {
		KerningClasses classes = KerningClasses.get_instance ();
		int y = 20;
		int s = 0;
		bool color = (scroll % 2) == 0;
		
		this.allocation = allocation;
		
		visible_rows = (int) (allocation.height / 18.0);
		
		cr.save ();
		cr.set_source_rgba (1, 1, 1, 1);
		cr.rectangle (0, 0, allocation.width, allocation.height);
		cr.fill ();
		cr.restore ();
		
		cr.save ();
		cr.set_source_rgba (0.3, 0.3, 0.3, 1);
		cr.set_font_size (12);

		classes.get_classes ((left, right, kerning) => {
			if (s++ >= scroll) {
				draw_row (allocation, cr, left, right, @"$kerning", y, color);
				y += 18;
				color = !color;
			}
		});
		
		classes.get_single_position_pairs ((left, right, kerning) => {
			if (s++ >= scroll) {
				draw_row (allocation, cr, left, right, @"$kerning", y, color);
				y += 18;
				color = !color;
			}
		});
		
		cr.restore ();
	}	

	private static void draw_row (WidgetAllocation allocation, Context cr,
		string left, string right, string kerning, int y, bool color) {

		if (color) {
			cr.save ();
			cr.set_source_rgba (224/255.0, 224/255.0, 224/255.0, 1);
			cr.rectangle (0, y - 14, allocation.width, 18);
			cr.fill ();
			cr.restore ();
		}
		
		// remove kerning icon
		cr.save ();
		cr.set_line_width (1);
		cr.move_to (10, y - 8);
		cr.line_to (15, y - 3);
		cr.move_to (10, y - 3);
		cr.line_to (15, y - 8);		
		cr.stroke ();
		cr.restore ();
		
		cr.move_to (60, y);
		cr.show_text (left);
		cr.move_to (230, y);
		cr.show_text (right);
		cr.move_to (430, y);
		cr.show_text (kerning);
	}

	public override void button_release (int button, double ex, double ey) {
		KerningClasses classes = KerningClasses.get_instance ();
		string l, r;
		int s = 0;
		int y = 0;
		Font font = BirdFont.get_current_font ();
	
		l = "";
		r = "";
		
		if (ex < 20) {
			classes.get_classes ((left, right, kerning) => {
				if (s++ >= scroll) {
					y += 18;
					
					if (y - 10 <= ey <= y + 5) {
						l = left;
						r = right;
					}				
				}
			});
			
			if (l != "" && r != "") {
				classes.delete_kerning_for_class (l, r);
				font.touch ();
			}
			
			classes.get_single_position_pairs ((left, right, kerning) => {
				if (s++ >= scroll) {
					y += 18;
					
					if (y - 10 <= ey <= y + 5) {
						l = left;
						r = right;
					}				
				}
			});
			
			if (l != "" && r != "") {
				classes.delete_kerning_for_pair (l, r);
				font.touch ();
			}
			
			update_scrollbar ();
			redraw_area (0, 0, allocation.width, allocation.height);
		}
	}

	public override string get_label () {
		return t_("Kerning Pairs");
	}

	public override string get_name () {
		return "Kerning Pairs";
	}

	public override bool has_scrollbar () {
		return true;
	}
	
	public override void scroll_wheel_down (double x, double y) {
		uint pairs = KerningClasses.get_instance ().get_number_of_pairs ();
		scroll += 3;

		if (scroll > pairs - visible_rows) {
			scroll = (int) (pairs - visible_rows);
		}
		
		if (visible_rows > pairs) {
			scroll = 0;
		} 
		
		update_scrollbar ();
		redraw_area (0, 0, allocation.width, allocation.height);
	}
	
	public override void scroll_wheel_up (double x, double y) {
		scroll -= 3;
		
		if (scroll < 0) {
			scroll = 0;
		}
		
		update_scrollbar ();
		redraw_area (0, 0, allocation.width, allocation.height);
	}

	public override void selected_canvas () {
		update_scrollbar ();
		redraw_area (0, 0, allocation.width, allocation.height);
	}
	
	public void update_scrollbar () {
		uint rows = KerningClasses.get_instance ().get_number_of_pairs ();

		if (rows == 0 || visible_rows == 0) {
			MainWindow.set_scrollbar_size (0);
			MainWindow.set_scrollbar_position (0);
		} else {
			MainWindow.set_scrollbar_size ((double) visible_rows / rows);
			MainWindow.set_scrollbar_position ((double) scroll /  rows);
		}
	}

	public override void scroll_to (double percent) {
		uint pairs = KerningClasses.get_instance ().get_number_of_pairs ();
		scroll = (int) (percent * pairs);
		
		if (scroll > pairs - visible_rows) {
			scroll = (int) (pairs - visible_rows);
		}
		
		redraw_area (0, 0, allocation.width, allocation.height);
	}
}

}
