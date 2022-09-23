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

namespace BirdFont {

public class MenuTab : FontDisplay {
	
	/** Ignore input events when the background thread is running.
	 * 
	 * Do always check the return value of set_suppress_event when this
	 * variable is updated.
	 * 
	 * This variable is used only in the gui thread.
	 */
	private static bool suppress_event;

	/** True if the background thread is running. */
	public static bool background_thread;

	/** A notification sent when the file has been saved. */
	public static SaveCallback save_callback;

	/** A notification sent when the file has been loaded. */
	public static LoadCallback load_callback;

	/** A notification sent when the file has been loaded. */
	public static ExportCallback export_callback;

	public MenuTab () {
		save_callback = new SaveCallback ();
		save_callback.is_done = true;
		
		load_callback = new LoadCallback ();
		export_callback = new ExportCallback ();
		
		suppress_event = false;
		background_thread = false;
	}

	public static ExportCallback get_export_callback () {
		return export_callback;
	}

	public static bool has_suppress_event () {
		bool suppress;
		
		lock (suppress_event) {
			suppress = suppress_event;
		}
		
		return suppress;
	}

	public static void set_save_callback (SaveCallback c) {
		if (!save_callback.is_done) {
			warning ("Prevoius save command has not finished");
		}
		
		save_callback = c;
	}
	
	public static void start_background_thread () {
		if (!set_suppress_event (true)) {
			warning ("suppressed event");
			return;
		}
		
		TabBar.start_wheel ();
	}

	public static void stop_background_thread () {
		IdleSource idle = new IdleSource ();
		idle.set_callback (() => {
			set_suppress_event (false);
			TabBar.stop_wheel ();
			GlyphCanvas.redraw ();			
			return false;
		});
		idle.attach (null);
	}
	
	public static bool validate_metadata () {
		Font font = BirdFont.get_current_font ();
		string m = t_("Missing metadata in font:") + "\n";
		
		if (font.postscript_name == "") {
			MainWindow.show_message (m + t_("PostScript Name"));
			return false;
		}

		if (font.name == "") {
			MainWindow.show_message (m + t_("Name"));
			return false;
		}

		if (font.subfamily == "") {
			MainWindow.show_message (m + t_("Style"));
			return false;
		}

		if (font.full_name == "") {
			MainWindow.show_message (m + t_("Full Name (Name and Style)"));
			return false;
		}

		if (font.unique_identifier == "") {
			MainWindow.show_message (m + t_("Unique Identifier"));
			return false;
		}

		Font current_font = BirdFont.get_current_font ();
		string ttf_name = ExportSettings.get_file_name (current_font) + ".ttf";
		string ttf_name_mac = ExportSettings.get_file_name_mac (current_font) + ".ttf";
		
		print (@"$ttf_name == $ttf_name_mac");
		if (ttf_name == ttf_name_mac) {
			MainWindow.show_message (t_("You need to choose a different name for the TTF file with Mac adjustmets."));
			ttf_name_mac = ExportSettings.get_file_name_mac (current_font) + " Mac.ttf";
			return false;
		}
			
		return true;
	}
	
	public static void export_fonts_in_background () {
		Font f;
		
		if (suppress_event || !MainWindow.native_window.can_export ()) {
			return;
		}
		
		f = BirdFont.get_current_font ();
		
		if (f.font_file == null) {
			MainWindow.show_message (t_("You need to save your font before exporting it."));
			return;
		} 
		
		if (!validate_metadata ()) {
			return;
		}
		
		if (!ExportSettings.has_export_settings  (f)) {
			show_export_settings_tab ();
		} else {
			MenuTab.export_callback = new ExportCallback ();
			MenuTab.export_callback.export_fonts_in_background ();
			
			MenuTab.export_callback.file_exported.connect (() => {
				string first_export = Preferences.@get ("first_export_done");
				
				if (first_export == "") {
					Preferences.@set ("first_export_done", "true");
					MainWindow.show_message (t_("Congratulations to your first font!\n\n"
						+ "Please consider supporting the project by purchasing the pro version at birdfont.org.\n"));
				}
			});		
		}
	}
	
