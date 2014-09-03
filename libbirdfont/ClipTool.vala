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
		
		if (fd is OverView) {
			copy_overview_glyphs ();
		}			
	}

	/** Copy entire glyph. */
	public static void copy_glyph (Glyph glyph) {
		string svg_data;
		string bf_data;
		string data;
			
		svg_data = ExportTool.export_to_inkscape_clipboard (glyph, false);
		bf_data = export_paths_to_birdfont_clipboard (false, false);
		
		data = svg_data + bf_data;
		MainWindow.native_window.set_clipboard (data);
		MainWindow.native_window.set_inkscape_clipboard (data);	
	}

	public static void copy_overview_glyphs () {
		string svg_data = "";
		string bf_data = "";
		string data;
		OverView o = MainWindow.get_overview ();
		
		if (o.selected_items.size > 0) {
			svg_data = ExportTool.export_to_inkscape_clipboard (
				o.selected_items.get (0).get_current (), false);

			bf_data = export_paths_to_birdfont_clipboard (true, false);
			
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
		
		if (fd is OverView) {
			paste_to_overview ();
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
	
	static void paste_to_overview () {
		string data = MainWindow.native_window.get_clipboard_data ();
		import_birdfont_clipboard (data, true, true);
		GlyphCanvas.redraw ();
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
			import_birdfont_clipboard (data, paste_guide_lines, false);
		} else if (data != "") {
			SvgParser.import_svg_data (data, SvgFormat.INKSCAPE);
		}
		
		((!)destination).update_view ();	
	}

	static string export_selected_paths_to_birdfont_clipboard () {
		return export_paths_to_birdfont_clipboard (false, true);
	}
	
	static string export_paths_to_birdfont_clipboard (bool overview, bool selected = false) {
		StringBuilder s = new StringBuilder ();
		Gee.ArrayList<Path> paths = new Gee.ArrayList<Path> ();
		Path new_path;
		Glyph glyph;
		OverView o;
		
		if (overview) {
			o = MainWindow.get_overview ();
			foreach (GlyphCollection gc in o.selected_items) {
				s.append ("\n");
				s.append ("<!-- BirdFontClipboard\n");

				s.append ("BF glyph: ");
				s.append (@"$(Font.to_hex (gc.get_unicode_character ()))");
				s.append ("\n");
				
				s.append ("BF left: ");
				s.append (@"$(gc.get_current ().left_limit)");
				s.append ("\n");
				
				s.append ("BF right: ");
				s.append (@"$(gc.get_current ().right_limit)");
				s.append ("\n");

				foreach (Path path in gc.get_current ().path_list) {
					s.append ("BF path: ");
					s.append (BirdFontFile.get_point_data (path));
					s.append ("\n");
				}
				
				s.append ("BF end -->");
			}
		} else {
			glyph = MainWindow.get_current_glyph ();
			
			s.append ("\n");
			s.append ("<!-- BirdFontClipboard\n");

			s.append ("BF glyph: ");
			s.append (@"$(Font.to_hex (glyph.unichar_code))");
			s.append ("\n");
			
			s.append ("BF left: ");
			s.append (@"$(glyph.left_limit)");
			s.append ("\n");
			
			s.append ("BF right: ");
			s.append (@"$(glyph.right_limit)");
			s.append ("\n");
									
			if (!selected) {
				foreach (Path path in glyph.path_list) {
					s.append ("BF path: ");
					s.append (BirdFontFile.get_point_data (path));
					s.append ("\n");
				}
			} else if (glyph.path_list.size > 0) {
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
								paths.add (new_path);
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
				
				paths.add (new_path);
				
				foreach (Path path in paths) {
					if (path.points.size > 0) {
						s.append ("BF path: ");
						s.append (BirdFontFile.get_point_data (path));
						s.append ("\n");
					}
				}
			}
			
			s.append ("BF end -->");
		}
		
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
	
	static void import_birdfont_clipboard (string data, bool paste_guide_lines, bool overview) {
		Gee.ArrayList<Glyph> glyphs = new Gee.ArrayList<Glyph> ();
		Glyph glyph = new Glyph ("null", '\0');
		string[] items = data.split ("\nBF ");
		string d;
		int i;
		unichar c;
		Glyph destination;
		GlyphCollection gc;
		OverView o;
		
		foreach (string p in items) {
			if (p.has_prefix ("glyph:")) {
				p = p.replace ("glyph: ", "");
				p = p.replace ("\n", "");
				c = Font.to_unichar (p);
				glyph = new Glyph ((!) c.to_string (), c);
				glyphs.add (glyph);
			}
			
			if (p.has_prefix ("path:")) {
				p = p.replace ("path: ", "");
				p = p.replace ("\n", "");
				import_birdfont_path (glyph, p);
			}
			
			if (p.has_prefix ("left:")) {
				glyph.left_limit = double.parse (p.replace ("left: ", ""));
				glyph.remove_lines ();
				glyph.add_help_lines ();			
			}
			
			if (p.has_prefix ("right:")) {
				glyph.right_limit = double.parse (p.replace ("right: ", ""));
				glyph.remove_lines ();
				glyph.add_help_lines ();	
			}
		}
		
		if (!overview) {
			return_if_fail (glyphs.size > 0);
			destination = MainWindow.get_current_glyph ();
			glyph = glyphs.get (0);
			
			foreach (Path p in glyph.path_list) {
				destination.add_path (p);
				destination.add_active_path (p);
			}
			
			if (paste_guide_lines) {
				destination.left_limit = glyph.left_limit;
				destination.right_limit = glyph.right_limit;
				destination.add_help_lines ();
				destination.update_other_spacing_classes ();
			}
		} else {
			o = MainWindow.get_overview ();
			o.copied_glyphs.clear ();
			foreach (Glyph g in glyphs) {	
				gc = new GlyphCollection (g.unichar_code, g.name);
				gc.add_glyph (g);
				o.copied_glyphs.add (gc);
			}
			o.paste ();
		}
	}
	
	static void import_birdfont_path (Glyph glyph, string data) {
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
