/*
	Copyright (C) 2012 2013 2014 Johan Mattsson

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
using BirdFont;
using WebKit;
using Gdk;
using Notify;

namespace BirdFont {

public class GtkWindow : Gtk.Window, NativeWindow {

	Box list_box;
	Box canvas_box;
	
	WebView html_canvas;
	ScrolledWindow html_box;

	Box tab_box;
	
	GlyphCanvasArea glyph_canvas_area;
	
	Clipboard clipboard;
	string clipboard_svg = "";
	string inkscape_clipboard = "";
	
	ToolboxCanvas toolbox;
	
	Task background_task = new Task(idle);
	
	public GtkWindow (string title) {
		((Gtk.Window)this).set_title ("BirdFont");
	}
	
	public static void idle () {
	}
	
	public void init () {
		Notify.init ("BirdFont");
		Signal.connect(this, "notify::is-active", (GLib.Callback) window_focus, null);

		clipboard = Clipboard.get_for_display (get_display (), Gdk.SELECTION_CLIPBOARD);
		
		delete_event.connect (() => {
			MenuTab.quit ();
			return true;
		});
		
		set_size_and_position ();
		
		glyph_canvas_area = new GlyphCanvasArea (MainWindow.glyph_canvas);

		html_canvas = new WebView ();
		html_box = new ScrolledWindow (null, null);
		html_box.set_policy (PolicyType.NEVER, PolicyType.AUTOMATIC);
		html_box.add (html_canvas);
		
		MainWindow.get_tab_bar ().signal_tab_selected.connect ((f, tab) => {
			string uri = "";
			string html = "";
			FontDisplay fd = tab.get_display ();
			
			if (fd.get_name () == "Preview") {
				uri = Preview.get_uri ();
				html = Preview.get_html_with_absolute_paths ();
										
				html_canvas.load_html (html, uri);
				
				// show the webview when loading has finished 
				html_box.set_visible (true); 
				glyph_canvas_area.set_visible (false); 
			} else {
				html_box.set_visible (false);
				glyph_canvas_area.set_visible (true);
			}
		});

		// Hide this canvas when window is realized and flip canvas 
		// visibility in tab selection signal.
		html_canvas.draw.connect ((t, e) => {
			glyph_canvas_area.set_visible (false);
			return false;
		});

		canvas_box = new Box (Orientation.HORIZONTAL, 0);
		canvas_box.pack_start (glyph_canvas_area, true, true, 0);
		canvas_box.pack_start (html_box, true, true, 0);
		
		tab_box = new Box (Orientation.VERTICAL, 0);		
		tab_box.pack_start (new TabbarCanvas (MainWindow.get_tab_bar ()), false, false, 0);
		tab_box.pack_start (canvas_box, true, true, 0);

		toolbox = new ToolboxCanvas (MainWindow.get_toolbox ()); 
		list_box = new Box (Orientation.HORIZONTAL, 0);
		list_box.pack_start (toolbox, false, false, 0);
		list_box.pack_start (tab_box, true, true, 0);
		
		Box vbox = new Box (Orientation.VERTICAL, 0);
		vbox.pack_start(list_box, true, true, 0);
		add (vbox);

		try {
			set_icon_from_file ((!) SearchPaths.find_file (null, "birdfont_window_icon.png").get_path ());
		} catch (GLib.Error e) {
			warning (e.message);
		}

		key_press_event.connect ((t, event) => {
			unichar c;
			
			c = keyval_to_unicode (event.keyval);
			
			if (c != '\0') {
				TabContent.key_press (c);
			} else {
				TabContent.key_press (event.keyval);
			}
			
			return false;
		});
		
		key_release_event.connect ((t, event) => {
			unichar c;
			
			c = keyval_to_unicode (event.keyval);
			
			if (c != '\0') {
				TabContent.key_release (c);
			} else {
				TabContent.key_release (event.keyval);
			}
			
			return false;
		});
		
		
		size_allocate.connect(() => {
			GlyphCanvas.redraw ();
		});

		show_all ();

		MainWindow.open_recent_files_tab ();		

#if FREE
		MainWindow.show_license_dialog ();
#endif
	}

	public void window_focus (void* data) {
		TabContent.reset_modifier ();
	}

	public static void reset_modifier (ModifierType flags) {
		if ((flags & ModifierType.CONTROL_MASK) == 0) {
			TabContent.key_release (Key.CTRL_RIGHT);
			TabContent.key_release (Key.CTRL_LEFT);
		}
		
		if ((flags & ModifierType.SHIFT_MASK) == 0) {
			TabContent.key_release (Key.SHIFT_LEFT);
			TabContent.key_release (Key.SHIFT_RIGHT);
		}

		if ((flags & ModifierType.MOD1_MASK) == 0) {
			TabContent.key_release (Key.ALT_LEFT);
			TabContent.key_release (Key.ALT_RIGHT);
		}
		
		if ((flags & ModifierType.MOD5_MASK) == 0) {
			TabContent.key_release (Key.LOGO_LEFT);
			TabContent.key_release (Key.LOGO_RIGHT);
		}
	}
	
	public void font_loaded () {
		Font f = BirdFont.get_current_font ();
		set_title (@"$(f.full_name)");
	}

	public void dump_clipboard_content (Clipboard clipboard, SelectionData selection_data) {
		string d;
		return_if_fail (!is_null (selection_data));
		d = (string) ((!) selection_data);
		stdout.printf (d);
	}

	public void dump_clipboard_target (Clipboard clipboard, Atom[]? atoms) {
		if (atoms != null) {
			foreach (Atom target in (!) atoms) {
				print ("Target: " + target.name () + "\n");
				clipboard.request_contents (target, dump_clipboard_content);
			}
		}
	}
	
	public void dump_clipboard () {
		clipboard.request_targets (dump_clipboard_target);
	}
	
	public string get_clipboard_data () {
		SelectionData? selection_data;
		Atom target;
		string? t;
		
		target = Atom.intern_static_string ("image/x-inkscape-svg");
		selection_data = clipboard.wait_for_contents (target);
		
		if (!is_null (selection_data)) {
			return (string) (((!) selection_data).get_data ());
		}
		
		t = clipboard.wait_for_text ();
		if (t != null) {
			return (!) t;
		}
		
		return "";
	}
	
	public void set_inkscape_clipboard (string inkscape_clipboard_data) {
		if (BirdFont.mac) {
			clipboard.set_text (inkscape_clipboard_data, -1);
		} else {
			TargetEntry t = { "image/x-inkscape-svg", 0, 0 };
			TargetEntry[] targets = { t };
			inkscape_clipboard = inkscape_clipboard_data;
			
			// we can not add data to this closure because the third argument 
			// is owner and not private data.
			clipboard.set_with_owner (targets,
			
				// obtain clipboard data 
				(clipboard, selection_data, info, owner) => {
					Atom type;
					uchar[] data = (uchar[])(!)((GtkWindow*)owner)->inkscape_clipboard.to_utf8 ();
					type = Atom.intern_static_string ("image/x-inkscape-svg");
					selection_data.set (type, 8, data);
				},
				
				// clear clipboard data
				(clipboard, user_data) => {
				},
				
				this);		
		}
	}
	
	public void set_clipboard_text (string text) {
		clipboard.set_text (text, -1);
	}
	
	public string get_clipboard_text () {
		string? t;
		
		t = clipboard.wait_for_text ();
		if (t != null) {
			return ((!) t).dup ();
		}
		
		return "".dup ();
	}
	
	public void set_clipboard (string svg) {
		TargetEntry t = { "image/svg+xml", 0, 0 };
		TargetEntry[] targets = { t };
		clipboard_svg = svg;
		clipboard.set_with_owner (targets,
		
			// obtain clipboard data 
			(clipboard, selection_data, info, owner) => {
				Atom type;
				uchar[] data = (uchar[])(!)((GtkWindow*)owner)->clipboard_svg.to_utf8 ();
				type = Atom.intern_static_string ("image/svg+xml");
				selection_data.set (type, 0, data);
			},
			
			// clear clipboard data
			(clipboard, user_data) => {
			},
			
			this);
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
	}
	
	public void quit () {
		Gtk.main_quit ();	
	}
	
	public void file_chooser (string title, FileChooser fc, uint flags) {
		string? fn = null;
		bool folder;
		if (BirdFont.get_arguments () .has_argument ("--windows")) {
			folder = (flags & FileChooser.DIRECTORY) > 0;
			MenuTab.show_file_dialog_tab (title, fc, folder);
		} else {
			if ((flags & FileChooser.DIRECTORY) > 0) { 
				if ((flags & FileChooser.LOAD) > 0) {
					fn = show_file_chooser (title, FileChooserAction.SELECT_FOLDER, t_("Open"));
				} else if ((flags & FileChooser.SAVE) > 0) {
					fn = show_file_chooser (title, FileChooserAction.SELECT_FOLDER, t_("Save"));
				} else {
					warning ("Open or save is not set.");
				}
			} else if ((flags & FileChooser.LOAD) > 0) {
				fn = show_file_chooser (title, FileChooserAction.OPEN, t_("Open"));
			} else if ((flags & FileChooser.SAVE) > 0) {
				fn = show_file_chooser (title, FileChooserAction.SAVE, t_("Save"));
			} else {
				warning ("Unknown type");
			}
		}
		
		fc.selected (fn);
	}
	
	public string? show_file_chooser (string title, FileChooserAction action, string label) {
		string? fn = null;
		FileChooserDialog file_chooser = new FileChooserDialog (title, this, action, t_("Cancel"), ResponseType.CANCEL, label, ResponseType.ACCEPT);
		Font font = BirdFont.get_current_font ();
		int i;
		string last_folder;
		
		last_folder = Preferences.get ("last_folder");
		
		try {
			if (last_folder == "") {
				file_chooser.set_current_folder_file (font.get_folder ());
			} else {
				file_chooser.set_current_folder_file (File.new_for_path (last_folder));
			}
		} catch (GLib.Error e) {
			stderr.printf (e.message);
		}
		
		if (file_chooser.run () == ResponseType.ACCEPT) {	
			GlyphCanvas.redraw ();
			fn = file_chooser.get_filename ();
		}

		file_chooser.destroy ();
		
		if (fn != null) {
			i = ((!) fn).last_index_of ("/");
			if (i > -1) {
				last_folder = ((!) fn).substring (0, i);
				Preferences.set ("last_folder", @"$last_folder");
			}
		}
		
		return fn;
	}
	
	public bool convert_to_png (string from, string to) {
		Pixbuf pixbuf;
		string folder;
		int i;
		
		try {
			i = to.last_index_of ("/");
			if (i != -1) {
				folder = to.substring (0, i);
				DirUtils.create (folder, 0xFFFFFF);
			}
			
			pixbuf = new Pixbuf.from_file (from);
			pixbuf.save (to, "png");
		} catch (GLib.Error e) {
			warning (e.message);
			return false;
		}
		
		return true;
	}
	
	public void run_background_thread (Task t) {
		unowned Thread<void*> bg;
		
		MenuTab.start_background_thread ();
		background_task = t;
		
		try {
			bg = new Thread<void*>.try ("bg", this.background_thread);
		} catch (GLib.Error e) {
			warning (e.message);
		}
	}

	public void run_non_blocking_background_thread (Task t) {
		unowned Thread<void*> bg;
		
		try {
			bg = new Thread<void*>.try ("bg", t.perform_task);
		} catch (GLib.Error e) {
			warning (e.message);
		}
	}
	
	public void* background_thread () {	
		background_task.run ();
		MenuTab.stop_background_thread ();
		return null;
	}
	
	/** Run export in a background thread. */
	public void export_font () {
		unowned Thread<void*> export_thread;
		
		MenuTab.start_background_thread ();
		
		try {
			export_thread = new Thread<void*>.try ("export_thread", this.export_thread);
		} catch (GLib.Error e) {
			warning (e.message);
		}
	}
	
	public void* export_thread () {
		IdleSource idle = new IdleSource ();

		ExportCallback.export_fonts ();
		MenuTab.stop_background_thread ();
		MenuTab.signal_file_exported ();

		idle.set_callback (() => {
			Notify.Notification export_notification;
			export_notification = new Notify.Notification ("BirdFont", t_("Your fonts have been exported."), null);
			try {
				export_notification.show ();
			} catch (GLib.Error e) {
				warning (e.message);
			}
			return false;
		});
		idle.attach (null);

		return null;
	}
	
	/** Load font in a background thread. */
	public void load () {
		unowned Thread<void*> thread;
		
		MenuTab.start_background_thread ();
		
		try {
			thread = new Thread<void*>.try ("thread", this.loading_thread);
		} catch (GLib.Error e) {
			warning (e.message);
		}
	}
	
	public void* loading_thread () {
		BirdFont.get_current_font ().load ();
		MenuTab.stop_background_thread ();
		MenuTab.signal_file_loaded ();
		return null;
	}

	/** Save font in a background thread. */
	public void save () {
		unowned Thread<void*> thread;
		
		MenuTab.start_background_thread ();
		
		try {
			thread = new Thread<void*>.try ("thread", this.saving_thread);
		} catch (GLib.Error e) {
			warning (e.message);
		}
	}
	
	public void* saving_thread () {
		BirdFont.get_current_font ().save ();
		MenuTab.stop_background_thread ();
		MenuTab.signal_file_saved ();
		return null;
	}

	public void load_background_image () {
		unowned Thread<void*> thread;
		
		MenuTab.start_background_thread ();
		
		try {
			thread = new Thread<void*>.try ("thread", this.background_image_thread);
		} catch (GLib.Error e) {
			warning (e.message);
		}
	}

	public void* background_image_thread () {
		BackgroundTool.load_background_image ();
		MenuTab.stop_background_thread ();
		return null;
	}
	
	public bool can_export () {
		return true;
	}
	
	public void set_cursor (int visible) {
	}

	public double get_screen_scale () {
		var screen = Gdk.Screen.get_default();
		return_val_if_fail (screen != null, 1);

		var current_screen = (!) screen;
		var resolution = current_screen.get_resolution();
		var reference_resolution = 96.0;  // reference resolution
		double fractional_scale = resolution / reference_resolution;

		int scale_factor = this.get_scale_factor(); // probably 1 or 2 for 100% or 200%

		return scale_factor * fractional_scale;
	}
}

