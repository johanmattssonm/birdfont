/*
    Copyright (C) 2012, 2013, 2014 Johan Mattsson

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
	
	Scrollbar scrollbar;
	bool scrollbar_supress_signal = false;
	
	DescriptionForm description;
	
	/** Text input and callbacks. */
	public static bool text_input_is_active = false;
	TextListener text_listener = new TextListener ("", "", "");
	Label text_input_label;
	Entry text_entry;
	Box text_box;
	Gtk.Button submit_text_button;
	
	Gtk.Window tooltip_window = new Gtk.Window ();
	
	ToolboxCanvas toolbox;
	
	Task background_task = new Task ();
	
	public GtkWindow (string title) {
		scrollbar = new Scrollbar (Orientation.VERTICAL, new Adjustment (0, 0, 1, 1, 0.01, 0.1));
		((Gtk.Window)this).set_title ("BirdFont");
	}
	
	public void init () {
		Notify.init ("Fonts have been exported.");
		
		description = new DescriptionForm ();
		
		clipboard = Clipboard.get_for_display (get_display (), Gdk.SELECTION_CLIPBOARD);

		Signal.connect(this, "notify::is-active", (GLib.Callback) window_focus, null);

		scrollbar.value_changed.connect (() => {
			double p;
			
			if (!scrollbar_supress_signal) {
				p = scrollbar.get_value () / (1 - scrollbar.adjustment.page_size);
				FontDisplay display = MainWindow.get_current_display ();
				display.scroll_to (p);
			}
		});
		
		delete_event.connect (() => {
			MenuTab.quit ();
			return true;
		});
		
		set_size_and_position ();
		
		glyph_canvas_area = new GlyphCanvasArea (MainWindow.glyph_canvas);

		html_canvas = new WebView ();
		WebKit.set_cache_model (CacheModel.DOCUMENT_VIEWER);
		html_canvas.get_settings ().enable_default_context_menu = false;
		
		html_box = new ScrolledWindow (null, null);
		html_box.set_policy (PolicyType.NEVER, PolicyType.AUTOMATIC);
		html_box.add (html_canvas);
		html_canvas.set_editable (true);
		
		MainWindow.get_tab_bar ().signal_tab_selected.connect ((f, tab) => {
			string uri = "";
			string html = "";
			FontDisplay fd = tab.get_display ();
			
			scrollbar.set_visible (fd.has_scrollbar ());
			
			if (fd.get_name () == "Preview") {
				uri = Preview.get_uri ();
				html = Preview.get_html_with_absolute_paths ();
										
				try {	
					html_canvas.load_html_string (html, uri);
				} catch (Error e) {
					warning (e.message);
					warning ("Failed to load html into canvas.");
				}
				
				// show the webview when loading has finished
				html_box.set_visible (true);
				glyph_canvas_area.set_visible (false);
				description.canvas.set_visible (false);
				
			} else {
				html_box.set_visible (false);
				glyph_canvas_area.set_visible (true);
				description.canvas.set_visible (false);
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
		canvas_box.pack_start (description.canvas, true, true, 0);
		canvas_box.pack_start (scrollbar, false, true, 0);

		submit_text_button = new Gtk.Button ();
		submit_text_button.set_label ("Submit");
		text_input_label = new Label ("   " + "Text");
		text_entry = new Entry ();
		text_box = new Box (Orientation.HORIZONTAL, 6);
		text_box.pack_start (text_input_label, false, false, 0);
		text_box.pack_start (text_entry, true, true, 0);
		text_box.pack_start (submit_text_button, false, false, 0);

		text_entry.changed.connect (() => {
			text_listener.signal_text_input (text_entry.text);
		});

		submit_text_button.clicked.connect (() => {
			text_listener.signal_submit (text_entry.text);
			text_input_is_active = false;
		});
		
		tab_box = new Box (Orientation.VERTICAL, 0);
		
		tab_box.pack_start (new TabbarCanvas (MainWindow.get_tab_bar ()), false, false, 0);
		tab_box.pack_start (text_box, false, false, 5);	
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
			if (!GtkWindow.text_input_is_active) {
				GtkWindow.reset_modifier (event.state);
				TabContent.key_press (event.keyval);
			}
			
			return false;
		});
		
		key_release_event.connect ((t, event) => {
			if (!GtkWindow.text_input_is_active) {
				TabContent.key_release (event.keyval);
			}
			
			return false;
		});
		
		show_all ();
		
		scrollbar.set_visible (false);
		description.canvas.set_visible (false);
		
		hide_text_input ();
		
		MainWindow.open_recent_files_tab ();
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

	public void set_scrollbar_size (double size) {
		scrollbar.adjustment.page_size = size;		
		scrollbar.set_visible (size != 0);
	}
	
	public void set_scrollbar_position (double position) {
		scrollbar_supress_signal = true;
		scrollbar.adjustment.value = position * (1 - scrollbar.adjustment.page_size);
		scrollbar_supress_signal = false;
	}

	public void dump_clipboard_content (Clipboard clipboard, SelectionData selection_data) {
		string d;
		return_if_fail (!is_null (selection_data));
		d = (string) ((!) selection_data);
		stdout.printf (d);
	}

	public void dump_clipboard_target (Clipboard clipboard, Atom[] atoms) {
		foreach (Atom target in atoms) {
			print ("Target: " + target.name () + "\n");
			clipboard.request_contents (target, dump_clipboard_content);
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
					fn = show_file_chooser (title, FileChooserAction.SELECT_FOLDER, Stock.OPEN);
				} else if ((flags & FileChooser.SAVE) > 0) {
					fn = show_file_chooser (title, FileChooserAction.SELECT_FOLDER, Stock.SAVE);
				} else {
					warning ("Open or save is not set.");
				}
			} else if ((flags & FileChooser.LOAD) > 0) {
				fn = show_file_chooser (title, FileChooserAction.OPEN, Stock.OPEN);
			} else if ((flags & FileChooser.SAVE) > 0) {
				fn = show_file_chooser (title, FileChooserAction.SAVE, Stock.SAVE);
			} else {
				warning ("Unknown type");
			}
		}
		
		fc.selected (fn);
	}
	
	public string? show_file_chooser (string title, FileChooserAction action, string label) {
		string? fn = null;
		FileChooserDialog file_chooser = new FileChooserDialog (title, this, action, Stock.CANCEL, ResponseType.CANCEL, label, ResponseType.ACCEPT);
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
	
	public void hide_text_input () {
		text_listener = new TextListener ("", "", "");
		text_box.hide ();
		text_input_is_active = false;
	}
	
	public void set_text_listener (TextListener listener) {
		text_listener = listener;
		text_input_label.set_text ("   " + listener.label);
		submit_text_button.set_label (listener.button_label);
		text_box.show ();
		text_entry.set_text (listener.default_text);
		text_entry.activate.connect (() => {
			text_listener.signal_submit (text_entry.text);
			text_input_is_active = false;
		});
		text_entry.grab_focus ();
		text_input_is_active = true;
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
			bg = Thread.create<void*> (this.background_thread, true);
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
			export_thread = Thread.create<void*> (this.export_thread, true);
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
			export_notification.show ();
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
			thread = Thread.create<void*> (this.loading_thread, true);
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
			thread = Thread.create<void*> (this.saving_thread, true);
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
			thread = Thread.create<void*> (this.background_image_thread, true);
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
		if (visible != NativeWindow.VISIBLE) {
			get_window ().set_cursor (new Cursor (CursorType.BLANK_CURSOR));
		} else {
			get_window ().set_cursor (new Cursor (CursorType.ARROW));
		}
	}
}

