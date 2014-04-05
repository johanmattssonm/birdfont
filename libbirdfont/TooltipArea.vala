/*
    Copyright (C) 2012 2013 Johan Mattsson

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
using Gdk;

namespace BirdFont {

public class TooltipArea : GLib.Object {
	string tooltip;
	
	public signal void redraw ();

	public TooltipArea () {
		set_text_from_tool ();
	}

	public void update_text () {
		set_text_from_current_tool ();
		redraw ();
	}
	
	public static void show_text (string text) {
		if (is_null (MainWindow.get_tooltip ())) {
			return;
		}
		
		MainWindow.get_tooltip ().tooltip = text;
		MainWindow.get_tooltip ().redraw ();
	}
	
	public void set_text_from_tool () {
		set_text_from_current_tool ();
		redraw ();
	}
	
	private void set_text_from_current_tool () {
		Toolbox? tb = MainWindow.get_toolbox ();
		Tool? t;
		Tool tool;
		StringBuilder sb;
		
		if (tb == null) {
			return;
		}
		
		t = ((!)tb).get_active_tool ();
		
		if (t == null) {
			return;
		}
		
		tool = (!) t;
		
		if (tool.key != '\0') {
			sb = new StringBuilder ();

			sb.append ("(");
			
			if (tool.modifier_flag == CTRL) {
				sb.append ("Ctrl+");
			} else if (tool.modifier_flag == SHIFT) {
				sb.append ("Shift+");
			} 

			sb.append_unichar (tool.key);
			sb.append (") ");
			sb.append (tool.get_tip ());
			
			show_text (sb.str);
		} else {
			show_text (tool.get_tip ());
		}
		
	}
	
	public void draw (Context cr, WidgetAllocation alloc) {
		cr.save ();
		cr.rectangle (0, 0, alloc.width, alloc.height);
		cr.set_line_width (0);
		cr.set_source_rgba (200/255.0, 200/255.0, 200/255.0, 1);
		cr.fill_preserve ();
		cr.stroke ();
		cr.restore ();

		cr.save ();
		cr.rectangle (0, 0, alloc.width, 1);
		cr.set_line_width (0);
		cr.set_source_rgba (127/255.0, 127/255.0, 127/255.0, 1);
		cr.fill_preserve ();
		cr.stroke ();
		cr.restore ();
		
		cr.save ();
		cr.rectangle (0, 1, alloc.width, 1);
		cr.set_line_width (0);
		cr.set_source_rgba (170/255.0, 170/255.0, 170/255.0, 1);
		cr.fill_preserve ();
		cr.stroke ();
		cr.restore ();
		
		cr.save ();
		cr.set_font_size (14);
		cr.move_to (5, 15);
		cr.show_text (tooltip);
		cr.restore ();
	}
}

}