class TabbarCanvas : DrawingArea {
	TabBar tabbar;
	
	public TabbarCanvas (TabBar tb) {		
		tabbar = tb;

		add_events (EventMask.BUTTON_PRESS_MASK | EventMask.POINTER_MOTION_MASK | EventMask.LEAVE_NOTIFY_MASK);
			  
		motion_notify_event.connect ((t, e)=> {
			Gtk.Allocation alloc;
			tabbar.motion (e.x, e.y);
			get_allocation (out alloc);
			queue_draw_area (0, 0, alloc.width, alloc.height);
			return true;
		});	
				
		button_press_event.connect ((t, e)=> {
			Gtk.Allocation alloc;
			get_allocation (out alloc);
			GtkWindow.reset_modifier (e.state);
			tabbar.select_tab_click (e.x, e.y, alloc.width, alloc.height);
			queue_draw_area (0, 0, alloc.width, alloc.height);
			return true;
		});

		draw.connect ((t, e)=> {
			Gtk.Allocation alloc;
			Context cr = e;
									
			//cr = cairo_create ((!) get_window ());
			get_allocation (out alloc);
						
			tabbar.draw (cr, alloc.width, alloc.height);
			return true;
		});
	
		tabbar.signal_tab_selected.connect ((t) => {
			Gtk.Allocation alloc;
			get_allocation (out alloc);
			queue_draw_area (0, 0, alloc.width, alloc.height);	
		});

		tabbar.redraw_tab_bar.connect ((x, y, w, h) => {
			queue_draw_area (x, y, w, h);
		});
				
		set_size_request (20, 38);
	}
	
}

