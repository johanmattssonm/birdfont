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

public class MainWindow {
	
	public static Toolbox tools;
	public static GlyphCanvas glyph_canvas;
	public static MainWindow singleton;
	public static KeyBindings key_bindings;
	public static MenuTab menu_tab;
	public static FileTab file_tab;
	public static TooltipArea tool_tip;
	public static OverView over_view;	
	public static TabBar tabs;
	public static NativeWindow native_window;
	public static KerningDisplay kerning_display;
	public static CharDatabase character_database;

	public MainWindow () {
		singleton = this;
		
		key_bindings = new KeyBindings ();
		glyph_canvas = new GlyphCanvas ();
		tabs = new TabBar ();
		tools = new Toolbox (glyph_canvas, tabs);
		menu_tab = new MenuTab ();
		file_tab = new FileTab ();
		tool_tip = new TooltipArea ();
		over_view = new OverView();
		kerning_display = new KerningDisplay ();
		character_database = new CharDatabase ();
	}

	public static void open_recent_files_tab () {
		IdleSource idle = new IdleSource ();
		tabs.add_unique_tab (file_tab);
		idle.set_callback (() => {			
			tabs.select_tab_name ("Files");
			return false;
		});
		idle.attach (null);
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

	public static TooltipArea get_tool_tip () {
		return tool_tip;
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
		TextListener listener = new TextListener (_("Glyph sequence"), Preferences.get ("glyph_sequence"), _("Close"));
		listener.signal_text_input.connect ((text) => {
			Preferences.set ("glyph_sequence", text);
			get_glyph_canvas ().redraw ();
		});
		listener.signal_submit.connect (() => {
			MainWindow.native_window.hide_text_input ();
		});
		native_window.set_text_listener (listener);
	}
	
	public static MainWindow get_singleton () {
		return singleton;
	}
	
	public static string? file_chooser_save (string title) {
		return MainWindow.native_window.file_chooser_save (title);
	}

	public static string? file_chooser_open (string title) {
		return MainWindow.native_window.file_chooser_open (title);
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
		
		get_glyph_canvas ().redraw ();
	}
		
	public static void close_all_tabs () {
		uint i = 0;
		uint len = get_tab_bar ().get_length ();
		
		while (i < len) {
			if (!get_tab_bar ().close_tab ((int) i)) {
				i++;
			}
		}
	}

	public static string translate (string s) {
		return _(s);
	}
	
	public static void set_status (string s) {
		if (!is_null (tool_tip)) {
			tool_tip.show_text (s);
			Tool.yield ();
		}  
	}
	
	public static KerningDisplay get_kerning_display () {
		return kerning_display;
	}
}

}
