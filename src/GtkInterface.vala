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
using Supplement;
using WebKit;

namespace Supplement {

public class GtkWindow : Gtk.Window, NativeWindow {

	HBox list_box;
	HBox canvas_box;
	
	WebView html_canvas;
	ScrolledWindow html_box;

	VBox tab_box;

	static DrawingArea margin_bottom;
	static DrawingArea margin_right;
		
	public GtkWindow (string title) {
		// set_title (title);
	}
	
	public void init () {
		margin_bottom = new DrawingArea ();
		margin_right = new DrawingArea ();
	
		margin_bottom.set_size_request (0, 0);
		margin_right.set_size_request (0, 0);
		
		delete_event.connect (quit);
		
		set_size_and_position ();
		
		html_canvas = new WebView ();
		WebKit.set_cache_model (CacheModel.DOCUMENT_VIEWER);
		html_canvas.get_settings ().enable_default_context_menu = false;
				
		html_canvas.title_changed.connect ((p, s) => {
			webkit_callback (s);
		});
		
		html_box = new ScrolledWindow (null, null);
		html_box.set_policy (PolicyType.NEVER, PolicyType.AUTOMATIC);
		
		html_box.add (html_canvas);
		
		html_canvas.set_editable (true);
		
		MainWindow.get_tab_bar ().signal_tab_selected.connect ((f, tab) => {
			bool n;
			File layout_dir;
			File layout_uri;
			string uri = "";
			FontDisplay fd = tab.get_display ();
			
			MainWindow.glyph_canvas.set_current_glyph (fd);
			n = fd.is_html_canvas ();
			
			if (n) {
				layout_dir = FontDisplay.find_layout_dir ();
				uri = fd.get_uri ();
				
				if (uri == "") {
					layout_uri = layout_dir.get_child (fd.get_html_file ());
					uri = fd.path_to_uri ((!) layout_uri.get_path ());
				}

				if (fd.get_name () == "Preview") {
					ExportTool.export_all ();
				}
				
				if (fd.get_html () == "") {
					html_canvas.load_html_string ("<html></html>", "file:///");	
					html_canvas.reload_bypass_cache ();
					
					html_canvas.load_uri (uri);
					html_canvas.reload_bypass_cache ();
					html_canvas.load_uri (uri);
					
				} else {
					html_canvas.load_html_string (fd.get_html (), uri);
				}
				
				html_box.set_visible (n);
				MainWindow.glyph_canvas.set_visible (!n);
			} else {
				html_box.set_visible (false);
				MainWindow.glyph_canvas.set_visible (true);
			}
		});

		// Hide this canvas when window is realized and flip canvas 
		// visibility in tab selection signal.
		html_canvas.expose_event.connect ((t, e) => {
			MainWindow.glyph_canvas.set_visible (false);
			return false;
		});
				
		MainWindow.tabs.add_unique_tab (MainWindow.content, 60, true);
		
		MainWindow.tabs.select_tab_name ("Menu");

		canvas_box = new HBox (false, 0);
		canvas_box.pack_start (MainWindow.glyph_canvas, true, true, 0);
		canvas_box.pack_start (html_box, true, true, 0);
		
		tab_box = new VBox (false, 0);
		tab_box.pack_start (new TabbarCanvas (MainWindow.tabs), false, false, 0);	
		
		tab_box.pack_start (canvas_box, true, true, 0);

		tab_box.pack_start (MainWindow.tool_tip, false, false, 0);
		tab_box.pack_start (margin_bottom, false, false, 0);
		
		list_box = new HBox (false, 0);
		list_box.pack_start (tab_box, true, true, 0);
		list_box.pack_start (new ToolboxCanvas (MainWindow.tools), false, false, 0);
		list_box.pack_start (margin_right, false, false, 0);

		add (list_box);
				
		key_snooper_install (MainWindow.global_key_bindings, null);
		
		add_events (EventMask.FOCUS_CHANGE_MASK);
		
		focus_in_event.connect ((t, e)=> {
			MainWindow.key_bindings.reset ();
			return true;
		});
	
		set_icon_from_file ((!) Icons.find_icon ("window_icon.png").get_path ());
		
		show_all ();		
	
	}

	internal void toggle_expanded_margin_bottom () {
		int w, h;
		margin_bottom.get_size_request (out w, out h);
		
		if (h == 1) h = 2; 
		else h = 1;
		
		margin_bottom.set_size_request (w, h);
	}
	
	internal void toggle_expanded_margin_right () {	
		int w, h;
		margin_right.get_size_request (out w, out h);

		if (w == 1) w = 2; 
		else w = 1;

		margin_right.set_size_request (w, h);
	}

