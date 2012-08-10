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

using Gdk;
using Gtk;
using WebKit;

namespace Supplement {

public class MainWindow : Gtk.Window {

	HBox list_box;
	HBox canvas_box;
	
	WebView html_canvas;
	ScrolledWindow html_box;
		
	static TabBar tabs;
	VBox tab_box;
	
	static Toolbox tools;
	static GlyphCanvas glyph_canvas;
	static MainWindow singleton;
	static KeyBindings key_bindings;
	static MenuTab content;
	static TooltipArea tool_tip;
		
	static DrawingArea margin_bottom;
	static DrawingArea margin_right;

	static OverView over_view;
	
	public MainWindow (string title) {
		singleton = this;
		
		key_bindings = new KeyBindings ();
		
		glyph_canvas = new GlyphCanvas ();
		tools = new Toolbox (glyph_canvas);
		tabs = new TabBar ();
		content = new MenuTab ();
		tool_tip = new TooltipArea ();

		margin_bottom = new DrawingArea ();
		margin_right = new DrawingArea ();
	
		margin_bottom.set_size_request (0, 0);
		margin_right.set_size_request (0, 0);
		
		set_title (title);
		
		delete_event.connect (quit);
		
		set_size_and_position ();
		
		html_canvas = new WebView ();
		
		html_canvas.title_changed.connect ((p, s) => {
			FontDisplay fd = get_current_display ();
			fd.process_property (s);
		});
		
		html_box = new ScrolledWindow (null, null);
		html_box.set_policy (PolicyType.NEVER, PolicyType.AUTOMATIC);
		
		html_box.add (html_canvas);
		
		tabs.signal_tab_selected.connect ((f, tab) => {
			bool n;
			File layout_dir;
			string uri;
			FontDisplay fd = tab.get_display ();
			
			glyph_canvas.set_current_glyph (fd);
			n = fd.is_html_canvas ();
			
			if (n) {			
				layout_dir = FontDisplay.find_layout_dir ();
				html_box.set_visible (n);
				glyph_canvas.set_visible (!n);
				
				uri = fd.get_uri ();
				
				if (uri == "") {
					uri = @"file://$((!) layout_dir.get_path ())/$(fd.get_html_file ())";
				}
				
				if (fd.get_html () == "") {
					html_canvas.load_uri (uri);
				} else {
					html_canvas.load_html_string (fd.get_html (), uri);
				}				
			} else {
				html_box.set_visible (false);
				glyph_canvas.set_visible (true);
			} 
		});

		// Hide this canvas when window is realized and flip canvas 
		// visibility in tab selection signal.
		html_canvas.expose_event.connect ((t, e) => {
			glyph_canvas.set_visible (false);
			return false;
		});

		over_view = new OverView();
				
		tabs.add_unique_tab (content, 60, true);
		tabs.add_unique_tab (over_view, 75, false);
		
		tabs.select_tab_name ("Menu");

		canvas_box = new HBox (false, 0);
		canvas_box.pack_start (glyph_canvas, true, true, 0);
		canvas_box.pack_start (html_box, true, true, 0);
		
		tab_box = new VBox (false, 0);
		tab_box.pack_start (tabs, false, false, 0);	
		
		tab_box.pack_start (canvas_box, true, true, 0);

		tab_box.pack_start (tool_tip, false, false, 0);
		tab_box.pack_start (margin_bottom, false, false, 0);
		
		list_box = new HBox (false, 0);
		list_box.pack_start (tab_box, true, true, 0);
		list_box.pack_start (tools, false, false, 0);
		list_box.pack_start (margin_right, false, false, 0);

		add (list_box);
				
		key_snooper_install (global_key_bindings, null);
		
		add_events (EventMask.FOCUS_CHANGE_MASK);
		
		focus_in_event.connect ((t, e)=> {
			key_bindings.reset ();
			return true;
		});
		
		show_all ();
	}
	
	public static WebView get_webview () {
		return singleton.html_canvas;
	}