class TabbarCanvas : DrawingArea {
	TabBar tabbar;
	
	public TabbarCanvas (TabBar tb) {		
		tabbar = tb;

		// FIXME: DELETE set_extension_events (ExtensionMode.CURSOR | EventMask.POINTER_MOTION_MASK);
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
			Context cr;
			StyleContext context;
			Gdk.RGBA color;
						
			cr = cairo_create (get_window ());
			get_allocation (out alloc);

			context = get_style_context ();
			context.add_class (STYLE_CLASS_BUTTON);
			color = context.get_background_color (Gtk.StateFlags.NORMAL);
			
			if (color.alpha > 0) {
				tabbar.set_background_color (color.red, color.green, color.blue);
			}
						
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
			// FIXME: e.y is two pixels off in GTK under Gnome
			tb.move (e.x, e.y);
			return true;
		});
		
		draw.connect ((t, e)=> {
			Gtk.Allocation allocation;
			get_allocation (out allocation);
			
			Context cw = cairo_create(get_window());
			Toolbox.allocation_width = allocation.width;
			Toolbox.allocation_height = allocation.height;
			tb.draw (allocation.width, allocation.height, cw);
			
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

		set_size_request (212, 100);

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

		bool button_down = false;

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
			
			Context cw = cairo_create (get_window());
			
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

			if (button_down) {
				warning (@"Button already is down. $(e.button)");
			}
			
			if (e.time < last_press) {
				warning ("Discarding event.");
				return true;
			}
			
			last_press = e.time;
			
			if (e.type == EventType.BUTTON_PRESS) {
				TabContent.button_press (e.button, e.x, e.y);
				button_down = true;
			} else if (e.type == EventType.2BUTTON_PRESS) {
				TabContent.double_click (e.button, e.x, e.y);
			}
			 
			return true;
		});
		
		button_release_event.connect ((t, e)=> {
			if (!button_down) {
				warning (@"Button is not down $(e.button)");
			}
			
			if (e.time < last_release) {
				warning ("Discarding event.");
				return true;
			}
			
			if (e.type == EventType.BUTTON_RELEASE) {
				TabContent.button_release ((int) e.button, e.x, e.y);
				last_release = e.time;
				button_down = false;
			}
			
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

public class DescriptionForm : GLib.Object {

	public ScrolledWindow canvas;
	public Box box;
	
	Entry postscript_name;
	Entry font_name;
	Entry style;
	CheckButton bold;
	CheckButton italic;
	Entry weight;
	Entry full_name;
	Entry id;
	Entry version;

	TextView description;
	TextView copyright;
		
	public DescriptionForm () {
		box = new Box (Orientation.VERTICAL, 6);
		canvas = new ScrolledWindow (null, null);
		canvas.set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
		
		postscript_name = new Entry ();
		add_entry (postscript_name, t_("PostScript Name"));
		postscript_name.changed.connect (() => {
			Font f = BirdFont.get_current_font ();
			f.postscript_name = postscript_name.text;
		});
		
		font_name = new Entry ();
		add_entry (font_name, t_("Name"));
		font_name.changed.connect (() => {
			Font f = BirdFont.get_current_font ();
			f.name = font_name.text;
		});
		
		style = new Entry ();
		add_entry (style, t_("Style"));
		style.changed.connect (() => {
			Font f = BirdFont.get_current_font ();
			f.subfamily = style.text;
		});
		
		bold = new CheckButton.with_label (t_("Bold"));
		bold.toggled.connect (() => {
			Font f = BirdFont.get_current_font ();
			f.bold = bold.active;;
		});
		box.pack_start (bold, false, false, 0);
		
		italic = new CheckButton.with_label (t_("Italic"));
		italic.toggled.connect (() => {
			Font f = BirdFont.get_current_font ();
			f.italic = italic.active;;
		});
		box.pack_start (italic, false, false, 0);

		weight = new Entry ();
		add_entry (weight, t_("Weight"));
		weight.changed.connect (() => {
			Font f = BirdFont.get_current_font ();
			f.set_weight (weight.text);
		});
		
		full_name = new Entry ();
		add_entry (full_name, t_("Full name (name and style)"));
		full_name.changed.connect (() => {
			Font f = BirdFont.get_current_font ();
			f.full_name = full_name.text;
		});
		
		id = new Entry ();
		add_entry (id, t_("Unique identifier"));
		id.changed.connect (() => {
			Font f = BirdFont.get_current_font ();
			f.unique_identifier = id.text;
		});
		
		version = new Entry ();
		add_entry (version, t_("Version"));
		version.changed.connect (() => {
			Font f = BirdFont.get_current_font ();
			f.version = version.text;
		});
		
		description = new TextView ();
		add_textview (description, t_("Description"));
		description.get_buffer ().changed.connect (() => {
			Font f = BirdFont.get_current_font ();
			f.description = description.get_buffer ().text;
		});
		description.set_wrap_mode (Gtk.WrapMode.WORD);

		copyright = new TextView ();
		add_textview (copyright, t_("Copyright"));
		copyright.get_buffer ().changed.connect (() => {
			Font f = BirdFont.get_current_font ();
			f.copyright = copyright.get_buffer ().text;
		});
		copyright.set_wrap_mode (Gtk.WrapMode.WORD);
		
		update_fields ();
		
		canvas.add_with_viewport (box);
		canvas.show_all ();
	}
	
	public void update_fields () {
		Font font = BirdFont.get_current_font ();

		return_if_fail (font.postscript_name.validate ());
		return_if_fail (font.name.validate ());
		return_if_fail (font.subfamily.validate ());
		return_if_fail (font.full_name.validate ());
		return_if_fail (font.unique_identifier.validate ());
		return_if_fail (font.version.validate ());
		return_if_fail (font.description.validate ());
		return_if_fail (font.copyright.validate ());
		
		postscript_name.set_text (font.postscript_name);
		font_name.set_text (font.name);
		style.set_text (font.subfamily);
		bold.active = font.bold;
		italic.active = font.italic;
		weight.set_text (font.get_weight ());
		full_name.set_text (font.full_name);
		id.set_text (font.unique_identifier);
		version.set_text (font.version);

		description.get_buffer ().set_text (font.description.dup ());
		copyright.get_buffer ().set_text (font.copyright.dup ());

	}
	
	void add_entry (Entry e, string label) {
		Box vb;
		Box hb;
		Label l;
		Box margin;
		
		margin = new Box (Orientation.HORIZONTAL, 6);
		l = new Label (label);
		vb = new Box (Orientation.VERTICAL, 2);
		hb = new Box (Orientation.HORIZONTAL, 2);
		hb.pack_start (l, false, false, 0);
		vb.pack_start (hb, true, true, 5);
		vb.pack_start (e, true, true, 0);
		margin.pack_start (vb, true, true, 5);
		box.pack_start (margin, false, false, 5);
	}

	void add_textview (TextView t, string label) {
		Box vb;
		Box hb;
		Label l;
		Box margin;
		
		margin = new Box (Orientation.HORIZONTAL, 6);
		l = new Label (label);
		vb = new Box (Orientation.VERTICAL, 2);
		hb = new Box (Orientation.HORIZONTAL, 2);
		hb.pack_start (l, false, false, 0);
		vb.pack_start (hb, true, true, 5);
		vb.pack_start (t, true, true, 0);
		margin.pack_start (vb, true, true, 5);
		box.pack_start (margin, false, false, 5);
	}
}

}
