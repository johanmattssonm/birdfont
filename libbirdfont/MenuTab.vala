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
	public static bool suppress_event;

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
	
	public static void export_fonts_in_background () {
		if (suppress_event || MainWindow.native_window.can_export ()) {
			warning ("suppress_event is already set");
			return false;
		}
		
		MenuTab.export_callback = new ExportCallback ();
		MenuTab.export_callback.export_fonts_in_background ();
	}
	
	public static bool set_suppress_event (bool e) {
		if (suppress_event && e) {
			warning ("suppress_event is already set");
			return false;
		}
		background_thread = e;
		suppress_event = e;
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
			MainWindow.get_tab_bar ().add_unique_tab (new OverView ());
			MainWindow.get_tab_bar ().select_tab_name ("Overview");
		}
	}
	
	public static void signal_file_exported () {
		IdleSource idle = new IdleSource ();
		idle.set_callback (() => {
			export_callback.file_exported ();
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
		
	public static void set_font_setting_from_tools (Font f) {	
		f.background_scale = DrawingTools.background_scale.get_display_value ();
		
		f.grid_width.clear ();
		
		foreach (SpinButton s in GridTool.sizes) {
			f.grid_width.add (s.get_display_value ());
		}
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
		
		if (!font.is_modified ()) {
			dialog.signal_discard ();
		} else {
			MainWindow.native_window.set_save_dialog (dialog);
		}
		
		return;
	}

	public static void quit () {
		if (suppress_event) {
			warn_if_test ("Event suppressed");
			return;
		}

		MainWindow.native_window.hide_text_input ();

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
		
		if (!font.is_modified ()) {
			dialog.signal_discard ();
		} else {
			MainWindow.native_window.set_save_dialog (dialog);
		}
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
		OverWriteDialogListener dialog = new OverWriteDialogListener ();
		TabBar tab_bar = MainWindow.get_tab_bar ();
		FontFormat format = BirdFont.get_current_font ().format;
		
		if (suppress_event) {
			warn_if_test ("Event suppressed");
			return;
		}	
			
		dialog.overwrite_signal.connect (() => {
			tab_bar.add_unique_tab (new Preview (), true);
			PreviewTools.update_preview ();
		});
			
		if ((format == FontFormat.SVG || format == FontFormat.FREETYPE) && !OverWriteDialogListener.dont_ask_again) {
			MainWindow.native_window.set_overwrite_dialog (dialog);
		} else {
			dialog.overwrite ();
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
		
		if (MainWindow.get_current_display () is OverView) {
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
		MenuTab.set_save_callback (new SaveCallback ());
		MenuTab.save_callback.save_as();
	}

	public static void save ()  {
		MenuTab.set_save_callback (new SaveCallback ());
		MenuTab.save_callback.save ();
	}
	
	public static void load () {
		MenuTab.load_callback = new LoadCallback ();
		MenuTab.load_callback.load ();
	}

	public static void move_to_baseline () {
		if (suppress_event) {
			warn_if_test ("Event suppressed");
			return;
		}
		
		DrawingTools.move_tool.move_to_baseline ();
	}

	public static void show_file_dialog_tab (string title, FileChooser action) {
		MainWindow.get_tab_bar ().add_tab (new FileDialogTab (title, action));
	}
	
	public static void simplify_path () {
		Task t = new Task ();
		t.task.connect (simplify);
		MainWindow.native_window.run_background_thread (t);
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
			foreach (Path p in g.path_list) {
				g.add_active_path (p);
			}
			
			foreach (Path p in g.active_paths) {
				paths.add (PenTool.simplify (p, true, PenTool.simplification_threshold));
			}
		}
		
		g.store_undo_state ();
		
		foreach (Path p in g.active_paths) {
			g.path_list.remove (p);
		}

		foreach (Path p in g.active_paths) {
			g.path_list.remove (p);
		}
				
		foreach (Path p in paths) {
			g.add_path (p);
			g.add_active_path (p);
		}

		g.active_paths.clear ();
		g.update_view ();
	}
	
	public static void show_spacing_tab () {
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
			OverView o = MainWindow.get_overview ();

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
			
			MainWindow.native_window.hide_text_input ();
			show_all_available_characters ();
		});
		
		MainWindow.native_window.set_text_listener (listener);
	}
	
	public static void show_default_characters () {
		MainWindow.get_tab_bar ().add_unique_tab (new OverView ());
		OverView o = MainWindow.get_overview ();
		GlyphRange gr = new GlyphRange ();

		if (!BirdFont.get_current_font ().initialised) {
			MenuTab.new_file ();
		}
			
		DefaultCharacterSet.use_default_range (gr);
		o.set_glyph_range (gr);

		MainWindow.get_tab_bar ().select_tab_name ("Overview");
	}
	
	public static void show_all_available_characters () {
		MainWindow.get_tab_bar ().add_unique_tab (new OverView ());
		
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
		MainWindow.get_tab_bar ().add_unique_tab (new SettingsDisplay ());
	}
}

}
