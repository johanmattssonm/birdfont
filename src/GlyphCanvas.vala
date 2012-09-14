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
using Gtk;
using Gdk;
using Math;

namespace Supplement {

class GlyphCanvas : DrawingArea  {

	FontDisplay current_display;
	
	Allocation alloc;
	
	public GlyphCanvas () {
		set_size_request (300, 50);

		alloc.width = 0;
		alloc.height = 0;
		
		current_display = new Glyph ("");
		
		expose_event.connect ((t, e)=> {
				
				Allocation allocation;
				get_allocation (out allocation);
				
				if (unlikely (allocation != alloc && alloc.width != 0)) {
					// Set size of glyph widget to an even number and notify 
					// set new allocation for glyph
					bool ug = false;
					
					if (allocation.height % 2 != 0) {
						MainWindow.native_window.toggle_expanded_margin_bottom ();
						ug = true;
					}
					
					if (allocation.width % 2 != 0) {
						MainWindow.native_window.toggle_expanded_margin_right ();
						ug = true;
					}					
					
					if (ug) {
						redraw_area (1, 1, 2, 2);
					} else if (unlikely (allocation.width % 2 != 0 || allocation.height % 2 != 0)) {
						warning (@"\nGlyph canvas is not divisible by two.\nWidth: $(allocation.width)\nHeight: $(allocation.height)");
					}
					
					Supplement.current_glyph.resized (alloc, allocation);
					Preferences.update_window_size ();
				}
				
				alloc = allocation;
				
				Context cw = cairo_create (get_window());
				
				Surface s = new Surface.similar (cw.get_target (), Cairo.Content.COLOR_ALPHA, allocation.width, allocation.height);
				Context c = new Context (s); 

				current_display.draw (allocation, c);

				cw.save ();
				cw.set_source_surface (c.get_target (), 0, 0);
				cw.paint ();
				cw.restore ();
				
				return true;
			});

		add_events (EventMask.BUTTON_PRESS_MASK | EventMask.BUTTON_RELEASE_MASK | EventMask.POINTER_MOTION_MASK | EventMask.LEAVE_NOTIFY_MASK | EventMask.SCROLL_MASK);
		
		leave_notify_event.connect ((t, e)=> {
			current_display.leave_notify (e);
			return true;
		});
				           
		button_press_event.connect ((t, e)=> {
			current_display.button_press (e);		
			return true;
		});

		button_release_event.connect ((t, e)=> {
			current_display.button_release (e);
			return true;
		});
		
		motion_notify_event.connect ((t, e)=> {
			current_display.motion_notify (e);		
			return true;
		});
		
		scroll_event.connect ((t, e)=> {
			if (e.direction == Gdk.ScrollDirection.UP) {
				current_display.scroll_wheel_up (e);
			} else if (e.direction == Gdk.ScrollDirection.DOWN) {
				current_display.scroll_wheel_down (e);
			}
			
			return true;
		});
		
	}
	
	public void key_release (uint e) {
		current_display.key_release (e);
	}
	
	public void key_press (uint e) {
		current_display.key_press (e);
	}
	
	public void set_current_glyph (FontDisplay fd) {
		if (fd is Glyph) {
			Allocation allocation;
			get_allocation (out allocation);

			Glyph g = (Glyph) fd;
			
			g.allocation = allocation;
			
			Supplement.current_glyph = g;
			Supplement.current_glyph.resized (alloc, allocation);
			
			warn_if_fail (g.allocation.width != 0 && g.allocation.height != 0);
		}
		
		current_display = fd;
		
		fd.selected_canvas ();
		
		fd.redraw_area.connect ((x, y, w, h) => {
			queue_draw_area ((int)x, (int)y, (int)w, (int)h);
		});

		redraw ();
	}
	
	public static Glyph get_current_glyph ()  {
		return Supplement.current_glyph;
	}
	
	public FontDisplay get_current_display () {
		return current_display;
	}
	
	// Deprecated
	private void redraw_area (int x, int y, int w, int h) {
		queue_draw_area (x, y, w, h);
	}
	
	public void redraw () {
		Allocation allocation;
		get_allocation(out allocation);
		queue_draw_area (0, 0, allocation.width, allocation.height);
	}
}

}
