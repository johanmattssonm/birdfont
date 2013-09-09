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
	
	GlyphCanvasArea glyph_canvas_area;
	
	Clipboard clipboard;
	string clipboard_svg = "";
	string inkscape_clipboard = "";
	
	VScrollbar scrollbar;
	bool scrollbar_supress_signal = false;
	
	DescriptionForm description;
	
	/** Text input and callbacks. */
	public static bool text_input_is_active = false;
	TextListener text_listener = new TextListener ("", "", "");
	Label text_input_label;
	Entry text_entry;
	HBox text_box;
	Button submit_text_button;
	
	public GtkWindow (string title) {
		scrollbar = new VScrollbar (new Adjustment (0, 0, 1, 1, 0.01, 0.1));
		((Gtk.Window)this).set_title ("BirdFont");
	}
	
	public void init () {
		description = new DescriptionForm ();
		
		clipboard = Clipboard.get_for_display (get_display (), Gdk.SELECTION_CLIPBOARD);
		
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
			return false;
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
			File layout_dir;
			File layout_uri;
			string uri = "";
			FontDisplay fd = tab.get_display ();
			bool html = fd.get_name () == "Preview";
			MainWindow.glyph_canvas.set_current_glyph (fd);
			
			scrollbar.set_visible (fd.has_scrollbar ());
			
			if (fd.get_name () == "Description") {
				description.update_fields ();
				description.canvas.set_visible (true);
				html_box.set_visible (false);
				glyph_canvas_area.set_visible (false);
			} else if (html) {
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
							
							File f_ttf = font.get_folder ().get_child (@"$(font.get_full_name ()).ttf");
							File f_eot = font.get_folder ().get_child (@"$(font.get_full_name ()).eot");
							File f_svg = font.get_folder ().get_child (@"$(font.get_full_name ()).svg");

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
							
							File r_ttf = preview_directory.get_child (@"$(font.get_full_name ())$rid.ttf");
							File r_svg = preview_directory.get_child (@"$(font.get_full_name ())$rid.svg");
							
							if (BirdFont.win32) {
								f_ttf.copy (r_ttf, FileCopyFlags.NONE);
							}
							
							f_svg.copy (r_svg, FileCopyFlags.NONE);

							while ((line = dis.read_line (null)) != null) {
								line = ((!) line).replace (@"$(font.get_full_name ()).ttf", @"$(FontDisplay.path_to_uri ((!) f_ttf.get_path ()))?$rid");
								line = ((!) line).replace (@"$(font.get_full_name ()).eot", @"$(FontDisplay.path_to_uri ((!) f_eot.get_path ()))?$rid");
								line = ((!) line).replace (@"$(font.get_full_name ()).svg", @"$(FontDisplay.path_to_uri ((!) f_svg.get_path ()))?$rid");
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
				description.canvas.set_visible (false);
			} else {
				html_box.set_visible (false);
				glyph_canvas_area.set_visible (true);
				description.canvas.set_visible (false);
			}
		});

		// Hide this canvas when window is realized and flip canvas 
		// visibility in tab selection signal.
		html_canvas.expose_event.connect ((t, e) => {
			glyph_canvas_area.set_visible (false);
			return false;
		});

		canvas_box = new HBox (false, 0);
		canvas_box.pack_start (glyph_canvas_area, true, true, 0);
		canvas_box.pack_start (html_box, true, true, 0);
		canvas_box.pack_start (description.canvas, true, true, 0);
		canvas_box.pack_start (scrollbar, false, true, 0);

		submit_text_button = new Button ();
		submit_text_button.set_label ("Submit");
		text_input_label = new Label ("   " + "Text");
		text_entry = new Entry ();
		text_box = new HBox (false, 6);
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
		
		tab_box = new VBox (false, 0);
		
		tab_box.pack_start (new TabbarCanvas (MainWindow.tabs), false, false, 0);
		tab_box.pack_start (text_box, false, false, 5);	
		tab_box.pack_start (canvas_box, true, true, 0);

		tab_box.pack_start (new TooltipCanvas (MainWindow.tool_tip), false, false, 0);
		
		list_box = new HBox (false, 0);
		list_box.pack_start (tab_box, true, true, 0);
		list_box.pack_start (new ToolboxCanvas (MainWindow.tools), false, false, 0);

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
			if (!GtkWindow.text_input_is_active) {
				FontDisplay fd = MainWindow.glyph_canvas.current_display;
				
				if (fd is Glyph) {
					MainWindow.tools.key_press (event.keyval);
				}
				
				MainWindow.glyph_canvas.key_press (event.keyval);
				KeyBindings.add_modifier_from_keyval (event.keyval);
				
				if (KeyBindings.modifier == CTRL) {
					switch (event.keyval) {
						case 'a':
							Toolbox.select_tool_by_name ("move");
							MainWindow.get_current_glyph ().select_all_paths ();
							break;
						case 'c':
							ClipTool.copy ();
							break;
						case 'v':
							ClipTool.paste ();
							break;
					}
				}
			}
			
			return false;
		});
		
		key_release_event.connect ((t, event) => {
			if (!GtkWindow.text_input_is_active) {
				FontDisplay fd = MainWindow.glyph_canvas.current_display;
				
				if (fd is Glyph) {
					MainWindow.glyph_canvas.key_release (event.keyval);
				}
				
				KeyBindings.remove_modifier_from_keyval (event.keyval);
			}
			
			return false;
		});
		
		show_all ();
		
		scrollbar.set_visible (false);
		description.canvas.set_visible (false);
		
		hide_text_input ();
		
		MainWindow.open_recent_files_tab ();
	}

	public void set_save_dialog (SaveDialogListener d) {
		Gtk.Dialog dialog = new Gtk.Dialog.with_buttons (d.message, null, 0);
		
		dialog.add_button (d.save_message, 0);
		dialog.add_button (d.discard_message, 1);
		
		dialog.response.connect ((respons) => {
			switch (respons) {
				case 0:
					d.save ();
					break;
				case 1:
					d.discard ();
					break;
			}
			dialog.destroy ();
		}); 
		
		dialog.show_all ();
	}

	public void font_loaded () {
		Font f = BirdFont.get_current_font ();
		set_title (@"BirdFont $(f.full_name)");
	}

	public void set_overwrite_dialog (OverWriteDialogListener d) {
		Gtk.Dialog dialog = new Gtk.Dialog.with_buttons (d.message, null, 0);
		
		dialog.add_button (d.overwrite_message, 0);
		dialog.add_button (d.cancel_message, 1);
		dialog.add_button (d.dont_ask_again_message, 2);
		
		dialog.response.connect ((respons) => {
			switch (respons) {
				case 0:
					d.overwrite ();
					break;
				case 1:
					d.cancel ();
					break;
				case 2:
					d.overwrite_dont_ask_again ();
					break;
			}
			dialog.destroy ();
		}); 
		
		dialog.show_all ();
	}

	public void spawn (string command) {
		try {
			print (command);
			print ("\n");
			Process.spawn_command_line_async (command);
		} catch (GLib.Error e) {
			warning (@"Command failed: $command");
			warning (e.message);
		}
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
		Gtk.Menu kerning_menu = new Gtk.Menu ();

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

		Gtk.MenuItem recent_files_item = new Gtk.MenuItem.with_mnemonic (_("_Recent Files"));
		file_menu.append (recent_files_item);
		recent_files_item.activate.connect (() => { MainWindow.open_recent_files_tab (); });

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

		if (!BirdFont.mac) {
			Gtk.MenuItem preview_item = new Gtk.MenuItem.with_mnemonic(_("_Preview"));
			file_menu.append (preview_item);
			preview_item.activate.connect (() => { MenuTab.preview (); });
			preview_item.add_accelerator ("activate", accel_group, 'P', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);
		}
		
		Gtk.MenuItem description_item = new Gtk.MenuItem.with_mnemonic(_("Name and _Description"));
		file_menu.append (description_item);
		description_item.activate.connect (() => { MenuTab.show_description (); });

		Gtk.MenuItem select_language_item = new Gtk.MenuItem.with_mnemonic (_("Select _Character Set"));
		file_menu.append (select_language_item);
		select_language_item.activate.connect (() => { MenuTab.select_language (); });
		
		Gtk.MenuItem quit_item = new Gtk.MenuItem.with_mnemonic (_("_Quit"));
		file_menu.append (quit_item);
		quit_item.activate.connect (() => { MenuTab.quit (); });

		// Edit
		Gtk.MenuItem undo_item = new Gtk.MenuItem.with_mnemonic (_("_Undo"));
		edit_menu.append (undo_item);
		undo_item.activate.connect (() => { MainWindow.get_current_display ().undo (); });	
		undo_item.add_accelerator ("activate", accel_group, 'Z', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);
		
		Gtk.MenuItem copy_item = new Gtk.MenuItem.with_mnemonic (_("_Copy"));
		edit_menu.append (copy_item);
		copy_item.activate.connect (() => { ClipTool.copy (); });		

		Gtk.MenuItem paste_item = new Gtk.MenuItem.with_mnemonic (_("_Paste"));
		edit_menu.append (paste_item);
		paste_item.activate.connect (() => { ClipTool.paste (); });	

		Gtk.MenuItem paste_in_place_item = new Gtk.MenuItem.with_mnemonic (_("Paste _In Place"));
		edit_menu.append (paste_in_place_item);
		paste_in_place_item.activate.connect (() => { ClipTool.paste_in_place (); });	
		paste_in_place_item.add_accelerator ("activate", accel_group, 'V', Gdk.ModifierType.CONTROL_MASK | Gdk.ModifierType.SHIFT_MASK, Gtk.AccelFlags.VISIBLE);

		Gtk.MenuItem select_all_item = new Gtk.MenuItem.with_mnemonic (_("Select All Pa_ths"));
		edit_menu.append (select_all_item);
		select_all_item.activate.connect (() => {
			Toolbox.select_tool_by_name ("move");
			MainWindow.get_current_glyph ().select_all_paths ();
		});

		Gtk.MenuItem search_item = new Gtk.MenuItem.with_mnemonic (_("_Search"));
		edit_menu.append (search_item);
		search_item.activate.connect (() => { OverView.search (); });	
		search_item.add_accelerator ("activate", accel_group, 'F', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);
	
		Gtk.MenuItem export_svg_item = new Gtk.MenuItem.with_mnemonic (_("_Export Glyph as SVG"));
		edit_menu.append (export_svg_item);
		export_svg_item.activate.connect (() => { ExportTool.export_current_glyph (); });	
	
		Gtk.MenuItem import_svg_item = new Gtk.MenuItem.with_mnemonic (_("_Import SVG"));
		edit_menu.append (import_svg_item);
		import_svg_item.activate.connect (() => { ImportSvg.import (); });	
		import_svg_item.add_accelerator ("activate", accel_group, 'I', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);

		Gtk.MenuItem close_path_item = new Gtk.MenuItem.with_mnemonic (_("Close _Path"));
		edit_menu.append (close_path_item);
		close_path_item.activate.connect (() => { PenTool.close_all_paths (); });
		close_path_item.add_accelerator ("activate", accel_group, 'B', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);

		Gtk.MenuItem glyph_sequence_item = new Gtk.MenuItem.with_mnemonic (_("_Glyph Sequence"));
		edit_menu.append (glyph_sequence_item);
		glyph_sequence_item.activate.connect (() => { MainWindow.update_glyph_sequence (); });
		glyph_sequence_item.add_accelerator ("activate", accel_group, 'Q', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);

		Gtk.MenuItem background_glyph_item = new Gtk.MenuItem.with_mnemonic (_("Set Glyph _Background"));
		edit_menu.append (background_glyph_item);
		background_glyph_item.activate.connect (() => { MenuTab.use_current_glyph_as_background (); });

		Gtk.MenuItem reset_background_glyph_item = new Gtk.MenuItem.with_mnemonic (_("_Remove Glyph Background"));
		edit_menu.append (reset_background_glyph_item);
		reset_background_glyph_item.activate.connect (() => { MenuTab.reset_glyph_background (); });

		edit_menu.append (new SeparatorMenuItem ());

		Gtk.MenuItem select_point_above = new Gtk.MenuItem.with_mnemonic (" Ctrl+↑  " + _("_Select Point Above"));
		edit_menu.append (select_point_above);
		select_point_above.activate.connect (() => { PenTool.select_point_up (); });

		Gtk.MenuItem select_next_point = new Gtk.MenuItem.with_mnemonic (" Ctrl+→  " + _("Select _Next Point"));
		edit_menu.append (select_next_point);
		select_next_point.activate.connect (() => { PenTool.select_point_right (); });

		Gtk.MenuItem select_previous_point = new Gtk.MenuItem.with_mnemonic (" Ctrl+←  " + _("Select _Previous Point"));
		edit_menu.append (select_previous_point);
		select_previous_point.activate.connect (() => { PenTool.select_point_left (); });

		Gtk.MenuItem select_point_below = new Gtk.MenuItem.with_mnemonic (" Ctrl+↓  " + _("Select Point _Below"));
		edit_menu.append (select_point_below);
		select_point_below.activate.connect (() => { PenTool.select_point_down (); });
				
		// Tab
		Gtk.MenuItem next_tab_item = new Gtk.MenuItem.with_mnemonic (_("_Next Tab"));
		tab_menu.append (next_tab_item);
		next_tab_item.activate.connect (() => { 
			TabBar tb = MainWindow.get_tab_bar ();
			int n = tb.get_selected () + 1;
			
			if (!(0 <= n < tb.get_length ())) {
				return;
			}
			
			tb.select_tab (n);
		});	

		Gtk.MenuItem prevoius_tab_item = new Gtk.MenuItem.with_mnemonic (_("_Previous Tab"));
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

		Gtk.MenuItem close_all_tabs_item = new Gtk.MenuItem.with_mnemonic (_("Close _All Tabs"));
		tab_menu.append (close_all_tabs_item);
		close_all_tabs_item.activate.connect (() => { 
			TabBar tb = MainWindow.get_tab_bar ();
			tb.close_all_tabs ();			
		});	

		// Tool
		Gtk.MenuItem pen_item = new Gtk.MenuItem.with_mnemonic (_("_Create Path"));
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

		Gtk.MenuItem counter_item = new Gtk.MenuItem.with_mnemonic (_("_Create Counter Path"));
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

		Gtk.MenuItem default_charset_item = new Gtk.MenuItem.with_mnemonic (_("Show De_fault Characters Set"));
		tool_menu.append (default_charset_item);
		default_charset_item.activate.connect (() => { 
			Toolbox.select_tool_by_name ("custom_character_set");
		});
		default_charset_item.add_accelerator ("activate", accel_group, 'R', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);

		Gtk.MenuItem avalilable_characters_item = new Gtk.MenuItem.with_mnemonic (_("Show Characters in Font"));
		tool_menu.append (avalilable_characters_item);
		avalilable_characters_item.activate.connect (() => { 
			Toolbox.select_tool_by_name ("available_characters");
		});
		avalilable_characters_item.add_accelerator ("activate", accel_group, 'D', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);

		Gtk.MenuItem add_grid_item = new Gtk.MenuItem.with_mnemonic (_("Add New _Grid Item"));
		tool_menu.append (add_grid_item);
		add_grid_item.activate.connect (() => { 
			MainWindow.get_drawing_tools ().add_new_grid ();
		});

		Gtk.MenuItem remove_grid_item = new Gtk.MenuItem.with_mnemonic (_("Remove Gr_id Item"));
		tool_menu.append (remove_grid_item);
		remove_grid_item.activate.connect (() => { 
			MainWindow.get_drawing_tools().remove_current_grid ();
		});
		
		Gtk.MenuItem zoom_in_item = new Gtk.MenuItem.with_mnemonic (_("_Zoom In"));
		tool_menu.append (zoom_in_item);
		zoom_in_item.activate.connect (() => { 
			Toolbox.select_tool_by_name ("zoom_in");
		});
		zoom_in_item.add_accelerator ("activate", accel_group, '+', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);

		Gtk.MenuItem zoom_out_item = new Gtk.MenuItem.with_mnemonic (_("Zoom _Out"));
		tool_menu.append (zoom_out_item);
		zoom_out_item.activate.connect (() => { 
			Toolbox.select_tool_by_name ("zoom_out");
		});
		zoom_out_item.add_accelerator ("activate", accel_group, '-', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);

		Gtk.MenuItem zoom_1_1_item = new Gtk.MenuItem.with_mnemonic (_("Zoom to _Scale 1:1"));
		tool_menu.append (zoom_1_1_item);
		zoom_1_1_item.activate.connect (() => { 
			Toolbox.select_tool_by_name ("zoom_1_1");
		});
		zoom_1_1_item.add_accelerator ("activate", accel_group, '0', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);

		// Kerning
		Gtk.MenuItem show_kerning_tab = new Gtk.MenuItem.with_mnemonic (_("Show Kerning _Tab"));
		kerning_menu.append (show_kerning_tab);
		show_kerning_tab.activate.connect (() => { 
			 MenuTab.show_kerning_context ();
		});
		show_kerning_tab.add_accelerator ("activate", accel_group, 'k', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);

		Gtk.MenuItem list_all_kerning_pairs = new Gtk.MenuItem.with_mnemonic (_("_List Kerning Pairs"));
		kerning_menu.append (list_all_kerning_pairs);
		list_all_kerning_pairs.activate.connect (() => { 
			 MenuTab.list_all_kerning_pairs ();
		});
		
		Gtk.MenuItem remove_all_kerning_pairs = new Gtk.MenuItem.with_mnemonic (_("_Remove All Kerning Pairs"));
		kerning_menu.append (remove_all_kerning_pairs);
		remove_all_kerning_pairs.activate.connect (() => { 
			 MenuTab.remove_all_kerning_pairs ();
		});

		kerning_menu.append (new SeparatorMenuItem ());

		Gtk.MenuItem select_next_kerning_pair = new Gtk.MenuItem.with_mnemonic (" Ctrl+→  " + _("Select _Next Kerning Pair"));
		kerning_menu.append (select_next_kerning_pair);
		select_next_kerning_pair.activate.connect (() => { KerningDisplay.next_pair (); });
		
		Gtk.MenuItem select_previous_kerning_pair = new Gtk.MenuItem.with_mnemonic (" Ctrl+←  " + _("Select _Previous Kerning Pair"));
		kerning_menu.append (select_previous_kerning_pair);
		select_previous_kerning_pair.activate.connect (() => { KerningDisplay.previous_pair (); });
		
		// Add menus
		Gtk.MenuItem file_launcher = new Gtk.MenuItem.with_mnemonic (_("_File"));
		file_launcher.set_submenu (file_menu);

		Gtk.MenuItem edit_launcher = new Gtk.MenuItem.with_mnemonic (_("_Edit"));
		edit_launcher.set_submenu (edit_menu);

		Gtk.MenuItem tab_launcher = new Gtk.MenuItem.with_mnemonic (_("_Tab"));
		tab_launcher.set_submenu (tab_menu);

		Gtk.MenuItem tool_launcher = new Gtk.MenuItem.with_mnemonic (_("T_ool"));
		tool_launcher.set_submenu (tool_menu);

		Gtk.MenuItem kerning_launcher = new Gtk.MenuItem.with_mnemonic (_("_Kerning"));
		kerning_launcher.set_submenu (kerning_menu);
						
		menubar.append (file_launcher);
		menubar.append (edit_launcher);
		menubar.append (tab_launcher);
		menubar.append (tool_launcher);
		menubar.append (kerning_launcher);
		
		return menubar;	
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
			listener.signal_submit (listener.default_text);
			text_input_is_active = false;
		});
		text_entry.grab_focus ();
		text_input_is_active = true;
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
		
		set_size_request (20, 33);
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

		scroll_event.connect ((t, e)=> {
			if (e.direction == Gdk.ScrollDirection.UP) {
				tb.scroll_up (e.x, e.y);
			} else if (e.direction == Gdk.ScrollDirection.DOWN) {
				tb.scroll_down (e.x, e.y);
			}			
			return true;
		});
		
		add_events (EventMask.BUTTON_PRESS_MASK | EventMask.BUTTON_RELEASE_MASK | EventMask.POINTER_MOTION_MASK | EventMask.LEAVE_NOTIFY_MASK | EventMask.SCROLL_MASK);

		set_size_request (160, 100);

		leave_notify_event.connect ((t, e)=> {
			tb.reset_active_tool ();
			return true;
		});
		
	}
}

