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

public class ClipTool : Tool {

	public static void copy () {
		FontDisplay fd = MainWindow.get_current_display ();
		string svg_data;
		string bf_data;
		string data;
		
		if (fd is Glyph) {
			svg_data = ExportTool.export_selected_paths_to_svg ();
			bf_data = export_selected_paths_to_birdfont_clipboard ();
			data = svg_data + bf_data;
			MainWindow.native_window.set_clipboard (data);
			MainWindow.native_window.set_inkscape_clipboard (data);
		}
	}

	public static void paste_in_place () {
		paste_paths ();
	}
	
	/** Paste at cursor. */
	public static void paste () {
		Glyph g = MainWindow.get_current_glyph ();
		double x, y, w, h;
		double dx, dy;
		
		paste_paths ();
		
		g.selection_boundries (out x, out y, out w, out h);
		
		dx = g.motion_x - x - w / 2.0;
		dy = g.motion_y - y + h / 2.0;
		
		foreach (Path path in g.active_paths) {
			path.move (dx, dy);
		}
	}
	
	static void paste_paths () {
		bool is_bf_clipboard;
		FontDisplay fd;
		string clipboard_data = MainWindow.native_window.get_clipboard_data ();
		
		fd = MainWindow.get_current_display ();
		
		// Determine if clipboard contains data in birdfont format.
		is_bf_clipboard = clipboard_data.index_of ("BirdFontClipboard") > -1; 

		if (fd is Glyph) {
			paste_to_glyph (is_bf_clipboard);
		}
	}
	
	static void paste_to_glyph (bool bf_clipboard_data) {
		FontDisplay fd = MainWindow.get_current_display ();
		Glyph? destination = null;
		string data;
		PathList new_paths;
		return_if_fail (fd is Glyph);
		
		destination = (Glyph) fd;
		((!)destination).store_undo_state ();
		((!)destination).clear_active_paths ();
		
		data = MainWindow.native_window.get_clipboard_data ();

		if (bf_clipboard_data) {
			import_birdfont_clipboard (data);
		} else if (data != "") {
			new_paths = ImportSvg.import_svg_data (data);
			foreach (Path p in new_paths.paths) {
				((!)destination).active_paths.append (p);
			}
		}
		
		((!)destination).update_view ();			
	}

	static string export_selected_paths_to_birdfont_clipboard () {
		Glyph glyph = MainWindow.get_current_glyph ();
		StringBuilder s = new StringBuilder ();
		
		s.append ("\n");
		s.append ("<!-- BirdFontClipboard\n");
		
		foreach (Path path in glyph.active_paths) {
			s.append ("BF path: ");
			s.append (BirdFontFile.get_point_data (path));
			s.append ("\n");
		}
		
		s.append ("-->");
		
		return s.str;
	}
	
	static void import_birdfont_clipboard (string data) {
		string[] paths = data.split ("\nBF ");
		string d;
		int i;
		
		foreach (string p in paths) {
			if (p.has_prefix ("path:")) {
				i = p.index_of ("\n");
				if (i > -1) {
					p = p.substring (0, i);
				}
				d = p.replace ("path: ", "");
				import_birdfont_path (d);
			}
		}	
	}
	
	static void import_birdfont_path (string data) {
		Glyph glyph = MainWindow.get_current_glyph ();
		Path path = BirdFontFile.parse_path_data (data);
		path.close ();
		glyph.add_path (path);
		glyph.active_paths.append (path);
	}
}

}
