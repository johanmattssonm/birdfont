/*
    Copyright (C) 2012 2014 Johan Mattsson

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

public class MainWindow : GLib.Object {
	
	public static Toolbox tools;
	public static GlyphCanvas glyph_canvas;
	public static MainWindow singleton;
	public static MenuTab menu_tab;
	public static RecentFiles file_tab;
	public static OverView over_view;	
	public static TabBar tabs;
	public static NativeWindow native_window;
	public static KerningDisplay kerning_display;
	public static CharDatabase character_database;
	public static LigatureList ligature_display;
	public static SpacingClassTab spacing_class_tab;
	public static AbstractMenu menu;
	public static Dialog dialog;
	public static SpacingTab spacing_tab;
	
	/** Number of pixels per mm */
	public static double units = 1;

	public MainWindow () {
		singleton = this;
		
		glyph_canvas = new GlyphCanvas ();
		tabs = new TabBar ();
		tools = new Toolbox (glyph_canvas, tabs);
		menu_tab = new MenuTab ();
		file_tab = new RecentFiles ();
		over_view = new OverView();
		kerning_display = new KerningDisplay ();
		character_database = new CharDatabase ();
		ligature_display = new LigatureList ();
		spacing_class_tab = new SpacingClassTab ();
		menu = new Menu ();
		dialog = new Dialog ();
		spacing_tab = new SpacingTab ();
		
		tools.select_tool (DrawingTools.bezier_tool);
	}

	public static SpacingTab get_spacing_tab () {
		return spacing_tab;
	}

	public static Dialog get_dialog () {
		return dialog;
	}

	public static void show_dialog (Dialog d) 
	requires (!is_null(MainWindow.get_tab_bar ())) {
		Tab t = MainWindow.get_tab_bar ().get_selected_tab ();
		string tab_name = t.get_display ().get_name ();
		
		if (tab_name == "Preview") {
			MenuTab.select_overview ();
		}
				
		dialog = d;
		dialog.visible = true;
		GlyphCanvas.redraw ();
		
		set_cursor (NativeWindow.VISIBLE);
	}

	public static void set_cursor (int flags) {
		if (BirdFont.has_argument ("--test")) {
			if (dialog.visible) {
				native_window.set_cursor (NativeWindow.VISIBLE);
			} else {
				native_window.set_cursor (flags);
			}
		}
	}

	public static void show_message (string text) {
		show_dialog (new MessageDialog (text));
	}

	public static void hide_dialog () {
		dialog = new Dialog ();
		dialog.visible = false;
		GlyphCanvas.redraw ();
	}

	public static void set_menu (AbstractMenu m) {
		menu = m;
	}
	
	public static AbstractMenu get_menu () {
		return menu;
	}

	/** Set the number of pixels per millimeter for the current screen. */
	public static void set_units_per_pixel (double u) {
		MainWindow.units = u;
	}

	public static void init () {
		singleton = new MainWindow ();
	}

	public static RecentFiles get_recent_files_tab () {
		return file_tab;
	}
	
	public static void open_recent_files_tab () {
		// FIXME: do not idle 
		IdleSource idle = new IdleSource ();
		tabs.add_unique_tab (file_tab);
		idle.set_callback (() => {			
			tabs.select_tab_name ("Files");
			return false;
		});
		idle.attach (null);
	}

	public static void select_all_paths () {
		Tool t = tools.get_current_tool ();
		
		if (! (t is MoveTool || t is ResizeTool)) {
			get_toolbox ().select_tool (DrawingTools.move_tool);
		}

		IdleSource idle = new IdleSource (); 
		idle.set_callback (() => {
			DrawingTools.move_tool.select_all_paths ();
			return false;
		});
		idle.attach (null);
	}

	public static DrawingTools get_drawing_tools () {
		return Toolbox.drawing_tools;
	}

	public void set_native (NativeWindow nw) {
		native_window = nw;
	}
	 
	public static FontDisplay get_current_display () {
		return get_glyph_canvas ().get_current_display ();
	}
	
	public static GlyphCanvas get_glyph_canvas () {
		return glyph_canvas;
	}

	public static GlyphCollection get_current_glyph_collection () {
		if (unlikely (is_null (BirdFont.current_glyph_collection))) {
			GlyphCollection gc;
			
			warning ("No default glyph have been set yet.\n");
			gc = new GlyphCollection ('\0', "");
			gc.add_glyph (new Glyph ("", '\0'));
			
			return gc;
		}
		
		return BirdFont.current_glyph_collection;
	}
		
	public static Glyph get_current_glyph () {
		return get_current_glyph_collection ().get_current ();
	}
	
	public static Toolbox get_toolbox () {
		return tools;
	}
	
	public static Tool get_tool (string n) {
		return tools.get_tool (n);
	}
	
	public static TabBar get_tab_bar () {
		return tabs;
	}

	public static Tab get_current_tab () {
		return tabs.get_selected_tab ();
	}

	public static bool select_tab (Tab t) {
		return tabs.selected_open_tab (t);
	}

	public static OverView get_overview () {
		OverView over_view;
		
		foreach (var t in tabs.tabs) {
			if (t.get_display () is OverView) {
				return (OverView) t.get_display ();
			}
		}
		
		over_view = new OverView();
		tabs.add_unique_tab (over_view);
					
		return over_view;
	}
	
	public static SpacingClassTab get_spacing_class_tab () {
		return spacing_class_tab;
	}
	
	public static void update_glyph_sequence () {
		TextListener listener = new TextListener (t_("Glyph sequence"), Preferences.get ("glyph_sequence"), t_("Close"));
		listener.signal_text_input.connect ((text) => {
			Preferences.set ("glyph_sequence", text);
			GlyphCanvas.redraw ();
		});
		listener.signal_submit.connect (() => {
			TabContent.hide_text_input ();
		});
		TabContent.show_text_input (listener);
	}
	
	public static MainWindow get_singleton () {
		return singleton;
	}
	
	public static void file_chooser (string title, FileChooser fc, uint flags) {		
		MainWindow.native_window.file_chooser (title, fc, flags);
	}
	
	public static void set_scrollbar_size (double size) {
		if (!is_null (MainWindow.native_window)) {
			MainWindow.native_window.set_scrollbar_size (size);
		}
	}
	
	public static void set_scrollbar_position (double position) {
		if (!is_null (MainWindow.native_window)) {
			MainWindow.native_window.set_scrollbar_position (position);
		}
	}

	/** Reaload all paths and help lines from disk. */
	public static void clear_glyph_cache () {
		Glyph g;
		foreach (Tab t in get_tab_bar ().tabs) {
			if (t.get_display () is Glyph) {
				g = (Glyph) t.get_display ();
				g.add_help_lines ();
			}
		}
		
		GlyphCanvas.redraw ();
	}
		
	public static void close_all_tabs () {
		get_tab_bar ().close_all_tabs ();
	}

	public static string translate (string s) {
		return t_(s);
	}
	
	public static KerningDisplay get_kerning_display () {
		return kerning_display;
	}
	
	public static LigatureList get_ligature_display () {
		return ligature_display;
	}

	public static void next_tab () {
		TabBar tb = MainWindow.get_tab_bar ();
		int n = tb.get_selected () + 1;
			
		if (!(0 <= n < tb.get_length ())) {
			return;
		}
			
		tb.select_tab (n);
	}

	public static void previous_tab () {
		TabBar tb = MainWindow.get_tab_bar ();
		int n = tb.get_selected () - 1;

		if (!(0 <= n < tb.get_length ())) {
			return;
		}
			
		tb.select_tab (n);
	}

	public static void close_tab () {
		TabBar tb = MainWindow.get_tab_bar ();
		int n = tb.get_selected ();

		if (!(0 <= n < tb.get_length ())) {
			return;
		}
		
		tb.close_tab (n);
	}
	
	public static void set_toolbox (Toolbox tb) {
		tools = tb;
	}
}

}