	public static bool set_suppress_event (bool e) {
		if (suppress_event && e) {
			warning ("suppress_event is already set");
			return false;
		}
		
		if (e) {
			TabContent.create_pause_surface ();
		}
		
		background_thread = e;
		suppress_event = e;
		
		// key up will be ignored if events are suppressed
		if (suppress_event) {
			IdleSource idle = new IdleSource ();
			idle.set_callback (() => {
				KeyBindings.reset ();
				return false;
			});
			idle.attach (null);
		}
		
		return true;
	}

	public override string get_label () {
		return t_("Menu");
	}
		
	public override string get_name () {
		return "Menu";
	}

	public static void select_overview () {
		if (suppress_event) {
			warn_if_test ("Event suppressed");
			return;
		}
		
		if (BirdFont.get_current_font ().is_empty ()) {
			show_default_characters ();
		} else {
			MainWindow.get_tab_bar ().add_unique_tab (new Overview ());
			MainWindow.get_tab_bar ().select_tab_name ("Overview");
		}
	}
	
	public static void clear_font_settings () {
		Toolbox.background_tools = new BackgroundTools (); // clear toolbox selection of images
	}
		
	public static void signal_file_exported () {
		IdleSource idle = new IdleSource ();
		idle.set_callback (() => {
			export_callback.file_exported ();			
			
			if (ExportTool.error_message != null) {
				MainWindow.show_message (t_("Can't create TTF font.") + "\n" + (!) ExportTool.error_message);
			}

			return false;
		});
		idle.attach (null);
	}

	public static void signal_file_saved () {
		IdleSource idle = new IdleSource ();
		idle.set_callback (() => {
			save_callback.file_saved ();
			return false;
		});
		idle.attach (null);
	}

	public static void signal_file_loaded () {
		IdleSource idle = new IdleSource ();
		idle.set_callback (() => {
			load_callback.file_loaded ();
			MainWindow.native_window.font_loaded ();
			return false;
		});
		idle.attach (null);
	}
		
	public static void apply_font_setting  (Font f) {
		DrawingTools.background_scale.set_value (f.background_scale);
		
		DrawingTools.grid_expander.tool.clear ();

		if (f.grid_width.size == 0) {
			f.grid_width.add ("1");
			f.grid_width.add ("2");
			f.grid_width.add ("4");
		}
				
		foreach (string grid in f.grid_width) {
			DrawingTools.add_new_grid (double.parse (grid), false);
		}

		string sw = f.settings.get_setting ("stroke_width");
		if (sw != ""){
			StrokeTool.stroke_width = double.parse (sw);
			DrawingTools.object_stroke.set_value_round (StrokeTool.stroke_width);
		}
		
		string pt = f.settings.get_setting ("point_type");
		DrawingTools.set_default_point_type (pt);

		string stroke = f.settings.get_setting ("apply_stroke");
		bool s = bool.parse (stroke);
		DrawingTools.add_stroke.set_selected (s);
		StrokeTool.add_stroke = s;

		string lc = f.settings.get_setting ("line_cap");
		
		if (lc == "butt") {
			StrokeTool.line_cap = LineCap.BUTT;
		} else if (lc == "square") {
			StrokeTool.line_cap = LineCap.SQUARE;
		} else if (lc == "round") {
			StrokeTool.line_cap = LineCap.ROUND;
		}
		
		DrawingTools.set_stroke_tool_visibility ();

		string lock_grid = f.settings.get_setting ("lock_grid");
		bool lg = bool.parse (lock_grid);		
		GridTool.lock_grid = lg;
		DrawingTools.lock_grid.selected = GridTool.lock_grid;

		string skew_overview = f.settings.get_setting ("skew_overview");
		if (skew_overview != "") {
			double so = double.parse (skew_overview);
			OverviewTools.skew.set_value_round (so);
		}

		string autotrace_resolution = f.settings.get_setting ("autotrace_resolution");
		if (autotrace_resolution != "") {
			double ar = double.parse (autotrace_resolution);
			DrawingTools.background_threshold.set_value_round (ar);
		}
		
		string autotrace_threshold = f.settings.get_setting ("autotrace_threshold");
		if (autotrace_threshold != "") {
			double at = double.parse (autotrace_threshold);
			DrawingTools.auto_trace_resolution.set_value_round (at);
		}	

		string autotrace_simplification = f.settings.get_setting ("autotrace_simplification");
		if (autotrace_simplification != "") {
			double asi = double.parse (autotrace_simplification);
			DrawingTools.auto_trace_simplify.set_value_round (asi);
		}
		
		string kerning_zoom = f.settings.get_setting ("kerning_zoom");
		if (kerning_zoom != "") {
			double k = double.parse (kerning_zoom);
			if (!is_null (KerningTools.zoom_bar)) {
				KerningTools.zoom_bar.zoom_level = k;
				KerningTools.zoom_bar.new_zoom (k);
			}
		}

		string spacing_zoom = f.settings.get_setting ("spacing_zoom");
		if (spacing_zoom != "") {
			double sz = double.parse (spacing_zoom);
			if (!is_null (SpacingTools.zoom_bar)) {
				SpacingTools.zoom_bar.zoom_level = sz;
				SpacingTools.zoom_bar.new_zoom (sz);
			}
		}

		MainWindow.get_toolbox ().update_expanders ();
		MainWindow.get_toolbox ().update_all_expanders ();
		Toolbox.redraw_tool_box ();
	}
	