	public static void hide_cursor () {
		Pixmap pixmap = new Pixmap (null, 1, 1, 1);
		Color color = { 0, 0, 0, 0 };
		Cursor cursor = new Cursor.from_pixmap (pixmap, pixmap, color, color, 0, 0);

		// Fixa: But why?
		// (Supplement.exe:1300): Gdk-CRITICAL **: gdk_window_set_cursor: assertion `GDK_IS_WINDOW (window)' failed		
		// singleton.frame.set_cursor (cursor);
	}

	public void update_window_size () {
		int w, h;
		get_size (out w, out h);
		
		Preferences.set ("window_width", @"$w");
		Preferences.set ("window_height", @"$h");
	}
		
	private void set_size_and_position () {
		int w = Preferences.get_window_width ();
		int h = Preferences.get_window_height ();
		
		set_default_size (w, h);
		// move (10, 240);
	}
	
	public bool quit () {
		bool added;
		SaveDialog s = new SaveDialog ();
		
		if (Supplement.get_current_font ().is_modified ()) {
			added = MainWindow.get_tab_bar ().add_unique_tab (s, 50);
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
	
	public string? file_chooser (string title) {
		string? fn = null;
		FileChooserDialog file_chooser = new FileChooserDialog (title, this, FileChooserAction.SAVE, Stock.CANCEL, ResponseType.CANCEL, Stock.SAVE, ResponseType.ACCEPT);
		Font font = Supplement.get_current_font ();
		
		try {
			file_chooser.set_current_folder_file (font.get_folder ());
		} catch (GLib.Error e) {
			stderr.printf (e.message);
		}
		
		if (file_chooser.run () == ResponseType.ACCEPT) {	
			MainWindow.get_glyph_canvas ().redraw ();
			fn = file_chooser.get_filename ();
		}

		file_chooser.destroy ();
		
		return fn;
	}	
}

class TabbarCanvas : DrawingArea {
	TabBar tabbar;
	
	public TabbarCanvas (TabBar tb) {		
		tabbar = tb;

		set_extension_events (ExtensionMode.CURSOR | EventMask.POINTER_MOTION_MASK);
		add_events (EventMask.BUTTON_PRESS_MASK | EventMask.POINTER_MOTION_MASK | EventMask.LEAVE_NOTIFY_MASK);
	  
		motion_notify_event.connect ((t, e)=> {
			Allocation alloc;
			tabbar.motion (e.x, e.y);
			get_allocation (out alloc);
			queue_draw_area (0, 0, alloc.width, alloc.height);
			return true;
		});	
				
		button_press_event.connect ((t, e)=> {
			Allocation alloc;
			get_allocation (out alloc);
			tabbar.select_tab_click (e.x, e.y, alloc.width, alloc.height);
			queue_draw_area (0, 0, alloc.width, alloc.height);
			return true;
		});

		expose_event.connect ((t, e)=> {
			Context cr = cairo_create (get_window ());

			Allocation alloc;
			get_allocation (out alloc);

			tabbar.draw (cr, alloc.width, alloc.height);
			return true;
		});
	
		tabbar.signal_tab_selected.connect ((t) => {
			Allocation alloc;
			get_allocation (out alloc);
			queue_draw_area (0, 0, alloc.width, alloc.height);	
		});
		
		set_size_request (20, 25);
	}
	
}

class ToolboxCanvas : DrawingArea {
	Toolbox tb;
	
	public ToolboxCanvas (Toolbox toolbox) {
		tb = toolbox;
		
		tb.redraw.connect ((x, y, w, h) => {
			queue_draw_area (x, y, w, h);
		});
		
		button_press_event.connect ((se, e)=> {
			tb.press (e.button, e.x, e.y);
			return true;
		});	
				
		button_release_event.connect ((se, e)=> {
			tb.release (e.button, e.x, e.y);
			return true;
		});

		motion_notify_event.connect ((sen, e)=> {
			tb.move (e.x, e.y);
			return true;
		});
		
		expose_event.connect ((t, e)=> {
			Allocation allocation;
			get_allocation (out allocation);
			
			Context cw = cairo_create(get_window());
			tb.allocation_width = allocation.width;
			tb.allocation_height = allocation.height;
			tb.draw (allocation.width, allocation.height, cw);
			
			return true;
		});
		
		add_events (EventMask.BUTTON_PRESS_MASK | EventMask.BUTTON_RELEASE_MASK | EventMask.POINTER_MOTION_MASK | EventMask.LEAVE_NOTIFY_MASK);

		set_size_request (160, 100);

		leave_notify_event.connect ((t, e)=> {
			tb.reset_active_tool ();
			return true;
		});
		
	}
}

}