class ToolboxCanvas : DrawingArea {
	Toolbox tb;
	
	public ToolboxCanvas (Toolbox toolbox) {
		tb = toolbox;
		
		realize.connect (() => {
			Gtk.Allocation allocation;
			get_allocation (out allocation);
			Toolbox.allocation_width = allocation.width;
			Toolbox.allocation_height = allocation.height;
			
			Toolbox.redraw_tool_box ();
		});
		
		tb.redraw.connect ((x, y, w, h) => {
			if (h < 0) {
				warning (@"Toolbox height is less than zero: $(h)");
				return;
			}
			
			queue_draw_area (x, y, w, h);
		});
		
		button_press_event.connect ((se, e)=> {
			if (e.type == EventType.2BUTTON_PRESS)	{
				tb.double_click (e.button, e.x, e.y);
			} else {
				tb.press (e.button, e.x, e.y);
			}
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
		
		draw.connect ((t, e)=> {
			Gtk.Allocation allocation;
			get_allocation (out allocation);
			
			Context cw = cairo_create((!) get_window());
			Toolbox.allocation_width = allocation.width;
			Toolbox.allocation_height = allocation.height;
			
			tb.draw (Toolbox.allocation_width, Toolbox.allocation_height, cw);
			
			return true;
		});

		scroll_event.connect ((t, e)=> {
			if (e.direction == Gdk.ScrollDirection.UP) {
				tb.scroll_up (e.x, e.y);
			} else if (e.direction == Gdk.ScrollDirection.DOWN) {
				tb.scroll_down (e.x, e.y);
			}			
			return true;
		});
		
		add_events (EventMask.BUTTON_PRESS_MASK | EventMask.BUTTON_RELEASE_MASK | EventMask.POINTER_MOTION_MASK | EventMask.LEAVE_NOTIFY_MASK | EventMask.SCROLL_MASK);

		int width = 212;
		set_size_request (width, 100);

		leave_notify_event.connect ((t, e)=> {
			tb.reset_active_tool ();
			return true;
		});
		
	}
}

public class GlyphCanvasArea : DrawingArea  {
	GlyphCanvas glyph_canvas;
	WidgetAllocation alloc = new WidgetAllocation ();
	uint32 last_release = 0;
	uint32 last_press = 0;

	public GlyphCanvasArea (GlyphCanvas gc) {
		int event_flags;
		
		glyph_canvas = gc;

		event_flags = EventMask.BUTTON_PRESS_MASK;
		event_flags |= EventMask.BUTTON_RELEASE_MASK;
		event_flags |= EventMask.POINTER_MOTION_MASK;
		event_flags |= EventMask.LEAVE_NOTIFY_MASK;
		event_flags |= EventMask.SCROLL_MASK;
		
		add_events (event_flags);
		
		glyph_canvas.signal_redraw_area.connect ((x, y, w, h) => {
			queue_draw_area ((int)x, (int)y, (int)w, (int)h);
		});

		draw.connect ((t, e)=> {		
			Gtk.Allocation allocation;
			get_allocation (out allocation);
			
			alloc = new WidgetAllocation ();
			
			alloc.width = allocation.width;
			alloc.height = allocation.height;
			alloc.x = allocation.x;
			alloc.y = allocation.y;
			
			Context cw = e;
			//cw = cairo_create ((!) get_window());
			
			Surface s = new Surface.similar (cw.get_target (), Cairo.Content.COLOR_ALPHA, alloc.width, alloc.height);
			Context c = new Context (s); 

			TabContent.draw (alloc, c);

			cw.save ();
			cw.set_source_surface (c.get_target (), 0, 0);
			cw.paint ();
			cw.restore ();
			
			return true;
		});

		button_press_event.connect ((t, e)=> {
			GtkWindow.reset_modifier (e.state);

			if (e.time < last_press) {
				warning ("Discarding event.");
				return true;
			}
			
			last_press = e.time;
			
			if (e.type == EventType.BUTTON_PRESS) {
				TabContent.button_press (e.button, e.x, e.y);
			} else if (e.type == EventType.2BUTTON_PRESS) {
				TabContent.double_click (e.button, e.x, e.y);
			}
			 
			return true;
		});
		
		button_release_event.connect ((t, e)=> {
			if (e.time < last_release) {
				warning ("Discarding event.");
				return true;
			}
			
			if (e.type == EventType.BUTTON_RELEASE) {
				TabContent.button_release ((int) e.button, e.x, e.y);
			}
			
			last_release = e.time;
			
			return true;
		});
		
		motion_notify_event.connect ((t, e)=> {
			TabContent.motion_notify (e.x, e.y);		
			return true;
		});
		
		scroll_event.connect ((t, e)=> {
			if (e.direction == Gdk.ScrollDirection.UP) {
				TabContent.scroll_wheel_up (e.x, e.y);
			} else if (e.direction == Gdk.ScrollDirection.DOWN) {
				TabContent.scroll_wheel_down (e.x, e.y)		;
			}
			
			TabContent.button_release (2, e.x, e.y);
			return true;
		});
		
		can_focus = true;
	}
}

}
