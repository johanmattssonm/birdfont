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
using Math;

namespace BirdFont {

public class GlyphCanvas : GLib.Object {

	/** Tab content. */
	public static FontDisplay current_display;
	
	public signal void signal_redraw_area (int x, int y, int w, int h);
	public static WidgetAllocation allocation;
	
	public GlyphCanvas () {
		allocation = new WidgetAllocation ();
	}

	public static WidgetAllocation get_allocation () {
		return allocation;
	}

	public static void set_allocation (WidgetAllocation w) {
		allocation = w.copy ();
	}

	public void key_release (uint e) {
		current_display.key_release (e);
	}
	
	public void key_press (uint e) {
		Toolbox tb;
		
		current_display.key_press (e);
		
		if (current_display is Glyph) {
			tb = MainWindow.get_toolbox ();
			tb.key_press (e);
		}
	}
	
	internal static void set_display (FontDisplay fd) {
		current_display = fd;
	}
	
	public void set_current_glyph_collection (GlyphCollection gc, bool signal_selected = true) {
		Glyph g = gc.get_current ();
		
		BirdFont.current_glyph_collection = gc;
		g.resized (allocation);
		
		if (signal_selected) {
			current_display.selected_canvas ();
		}
		
		current_display.redraw_area.connect ((x, y, w, h) => {
			signal_redraw_area ((int)x, (int)y, (int)w, (int)h);
		});

		redraw ();
		
		if (!is_null (MainWindow.native_window)) {
			MainWindow.native_window.update_window_size ();
		}
	}
	
	public static Glyph get_current_glyph ()  {
		return MainWindow.get_current_glyph ();
	}
	
	public FontDisplay get_current_display () {
		return current_display;
	}

	public void redraw_area (int x, int y, int w, int h) {
		if (MenuTab.suppress_event) {
			warning ("Do not call redraw from background thread.");
		} else {
			signal_redraw_area (x, y, w, h);;
		}
	}
	
	public static void redraw () {
		GlyphCanvas c = MainWindow.get_glyph_canvas ();
		if (!is_null (c)) {
			c.redraw_area (0, 0, allocation.width, allocation.height);
		}
	}
}

}