public class GlyphCanvasArea : DrawingArea  {
	GlyphCanvas glyph_canvas;
	WidgetAllocation alloc = new WidgetAllocation ();
	WidgetAllocation prev_alloc = new WidgetAllocation ();
	
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
			
			alloc = new WidgetAllocation ();

			alloc.width = allocation.width;
			alloc.height = allocation.height;
			alloc.x = allocation.x;
			alloc.y = allocation.y;
			
			glyph_canvas.set_allocation (alloc);
			BirdFont.current_glyph.resized (alloc);
				
			prev_alloc = new WidgetAllocation ();
			prev_alloc.width = allocation.width;
			prev_alloc.height = allocation.height;
			prev_alloc.x = allocation.x;
			prev_alloc.y = allocation.y;
			
			Context cw = cairo_create (get_window());
			
			Surface s = new Surface.similar (cw.get_target (), Cairo.Content.COLOR_ALPHA, alloc.width, alloc.height);
			Context c = new Context (s); 

			glyph_canvas.current_display.draw (alloc, c);

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
		
		can_focus = true;
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
				WidgetAllocation allocation = new WidgetAllocation ();
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

public class DescriptionForm : GLib.Object {
	
	public ScrolledWindow canvas;
	public VBox box;
	
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
		box = new VBox (false, 6);
		canvas = new ScrolledWindow (null, null);
		canvas.set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
		