	// FIXME: background thread
	public static void save_as_bfp () {
		FileChooser fc = new FileChooser ();
		
		if (suppress_event) {
			warn_if_test ("Event suppressed");
			return;
		}	
		
		if (!set_suppress_event (true)) {
			return;
		}
		
		fc.file_selected.connect((fn) => {
			Font f = BirdFont.get_current_font ();	
			
			if (fn != null) {
				f.init_bfp ((!) fn);
			}
			
			set_suppress_event (false);
		});
		
		MainWindow.file_chooser (t_("Save"), fc, FileChooser.SAVE);
	}
	
	public static void new_file () {
		Font font;
		SaveDialogListener dialog = new SaveDialogListener ();

		if (suppress_event) {
			warn_if_test ("Event suppressed");
			return;
		}
		
		font = BirdFont.get_current_font ();
		
		dialog.signal_discard.connect (() => {
			MainWindow.close_all_tabs ();
			
			BirdFont.new_font ();			
			MainWindow.native_window.font_loaded ();
			
			show_default_characters ();
			
			GlyphCanvas.redraw ();
		});

		dialog.signal_save.connect (() => {
			MenuTab.save_callback = new SaveCallback ();
			MenuTab.save_callback.file_saved.connect (() => {
				dialog.signal_discard ();
			});
			save_callback.save ();
		});

		dialog.signal_cancel.connect (() => {
			MainWindow.hide_dialog ();
		});
				
		if (!font.is_modified ()) {
			dialog.signal_discard ();
		} else {
			MainWindow.show_dialog (new SaveDialog (dialog));
		}
		
		return;
	}

	public static void quit () {
		if (suppress_event) {
			warn_if_test ("Event suppressed");
			return;
		}

		TabContent.hide_text_input ();

		SaveDialogListener dialog = new SaveDialogListener ();
		Font font = BirdFont.get_current_font ();
		
		Preferences.save ();
				
		dialog.signal_discard.connect (() => {
			ensure_main_loop_is_empty ();
			MainWindow.native_window.quit ();
		});

		dialog.signal_save.connect (() => {
			MenuTab.set_save_callback (new SaveCallback ());
			MenuTab.save_callback.file_saved.connect (() => {
				ensure_main_loop_is_empty ();
				MainWindow.native_window.quit ();
			});
			save_callback.save ();
		});

		dialog.signal_cancel.connect (() => {
			MainWindow.hide_dialog ();
		});
				
		if (!font.is_modified ()) {
			dialog.signal_discard ();
		} else {
			MainWindow.show_dialog (new SaveDialog (dialog));
		}
		
		MainWindow.native_window.update_window_size ();
	} 
	
	public static void show_export_settings_tab () {
		MainWindow.get_tab_bar ().add_unique_tab (new ExportSettings ());
	}
	
	public static void show_description () {
		MainWindow.get_tab_bar ().add_unique_tab (new DescriptionDisplay ());
	}
	
	public static void show_kerning_context () {
		if (suppress_event) {
			warn_if_test ("Event suppressed");
			return;
		}
		
		KerningDisplay kd = MainWindow.get_kerning_display ();
		MainWindow.get_tab_bar ().add_unique_tab (kd);
	}

	public static void show_spacing_tab () {
		if (suppress_event) {
			warn_if_test ("Event suppressed");
			return;
		}
		
		SpacingTab s = MainWindow.get_spacing_tab ();
		MainWindow.get_tab_bar ().add_unique_tab (s);
	}

