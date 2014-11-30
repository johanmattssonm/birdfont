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

public class LanguageSelectionTab : FontDisplay {
	
	int scroll = 0;
	int visible_rows = 0;
	WidgetAllocation allocation;
	
	public LanguageSelectionTab () {
		allocation = new WidgetAllocation ();
	}

	void select_language (int row) {
		string iso_code;
		TabBar tb = MainWindow.get_tab_bar ();
		
		return_if_fail (0 <= row < DefaultLanguages.codes.size);
		
		iso_code = DefaultLanguages.codes.get (row);
		Preferences.set ("language", iso_code);
		tb.close_display (this);
		Toolbox.select_tool_by_name ("custom_character_set");
	}

	public override void button_release (int button, double ex, double ey) {
		int r = (int) rint ((ey - 17) / 18.0);
		if (button == 1 && 0 <= r < DefaultLanguages.codes.size) {
			select_language (r + scroll);
		}
	}
	
	public override void draw (WidgetAllocation allocation, Context cr) {
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
		
		foreach (string language in DefaultLanguages.names) {
			if (s++ >= scroll) {
				draw_row (allocation, cr, language, color, y);
				y += 18;
				color = !color;
			}
		}
		cr.restore ();
	}	

	private static void draw_row (WidgetAllocation allocation, Context cr, string language, bool color, double y) {

		if (color) {
			cr.save ();
			cr.set_source_rgba (224/255.0, 224/255.0, 224/255.0, 1);
			cr.rectangle (0, y - 14, allocation.width, 18);
			cr.fill ();
			cr.restore ();
		}
		
		cr.move_to (30, y);
		cr.show_text (language);
	}

	public override string get_label () {
		return t_("Character Set");
	}
	
	public override string get_name () {
		return "Character Set";
	}

	public override bool has_scrollbar () {
		return true;
	}
	
	public override void scroll_wheel_down (double x, double y) {
		uint rows = DefaultLanguages.names.size;
		scroll += 3;

		if (scroll + visible_rows > rows) {
			scroll = (int) (rows - visible_rows);
		}
		
		if (scroll < 0) {
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
	
	public override void update_scrollbar () {
		uint rows = DefaultLanguages.names.size;

		if (rows == 0 || visible_rows == 0) {
			MainWindow.set_scrollbar_size (0);
			MainWindow.set_scrollbar_position (0);
		} else {
			MainWindow.set_scrollbar_size ((double) visible_rows / rows);
			MainWindow.set_scrollbar_position ((double) scroll /  rows);
		}
	}

	public override void scroll_to (double percent) {
		uint rows = DefaultLanguages.names.size;
		scroll = (int) (percent * rows);
		
		if (scroll > rows - visible_rows) {
			scroll = (int) (rows - visible_rows);
		}
		
		redraw_area (0, 0, allocation.width, allocation.height);
	}
}

}