		postscript_name = new Entry ();
		add_entry (postscript_name, _("PostScript Name"));
		postscript_name.changed.connect (() => {
			Font f = BirdFont.get_current_font ();
			f.postscript_name = postscript_name.text;
		});
		
		font_name = new Entry ();
		add_entry (font_name, _("Name"));
		font_name.changed.connect (() => {
			Font f = BirdFont.get_current_font ();
			f.name = font_name.text;
		});
		
		style = new Entry ();
		add_entry (style, _("Style"));
		style.changed.connect (() => {
			Font f = BirdFont.get_current_font ();
			f.subfamily = style.text;
		});
		
		bold = new CheckButton.with_label (_("Bold"));
		bold.toggled.connect (() => {
			Font f = BirdFont.get_current_font ();
			f.bold = bold.active;;
		});
		box.pack_start (bold, false, false, 0);
		
		italic = new CheckButton.with_label (_("Italic"));
		italic.toggled.connect (() => {
			Font f = BirdFont.get_current_font ();
			f.italic = italic.active;;
		});
		box.pack_start (italic, false, false, 0);

		weight = new Entry ();
		add_entry (weight, _("Weight"));
		weight.changed.connect (() => {
			Font f = BirdFont.get_current_font ();
			f.set_weight (weight.text);
		});
		