	public static void hide_cursor () {
		Pixmap pixmap = new Pixmap (null, 1, 1, 1);
		Color color = { 0, 0, 0, 0 };
		Cursor cursor = new Cursor.from_pixmap (pixmap, pixmap, color, color, 0, 0);

		// Fixa: But why?
		// (Supplement.exe:1300): Gdk-CRITICAL **: gdk_window_set_cursor: assertion `GDK_IS_WINDOW (window)' failed		
		// singleton.frame.set_cursor (cursor);
	}
	
	private void set_size_and_position () {
		int w = Preferences.get_window_width();
		int h = Preferences.get_window_height();
		
		set_default_size (w, h);
		// move (10, 240);
	}
	
	public bool quit () {
		bool added;
		SaveDialog s = new SaveDialog ();
		
		if (Supplement.get_current_font ().is_modified ()) {
			added = tabs.add_unique_tab (s, 50);
		} else {
			added = false;
		}
		
		if (!added) {
			Supplement.get_current_font ().save_backup ();
			Gtk.main_quit ();
		}
		
		s.finished.connect (() => {
			Supplement.get_current_font ().delete_backup ();
			Gtk.main_quit ();
		});
		
		return true;
	}
	
	internal static MainWindow get_current_window () {
		return singleton;
	}
	 
	internal static FontDisplay get_current_display () {
		return get_glyph_canvas ().get_current_display ();
	}
	
	internal static GlyphCanvas get_glyph_canvas () {
		return glyph_canvas;
	}
	
	internal static Glyph get_current_glyph () {
		Glyph? g = get_singleton ().glyph_canvas.get_current_glyph ();
		
		if (unlikely (g == null)) {
				warning ("No default glyph have been set yet.\n");
				return new Glyph ("no_glyph_created");
		}
		
		return (!) g;
	}
	
	internal static Toolbox get_toolbox () {
		return get_singleton ().tools;
	}
	
	internal static Tool get_tool (string n) {
		return get_singleton ().tools.get_tool (n);
	}
	
	internal static TabBar get_tab_bar () {
		return get_singleton ().tabs;
	}

	internal static Tab get_current_tab () {
		return get_singleton ().tabs.get_selected_tab ();
	}

	internal static TooltipArea get_tool_tip () {
		return tool_tip;
	}

	internal static bool select_tab (Tab t) {
		return get_singleton ().tabs.selected_open_tab (t);
	}

	internal static OverView get_overview () {
		OverView over_view;
		
		foreach (var t in tabs.tabs) {
			if (t.get_display () is OverView) {
				return (OverView) t.get_display ();
			}
		}
		
		over_view = new OverView();
		tabs.add_unique_tab (over_view, 75, false);
				
		return over_view;
	}
	
	internal static MenuTab get_content_display () {
		if (unlikely ((MenuTab?) get_singleton ().content == null)) {
			warning ("MenuTab not instantiated.");
		}
		
		return get_singleton ().content;
	}
	
	public static MainWindow get_singleton () {
		return singleton;
	}
	
	public static int global_key_bindings (Widget grab_widget, EventKey event, void* data) {		
		MainWindow window = get_singleton ();
		
		window.glyph_canvas.key_press (event);
		window.key_bindings.key_press (event);
		
		return 0;
	}
	
	/** Reaload all paths and help lines from disk. */
	internal static void clear_glyph_cache () {
		Glyph g;
		foreach (Tab t in get_tab_bar ().tabs) {
			if (t.get_display () is Glyph) {
				g = (Glyph) t.get_display ();
				g.add_help_lines ();
			}
		}
		
		get_glyph_canvas ().redraw ();
	}
		
	internal static void close_all_tabs () {
		uint i = 0;
		uint len = get_tab_bar ().get_length ();

		while (i < len) {
			if (!get_tab_bar ().close_tab ((int) i)) {
				i++;
			}
		}
	}

	internal static void toggle_expanded_margin_bottom () {
		int w, h;
		margin_bottom.get_size_request (out w, out h);
		
		if (h == 1) h = 2; 
		else h = 1;
		
		margin_bottom.set_size_request (w, h);
	}
	
	internal static void toggle_expanded_margin_right () {	
		int w, h;
		margin_right.get_size_request (out w, out h);

		if (w == 1) w = 2; 
		else w = 1;

		margin_right.set_size_request (w, h);
	}
}

}
