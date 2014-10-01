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
using Math;

namespace BirdFont {

public class LigatureList : FontDisplay {
	
	int scroll = 0;
	int visible_rows = 0;
	WidgetAllocation allocation;
	
	public LigatureList () {
		allocation = new WidgetAllocation ();
	}

	public override void draw (WidgetAllocation allocation, Context cr) {
		Ligatures ligatures = BirdFont.get_current_font ().get_ligatures ();
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

		ligatures.get_ligatures ((substitution, ligature) => {
			if (s++ >= scroll) {
				draw_row (allocation, cr, substitution, ligature, y, color);
				y += 18;
				color = !color;
			}
		});
		
		cr.restore ();
	}	

	private static void draw_row (WidgetAllocation allocation, Context cr,
		string substitution, string ligature, int y, bool color) {

		if (color) {
			cr.save ();
			cr.set_source_rgba (224/255.0, 224/255.0, 224/255.0, 1);
			cr.rectangle (0, y - 14, allocation.width, 18);
			cr.fill ();
			cr.restore ();
		}
		
		cr.move_to (30, y);
		cr.show_text (substitution);
		cr.move_to (230, y);
		cr.show_text (ligature);
	}

	public override string get_label () {
		return t_("Ligatures");
	}

	public override string get_name () {
		return "Ligatures";
	}

	public override bool has_scrollbar () {
		return true;
	}
	
	public override void scroll_wheel_down (double x, double y) {
		Ligatures ligatures = BirdFont.get_current_font ().get_ligatures ();
		uint liga = ligatures.count ();
		scroll += 3;

		if (scroll > liga - visible_rows) {
			scroll = (int) (liga - visible_rows);
		}
		
		if (visible_rows > liga) {
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
		Ligatures ligatures = BirdFont.get_current_font ().get_ligatures ();
		uint rows = ligatures.count ();

		if (rows == 0 || visible_rows == 0) {
			MainWindow.set_scrollbar_size (0);
			MainWindow.set_scrollbar_position (0);
		} else {
			MainWindow.set_scrollbar_size ((double) visible_rows / rows);
			MainWindow.set_scrollbar_position ((double) scroll /  rows);
		}
	}

	public override void scroll_to (double percent) {
		Ligatures ligatures = BirdFont.get_current_font ().get_ligatures ();
		uint liga = ligatures.count ();
		scroll = (int) (percent * liga);
		
		if (scroll > liga - visible_rows) {
			scroll = (int) (liga - visible_rows);
		}
		
		redraw_area (0, 0, allocation.width, allocation.height);
	}
}

}

