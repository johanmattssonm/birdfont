/*
    Copyright (C) 2012 Johan Mattsson

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

using Cairo;
using Math;

namespace BirdFont {

public class GlyphCanvas : GLib.Object {

	public FontDisplay current_display;
	public signal void signal_redraw_area (int x, int y, int w, int h);
	public static WidgetAllocation allocation = new WidgetAllocation ();
	
	public GlyphCanvas () {
	}

	public static WidgetAllocation get_allocation () {
		return allocation;
	}

	public void set_allocation (WidgetAllocation w) {
		allocation = w.copy ();
	}

	public void key_release (uint e) {
		current_display.key_release (e);
	}
	
	public void key_press (uint e) {
		current_display.key_press (e);
	}
	
	public void set_current_glyph (FontDisplay fd) {
		if (fd is Glyph) {
			Glyph g = (Glyph) fd;
			
			BirdFont.current_glyph = g;
			BirdFont.current_glyph.resized (allocation);
			
			if (g.allocation.width == 0 || g.allocation.height == 0) {
				warning ("area is zero in glyph canvas");
			}
		}

		current_display = fd;
		
		fd.selected_canvas ();
		
		fd.redraw_area.connect ((x, y, w, h) => {
			signal_redraw_area ((int)x, (int)y, (int)w, (int)h);
		});

		redraw ();

		MainWindow.native_window.update_window_size ();
	}
	
	public static Glyph get_current_glyph ()  {
		return BirdFont.current_glyph;
	}
	
	public FontDisplay get_current_display () {
		return current_display;
	}

	public void redraw_area (int x, int y, int w, int h) {
		signal_redraw_area (x, y, w, h);
	}
	
	public static void redraw () {
		GlyphCanvas c = MainWindow.get_glyph_canvas ();
		if (!is_null (c)) {
			c.signal_redraw_area (0, 0, allocation.width, allocation.height);
		}
	}
}

}
