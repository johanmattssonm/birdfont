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
		paste_paths (true);
	}
	
	/** Paste at cursor. */
	public static void paste () {
		FontDisplay fd = MainWindow.get_current_display ();
		Glyph g = MainWindow.get_current_glyph ();
		double x, y, w, h;
		double dx, dy;
		
		if (fd is Glyph) {
			paste_paths (false);
			
			g.selection_boundaries (out x, out y, out w, out h);
			
			dx = g.motion_x - x - w / 2.0;
			dy = g.motion_y - y + h / 2.0;
			
			foreach (Path path in g.active_paths) {
				path.move (dx, dy);
			}
		}
		
		if (fd is KerningDisplay) {
			paste_letters_to_kerning_tab ();
		}
	}
	
	static void paste_paths (bool paste_guide_lines) {
		bool is_bf_clipboard;
		FontDisplay fd;
		string clipboard_data = MainWindow.native_window.get_clipboard_data ();
		
		fd = MainWindow.get_current_display ();
		
		// Determine if clipboard contains data in birdfont format.
		is_bf_clipboard = clipboard_data.index_of ("BirdFontClipboard") > -1; 

		if (fd is Glyph) {
			paste_to_glyph (is_bf_clipboard, paste_guide_lines);
		}
		
		BirdFont.get_current_font ().touch ();
	}
	
	static void paste_to_glyph (bool bf_clipboard_data, bool paste_guide_lines) {
		FontDisplay fd = MainWindow.get_current_display ();
		Glyph? destination = null;
		string data;
		return_if_fail (fd is Glyph);
		
		destination = (Glyph) fd;
		((!)destination).store_undo_state ();
		((!)destination).clear_active_paths ();
		
		data = MainWindow.native_window.get_clipboard_data ();

		if (bf_clipboard_data) {
			import_birdfont_clipboard (data, paste_guide_lines);
		} else if (data != "") {
			SvgParser.import_svg_data (data);
		}
		
		((!)destination).update_view ();			
	}

	static string export_selected_paths_to_birdfont_clipboard () {
		Glyph glyph = MainWindow.get_current_glyph ();
		StringBuilder s = new StringBuilder ();
		Path new_path;
		List<Path> paths = new List<Path> ();
		
		s.append ("\n");
		s.append ("<!-- BirdFontClipboard\n");

		s.append ("BF left: ");
		s.append (@"$(glyph.left_limit)");
		s.append ("\n");
		
		s.append ("BF right: ");
		s.append (@"$(glyph.right_limit)");
		s.append ("\n");
								
		if (glyph.path_list.size > 0) {
			foreach (Path path in glyph.active_paths) {
				s.append ("BF path: ");
				s.append (BirdFontFile.get_point_data (path));
				s.append ("\n");
			}
		} else {
			
			new_path = new Path ();
			foreach (Path path in glyph.path_list) {
				if (path.points.size > 0
					&& path.points.get (0).is_selected ()
					&& path.points.get (path.points.size - 1).is_selected ()) {
					
					foreach (EditPoint ep in path.points) {
						if (!ep.is_selected ()) {
							path.set_new_start (ep);
							break;
						}	
					}
				}
				
				foreach (EditPoint ep in path.points) {
					if (!ep.is_selected ()) {
						if (path.points.size > 0) {
							paths.append (new_path);
							new_path = new Path ();
						}
					} else {
						new_path.add_point (ep);
					}
				}

				if (all_points_selected (path)) {
					new_path.close ();
				}
			}
			
			paths.append (new_path);
			
			foreach (Path path in paths) {
				if (path.points.size > 0) {
					s.append ("BF path: ");
					s.append (BirdFontFile.get_point_data (path));
					s.append ("\n");
				}
			}
		}
		
		s.append ("-->");
		
		return s.str;
	}
	
	static bool all_points_selected (Path p) {
		foreach (EditPoint ep in p.points) {
			if (!ep.is_selected ()) {
				return false;
			}
		}
		return true;
	}
	
	static void import_birdfont_clipboard (string data, bool paste_guide_lines) {
		Glyph glyph = MainWindow.get_current_glyph ();
		string[] items = data.split ("\nBF ");
		string d;
		int i;
		
		foreach (string p in items) {
			if (p.has_prefix ("path:")) {
				i = p.index_of ("\n");
				if (i > -1) {
					p = p.substring (0, i);
				}
				d = p.replace ("path: ", "");
				import_birdfont_path (d);
			}
			
			if (paste_guide_lines && p.has_prefix ("left:")) {
				glyph.left_limit = double.parse (p.replace ("left: ", ""));
				glyph.remove_lines ();
				glyph.add_help_lines ();			
			}
			
			if (paste_guide_lines && p.has_prefix ("right:")) {
				glyph.right_limit = double.parse (p.replace ("right: ", ""));
				glyph.remove_lines ();
				glyph.add_help_lines ();	
			}
		}	
	}
	
	static void import_birdfont_path (string data) {
		Glyph glyph = MainWindow.get_current_glyph ();
		Path path = BirdFontFile.parse_path_data (data);

		if (path.points.size > 0) {
			glyph.add_path (path);
			glyph.active_paths.add (path);
			path.update_region_boundaries ();
		}
		
		PenTool.remove_all_selected_points ();
		
		foreach (Path p in glyph.active_paths) {
			if (p.is_open ()) {
				foreach (EditPoint e in p.points) {
					e.set_selected (true);
				}
			}
		}
		
		PenTool.update_selection ();
	}
	
	static void paste_letters_to_kerning_tab () {
		string clipboard_data = MainWindow.native_window.get_clipboard_data ();
		KerningDisplay kerning_display = MainWindow.get_kerning_display ();
		
		if (!clipboard_data.has_prefix ("<?xml")) {
			kerning_display.add_text (clipboard_data);
		}
	}
}

}
