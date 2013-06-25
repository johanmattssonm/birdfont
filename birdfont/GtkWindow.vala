/*
    Copyright (C) 2012, 2013 Johan Mattsson

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

namespace BirdFont {

public class GtkWindow : Gtk.Window, NativeWindow {

	HBox list_box;
	HBox canvas_box;
	
	WebView html_canvas;
	ScrolledWindow html_box;

	VBox tab_box;

	static DrawingArea margin_bottom;
	static DrawingArea margin_right;
	
	GlyphCanvasArea glyph_canvas_area;
	
	Clipboard clipboard;
	string clipboard_svg = "";
	string inkscape_clipboard = "";
	
	VScrollbar scrollbar;
	bool scrollbar_supress_signal = false;
	
	public GtkWindow (string title) {
		scrollbar = new VScrollbar (new Adjustment (0, 0, 1, 1, 0.01, 0.1));;
		((Gtk.Window)this).set_title ("BirdFont");
	}
	
	public void init () {
		clipboard = Clipboard.get_for_display (get_display (), Gdk.SELECTION_CLIPBOARD);
		
		scrollbar.value_changed.connect (() => {
			if (!scrollbar_supress_signal) {
				FontDisplay display = MainWindow.get_current_display ();
				display.scroll_to (scrollbar.get_value ());
			}
		});

		margin_bottom = new DrawingArea ();
		margin_right = new DrawingArea ();
	
		margin_bottom.set_size_request (0, 0);
		margin_right.set_size_request (0, 0);
		
		delete_event.connect (quit);
		
		set_size_and_position ();
		
		glyph_canvas_area = new GlyphCanvasArea (MainWindow.glyph_canvas);

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
			File layout_dir;
			File layout_uri;
			string uri = "";
			FontDisplay fd = tab.get_display ();
			bool html = fd.is_html_canvas ();
			MainWindow.glyph_canvas.set_current_glyph (fd);
			
			scrollbar.set_visible (fd.has_scrollbar ());
					
			if (html) {
				layout_dir = FontDisplay.find_layout_dir ();
				uri = fd.get_uri ();
				
				if (uri == "") {
					layout_uri = layout_dir.get_child (fd.get_html_file ());
					uri = FontDisplay.path_to_uri ((!) layout_uri.get_path ());
				}
		
				if (fd.get_html () == "") {
					
					if (fd.get_name () == "Preview") {
						// hack: force webkit to ignore cache in preview					

						html_box.set_visible (false);
						glyph_canvas_area.set_visible (true);
												
						try {
							Preview preview = (Preview) fd;
							DataInputStream dis = new DataInputStream (preview.get_html_file ().read ());
							string? line;
							StringBuilder sb = new StringBuilder ();
							uint rid = Random.next_int ();
							Font font = BirdFont.get_current_font ();
							
							File preview_directory = BirdFont.get_preview_directory ();
							
							File f_ttf = font.get_folder ().get_child (@"$(font.get_name ()).ttf");
							File f_eot = font.get_folder ().get_child (@"$(font.get_name ()).eot");
							File f_svg = font.get_folder ().get_child (@"$(font.get_name ()).svg");

							if (f_ttf.query_exists ()) {
								f_ttf.delete ();
							}
								
							if (f_eot.query_exists ()) {
								f_eot.delete ();
							}
							
							if (f_svg.query_exists ()) {
								f_svg.delete ();
							}
							
							ExportTool.export_ttf_font ();							
							ExportTool.export_svg_font ();
							
							File r_ttf = preview_directory.get_child (@"$(font.get_name ())$rid.ttf");
							File r_svg = preview_directory.get_child (@"$(font.get_name ())$rid.svg");
							
							if (BirdFont.win32) {
								f_ttf.copy (r_ttf, FileCopyFlags.NONE);
							}
							
							f_svg.copy (r_svg, FileCopyFlags.NONE);

							while ((line = dis.read_line (null)) != null) {
								line = ((!) line).replace (@"$(font.get_name ()).ttf", @"$(FontDisplay.path_to_uri ((!) f_ttf.get_path ()))?$rid");
								line = ((!) line).replace (@"$(font.get_name ()).eot", @"$(FontDisplay.path_to_uri ((!) f_eot.get_path ()))?$rid");
								line = ((!) line).replace (@"$(font.get_name ()).svg", @"$(FontDisplay.path_to_uri ((!) f_svg.get_path ()))?$rid");
								sb.append ((!) line);
							}
					
							html_canvas.load_html_string (sb.str, uri);							
						} catch (Error e) {
							warning (e.message);
							warning ("Failed to load html into canvas.");
						}
						
					} else {
						// normal way to load a uri for all other pages
						html_canvas.load_uri (uri);
						html_canvas.reload_bypass_cache ();			
					}
						
				} else {
					html_canvas.load_html_string (fd.get_html (), uri);
				}
				
				html_box.set_visible (html);
				glyph_canvas_area.set_visible (!html);
			} else {
				html_box.set_visible (false);
				glyph_canvas_area.set_visible (true);
			}
		});

		// Hide this canvas when window is realized and flip canvas 
		// visibility in tab selection signal.
		html_canvas.expose_event.connect ((t, e) => {
			glyph_canvas_area.set_visible (false);
			return false;
		});
				
		MainWindow.tabs.add_unique_tab (MainWindow.menu_tab, 60, true);
		MainWindow.tabs.select_tab_name ("Menu");

		canvas_box = new HBox (false, 0);
		canvas_box.pack_start (glyph_canvas_area, true, true, 0);
		canvas_box.pack_start (html_box, true, true, 0);
		canvas_box.pack_start (scrollbar, false, true, 0);
		
		tab_box = new VBox (false, 0);
		tab_box.pack_start (new TabbarCanvas (MainWindow.tabs), false, false, 0);	
		
		tab_box.pack_start (canvas_box, true, true, 0);

		tab_box.pack_start (new TooltipCanvas (MainWindow.tool_tip), false, false, 0);
		tab_box.pack_start (margin_bottom, false, false, 0);
		
		list_box = new HBox (false, 0);
		list_box.pack_start (tab_box, true, true, 0);
		list_box.pack_start (new ToolboxCanvas (MainWindow.tools), false, false, 0);
		list_box.pack_start (margin_right, false, false, 0);

		VBox vbox = new VBox (false, 0);
		
		vbox.pack_start(create_menu (), false, false, 0);
		vbox.pack_start(list_box, true, true, 0);

		add (vbox);
		
		try {
			set_icon_from_file ((!) Icons.find_icon ("window_icon.png").get_path ());
		} catch (GLib.Error e) {
			warning (e.message);
		}

		key_press_event.connect ((t, event) => {
			FontDisplay fd = MainWindow.glyph_canvas.current_display;
			
			if (fd is Glyph) {
				MainWindow.tools.key_press (event.keyval);
			}
			
			MainWindow.glyph_canvas.key_press (event.keyval);
			KeyBindings.add_modifier_from_keyval (event.keyval);
			return false;
		});
		
		key_release_event.connect ((t, event) => {
			if (MainWindow.glyph_canvas is Glyph) {
				MainWindow.glyph_canvas.key_release (event.keyval);
			}
			
			KeyBindings.remove_modifier_from_keyval (event.keyval);
			return false;
		});
		
		show_all ();
		scrollbar.set_visible (false);
	}

	public void set_scrollbar_size (double size) {
		scrollbar.adjustment.page_size = size;
	}
	
	public void set_scrollbar_position (double position) {
		scrollbar_supress_signal = true;
		scrollbar.adjustment.value = position;
		scrollbar_supress_signal = false;
	}
	
	public void color_selection (ColorTool color_tool) {
		new ColorWindow (color_tool);
	}
	
	class ColorWindow : Gtk.Window {
		ColorSelection color_selection = new ColorSelection ();

		public ColorWindow (ColorTool color_tool) {			
			color_selection.color_changed.connect (() => {
				Color c;
				color_selection.get_current_color (out c);
				color_tool.color_r = (double) c.red / uint16.MAX;
				color_tool.color_g = (double) c.green / uint16.MAX;
				color_tool.color_b = (double) c.blue / uint16.MAX;
				color_tool.color_a = (double) color_selection.get_current_alpha () / uint16.MAX; 
				color_tool.color_updated ();
			});
			
			add (color_selection);
			show_all ();
		}	
	}
	
	public void dump_clipboard_content (Clipboard clipboard, SelectionData selection_data) {
		string d;
		return_if_fail (!is_null (selection_data));
		d = (string) ((!) selection_data).data;
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
		if (BirdFont.mac) {
			string? t;
			t = clipboard.wait_for_text ();
			return (t == null) ? "" : (!) t;
		} else {
			SelectionData? selection_data;
			Atom target;

			target = Atom.intern_static_string ("image/x-inkscape-svg");
			selection_data = clipboard.wait_for_contents (target);
			
			if (is_null (selection_data) || is_null (((!) selection_data).data)) {
				return "";
			}
			
			return (string) ((!) selection_data).data;
		}
	}
	
	public void set_inkscape_clipboard (string inkscape_clipboard_data) {
		// FIXME: clipboard seems to be rather broken on Mac 
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
	
	MenuBar create_menu () {
		MenuBar menubar = new MenuBar ();
		Gtk.Menu file_menu = new Gtk.Menu ();
		Gtk.Menu edit_menu = new Gtk.Menu ();
		Gtk.Menu tab_menu = new Gtk.Menu ();
		Gtk.Menu tool_menu = new Gtk.Menu ();

		AccelGroup accel_group = new Gtk.AccelGroup();
		add_accel_group (accel_group);
		
		// File
		Gtk.MenuItem new_item = new Gtk.MenuItem.with_mnemonic (_("_New"));
		file_menu.append (new_item);
		new_item.activate.connect (() => { MenuTab.new_file (); });
		new_item.add_accelerator ("activate", accel_group, 'N', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);

		Gtk.MenuItem load_item = new Gtk.MenuItem.with_mnemonic (_("_Open"));
		file_menu.append (load_item);
		load_item.activate.connect (() => { MenuTab.load (); });
		load_item.add_accelerator ("activate", accel_group, 'O', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);

		Gtk.MenuItem save_item = new Gtk.MenuItem.with_mnemonic (_("_Save"));
		file_menu.append (save_item);
		save_item.activate.connect (() => { MenuTab.save (); });
		save_item.add_accelerator ("activate", accel_group, 'S', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);

		Gtk.MenuItem save_as_item = new Gtk.MenuItem.with_mnemonic (_("Save _as"));
		file_menu.append (save_as_item);
		save_as_item.activate.connect (() => { MenuTab.save_as (); });
				
		Gtk.MenuItem export_item = new Gtk.MenuItem.with_mnemonic (_("_Export"));
		file_menu.append (export_item);
		export_item.activate.connect (() => { ExportTool.export_all (); });
		export_item.add_accelerator ("activate", accel_group, 'E', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);

		Gtk.MenuItem preview_item = new Gtk.MenuItem.with_mnemonic(_("_Preview"));
		file_menu.append (preview_item);
		preview_item.activate.connect (() => { MenuTab.preview (); });
		preview_item.add_accelerator ("activate", accel_group, 'P', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);

		Gtk.MenuItem description_item = new Gtk.MenuItem.with_mnemonic(_("_Description"));
		file_menu.append (description_item);
		description_item.activate.connect (() => { MenuTab.show_description (); });

		Gtk.MenuItem kerning_item = new Gtk.MenuItem.with_mnemonic (_("_Kerning"));
		file_menu.append (kerning_item);
		kerning_item.activate.connect (() => { MenuTab.show_kerning_context (); });
		kerning_item.add_accelerator ("activate", accel_group, 'K', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);

		Gtk.MenuItem quit_item = new Gtk.MenuItem.with_mnemonic (_("_Quit"));
		file_menu.append (quit_item);
		quit_item.activate.connect (() => { quit(); });

		// Edit
		Gtk.MenuItem undo_item = new Gtk.MenuItem.with_mnemonic (_("_Undo"));
		edit_menu.append (undo_item);
		undo_item.activate.connect (() => { MainWindow.get_current_display ().undo (); });	
		undo_item.add_accelerator ("activate", accel_group, 'Z', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);
		
		Gtk.MenuItem copy_item = new Gtk.MenuItem.with_mnemonic (_("_Copy"));
		edit_menu.append (copy_item);
		copy_item.activate.connect (() => { ClipTool.copy (); });		
		copy_item.add_accelerator ("activate", accel_group, 'C', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);

		Gtk.MenuItem paste_item = new Gtk.MenuItem.with_mnemonic (_("_Paste"));
		edit_menu.append (paste_item);
		paste_item.activate.connect (() => { ClipTool.paste (); });	
		paste_item.add_accelerator ("activate", accel_group, 'V', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);

		Gtk.MenuItem select_all_item = new Gtk.MenuItem.with_mnemonic (_("_Select all paths"));
		edit_menu.append (select_all_item);
		select_all_item.activate.connect (() => {
			Toolbox.select_tool_by_name ("move");
			MainWindow.get_current_glyph ().select_all_paths ();
		});
		select_all_item.add_accelerator ("activate", accel_group, 'A', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);

		Gtk.MenuItem export_svg_item = new Gtk.MenuItem.with_mnemonic (_("_Export glyph as SVG"));
		edit_menu.append (export_svg_item);
		export_svg_item.activate.connect (() => { ExportTool.export_current_glyph (); });	
	
		Gtk.MenuItem import_svg_item = new Gtk.MenuItem.with_mnemonic (_("_Import SVG"));
		edit_menu.append (import_svg_item);
		import_svg_item.activate.connect (() => { ImportSvg.import (); });	
		import_svg_item.add_accelerator ("activate", accel_group, 'I', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);

		Gtk.MenuItem close_path_item = new Gtk.MenuItem.with_mnemonic (_("Close _path"));
		edit_menu.append (close_path_item);
		close_path_item.activate.connect (() => { PenTool.close_all_paths (); });
		close_path_item.add_accelerator ("activate", accel_group, 'B', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);
		
		edit_menu.append (new SeparatorMenuItem ());

		Gtk.MenuItem select_point_above = new Gtk.MenuItem.with_mnemonic (" Ctrl+↑  " + _("_Select point above"));
		edit_menu.append (select_point_above);
		select_point_above.activate.connect (() => { PenTool.select_point_up (); });

		Gtk.MenuItem select_next_point = new Gtk.MenuItem.with_mnemonic (" Ctrl+→  " + _("Select _next point"));
		edit_menu.append (select_next_point);
		select_next_point.activate.connect (() => { PenTool.select_point_right (); });

		Gtk.MenuItem select_previous_point = new Gtk.MenuItem.with_mnemonic (" Ctrl+←  " + _("Select _previous point"));
		edit_menu.append (select_previous_point);
		select_previous_point.activate.connect (() => { PenTool.select_point_left (); });

		Gtk.MenuItem select_point_below = new Gtk.MenuItem.with_mnemonic (" Ctrl+↓  " + _("Select point _below"));
		edit_menu.append (select_point_below);
		select_point_below.activate.connect (() => { PenTool.select_point_down (); });
				
		// Tab
		Gtk.MenuItem next_tab_item = new Gtk.MenuItem.with_mnemonic (_("_Next tab"));
		tab_menu.append (next_tab_item);
		next_tab_item.activate.connect (() => { 
			TabBar tb = MainWindow.get_tab_bar ();
			int n = tb.get_selected () + 1;
			
			if (!(0 <= n < tb.get_length ())) {
				return;
			}
			
			tb.select_tab (n);
		});	

		Gtk.MenuItem prevoius_tab_item = new Gtk.MenuItem.with_mnemonic (_("_Previous tab"));
		tab_menu.append (prevoius_tab_item);
		prevoius_tab_item.activate.connect (() => { 
			TabBar tb = MainWindow.get_tab_bar ();
			int n = tb.get_selected () - 1;

			if (!(0 <= n < tb.get_length ())) {
				return;
			}
			
			tb.select_tab (n);
		});					

		Gtk.MenuItem close_tab_item = new Gtk.MenuItem.with_mnemonic (_("_Close tab"));
		tab_menu.append (close_tab_item);
		close_tab_item.activate.connect (() => { 
			TabBar tb = MainWindow.get_tab_bar ();
			int n = tb.get_selected ();

			if (!(0 <= n < tb.get_length ())) {
				return;
			}
			
			tb.close_tab (n);
		});	
		close_tab_item.add_accelerator ("activate", accel_group, 'W', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);

		Gtk.MenuItem close_all_tabs_item = new Gtk.MenuItem.with_mnemonic (_("Close _all tabs"));
		tab_menu.append (close_all_tabs_item);
		close_all_tabs_item.activate.connect (() => { 
			TabBar tb = MainWindow.get_tab_bar ();
			tb.close_all_tabs ();			
		});	

		// Tool
		Gtk.MenuItem pen_item = new Gtk.MenuItem.with_mnemonic (_("_Create path"));
		tool_menu.append (pen_item);
		pen_item.activate.connect (() => { 
			Toolbox.select_tool_by_name ("pen_tool");
		});
		pen_item.add_accelerator ("activate", accel_group, ',', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);

		Gtk.MenuItem zoom_item = new Gtk.MenuItem.with_mnemonic (_("_Zoom"));
		tool_menu.append (zoom_item);
		zoom_item.activate.connect (() => { 
			Toolbox.select_tool_by_name ("zoom_tool");
		});

		Gtk.MenuItem counter_item = new Gtk.MenuItem.with_mnemonic (_("_Create counter path"));
		tool_menu.append (counter_item);
		counter_item.activate.connect (() => { 
			Toolbox.select_tool_by_name ("cut");
		});
		counter_item.add_accelerator ("activate", accel_group, 'U', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);

		Gtk.MenuItem move_item = new Gtk.MenuItem.with_mnemonic (_("_Move"));
		tool_menu.append (move_item);
		move_item.activate.connect (() => { 
			Toolbox.select_tool_by_name ("move");
		});
		move_item.add_accelerator ("activate", accel_group, 'M', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);

		Gtk.MenuItem full_unicode_item = new Gtk.MenuItem.with_mnemonic (_("Show _full unicode characters set"));
		tool_menu.append (full_unicode_item);
		full_unicode_item.activate.connect (() => { 
			Toolbox.select_tool_by_name ("utf_8");
		});
		full_unicode_item.add_accelerator ("activate", accel_group, 'F', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);

		Gtk.MenuItem default_charset_item = new Gtk.MenuItem.with_mnemonic (_("Show de_fault characters set"));
		tool_menu.append (default_charset_item);
		default_charset_item.activate.connect (() => { 
			Toolbox.select_tool_by_name ("custom_character_set");
		});
		default_charset_item.add_accelerator ("activate", accel_group, 'R', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);

		Gtk.MenuItem avalilable_characters_item = new Gtk.MenuItem.with_mnemonic (_("Show characters in font"));
		tool_menu.append (avalilable_characters_item);
		avalilable_characters_item.activate.connect (() => { 
			Toolbox.select_tool_by_name ("available_characters");
		});
		avalilable_characters_item.add_accelerator ("activate", accel_group, 'D', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);

		Gtk.MenuItem add_grid_item = new Gtk.MenuItem.with_mnemonic (_("Add new _grid item"));
		tool_menu.append (add_grid_item);
		add_grid_item.activate.connect (() => { 
			MainWindow.get_toolbox ().add_new_grid ();
		});

		Gtk.MenuItem remove_grid_item = new Gtk.MenuItem.with_mnemonic (_("Remove gr_id item"));
		tool_menu.append (remove_grid_item);
		remove_grid_item.activate.connect (() => { 
			MainWindow.get_toolbox ().remove_current_grid ();
		});
		
		Gtk.MenuItem zoom_in_item = new Gtk.MenuItem.with_mnemonic (_("_Zoom in"));
		tool_menu.append (zoom_in_item);
		zoom_in_item.activate.connect (() => { 
			Toolbox.select_tool_by_name ("zoom_in");
		});
		zoom_in_item.add_accelerator ("activate", accel_group, '+', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);

		Gtk.MenuItem zoom_out_item = new Gtk.MenuItem.with_mnemonic (_("Zoom _out"));
		tool_menu.append (zoom_out_item);
		zoom_out_item.activate.connect (() => { 
			Toolbox.select_tool_by_name ("zoom_out");
		});
		zoom_out_item.add_accelerator ("activate", accel_group, '-', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);

		Gtk.MenuItem zoom_1_1_item = new Gtk.MenuItem.with_mnemonic (_("Zoom to _scale 1:1"));
		tool_menu.append (zoom_1_1_item);
		zoom_1_1_item.activate.connect (() => { 
			Toolbox.select_tool_by_name ("zoom_1_1");
		});
		zoom_1_1_item.add_accelerator ("activate", accel_group, '0', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);

		// Add menus
		Gtk.MenuItem file_launcher = new Gtk.MenuItem.with_mnemonic (_("_File"));
		file_launcher.set_submenu (file_menu);

		Gtk.MenuItem edit_launcher = new Gtk.MenuItem.with_mnemonic (_("_Edit"));
		edit_launcher.set_submenu (edit_menu);

		Gtk.MenuItem tab_launcher = new Gtk.MenuItem.with_mnemonic (_("_Tab"));
		tab_launcher.set_submenu (tab_menu);

		Gtk.MenuItem tool_launcher = new Gtk.MenuItem.with_mnemonic (_("T_ool"));
		tool_launcher.set_submenu (tool_menu);
						
		menubar.append (file_launcher);
		menubar.append (edit_launcher);
		menubar.append (tab_launcher);
		menubar.append (tool_launcher);
		
		return menubar;	
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
	
	public bool quit () {
		bool added;
		Font font = BirdFont.get_current_font ();
		SaveDialog save_tab = new SaveDialog ();
		
		if (BirdFont.get_current_font ().is_modified ()) {
			added = MainWindow.get_tab_bar ().add_unique_tab (save_tab, 50);
		} else {
			added = false;
		}
		
		if (!added) {
			font.delete_backup ();
			Gtk.main_quit ();
		}
		
		save_tab.finished.connect (() => {
			font.delete_backup ();
			Gtk.main_quit ();
		});
		
		return true;
	}
	
	public string? file_chooser_save (string title) {
		return file_chooser (title, FileChooserAction.SAVE, Stock.SAVE);
	}

	public string? file_chooser_open (string title) {
		return file_chooser (title, FileChooserAction.OPEN, Stock.OPEN);
	}
	
	public string? file_chooser (string title, FileChooserAction action, string label) {
		string? fn = null;
		FileChooserDialog file_chooser = new FileChooserDialog (title, this, action, Stock.CANCEL, ResponseType.CANCEL, label, ResponseType.ACCEPT);
		Font font = BirdFont.get_current_font ();
		
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
			Gtk.Allocation alloc;
			tabbar.motion (e.x, e.y);
			get_allocation (out alloc);
			queue_draw_area (0, 0, alloc.width, alloc.height);
			return true;
		});	
				
		button_press_event.connect ((t, e)=> {
			Gtk.Allocation alloc;
			get_allocation (out alloc);
			tabbar.select_tab_click (e.x, e.y, alloc.width, alloc.height);
			queue_draw_area (0, 0, alloc.width, alloc.height);
			return true;
		});

		expose_event.connect ((t, e)=> {
			Context cr = cairo_create (get_window ());

			Gtk.Allocation alloc;
			get_allocation (out alloc);

			tabbar.draw (cr, alloc.width, alloc.height);
			return true;
		});
	
		tabbar.signal_tab_selected.connect ((t) => {
			Gtk.Allocation alloc;
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
			if (e.type != EventType.2BUTTON_PRESS)	{
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
		
		expose_event.connect ((t, e)=> {
			Gtk.Allocation allocation;
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

public class GlyphCanvasArea : DrawingArea  {
	GlyphCanvas glyph_canvas;
	Gtk.Allocation alloc;

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

		expose_event.connect ((t, e)=> {		
			Gtk.Allocation allocation;
			get_allocation (out allocation);
			
			glyph_canvas.allocation.width = allocation.width;
			glyph_canvas.allocation.height = allocation.height;
			glyph_canvas.allocation.y = allocation.x;
			glyph_canvas.allocation.y = allocation.y;
				
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
				
				if (unlikely (allocation.width % 2 != 0 || allocation.height % 2 != 0)) {
					warning (@"\nGlyph canvas is not divisible by two.\nWidth: $(allocation.width)\nHeight: $(allocation.height)");
				}
				
				BirdFont.current_glyph.resized ();
			}
			
			alloc = allocation;
			
			Context cw = cairo_create (get_window());
			
			Surface s = new Surface.similar (cw.get_target (), Cairo.Content.COLOR_ALPHA, allocation.width, allocation.height);
			Context c = new Context (s); 

			glyph_canvas.current_display.draw (glyph_canvas.allocation, c);

			cw.save ();
			cw.set_source_surface (c.get_target (), 0, 0);
			cw.paint ();
			cw.restore ();
			
			return true;
		});

		button_press_event.connect ((t, e)=> {
			set_modifier ((int) e.state);
			
			if (e.type == EventType.BUTTON_PRESS) {
				glyph_canvas.current_display.button_press (e.button, e.x, e.y);	
			} else if (e.type == EventType.2BUTTON_PRESS) {
				glyph_canvas.current_display.double_click (e.button, e.x, e.y);
			}
				
			return true;
		});
		
		button_release_event.connect ((t, e)=> {
			set_modifier ((int) e.state);
			glyph_canvas.current_display.button_release ((int) e.button, e.x, e.y);
			return true;
		});
		
		motion_notify_event.connect ((t, e)=> {
			glyph_canvas.current_display.motion_notify (e.x, e.y);		
			return true;
		});
		
		scroll_event.connect ((t, e)=> {
			set_modifier ((int) e.state);
			
			if (e.direction == Gdk.ScrollDirection.UP) {
				glyph_canvas.current_display.scroll_wheel_up (e.x, e.y);
			} else if (e.direction == Gdk.ScrollDirection.DOWN) {
				glyph_canvas.current_display.scroll_wheel_down (e.x, e.y)		;
			}
			
			glyph_canvas.current_display.button_release (2, e.x, e.y);
			return true;
		});
	}

	static void set_modifier (int k) {
		KeyBindings.set_modifier (NONE);

		// MOD5 is logo button on Linux
		// MOD2 is logo button on Mac OS X

		if (BirdFont.mac) {
			if (has_flag (k, ModifierType.MOD2_MASK)) {
				KeyBindings.set_modifier (LOGO);
			}
		} else {
			if (has_flag (k, ModifierType.MOD5_MASK)) {
				KeyBindings.set_modifier (LOGO);
			}			
		}
				
		if (has_flag (k, ModifierType.SHIFT_MASK)) {
			KeyBindings.set_modifier (SHIFT);
		} else if (has_flag (k, ModifierType.CONTROL_MASK)) {
			KeyBindings.set_modifier (CTRL);
		} else if (has_flag (k, ModifierType.CONTROL_MASK | ModifierType.SHIFT_MASK)) {
			KeyBindings.set_modifier (SHIFT | CTRL);
		} 
	}
}

public class TooltipCanvas : DrawingArea {
	TooltipArea tooltip_area;
	
	public TooltipCanvas (TooltipArea ta) {
		tooltip_area = ta;

		expose_event.connect ((t, e)=> {
				Allocation allocation = {0, 0, 0, 0};
				Gtk.Allocation alloc;
				Context cr = cairo_create (get_window ());
				
				get_allocation (out alloc);

				allocation.width = alloc.width;
				allocation.height = alloc.height;
				allocation.y = alloc.x;
				allocation.y = alloc.y;
				
				tooltip_area.draw (cr, allocation);

				return true;
		});
		
		tooltip_area.redraw.connect (() => {
			Gtk.Allocation alloc;
			get_allocation (out alloc);
			queue_draw_area (0, 0, alloc.width, alloc.height);
		});
		
		set_size_request (10, 20);
	}
}

}
