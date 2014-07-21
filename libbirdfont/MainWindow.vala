/*
    Copyright (C) 2012 Johan Mattsson

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
	public static FileTab file_tab;
	public static TooltipArea tooltip;
	public static OverView over_view;	
	public static TabBar tabs;
	public static NativeWindow native_window;
	public static KerningDisplay kerning_display;
	public static CharDatabase character_database;
	public static LigatureList ligature_display;
	
	/** Number of pixels per mm */
	public static double units = 1;

	public MainWindow () {
		singleton = this;
		
		glyph_canvas = new GlyphCanvas ();
		tabs = new TabBar ();
		tools = new Toolbox (glyph_canvas, tabs);
		menu_tab = new MenuTab ();
		file_tab = new FileTab ();
		tooltip = new TooltipArea ();
		over_view = new OverView();
		kerning_display = new KerningDisplay ();
		character_database = new CharDatabase ();
		ligature_display = new LigatureList ();
	}

	/** Set the number of picels per millimeter for the current screen. */
	public static void set_units_per_pixel (double u) {
		MainWindow.units = u;
	}

	public static void init () {
		singleton = new MainWindow ();
	}

	public static FileTab get_recent_files_tab () {
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
			Toolbox.select_tool_by_name ("move");
		}

		get_current_glyph ().select_all_paths ();
	}

	public static DrawingTools get_drawing_tools () {
		return tools.drawing_tools;
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
	
	public static Glyph get_current_glyph () {
		if (unlikely (is_null (BirdFont.current_glyph))) {
			warning ("No default glyph have been set yet.\n");
			return new Glyph ("no_glyph_created");
		}
		
		return BirdFont.current_glyph;
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

	public static TooltipArea get_tooltip () {
		return tooltip;
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
	
	public static void update_glyph_sequence () {
		TextListener listener = new TextListener (t_("Glyph sequence"), Preferences.get ("glyph_sequence"), t_("Close"));
		listener.signal_text_input.connect ((text) => {
			Preferences.set ("glyph_sequence", text);
			GlyphCanvas.redraw ();
		});
		listener.signal_submit.connect (() => {
			MainWindow.native_window.hide_text_input ();
		});
		native_window.set_text_listener (listener);
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
}

}