		full_name = new Entry ();
		add_entry (full_name, _("Full name (name and style)"));
		full_name.changed.connect (() => {
			Font f = BirdFont.get_current_font ();
			f.full_name = full_name.text;
		});
		
		id = new Entry ();
		add_entry (id, _("Unique identifier"));
		id.changed.connect (() => {
			Font f = BirdFont.get_current_font ();
			f.unique_identifier = id.text;
		});
		
		version = new Entry ();
		add_entry (version, _("Version"));
		version.changed.connect (() => {
			Font f = BirdFont.get_current_font ();
			f.version = version.text;
		});
		
		description = new TextView ();
		add_textview (description, _("Description"));
		description.get_buffer ().changed.connect (() => {
			Font f = BirdFont.get_current_font ();
			f.description = description.get_buffer ().text;
		});
		description.set_wrap_mode (Gtk.WrapMode.WORD);

		copyright = new TextView ();
		add_textview (copyright, _("Copyright"));
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
		VBox vb;
		HBox hb;
		Label l;
		HBox margin;
		
		margin = new HBox (false, 6);
		l = new Label (label);
		vb = new VBox (false, 2);
		hb = new HBox (false, 2);
		hb.pack_start (l, false, false, 0);
		vb.pack_start (hb, true, true, 5);
		vb.pack_start (e, true, true, 0);
		margin.pack_start (vb, true, true, 5);
		box.pack_start (margin, false, false, 5);
	}

	void add_textview (TextView t, string label) {
		VBox vb;
		HBox hb;
		Label l;
		HBox margin;
		
		margin = new HBox (false, 6);
		l = new Label (label);
		vb = new VBox (false, 2);
		hb = new HBox (false, 2);
		hb.pack_start (l, false, false, 0);
		vb.pack_start (hb, true, true, 5);
		vb.pack_start (t, true, true, 0);
		margin.pack_start (vb, true, true, 5);
		box.pack_start (margin, false, false, 5);
	}
}

}
