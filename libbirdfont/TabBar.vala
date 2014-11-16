/*
    Copyright (C) 2012, 2014 Johan Mattsson

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

public class TabBar : GLib.Object {
	
	int width = 0;
	int height = 0;
	
	public Gee.ArrayList<Tab> tabs;

	static const int NO_TAB = -1;
	static const int NEXT_TAB = -2;
	static const int PREVIOUS_TAB = -3;
	static const int PROGRESS_WHEEL = -3;
	static const int SHOW_MENU = -4;

	int first_tab = 0;
	int selected = 0;
	int over = NO_TAB;
	int over_close_tab = NO_TAB;
	
	public signal void signal_tab_selected (Tab selected_tab);
	public signal void redraw_tab_bar (int x, int y, int w, int h);

	Tab? previous_tab = null;
	Tab? current_tab = null;
	
	ImageSurface? progress = null;

	ImageSurface? next_tab;
	ImageSurface? to_previous_tab;
	
	ImageSurface? tab_bar_background = null;
	ImageSurface? menu_icon;
	
	double scale = 1; // scale images in 320 dpi
	
	bool processing = false;
	double wheel_rotation = 0;

	double background_r = 51 /255.0;
	double background_g = 54 /255.0;
	double background_b = 59 /255.0;
	
	public TabBar () {
		tabs = new Gee.ArrayList<Tab> ();

		next_tab = Icons.get_icon ("next_tab.png");
		to_previous_tab = Icons.get_icon ("previous_tab.png");
		
		progress = Icons.get_icon ("progress_wheel.png");
		tab_bar_background = Icons.get_icon ("tab_bar_background.png");
		
		menu_icon = Icons.get_icon ("menu.png");
	}
	
	public void redraw (int x, int y, int w, int h) {
		if (MenuTab.suppress_event) {
			warn_if_test ("Redraw tab bar: event suppressed");
			return;
		}
		
		redraw_tab_bar (x, y, w, h);
	}
	
	public void set_background_color (double r, double g, double b) {
		background_r = r;
		background_g = g;
		background_b = r;
	}
	
	public void motion (double x, double y) {
		if (MenuTab.suppress_event) {
			warn_if_test ("Event suppressed");
			return;
		}
		
		over_close (x, y, out over, out over_close_tab);
	}

	private void over_close (double x, double y, out int over, out int over_close_tab) {
		int i = 0;
		double offset = 0;
		bool close_y, close_x;
		
		if (x < 24 && has_scroll ()) {
			over_close_tab = NO_TAB;
			over = PREVIOUS_TAB;
			return;
		}

		if (!has_progress_wheel ()) {
			if (x > width - 25) {
				over_close_tab = NO_TAB;
				over = SHOW_MENU;
				return;
			}
		} else if (has_scroll () && has_progress_wheel ()) {
			if (x > width - 19) {
				over_close_tab = NO_TAB;
				over = PROGRESS_WHEEL;
			} else if (x > width - 2 * 19) {
				over_close_tab = NO_TAB;
				over = NEXT_TAB;
			}
		} else if (!has_scroll () && has_progress_wheel ()) {
			if (x > width - 19) {
				over_close_tab = NO_TAB;
				over = PROGRESS_WHEEL;
			}
		} else if (has_scroll () && !has_progress_wheel ()) {
			if (x > width - 19) {
				over_close_tab = NO_TAB;
				over = NEXT_TAB;
			}
		}
		
		foreach (Tab t in tabs) {
			if (i < first_tab) {
				i++;
				continue;
			}

			if (offset < x < offset + t.get_width ()) {
				over = i;
				
				close_y = height / 2.0 - 4 < y < height / 2.0 + 4;
				close_x = x > offset + t.get_width () - 16;
				if (close_y && close_x) {
					over_close_tab =  i;
				} else {
					over_close_tab =  NO_TAB;
				}
				
				return;
			}
			
			offset += t.get_width ();
			i++;
		}

		over_close_tab = NO_TAB;		
		over = NO_TAB;
	}	
	
	
	/** Select tab for a glyph by charcode or name.
	 * @return true if the tab was found
	 */
	public bool select_char (string s) {
		int i = 0;
		
		if (MenuTab.suppress_event) {
			warn_if_test ("Event suppressed");
			return false;
		}
		
		foreach (Tab t in tabs) {
			if (t.get_display ().get_name () == s) {
				select_tab (i);
				return true;
			}
			i++;
		}
		
		return false;
	}

	public bool select_tab_name (string s) {
		if (MenuTab.suppress_event) {
			warn_if_test ("Event suppressed");
			return false;
		}
		
		return select_char (s);
	}

	public void select_overview () {
		if (MenuTab.suppress_event) {
			warn_if_test ("Event suppressed");
			return;
		}
		
		select_tab_name ("Overview");
	}

	private void select_previous_tab () {
		Tab t;
		bool open;
		
		if (MenuTab.suppress_event) {
			warn_if_test ("Event suppressed");
			return;
		}
		
		if (previous_tab == null) {
			return;
		}
		
		t = (!) previous_tab;
		open = selected_open_tab (t);
		
		if (!open) {
			select_tab ((int) tabs.size - 1);
		}
	}
		
	public void close_display (FontDisplay f) {
		int i = -1;
		
		if (MenuTab.suppress_event) {
			warn_if_test ("Event suppressed");
			return;
		}
		
		if (tabs.size >= 1) {
			foreach (Tab t in tabs) {
				++i;
				
				if (t.get_display () == f) {
					close_tab (i) ;
					return;
				}
			}	
		}
		
		return_if_fail (i != -1);
	} 

	public void close_all_tabs () {
		if (MenuTab.suppress_event) {
			warn_if_test ("Event suppressed");
			return;
		}
		
		for (int i = 0; i < get_length (); i++) {
			if (close_tab (i, false, true)) {
				close_all_tabs ();
			}
		}
	}

	public bool close_tab (int index, bool background_tab = false, bool select_new_tab = true) {
		Tab t;
		EmptyTab empty_tab_canvas;
		Tab empty_tab;
		GlyphCollection gc;

		if (MenuTab.suppress_event) {
			warn_if_test ("Event suppressed");
			return false;
		}
						
		if (!(0 <= index < tabs.size)) {
			return false;
		}
		
		if (tabs.size == 1) {
			empty_tab_canvas = new EmptyTab ("", "");
			gc = new GlyphCollection.with_glyph('\0', "");
			GlyphCanvas.set_display (empty_tab_canvas);
			MainWindow.get_glyph_canvas ().set_current_glyph_collection (gc);
			empty_tab = new Tab (empty_tab_canvas, 0, false);
			signal_tab_selected (empty_tab);
		}
		
		t = tabs.get (index);

		if (first_tab > 0) {
			first_tab--;
		}

		if (t.has_close_button ()) {
			t.get_display ().close ();
			
			tabs.remove_at (index);
			
			if (!background_tab && select_new_tab) {
				select_previous_tab ();
			}
			
			return true;
		}
		
		if (select_new_tab) {
			select_tab (index);
		}
		
		return false;
	}
	
	public bool close_by_name (string name, bool background_tab = false) {
		int i = 0;
				
		foreach (var t in tabs) {
			if (t.get_display ().get_name () == name) {
				return close_tab (i, background_tab);
			}
			
			i++;
		}
		
		return false;
	}
	
	public void close_background_tab_by_name (string name) {
		close_by_name (name, true);
	}
	
	/** Select a tab and return true if it is open. */
	public bool selected_open_tab (Tab t) {
		int i = 0;

		if (MenuTab.suppress_event) {
			warn_if_test ("Event suppressed");
			return false;
		}
				
		foreach (var n in tabs) {
			if (n == t) {
				select_tab (i);
				return true;
			}
			
			i++;
		}
		
		return false;
	}

	public Tab? get_nth (int i) {
		if (!(0 <= i < get_length ())) {
			return null;
		}
		
		return tabs.get (i);
	}

	public Tab? get_tab (string name) {
		foreach (var n in tabs) {
			if (n.get_display ().get_name () == name) {
				return n;
			}
		}
		
		return null;
	}

	public bool selected_open_tab_by_name (string t) {
		int i = 0;
		
		if (MenuTab.suppress_event) {
			warn_if_test ("Event suppressed");
			return false;
		}
			
		foreach (var n in tabs) {
			if (n.get_display ().get_name () == t) {
				select_tab (i);
				return true;
			}
			
			i++;
		}
		
		return false;
	}
	
	public Tab get_selected_tab () {
		int s = get_selected ();
		if (0 <= s < tabs.size) {
			return tabs.get (get_selected ());
		}
		
		warning ("No tab selected.");
		return new Tab (new EmptyTab ("Error", "Error"), 30, false);
	}
	
	public uint get_length () {
		return tabs.size;
	}

	public int get_selected () {
		return selected;
	}
	
	public void select_tab (int index, bool signal_selected = true) {
		Tab t;

		if (MenuTab.suppress_event) {
			warn_if_test ("Event suppressed");
			return;
		}
					
		// always close any pending text input if the user switches tab
		MainWindow.native_window.hide_text_input ();

		if (index == SHOW_MENU) {
			MainWindow.get_menu ().show_menu = !MainWindow.get_menu ().show_menu;
			GlyphCanvas.redraw ();
			return;
		}
		
		if (index == NEXT_TAB) {
			selected++;
			
			if (selected >=  tabs.size) {
				selected = (int) tabs.size - 1;
			}
			
			scroll_to_tab (selected);
			return;
		}
		
		if (index == PREVIOUS_TAB) {

			if (selected > 0) {
				selected--;
			}
			
			scroll_to_tab (selected);
			return;
		}
		
		if (!(0 <= index < tabs.size)) {
			return;
		}

		selected = index;
		
		t = tabs.get (index);
		
		previous_tab = current_tab;
		current_tab = t;

		scroll_to_tab (selected, signal_selected);
	}
	
	private bool has_scroll () {
		int i = 0;
		double offset = 19;
		double end = (has_progress_wheel ()) ? width - 28 : width - 19;
		
		if (first_tab > 0) {
			return true;
		}
		
		foreach (Tab t in tabs) {	
			if (i < first_tab) {
				i++;
				continue;
			}
			
			if (offset + t.get_width () + 3 > end) {
				return true;
			}

			offset += t.get_width ();
			i++;
		}
		
		return false;		
	}
	
	private void signal_selected (int index) {
		Tab t;
		
		t = tabs.get (index);
		
		GlyphCanvas.set_display (t.get_display ());
		
		MainWindow.get_glyph_canvas ()
			.set_current_glyph_collection (t.get_glyph_collection ());
		
		signal_tab_selected (t);		
	}
	
	private void scroll_to_tab (int index, bool send_signal_selected = true) {
		double offset = 19;
		int i = 0;
		double end = (has_progress_wheel ()) ? width - 28 : width - 19;
		
		if (index < first_tab) {
			first_tab = index;
			
			if (send_signal_selected) {
				signal_selected (index);
			}
			return;
		}
		
		foreach (Tab t in tabs) {
			
			if (i < first_tab) {
				i++;
				continue;
			}
			
			// out of view
			if (offset + t.get_width () + 3 > end) {
				first_tab++;
				scroll_to_tab (index);
				return;
			}

			// in view
			if (i == index) {
				
				if (send_signal_selected) {				
					signal_selected (index);
				}
				
				return;
			}

			offset += t.get_width ();
			i++;
		}
		
		warning ("");
	}
	
	public void select_tab_click (double x, double y, int width, int height) {
		int over, close;
		
		if (MainWindow.get_menu ().show_menu) {
			MainWindow.get_menu ().show_menu = false;
			GlyphCanvas.redraw ();
		}
		
		this.width = width;
		this.height = height;
		this.scale = height / 117.0;
		
		over_close (x, y, out over, out close);

		if (over_close_tab >= 0 && over == selected) {
			close_tab (over_close_tab);
		} else {
			select_tab (over);
		}
	}
	
	public void add_tab (FontDisplay display_item, bool signal_selected = true, GlyphCollection? gc = null) {
		double tab_width = -1;
		bool always_open = false;
		int s = (tabs.size == 0) ? 0 : selected + 1;
		Tab t;

		if (MenuTab.suppress_event) {
			warn_if_test ("Event suppressed");
			return;
		}
				
		if (tab_width < 0) {
			tab_width = 9 * display_item.get_label ().char_count ();
			tab_width += 36;
		}
		
		t = new Tab (display_item, tab_width, always_open);
		tabs.insert (s,t);
		
		if (gc != null) {
			t.set_glyph_collection ((!) gc);
		}

		GlyphCanvas.set_display (t.get_display ());

		MainWindow.get_glyph_canvas ()
			.set_current_glyph_collection (t.get_glyph_collection ());
				
		select_tab (s, signal_selected);
	}
	
	/** Returns true if the new item was added to the bar. */
	public bool add_unique_tab (FontDisplay display_item, bool signal_selected = true) {
		bool i;
		
		if (MenuTab.suppress_event) {
			warn_if_test ("Event suppressed");
			return false;
		}
				
		i = select_tab_name (display_item.get_name ());

		if (!i) {
			add_tab (display_item, signal_selected);
			return true;
		}
		
		return false;
	}
	
	public void draw (Context cr, int width, int height) {
		double next_tab_x;
		double w, h;
		double progress_y;
		
		this.width = width;
		this.height = height;
		this.scale = height / 117.0;
				
		return_if_fail (to_previous_tab != null);
		return_if_fail (next_tab != null);
		return_if_fail (progress != null);
		return_if_fail (tab_bar_background != null);

		cr.save ();
		cr.set_line_width (0);
		cr.set_source_rgba (background_r, background_g, background_b, 1);
		cr.rectangle (0, 0, width, height);
		cr.fill ();
		cr.restore ();

		cr.save ();
		cr.scale (scale, scale);
		
		w = width / scale;
		h = height / scale;

		if (has_scroll ()) {
			// left arrow
			cr.set_source_surface ((!) to_previous_tab, 2 / scale, h / 2.0 - ((!) to_previous_tab).get_height () / 2);
			cr.paint ();

			// right arrow
			next_tab_x = (has_progress_wheel ()) ? w - (2 * 19 + 3) / scale : w - 19 / scale;
			cr.set_source_surface ((!) next_tab, next_tab_x, h / 2.0 - ((!) next_tab).get_height () / 2.0);
			cr.paint ();
		}
		
		// progress wheel
		if (has_progress_wheel ()) {
			ImageSurface p = (!) progress;
			Surface s = new Surface.similar (p, p.get_content (), p.get_width (), p.get_height ());
			Context c = new Context (s);
			
			c.save ();
			c.rectangle (0, 0, p.get_width (), p.get_height ());
			c.set_line_width (0);
			c.set_source_rgba (background_r, background_g, background_b, 1);
			c.fill_preserve ();	
			
			c.translate (p.get_width () / 2.0, p.get_height () / 2.0);
			c.rotate (wheel_rotation);
			c.translate (-p.get_width () / 2.0, -p.get_height () / 2.0);
			
			c.set_source_surface ((!) progress, 0 ,0);
			
			c.translate (p.get_width () / 2.0, p.get_height () / 2.0);
			c.paint ();
			c.restore ();

			progress_y = (has_scroll ()) ? h - ((!) progress).get_height () - 5 / scale : (h - ((!) progress).get_height ()) / 2;
			cr.set_source_surface (c.get_target (), w - 19 / scale, progress_y);
			cr.paint ();
		} else {
			// menu icon
			if (menu_icon != null) {
				
				if (MainWindow.get_menu ().show_menu) {
					cr.set_source_rgba (38 / 255.0, 39 / 255.0, 43 / 255.0, 1);
					cr.rectangle (w - 32 / scale, 0, 32 / scale, h);
					cr.fill ();
				}
				
				cr.set_source_surface ((!) menu_icon, w - 25 / scale, h / 2.0 - ((!) menu_icon).get_height () / 2.0);
				cr.paint ();
			}
		}
		
		draw_tabs (cr);
		cr.restore ();
	}
	
	private void draw_tabs (Context cr) {
		double text_height, text_width, center_x, center_y;
		double close_opacity;
		double offset;
		double tab_width;
		double tabs_end = width / scale;
		double h = height / scale;
		double tab_height;
		Tab t;
		Text label;
					
		if (has_progress_wheel ()) {
			tabs_end -= 19 / scale;
		}
		
		if (has_scroll ()) {
			tabs_end -= 19 / scale;
			offset = 24 / scale;
		} else {
			offset = 0;
		}
		
		tab_height = this.height / scale;
		
		for (int tab_index = first_tab; tab_index < tabs.size; tab_index++) {
			t = tabs.get (tab_index);
				
			cr.save ();
			cr.translate (offset, 0);
			
			tab_width = t.get_width () / scale;
			
			if (offset + tab_width > tabs_end) {
				cr.restore ();
				break;
			}
				
			// background
			if (tab_index == selected) {
				cr.save ();
				cr.set_source_rgba (234 / 255.0, 77 / 255.0, 26 / 255.0, 1);
				cr.rectangle (0, 0, tab_width, h);
				cr.fill ();
				cr.restore ();				
			} else if (tab_index == over) {
				cr.save ();
				cr.set_source_rgba (56 / 255.0, 59 / 255.0, 65 / 255.0, 1);
				cr.rectangle (0, 0, tab_width, h);
				cr.fill ();
				cr.restore ();			
			} else {
				cr.save ();
				cr.set_source_rgba (51 / 255.0, 54 / 255.0, 59 / 255.0, 1);
				cr.rectangle (0, 0, tab_width, h);
				cr.fill ();
				cr.restore ();
			}
			
			// close (x)
			if (t.has_close_button ()) {
				cr.save ();
				cr.new_path ();
				cr.set_line_width (1 / scale);
				
				close_opacity = (over_close_tab == tab_index) ? 1 : 0.2; 

				if (tab_index == selected) {
					cr.set_source_rgba (40 / 255.0, 57 / 255.0, 65 / 255.0, close_opacity);
				} else {
					cr.set_source_rgba (101 / 255.0, 108 / 255.0, 116 / 255.0, close_opacity);
				}
				
				cr.move_to (tab_width - 7 / scale, h / 2.0 - 2.5 / scale);
				cr.line_to (tab_width - 12 / scale, h / 2.0 + 2.5 / scale);

				cr.move_to (tab_width - 12 / scale, h / 2.0 - 2.5 / scale);
				cr.line_to (tab_width - 7 / scale, h / 2.0 + 2.5 / scale);
				
				cr.stroke ();
				cr.restore ();
			}
			
			// tab label
			label = new Text ();
			label.set_text (t.get_label ());
			text_height = 16 / scale;
			text_width = label.get_extent (text_height);
			center_x = tab_width / 2.0 - text_width / 2.0;
			center_y = tab_height / 2.0 + 4 / scale;
			
			if (tab_index == selected) {
				cr.set_source_rgba (40 / 255.0, 57 / 255.0, 65 / 255.0, 1);
			} else {
				cr.set_source_rgba (101 / 255.0, 108 / 255.0, 116 / 255.0, 1);
			}
			
			label.draw (cr, center_x, center_y, text_height);
						
			// edges
			if (tab_index != selected) { // don't draw edges for the selected tab
				if (tab_index + 1 != selected) {
					cr.save ();
					cr.set_source_rgba (70 / 255.0, 77 / 255.0, 83 / 255.0, 1);
					cr.rectangle (tab_width - 1 / scale, 0, 1 / scale, h);
					cr.fill ();
					cr.restore ();
				}
				
				if (tab_index == first_tab) {
					cr.save ();
					cr.set_source_rgba (70 / 255.0, 77 / 255.0, 83 / 255.0, 1);
					cr.rectangle (0, 0, 1 / scale, h);
					cr.fill ();
					cr.restore ();
				}
			}

			cr.restore ();
			
			offset += tab_width;
		}
	}
	
	public void add_empty_tab (string name, string label) {
		add_tab (new EmptyTab (name, label));
	}
	
	bool has_progress_wheel () {
		return processing;
	}

	public void set_progress (bool running) {
		TimeoutSource timer;
		
		if (unlikely (processing == running)) {
			warning (@"Progress is already set to $running");
			return;
		}
		
		processing = running;
		
		if (processing) {
			timer = new TimeoutSource (50);
			timer.set_callback (() => {
				wheel_rotation += 0.008 * 2 * Math.PI;
				
				if (wheel_rotation > 2 * Math.PI) {
					wheel_rotation -= 2 * Math.PI;
				}
				
				redraw_tab_bar (width - 19, 0, 19, height);
				return processing;
			});
			timer.attach (null);
		}
	}
	
	public static void start_wheel () {
		if (!is_null (MainWindow.get_tab_bar ())) {
			MainWindow.get_tab_bar ().set_progress (true);
		}
	}

	public static void stop_wheel () {
		if (!is_null (MainWindow.get_tab_bar ())) {
			MainWindow.get_tab_bar ().set_progress (false);
		}
	}
}

}
