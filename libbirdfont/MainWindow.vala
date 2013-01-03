/*
    Copyright (C) 2012 Johan Mattsson

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

namespace Supplement {

public class MainWindow {
	
	public static Toolbox tools;
	public static GlyphCanvas glyph_canvas;
	public static MainWindow singleton;
	public static KeyBindings key_bindings;
	public static MenuTab menu_tab;
	public static TooltipArea tool_tip;
	public static OverView over_view;	
	public static TabBar tabs;
	public static NativeWindow native_window;

	public MainWindow () {
		singleton = this;
		
		key_bindings = new KeyBindings ();
		glyph_canvas = new GlyphCanvas ();
		tools = new Toolbox (glyph_canvas);
		tabs = new TabBar ();
		menu_tab = new MenuTab ();
		tool_tip = new TooltipArea ();
		over_view = new OverView();
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
		if (unlikely (is_null (Supplement.current_glyph))) {
			warning ("No default glyph have been set yet.\n");
			return new Glyph ("no_glyph_created");
		}
		
		return Supplement.current_glyph;
	}
	
	public static Toolbox get_toolbox () {
		return tools;
	}
	
	internal static Tool get_tool (string n) {
		return tools.get_tool (n);
	}
	
	public static TabBar get_tab_bar () {
		return tabs;
	}

	internal static Tab get_current_tab () {
		return tabs.get_selected_tab ();
	}

	internal static TooltipArea get_tool_tip () {
		return tool_tip;
	}

	internal static bool select_tab (Tab t) {
		return tabs.selected_open_tab (t);
	}

	internal static OverView get_overview () {
		OverView over_view;
		
		foreach (var t in tabs.tabs) {
			if (t.get_display () is OverView) {
				return (OverView) t.get_display ();
			}
		}
		
		over_view = new OverView();
		tabs.add_unique_tab (over_view, 100, false);
				
		return over_view;
	}
	
	public static MainWindow get_singleton () {
		return singleton;
	}
	
	public static string? file_chooser (string title) {
		return MainWindow.native_window.file_chooser (title);
	}
	
	public void set_title (string title) {
		// FIXA:
		// native_window.set_title (title);
	}
	
	/** Reaload all paths and help lines from disk. */
	internal static void clear_glyph_cache () {
		Glyph g;
		foreach (Tab t in get_tab_bar ().tabs) {
			if (t.get_display () is Glyph) {
				g = (Glyph) t.get_display ();
				g.add_help_lines ();
			}
		}
		
		get_glyph_canvas ().redraw ();
	}
		
	internal static void close_all_tabs () {
		uint i = 0;
		uint len = get_tab_bar ().get_length ();
		
		while (i < len) {
			if (!get_tab_bar ().close_tab ((int) i)) {
				i++;
			}
		}
	}
}

}
