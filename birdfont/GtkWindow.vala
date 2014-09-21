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
	Button submit_text_button;
	
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
			string uri = "";
			string html = "";
			FontDisplay fd = tab.get_display ();
			MainWindow.glyph_canvas.set_current_glyph (fd);
			
			scrollbar.set_visible (fd.has_scrollbar ());
			
			if (fd.get_name () == "Description") {
				description.update_fields ();
				description.canvas.set_visible (true);
				html_box.set_visible (false);
				glyph_canvas_area.set_visible (false);
			} else if (fd.get_name () == "Preview") {
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

		submit_text_button = new Button ();
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

		tab_box.pack_start (new TooltipCanvas (MainWindow.get_tooltip ()), false, false, 0);
		
		toolbox = new ToolboxCanvas (MainWindow.get_toolbox ()); 
		list_box = new Box (Orientation.HORIZONTAL, 0);
		list_box.pack_start (tab_box, true, true, 0);
		list_box.pack_start (toolbox, false, false, 0);

		Box vbox = new Box (Orientation.VERTICAL, 0);
		
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

	public void set_scrollbar_size (double size) {
		scrollbar.adjustment.page_size = size;
	}
	
	public void set_scrollbar_position (double position) {
		scrollbar_supress_signal = true;
		scrollbar.adjustment.value = position * (1 - scrollbar.adjustment.page_size);
		scrollbar_supress_signal = false;
	}
	
	public void color_selection (ColorTool color_tool) {
		new ColorWindow (color_tool);
	}
	
	class ColorWindow : Gtk.Window {
		
		ColorChooserWidget color_selection;
		
		public ColorWindow (ColorTool color_tool) {
			Button set_button;
			
			title = t_("Select color");
			window_position = Gtk.WindowPosition.CENTER;

			Box box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
			add (box);

			color_selection = new Gtk.ColorChooserWidget ();
			box.add (color_selection);
			
			color_selection.show_editor = true;

			color_selection.color_activated.connect ((color) => {
				Gdk.RGBA c = color_selection.rgba;
				color_tool.color_r = c.red;
				color_tool.color_g = c.green;
				color_tool.color_b = c.blue;
				color_tool.color_a = c.alpha;
				color_tool.color_updated ();
			});

			color_selection.color_activated.connect (() => {
				Gdk.RGBA c = new Gdk.RGBA ();
				c.red = color_tool.color_r;
				c.green = color_tool.color_g;
				c.blue = color_tool.color_b;
				c.alpha = color_tool.color_a;
				color_selection.rgba = c;
			});

			set_button = new Button.with_label (_("Set"));
			box.add (set_button);

			set_button.clicked.connect (() => {
				Gdk.RGBA c = color_selection.rgba;
				color_tool.color_r = c.red;
				color_tool.color_g = c.green;
				color_tool.color_b = c.blue;
				color_tool.color_a = c.alpha;
				color_tool.color_updated ();
			});

			show_all ();
		}	
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
		Gtk.Menu git_menu = new Gtk.Menu ();
		Gtk.Menu ligature_menu = new Gtk.Menu ();

		AccelGroup accel_group = new Gtk.AccelGroup();
		add_accel_group (accel_group);
		
		// File
		Gtk.MenuItem new_item = new Gtk.MenuItem.with_mnemonic (t_("_New"));
		file_menu.append (new_item);
		new_item.activate.connect (() => { MenuTab.new_file (); });
		new_item.add_accelerator ("activate", accel_group, 'N', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);

		Gtk.MenuItem load_item = new Gtk.MenuItem.with_mnemonic (t_("_Open"));
		file_menu.append (load_item);
		load_item.activate.connect (() => { MenuTab.load (); });
		load_item.add_accelerator ("activate", accel_group, 'O', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);

		Gtk.MenuItem recent_files_item = new Gtk.MenuItem.with_mnemonic (t_("_Recent Files"));
		file_menu.append (recent_files_item);
		recent_files_item.activate.connect (() => { MainWindow.open_recent_files_tab (); });

		Gtk.MenuItem save_item = new Gtk.MenuItem.with_mnemonic (_("_Save"));
		file_menu.append (save_item);
		save_item.activate.connect (() => { MenuTab.save (); });
		save_item.add_accelerator ("activate", accel_group, 'S', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);

		Gtk.MenuItem save_as_item = new Gtk.MenuItem.with_mnemonic (t_("Save _as"));
		file_menu.append (save_as_item);
		save_as_item.activate.connect (() => { MenuTab.save_as (); });
				
		Gtk.MenuItem export_item = new Gtk.MenuItem.with_mnemonic (t_("_Export"));
		file_menu.append (export_item);
		export_item.activate.connect (() => { MenuTab.export_fonts_in_background (); });
		export_item.add_accelerator ("activate", accel_group, 'E', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);

		Gtk.MenuItem preview_item = new Gtk.MenuItem.with_mnemonic(t_("_Preview"));
		file_menu.append (preview_item);
		preview_item.activate.connect (() => { MenuTab.preview (); });
		preview_item.add_accelerator ("activate", accel_group, 'P', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);
		
		Gtk.MenuItem description_item = new Gtk.MenuItem.with_mnemonic(t_("Name and _Description"));
		file_menu.append (description_item);
		description_item.activate.connect (() => { MenuTab.show_description (); });

		Gtk.MenuItem select_language_item = new Gtk.MenuItem.with_mnemonic (t_("Select _Character Set"));
		file_menu.append (select_language_item);
		select_language_item.activate.connect (() => { MenuTab.select_language (); });
		
		Gtk.MenuItem quit_item = new Gtk.MenuItem.with_mnemonic (t_("_Quit"));
		file_menu.append (quit_item);
		quit_item.activate.connect (() => { MenuTab.quit (); });

		// Edit
		Gtk.MenuItem undo_item = new Gtk.MenuItem.with_mnemonic (t_("_Undo"));
		edit_menu.append (undo_item);
		undo_item.activate.connect (() => { TabContent.undo (); });	
		undo_item.add_accelerator ("activate", accel_group, 'Z', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);

		Gtk.MenuItem redo_item = new Gtk.MenuItem.with_mnemonic (t_("_Redo"));
		edit_menu.append (redo_item);
		redo_item.activate.connect (() => { TabContent.redo (); });	
		redo_item.add_accelerator ("activate", accel_group, 'Y', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);

		Gtk.MenuItem copy_item = new Gtk.MenuItem.with_mnemonic (t_("_Copy"));
		edit_menu.append (copy_item);
		copy_item.activate.connect (() => { ClipTool.copy (); });		
		copy_item.add_accelerator ("activate", accel_group, 'C', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);

		Gtk.MenuItem paste_item = new Gtk.MenuItem.with_mnemonic (t_("_Paste"));
		edit_menu.append (paste_item);
		paste_item.activate.connect (() => { ClipTool.paste (); });	
		paste_item.add_accelerator ("activate", accel_group, 'V', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);

		Gtk.MenuItem paste_in_place_item = new Gtk.MenuItem.with_mnemonic (t_("Paste _In Place"));
		edit_menu.append (paste_in_place_item);
		paste_in_place_item.activate.connect (() => { ClipTool.paste_in_place (); });	
		paste_in_place_item.add_accelerator ("activate", accel_group, 'V', Gdk.ModifierType.CONTROL_MASK | Gdk.ModifierType.SHIFT_MASK, Gtk.AccelFlags.VISIBLE);

		Gtk.MenuItem select_all_item = new Gtk.MenuItem.with_mnemonic (t_("Select All Pa_ths"));
		edit_menu.append (select_all_item);
		select_all_item.activate.connect (() => {
			MainWindow.select_all_paths ();
		});
		select_all_item.add_accelerator ("activate", accel_group, 'A', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);

		Gtk.MenuItem move_to_baseline_item = new Gtk.MenuItem.with_mnemonic (t_("Move _To Baseline"));
		edit_menu.append (move_to_baseline_item);
		move_to_baseline_item.activate.connect (() => {
			MenuTab.move_to_baseline ();
		});
		move_to_baseline_item.add_accelerator ("activate", accel_group, 'T', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);
		
				
		Gtk.MenuItem search_item = new Gtk.MenuItem.with_mnemonic (t_("_Search"));
		edit_menu.append (search_item);
		search_item.activate.connect (() => { OverView.search (); });	
		search_item.add_accelerator ("activate", accel_group, 'F', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);
	
		Gtk.MenuItem export_svg_item = new Gtk.MenuItem.with_mnemonic (t_("_Export Glyph as SVG"));
		edit_menu.append (export_svg_item);
		export_svg_item.activate.connect (() => { ExportTool.export_current_glyph (); });	
	
		Gtk.MenuItem import_svg_item = new Gtk.MenuItem.with_mnemonic (t_("_Import SVG"));
		edit_menu.append (import_svg_item);
		import_svg_item.activate.connect (() => { SvgParser.import (); });	
		import_svg_item.add_accelerator ("activate", accel_group, 'I', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);

		Gtk.MenuItem simplify_item = new Gtk.MenuItem.with_mnemonic (t_("Simpl_ify Path"));
		edit_menu.append (simplify_item);
		simplify_item.activate.connect (() => { MenuTab.simplify_path (); });	
		simplify_item.add_accelerator ("activate", accel_group, 'S', Gdk.ModifierType.CONTROL_MASK | Gdk.ModifierType.SHIFT_MASK, Gtk.AccelFlags.VISIBLE);

		Gtk.MenuItem close_path_item = new Gtk.MenuItem.with_mnemonic (t_("Close _Path"));
		edit_menu.append (close_path_item);
		close_path_item.activate.connect (() => { PenTool.close_all_paths (); });
		close_path_item.add_accelerator ("activate", accel_group, 'B', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);

		Gtk.MenuItem glyph_sequence_item = new Gtk.MenuItem.with_mnemonic (t_("_Glyph Sequence"));
		edit_menu.append (glyph_sequence_item);
		glyph_sequence_item.activate.connect (() => { MainWindow.update_glyph_sequence (); });
		glyph_sequence_item.add_accelerator ("activate", accel_group, 'Q', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);

		Gtk.MenuItem background_glyph_item = new Gtk.MenuItem.with_mnemonic (t_("Set Glyph _Background"));
		edit_menu.append (background_glyph_item);
		background_glyph_item.activate.connect (() => { MenuTab.use_current_glyph_as_background (); });

		Gtk.MenuItem reset_background_glyph_item = new Gtk.MenuItem.with_mnemonic (t_("_Remove Glyph Background"));
		edit_menu.append (reset_background_glyph_item);
		reset_background_glyph_item.activate.connect (() => { MenuTab.reset_glyph_background (); });

		edit_menu.append (new SeparatorMenuItem ());

		Gtk.MenuItem select_point_above = new Gtk.MenuItem.with_mnemonic (" Ctrl+↑  " + t_("_Select Point Above"));
		edit_menu.append (select_point_above);
		select_point_above.activate.connect (() => { PenTool.select_point_up (); });

		Gtk.MenuItem select_next_point = new Gtk.MenuItem.with_mnemonic (" Ctrl+→  " + t_("Select _Next Point"));
		edit_menu.append (select_next_point);
		select_next_point.activate.connect (() => { PenTool.select_point_right (); });

		Gtk.MenuItem select_previous_point = new Gtk.MenuItem.with_mnemonic (" Ctrl+←  " + t_("Select _Previous Point"));
		edit_menu.append (select_previous_point);
		select_previous_point.activate.connect (() => { PenTool.select_point_left (); });

		Gtk.MenuItem select_point_below = new Gtk.MenuItem.with_mnemonic (" Ctrl+↓  " + t_("Select Point _Below"));
		edit_menu.append (select_point_below);
		select_point_below.activate.connect (() => { PenTool.select_point_down (); });
				
		// Tab
		Gtk.MenuItem next_tab_item = new Gtk.MenuItem.with_mnemonic (t_("_Next Tab"));
		tab_menu.append (next_tab_item);
		next_tab_item.activate.connect (() => { 
			MainWindow.next_tab ();
		});	

		Gtk.MenuItem prevoius_tab_item = new Gtk.MenuItem.with_mnemonic (t_("_Previous Tab"));
		tab_menu.append (prevoius_tab_item);
		prevoius_tab_item.activate.connect (() => {
			MainWindow.previous_tab ();
		});					

		Gtk.MenuItem close_tab_item = new Gtk.MenuItem.with_mnemonic (t_("_Close Tab"));
		tab_menu.append (close_tab_item);
		close_tab_item.activate.connect (() => { 
			MainWindow.close_tab ();
		});	
		close_tab_item.add_accelerator ("activate", accel_group, 'W', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);

		Gtk.MenuItem close_all_tabs_item = new Gtk.MenuItem.with_mnemonic (t_("Close _All Tabs"));
		tab_menu.append (close_all_tabs_item);
		close_all_tabs_item.activate.connect (() => { 
			MainWindow.close_all_tabs ();		
		});	

		// Tool
		Gtk.MenuItem pen_item = new Gtk.MenuItem.with_mnemonic (t_("_Create Path"));
		tool_menu.append (pen_item);
		pen_item.activate.connect (() => { 
			Toolbox.select_tool_by_name ("pen_tool");
		});
		pen_item.add_accelerator ("activate", accel_group, ',', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);

		Gtk.MenuItem zoom_item = new Gtk.MenuItem.with_mnemonic (t_("_Zoom"));
		tool_menu.append (zoom_item);
		zoom_item.activate.connect (() => { 
			Toolbox.select_tool_by_name ("zoom_tool");
		});

		Gtk.MenuItem counter_item = new Gtk.MenuItem.with_mnemonic (t_("_Create Counter Path"));
		tool_menu.append (counter_item);
		counter_item.activate.connect (() => { 
			Toolbox.select_tool_by_name ("cut");
		});
		counter_item.add_accelerator ("activate", accel_group, 'U', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);

		Gtk.MenuItem move_item = new Gtk.MenuItem.with_mnemonic (t_("_Move"));
		tool_menu.append (move_item);
		move_item.activate.connect (() => { 
			Toolbox.select_tool_by_name ("move");
		});
		move_item.add_accelerator ("activate", accel_group, 'M', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);

		Gtk.MenuItem full_unicode_item = new Gtk.MenuItem.with_mnemonic (t_("Show _Full Unicode Characters Set"));
		tool_menu.append (full_unicode_item);
		full_unicode_item.activate.connect (() => { 
			Toolbox.select_tool_by_name ("utf_8");
		});
		full_unicode_item.add_accelerator ("activate", accel_group, 'F', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);

		Gtk.MenuItem default_charset_item = new Gtk.MenuItem.with_mnemonic (t_("Show De_fault Characters Set"));
		tool_menu.append (default_charset_item);
		default_charset_item.activate.connect (() => { 
			Toolbox.select_tool_by_name ("custom_character_set");
		});
		default_charset_item.add_accelerator ("activate", accel_group, 'R', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);

		Gtk.MenuItem avalilable_characters_item = new Gtk.MenuItem.with_mnemonic (t_("Show Characters in Font"));
		tool_menu.append (avalilable_characters_item);
		avalilable_characters_item.activate.connect (() => {
			Toolbox.select_tool_by_name ("available_characters");
		});
		avalilable_characters_item.add_accelerator ("activate", accel_group, 'D', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);

		Gtk.MenuItem add_grid_item = new Gtk.MenuItem.with_mnemonic (t_("Add New _Grid Item"));
		tool_menu.append (add_grid_item);
		add_grid_item.activate.connect (() => { 
			MainWindow.get_drawing_tools ().add_new_grid ();
		});

		Gtk.MenuItem remove_grid_item = new Gtk.MenuItem.with_mnemonic (t_("Remove Gr_id Item"));
		tool_menu.append (remove_grid_item);
		remove_grid_item.activate.connect (() => { 
			MainWindow.get_drawing_tools().remove_current_grid ();
		});
		
		Gtk.MenuItem zoom_in_item = new Gtk.MenuItem.with_mnemonic (t_("_Zoom In"));
		tool_menu.append (zoom_in_item);
		zoom_in_item.activate.connect (() => { 
			Toolbox.select_tool_by_name ("zoom_in");
		});
		zoom_in_item.add_accelerator ("activate", accel_group, '+', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);

		Gtk.MenuItem zoom_out_item = new Gtk.MenuItem.with_mnemonic (t_("Zoom _Out"));
		tool_menu.append (zoom_out_item);
		zoom_out_item.activate.connect (() => { 
			Toolbox.select_tool_by_name ("zoom_out");
		});
		zoom_out_item.add_accelerator ("activate", accel_group, '-', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);

		Gtk.MenuItem zoom_1_1_item = new Gtk.MenuItem.with_mnemonic (t_("U_se One Pixel Per Unit"));
		tool_menu.append (zoom_1_1_item);
		zoom_1_1_item.activate.connect (() => { 
			Toolbox.select_tool_by_name ("zoom_1_1");
		});
		zoom_1_1_item.add_accelerator ("activate", accel_group, '0', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);

		// Kerning
		Gtk.MenuItem show_kerning_tab = new Gtk.MenuItem.with_mnemonic (t_("Show Kerning _Tab"));
		kerning_menu.append (show_kerning_tab);
		show_kerning_tab.activate.connect (() => { 
			 MenuTab.show_kerning_context ();
		});
		show_kerning_tab.add_accelerator ("activate", accel_group, 'k', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);

		Gtk.MenuItem list_all_kerning_pairs = new Gtk.MenuItem.with_mnemonic (t_("_List Kerning Pairs"));
		kerning_menu.append (list_all_kerning_pairs);
		list_all_kerning_pairs.activate.connect (() => { 
			 MenuTab.list_all_kerning_pairs ();
		});

		Gtk.MenuItem spacing_kerning_tab = new Gtk.MenuItem.with_mnemonic (t_("Show _Spacing Tab"));
		kerning_menu.append (spacing_kerning_tab);
		spacing_kerning_tab.activate.connect (() => { 
			 MenuTab.show_spacing_tab ();
		});
		spacing_kerning_tab.add_accelerator ("activate", accel_group, 'k', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);


		kerning_menu.append (new SeparatorMenuItem ());

		Gtk.MenuItem select_next_kerning_pair = new Gtk.MenuItem.with_mnemonic (" Ctrl+→  " + t_("Select _Next Kerning Pair"));
		kerning_menu.append (select_next_kerning_pair);
		select_next_kerning_pair.activate.connect (() => { KerningDisplay.next_pair (); });
		
		Gtk.MenuItem select_previous_kerning_pair = new Gtk.MenuItem.with_mnemonic (" Ctrl+←  " + t_("Select _Previous Kerning Pair"));
		kerning_menu.append (select_previous_kerning_pair);
		select_previous_kerning_pair.activate.connect (() => { KerningDisplay.previous_pair (); });
		
		// Git
		Gtk.MenuItem save_as_bfp = new Gtk.MenuItem.with_mnemonic (t_("_Save as .bfp"));
		git_menu.append (save_as_bfp);
		save_as_bfp.activate.connect (() => { 
			 MenuTab.save_as_bfp ();
		});

		// Ligatures
		Gtk.MenuItem show_ligatures = new Gtk.MenuItem.with_mnemonic (t_("_Show Ligatures"));
		ligature_menu.append (show_ligatures);
		show_ligatures.activate.connect (() => { 
			 MenuTab.show_ligature_tab ();
		});
		
		// Add menus
		Gtk.MenuItem file_launcher = new Gtk.MenuItem.with_mnemonic (t_("_File"));
		file_launcher.set_submenu (file_menu);

		Gtk.MenuItem edit_launcher = new Gtk.MenuItem.with_mnemonic (t_("_Edit"));
		edit_launcher.set_submenu (edit_menu);

		Gtk.MenuItem tab_launcher = new Gtk.MenuItem.with_mnemonic (t_("_Tab"));
		tab_launcher.set_submenu (tab_menu);

		Gtk.MenuItem tool_launcher = new Gtk.MenuItem.with_mnemonic (t_("T_ool"));
		tool_launcher.set_submenu (tool_menu);

		Gtk.MenuItem kerning_launcher = new Gtk.MenuItem.with_mnemonic (t_("_Kerning"));
		kerning_launcher.set_submenu (kerning_menu);

		Gtk.MenuItem git_launcher = new Gtk.MenuItem.with_mnemonic ("_Git");
		git_launcher.set_submenu (git_menu);

		Gtk.MenuItem ligature_launcher = new Gtk.MenuItem.with_mnemonic ("_Ligatures");
		ligature_launcher.set_submenu (ligature_menu);

		menubar.append (file_launcher);
		menubar.append (edit_launcher);
		menubar.append (tab_launcher);
		menubar.append (tool_launcher);
		menubar.append (kerning_launcher);
		
		if (BirdFont.has_argument ("--test")) {
			menubar.append (git_launcher);
			menubar.append (ligature_launcher);
		}
				
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
	
	public void file_chooser (string title, FileChooser fc, uint flags) {
		string? fn = null;
		
		if ((flags & FileChooser.LOAD) > 0) {
			fn = show_file_chooser (title, FileChooserAction.OPEN, Stock.OPEN);
		} else if ((flags & FileChooser.SAVE) > 0) {
			fn = show_file_chooser (title, FileChooserAction.SAVE, Stock.SAVE);
		} else {
			warning ("Unknown type");
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
			listener.signal_submit (listener.default_text);
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
	
	// TODO: add the default tooltip style to the label
	public void show_tooltip (string tooltip, int x, int y) {
		Label tooltip_label;
		int parent_x, parent_y;
		int tool_box_x, tool_box_y;
		int posx, posy;
		Gtk.Allocation label_allocation;
		Gtk.Box box;
		
		box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
		
		Screen screen = Screen.get_default ();

		get_position (out parent_x, out parent_y);
		toolbox.translate_coordinates (toolbox.get_toplevel (), 0, 0, out tool_box_x, out tool_box_y);
		
		tooltip_window.hide ();
		
		tooltip_window = new Gtk.Window (Gtk.WindowType.POPUP);
		tooltip_label = new Label(tooltip);
		tooltip_label.margin = 0;
		
		box.pack_start (tooltip_label, true, true, 0);
		
		tooltip_window.add (box);
		tooltip_label.show();
		box.show ();
		
		posx = parent_x + tool_box_x + x;
		posy = parent_y + tool_box_y + y - 7;
		tooltip_window.move (posx, posy);

		tooltip_window.show();

		label_allocation = new Gtk.Allocation ();
		tooltip_label.size_allocate (label_allocation);

		// move label to the left if it is off screen
		if (posx + label_allocation.width > screen.get_width () - 20) {
			tooltip_window.move (screen.get_width () - label_allocation.width - 20, posy);
		}

	}

	public void hide_tooltip () {
		tooltip_window.hide ();
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

		tabbar.redraw.connect ((x, y, w, h) => {
			queue_draw_area (x, y, w, h);
		});
				
		set_size_request (20, 33);
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

		set_size_request (170, 100);

		leave_notify_event.connect ((t, e)=> {
			tb.reset_active_tool ();
			return true;
		});
		
	}
}

public class GlyphCanvasArea : DrawingArea  {
	GlyphCanvas glyph_canvas;
	WidgetAllocation alloc = new WidgetAllocation ();
	
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
			set_modifier ((int) e.state);
			
			if (e.type == EventType.BUTTON_PRESS) {
				TabContent.button_press (e.button, e.x, e.y);	
			} else if (e.type == EventType.2BUTTON_PRESS) {
				TabContent.double_click (e.button, e.x, e.y);
			}
				
			return true;
		});
		
		button_release_event.connect ((t, e)=> {
			set_modifier ((int) e.state);
			TabContent.button_release ((int) e.button, e.x, e.y);
			return true;
		});
		
		motion_notify_event.connect ((t, e)=> {
			TabContent.motion_notify (e.x, e.y);		
			return true;
		});
		
		scroll_event.connect ((t, e)=> {
			set_modifier ((int) e.state);
			
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

	static void set_modifier (int k) {
		KeyBindings.set_modifier (NONE);

		if (has_flag (k, ModifierType.SHIFT_MASK)) {
			KeyBindings.set_modifier (SHIFT);
		} else if (has_flag (k, ModifierType.CONTROL_MASK)) {
			KeyBindings.set_modifier (CTRL);
		} else if (has_flag (k, ModifierType.CONTROL_MASK | ModifierType.SHIFT_MASK)) {
			KeyBindings.set_modifier (SHIFT | CTRL);
		} else if (has_flag (k, ModifierType.MOD5_MASK)) {
			KeyBindings.set_modifier (LOGO);
		}
	}
}

public class TooltipCanvas : DrawingArea {
	TooltipArea tooltip_area;
	
	public TooltipCanvas (TooltipArea ta) {
		tooltip_area = ta;

		draw.connect ((t, e)=> {
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
