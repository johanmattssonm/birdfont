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

namespace BirdFont {

/** Interface for events from native window to the current tab. */
public class TabContent : GLib.Object {

	public static void zoom_in () {
		if (MenuTab.suppress_event) {
		}
		
		GlyphCanvas.current_display.zoom_in ();
	}
	
	public static void zoom_out () {
		if (MenuTab.suppress_event) {
			return;
		}
		
		GlyphCanvas.current_display.zoom_out ();
	}
	
	public static void move_view (double x, double y) {
		if (MenuTab.suppress_event) {
			return;
		}
		
		GlyphCanvas.current_display.move_view (x, y);
	}
	
	public static bool has_scrollbar () {
		if (MenuTab.suppress_event) {
			return false;
		}
		
		return GlyphCanvas.current_display.has_scrollbar ();
	}
	
	public static void scroll_to (double percent) {
		if (MenuTab.suppress_event) {
			return;
		}
		
		GlyphCanvas.current_display.scroll_to (percent);
	}
	
	public static void draw (WidgetAllocation allocation, Context cr) {
		Menu menu = MainWindow.get_menu ();
		
		if (MenuTab.suppress_event) {
			cr.save ();
			cr.set_source_rgba (1, 1, 1, 1);
			cr.rectangle (0, 0, allocation.width, allocation.height);
			cr.fill ();
			cr.restore ();
		} else {
			GlyphCanvas.set_allocation (allocation);
			MainWindow.get_current_glyph ().resized (allocation);
			GlyphCanvas.current_display.draw (allocation, cr);
			
			if (menu.show_menu) {
				menu.draw (allocation, cr);
			}
		}
	}
	
	public static void key_press (uint keyval) {
		if (MenuTab.suppress_event) {
			return;
		}

		KeyBindings.add_modifier_from_keyval (keyval);
		MainWindow.get_menu ().process_key_binding_events (keyval);
		GlyphCanvas.current_display.key_press (keyval);
	}
	
	public static void key_release (uint keyval) {
		if (MenuTab.suppress_event) {
			return;
		}
		
		GlyphCanvas.current_display.key_release (keyval);
		KeyBindings.remove_modifier_from_keyval (keyval);
	}
	
	public static void motion_notify (double x, double y) {
		if (MenuTab.suppress_event) {
			return;
		}
		
		GlyphCanvas.current_display.motion_notify (x, y);
	}
	
	public static void button_release (int button, double x, double y) {
		if (MenuTab.suppress_event) {
			return;
		}
		
		if (MainWindow.get_menu ().show_menu) {
			MainWindow.get_menu ().button_release (button, x, y);
		} else {
			GlyphCanvas.current_display.button_release (button, x, y);
		}
	}
	
	public static void button_press (uint button, double x, double y) {
		if (MenuTab.suppress_event) {
			return;
		}
		
		if (!MainWindow.get_menu ().show_menu) {
			GlyphCanvas.current_display.button_press (button, x, y);
		}
	}

	public static void double_click (uint button, double ex, double ey) {
		if (MenuTab.suppress_event) {
			return;
		}
		
		if (!MainWindow.get_menu ().show_menu) {
			GlyphCanvas.current_display.double_click (button, ex, ey);
		}
	}
	
	public static void scroll_wheel_up (double x, double y) {
		if (MenuTab.suppress_event) {
			return;
		}
		
		if (!MainWindow.get_menu ().show_menu) {
			GlyphCanvas.current_display.scroll_wheel_up (x, y);
		}
	}
	
	public static void scroll_wheel_down (double x, double y) {
		if (MenuTab.suppress_event) {
			return;
		}
		
		if (!MainWindow.get_menu ().show_menu) {
			GlyphCanvas.current_display.scroll_wheel_down (x, y);
		}
	}

	public static void tap_down (int finger, int x, int y) {
		if (MenuTab.suppress_event) {
			return;
		}
		
		if (!MainWindow.get_menu ().show_menu) {
			GlyphCanvas.current_display.tap_down (finger, x, y);
		}
	}
	
	public static void tap_up (int finger, int x, int y) {
		if (MenuTab.suppress_event) {
			return;
		}
		
		if (!MainWindow.get_menu ().show_menu) {
			GlyphCanvas.current_display.tap_up (finger, x, y);
		}
	}
	
	public static void tap_move (int finger, int x, int y) {
		if (MenuTab.suppress_event) {
			return;
		}
		
		if (!MainWindow.get_menu ().show_menu) {
			GlyphCanvas.current_display.tap_move (finger, x, y);
		}
	}
		
	public static void undo () {
		if (MenuTab.suppress_event) {
			return;
		}
		
		GlyphCanvas.current_display.undo ();
	}

	public static void redo () {
		if (MenuTab.suppress_event) {
			return;
		}
		
		GlyphCanvas.current_display.redo ();
	}
		
	public static string path_to_uri (string path) {
		string uri = path;
		string wp;
		
		// wine uri hack
		if (BirdFont.win32) {
			wp = wine_to_unix_path (uri);
			
			if (SearchPaths.find_file (wp, "").query_exists ()) {
				uri = wp;
			}

			if (uri.index_of ("\\") > -1) {
				uri = uri.replace ("\\", "/");
			}
		}

		if (uri.index_of ("/") == 0) {
			uri = @"file://$uri";
		} else {
			uri = @"file:///$uri";
		}
		
		return uri;
	}
}

}