	public static void show_ligature_tab () {
		if (suppress_event) {
			warn_if_test ("Event suppressed");
			return;
		}
		
		LigatureList d = MainWindow.get_ligature_display ();
		MainWindow.get_tab_bar ().add_unique_tab (d);
	}
	
	public static void preview ()  {
		Font font = BirdFont.get_current_font ();
		
		if (suppress_event) {
			warn_if_test ("Event suppressed");
			return;
		}
		
		if (font.font_file == null) {
			save_callback = new SaveCallback ();
			save_callback.file_saved.connect (() => {
				show_preview_tab ();
			});
			save_callback.save ();
		} else {
			show_preview_tab ();
		}
	}
	
	public static void show_preview_tab () {
		OverWriteDialogListener listener = new OverWriteDialogListener ();
		TabBar tab_bar = MainWindow.get_tab_bar ();
		FontFormat format = BirdFont.get_current_font ().format;
		
		if (suppress_event) {
			warn_if_test ("Event suppressed");
			return;
		}	
			
		listener.overwrite_signal.connect (() => {
			KeyBindings.set_modifier (NONE);
			tab_bar.add_unique_tab (new Preview (), true);
			PreviewTools.update_preview ();
		});
			
		if ((format == FontFormat.SVG || format == FontFormat.FREETYPE) && !OverWriteDialogListener.dont_ask_again) {
			MainWindow.show_dialog (new OverwriteDialog (listener));
		} else {
			listener.overwrite ();
		}
	}
	
	/** Display the language selection tab. */
	public static void select_language () {
		if (suppress_event) {
			warn_if_test ("Event suppressed");
			return;
		}
		
		MainWindow.get_tab_bar ().add_unique_tab (new LanguageSelectionTab ());
	}

	public static void use_current_glyph_as_background () {
		if (suppress_event) {
			warn_if_test ("Event suppressed");
			return;
		}
		
		Glyph.background_glyph = MainWindow.get_current_glyph ();
		
		if (MainWindow.get_current_display () is Overview) {
			Glyph.background_glyph = MainWindow.get_overview ().get_current_glyph ();
		}
	}
	
	public static void reset_glyph_background () {
		Glyph.background_glyph = null;
	}
	
	public static void remove_all_kerning_pairs	() {
		if (suppress_event) {
			warn_if_test ("Event suppressed");
			return;
		}
		
		KerningClasses classes = BirdFont.get_current_font ().get_kerning_classes ();
		classes.remove_all_pairs ();
		KerningTools.update_kerning_classes ();
	}
	
	public static void list_all_kerning_pairs () {
		if (suppress_event) {
			warn_if_test ("Event suppressed");
			return;
		}
		
		MainWindow.get_tab_bar ().add_unique_tab (new KerningList ());
	}
	
	public static void ensure_main_loop_is_empty () {
		unowned MainContext context;
		bool acquired;

		context = MainContext.default ();
		acquired = context.acquire ();
		
		if (unlikely (!acquired)) {
			warning ("Failed to acquire main loop.\n");
			return;
		}

		while (context.pending ()) {
			context.iteration (true);
		}
		context.release ();
	}
	
	public static void save_as ()  {
		if (MenuTab.has_suppress_event () || !save_callback.is_done) {
			warn_if_test ("Event suppressed");
			return;
		}

		MenuTab.set_save_callback (new SaveCallback ());
		MenuTab.save_callback.save_as();
	}

	public static void save ()  {
		if (MenuTab.has_suppress_event () && !save_callback.is_done) {
			warn_if_test ("Event suppressed");
			return;
		}

		MenuTab.set_save_callback (new SaveCallback ());
		MenuTab.save_callback.save ();
	}
	
	public static void load () {
		if (MenuTab.has_suppress_event ()) {
			warn_if_test ("Event suppressed");
			return;
		}

		MenuTab.load_callback = new LoadCallback ();
		MenuTab.load_callback.load ();
		
		MenuTab.load_callback.file_loaded.connect (() => {
			Font f = BirdFont.get_current_font ();
			MenuTab.apply_font_setting (f);
		});
	}

	public static void move_to_baseline () {
		if (suppress_event) {
			warn_if_test ("Event suppressed");
			return;
		}
		
		DrawingTools.move_tool.move_to_baseline ();
	}

