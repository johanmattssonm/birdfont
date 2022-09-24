/*
	Copyright (C) 2014 2015 Johan Mattsson

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

	static Text text_input_label;
	static LineTextArea text_input;
	static Button text_input_button;
	static bool text_input_visible = false;
	static TextListener text_callback;
	static ImageSurface? pause_surface = null;

	const int TEXT_INPUT_HEIGHT = 51;

	static double last_press_time = 0;

	public static void zoom_in () {
		if (MenuTab.has_suppress_event ()) {
		}

		GlyphCanvas.current_display.zoom_in ();
	}

	public static void zoom_out () {
		if (MenuTab.has_suppress_event ()) {
			return;
		}

		GlyphCanvas.current_display.zoom_out ();
	}

	public static void move_view (double x, double y) {
		if (MenuTab.has_suppress_event ()) {
			return;
		}

		GlyphCanvas.current_display.move_view (x, y);
	}

	public static bool has_scrollbar () {
		if (MenuTab.has_suppress_event ()) {
			return false;
		}

		return GlyphCanvas.current_display.has_scrollbar ();
	}

	public static void scroll_to (double percent) {
		if (MenuTab.has_suppress_event ()) {
			return;
		}

		GlyphCanvas.current_display.scroll_to (percent);
	}

	public static void draw (WidgetAllocation allocation, Context cr) {
		AbstractMenu menu;
		Dialog dialog;
		double scollbar_width = 10 * Screen.get_scale ();
		
		if (MainWindow.has_scrollbar()) {
			allocation.width -= (int) scollbar_width;
		}

		if (unlikely (MenuTab.has_suppress_event ())) {
			cr.save ();
			Theme.color (cr, "Background 1");
			cr.rectangle (0, 0, allocation.width, allocation.height);
			cr.fill ();

			if (pause_surface != null) {
				cr.scale (1.0 / Screen.get_scale (), 1.0 / Screen.get_scale ());
				cr.set_source_surface ((!) pause_surface, 0, 0);
				cr.paint ();
			}

			cr.restore ();
		} else {
			menu = MainWindow.get_menu ();
			dialog = MainWindow.get_dialog ();

			GlyphCanvas.set_allocation (allocation);
			MainWindow.get_current_glyph ().resized (allocation);
			GlyphCanvas.current_display.draw (allocation, cr);

			if (dialog.visible) {
				dialog.allocation = allocation;
				dialog.layout ();
				dialog.draw (cr);
			} else if (menu.show_menu) {
				menu.draw (allocation, cr);
			}

			if (FontDisplay.dirty_scrollbar) {
				GlyphCanvas.current_display.update_scrollbar ();
				FontDisplay.dirty_scrollbar = false;
			}

			if (text_input_visible) {
				draw_text_input (allocation, cr);
			}

			if (MainWindow.has_scrollbar()) {
				MainWindow.scrollbar.draw (cr, allocation, scollbar_width);
			}
		}
	}

	public static void create_pause_surface () {
		Context cr;
		WidgetAllocation alloc;

		if (MenuTab.has_suppress_event ()) {
			warning ("Background surface already created.");
			return;
		}

		alloc = GlyphCanvas.get_allocation ();
		
		double scollbar_width = 10 * Screen.get_scale ();
		alloc.width += (int) scollbar_width;
		
		pause_surface = Screen.create_background_surface (alloc.width, alloc.height);
		cr = new Context ((!) pause_surface);
		cr.scale (Screen.get_scale (), Screen.get_scale ());
		draw (alloc, cr);
	}

	public static void key_press (uint keyval) {
		if (MenuTab.has_suppress_event () || MainWindow.get_dialog ().visible) {
			return;
		}

		unichar c = (unichar) keyval;

		if (unlikely (!c.validate ())) {
			warning ("Invalid unichar: $(keyval)");
			return;
		}

		KeyBindings.add_modifier_from_keyval (keyval);

		if (!text_input_visible) {
			AbstractMenu menu = MainWindow.get_menu ();
			bool consumed = menu.process_key_binding_events (keyval);
			
			if (!consumed) {
				GlyphCanvas.current_display.key_press (keyval);
			}
		} else {
			text_input.key_press (keyval);
		}
	}

	public static void key_release (uint keyval) {
		if (MenuTab.has_suppress_event () || MainWindow.get_dialog ().visible) {
			return;
		}

		unichar c = (unichar) keyval;

		if (unlikely (!c.validate ())) {
			warning ("Invalid unichar: $(keyval)");
			return;
		}

		KeyBindings.remove_modifier_from_keyval (keyval);

		if (!text_input_visible) {
			GlyphCanvas.current_display.key_release (keyval);
		}
	}

	public static void motion_notify (double x, double y) {
		Toolbox toolbox;

		if (MenuTab.has_suppress_event ()) {
			return;
		}

		if (!text_input_visible) {
			bool consumed = MainWindow.scrollbar.motion (x, y);
			
			if (!consumed) {
				GlyphCanvas.current_display.motion_notify (x, y);
			}
		} else {
			text_input.motion (x, y);
			GlyphCanvas.redraw ();
		}

		toolbox = MainWindow.get_toolbox ();
		toolbox.hide_tooltip ();
	}

	public static void button_release (int button, double x, double y) {
		if (MenuTab.has_suppress_event ()) {
			return;
		}

		if (MainWindow.get_dialog ().visible) {
			MainWindow.get_dialog ().button_release (button, x, y);
		} else if (MainWindow.get_menu ().show_menu) {
			MainWindow.get_menu ().button_release (button, x, y);
		} else if (text_input_visible) {
			text_input_button.button_release (button, x, y);
			text_input.button_release (button, x, y);
			GlyphCanvas.redraw ();
		} else {
			bool consumed = MainWindow.scrollbar.button_release (button, x, y);
						
			if (!consumed) {			
				GlyphCanvas.current_display.button_release (button, x, y);
			}
		}
	}

	public static void button_press (uint button, double x, double y) {
		if (MenuTab.has_suppress_event ()) {
			return;
		}

		last_press_time = GLib.get_real_time ();

		if (MainWindow.get_dialog ().visible) {
			MainWindow.get_dialog ().button_press (button, x, y);
		} else if (!MainWindow.get_menu ().show_menu) {
			if (text_input_visible) {
				text_input.button_press (button, x, y);
				text_input_button.button_press (button, x, y);

				if (y > TEXT_INPUT_HEIGHT) {
					hide_text_input ();
				}
			} else {
				bool consumed = MainWindow.scrollbar.button_press (button, x, y);
				
				if (!consumed) { 
					GlyphCanvas.current_display.button_press (button, x, y);
				}
			}
		}
	}

	public static void double_click (uint button, double ex, double ey) {
		if (MenuTab.has_suppress_event ()) {
			return;
		}

		if (!MainWindow.get_menu ().show_menu) {
			GlyphCanvas.current_display.double_click (button, ex, ey);
		}
	}

	public static void scroll_wheel_pixel_delta (double x, double y,
		double pixeldelta_x, double pixeldelta_y) {

		if (MenuTab.has_suppress_event ()) {
			return;
		}

		if (!MainWindow.get_menu ().show_menu) {
			GlyphCanvas.current_display.scroll_wheel (x, y, pixeldelta_x, pixeldelta_y);
		}
	}

	public static void scroll_wheel_up (double x, double y) {
		if (MenuTab.has_suppress_event ()) {
			return;
		}

		if (!MainWindow.get_menu ().show_menu) {
			GlyphCanvas.current_display.scroll_wheel (x, y, 0, 15);
		}
	}

	public static void scroll_wheel_down (double x, double y) {
		if (MenuTab.has_suppress_event ()) {
			return;
		}

		if (!MainWindow.get_menu ().show_menu) {
			GlyphCanvas.current_display.scroll_wheel (x, y, 0, -15);
		}
	}

  public static void magnify (double magnification) {
		if (MenuTab.has_suppress_event ()) {
			return;
		}

		if (!MainWindow.get_menu ().show_menu) {
			GlyphCanvas.current_display.magnify (magnification);
		}
	}

	public static void tap_down (int finger, int x, int y) {
		if (MenuTab.has_suppress_event ()) {
			return;
		}

		if (!MainWindow.get_menu ().show_menu) {
			GlyphCanvas.current_display.tap_down (finger, x, y);
		}
	}

	public static void tap_up (int finger, int x, int y) {
		if (MenuTab.has_suppress_event ()) {
			return;
		}

		if (!MainWindow.get_menu ().show_menu) {
			GlyphCanvas.current_display.tap_up (finger, x, y);
		}
	}

	public static void tap_move (int finger, int x, int y) {
		if (MenuTab.has_suppress_event ()) {
			return;
		}

		if (!MainWindow.get_menu ().show_menu) {
			GlyphCanvas.current_display.tap_move (finger, x, y);
		}
	}

	public static void undo () {
		if (MenuTab.has_suppress_event ()) {
			return;
		}

		GlyphCanvas.current_display.undo ();
	}

	public static void redo () {
		if (MenuTab.has_suppress_event ()) {
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

	public static void draw_text_input (WidgetAllocation allocation, Context cr) {
		cr.save ();

		Theme.color (cr, "Default Background");
		cr.rectangle (0, 0, allocation.width, TEXT_INPUT_HEIGHT);
		cr.fill ();
		cr.restore ();

		Theme.text_color (text_input_label, "Button Foreground");

		text_input_label.widget_x = 10;
		text_input_label.widget_y = 17;

		text_input.allocation = allocation;
		text_input.layout ();
		text_input.widget_x = text_input_label.get_extent () + 20;
		text_input.widget_y = 10;
		text_input.width = allocation.width
			- text_input_button.get_width ()
			- text_input_label.get_extent ()
			- 40;

		text_input_button.allocation = allocation;
		text_input_button.widget_x = text_input.widget_x + text_input.width + 10;
		text_input_button.widget_y = 10;

		text_input_label.draw (cr);
		text_input.draw (cr);
		text_input_button.draw (cr);
	}

	public static void show_text_input (TextListener tl) {
		text_callback = tl;

		text_input_label = new Text (tl.label);
		text_input = new LineTextArea (20);
		text_input_button = new Button (tl.button_label);

		text_input.carret_is_visible = true;

		text_input.set_text (tl.default_text);
		text_input.text_changed.connect ((text) => {
			tl.signal_text_input (text);
		});

		text_input.enter.connect ((text) => {
			tl.signal_submit (text);
			text_input_visible = false;
			GlyphCanvas.redraw ();
		});

		text_input_button.action.connect (() => {
			tl.signal_submit (text_input.get_text ());
		});

		text_input_visible = true;
		GlyphCanvas.redraw ();
	}

	public static void hide_text_input () {
		text_input_visible = false;
		text_callback = new TextListener ("", "", "");
	}

	public static void reset_modifier () {
		TabContent.key_release (Key.CTRL_RIGHT);
		TabContent.key_release (Key.CTRL_LEFT);
		TabContent.key_release (Key.SHIFT_LEFT);
		TabContent.key_release (Key.SHIFT_RIGHT);
		TabContent.key_release (Key.ALT_LEFT);
		TabContent.key_release (Key.ALT_RIGHT);
		TabContent.key_release (Key.LOGO_LEFT);
		TabContent.key_release (Key.LOGO_RIGHT);

		if (MainWindow.get_current_display () is GlyphTab) {
			TabContent.key_release ((uint) ' ');
		}
	}
}

}