	public static void show_file_dialog_tab (string title, FileChooser action, bool folder) {
		FileDialogTab ft = new FileDialogTab (title, action, folder);
		MainWindow.get_tab_bar ().add_tab (ft);
	}
	
	public static void simplify_path () {
		if (suppress_event) {
			warn_if_test ("Event suppressed");
			return;
		}
		
		Task t = new Task (simplify);
		MainWindow.run_blocking_task (t);
	}
	
	private static void simplify () {
		Glyph g = MainWindow.get_current_glyph ();
		Gee.ArrayList<Path> paths = new Gee.ArrayList<Path> ();
		
		// selected objects
		foreach (Path p in g.active_paths) {
			paths.add (PenTool.simplify (p, false, PenTool.simplification_threshold));
		}
		
		// selected segments
		if (paths.size == 0) {
			foreach (Path p in g.get_all_paths ()) {
				g.add_active_path (null, p);
			}
			
			foreach (Path p in g.active_paths) {
				paths.add (PenTool.simplify (p, true, PenTool.simplification_threshold));
			}
		}
		
		g.store_undo_state ();
		
		foreach (Path p in g.active_paths) {
			g.layers.remove_path (p);
		}

		foreach (Path p in g.active_paths) {
			g.layers.remove_path (p);
		}
				
		foreach (Path p in paths) {
			g.add_path (p);
			g.add_active_path (null, p);
		}

		g.active_paths.clear ();
		g.update_view ();
	}
	
	public static void show_spacing_class_tab () {
		SpacingClassTab t = MainWindow.get_spacing_class_tab ();
		MainWindow.get_tab_bar ().add_unique_tab (t);
	}

	public static void add_ligature () {
		TextListener listener;
		string ligature_name = "";
		
		if (suppress_event) {
			warn_if_test ("Event suppressed");
			return;
		}
		
		listener = new TextListener (t_("Name"), "", t_("Add ligature"));
		
		listener.signal_text_input.connect ((text) => {
			ligature_name = text;
		});
		
		listener.signal_submit.connect (() => {
			Font font = BirdFont.get_current_font ();
			GlyphCollection? fg;
			Glyph glyph;
			GlyphCollection glyph_collection;
			Overview o = MainWindow.get_overview ();

			fg = font.get_glyph_collection_by_name (ligature_name);

			if (fg == null) {
				glyph_collection = new GlyphCollection ('\0', ligature_name);
				
				glyph = new Glyph (ligature_name, '\0');
				glyph_collection.set_unassigned (true);
				glyph_collection.insert_glyph (glyph, true);

				font.add_glyph_collection (glyph_collection);
			}
			
			o.display_all_available_glyphs ();
			o.scroll_to_glyph (ligature_name);
			
			TabContent.hide_text_input ();
			show_all_available_characters ();
		});
		
		TabContent.show_text_input (listener);
	}
	
	public static void show_default_characters () {
		MainWindow.get_tab_bar ().add_unique_tab (new Overview ());
		Overview o = MainWindow.get_overview ();
		GlyphRange gr = new GlyphRange ();

		if (!BirdFont.get_current_font ().initialised) {
			MenuTab.new_file ();
		}
			
		DefaultCharacterSet.use_default_range (gr);
		o.set_current_glyph_range (gr);

		MainWindow.get_tab_bar ().select_tab_name ("Overview");
	}
	
	public static void show_all_available_characters () {
		MainWindow.get_tab_bar ().add_unique_tab (new Overview ());
		
		if (!BirdFont.get_current_font ().initialised) {
			MenuTab.new_file ();
		}
		
		MainWindow.get_tab_bar ().select_tab_name ("Overview");
		OverviewTools.show_all_available_characters ();
	}
	
	public static void show_background_tab () {
		BackgroundTab bt;
		
		if (suppress_event) {
			warn_if_test ("Event suppressed");
			return;
		}
		
		bt = BackgroundTab.get_instance ();
		MainWindow.get_tab_bar ().add_unique_tab (bt);
	}
	
	public static void show_settings_tab () {
		MainWindow.get_tab_bar ().add_unique_tab (new SettingsTab ());
	}

	public static void show_theme_tab () {
		MainWindow.get_tab_bar ().add_unique_tab (new ThemeTab ());
	}
	
	public static void show_guide_tab () {
		MainWindow.get_tab_bar ().add_unique_tab (new GuideTab ());
	}	
}

}
