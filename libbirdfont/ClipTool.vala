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

namespace BirdFont {

public class ClipTool : Tool {

	static List<Path> internal_clipboard = new List<Path> ();

	public static void copy () {
		FontDisplay fd = MainWindow.get_current_display ();
		NativeWindow native_window;
		string svg;
		string inkscape_svg;
		string stamp = "\n<!-- BirdFontClipboard -->\n";
		
		if (fd is OverView) {
			// TODO: copy glyphs in overview
		} 
		
		if (fd is Glyph) {	
			// the internal clipboard contains data in .bf format and the 
			// external clibboard contains inkscape compatible vector graphics
			while (internal_clipboard.length () > 0) {
				internal_clipboard.remove_link (internal_clipboard.first ());
			}
			
			foreach (Path p in ((Glyph) fd).active_paths) {
				internal_clipboard.append (p.copy ());
			}
		
			native_window = MainWindow.native_window;
			
			// copy only if paths have been selected
			if (MainWindow.get_current_glyph ().active_paths.length () == 0) {
				return;
			}
			
			// there is only one clipboard in windows
			if (!BirdFont.win32) {
				svg = ExportTool.export_selected_paths_to_svg ();
				native_window.set_clipboard (svg + stamp);
			}
			
			inkscape_svg = ExportTool.export_selected_paths_to_inkscape_clipboard ();
			native_window.set_inkscape_clipboard (inkscape_svg + stamp);
		}

	}

	public static void paste () {
		bool internal;
		FontDisplay fd;
		
		fd = MainWindow.get_current_display ();
		
		// Determine if the data in clipboard belongs to BirdFont.
		internal = MainWindow.native_window.get_clipboard_data ().index_of ("BirdFontClipboard") > -1; 
		
		if (fd is Glyph) {
			paste_to_glyph (internal);
		}
	}
	
	
	public static void paste_to_glyph (bool internal) {
		FontDisplay fd = MainWindow.get_current_display ();
		Glyph? destination = null;
		string svg;
		
		return_if_fail (fd is Glyph);
		
		destination = (Glyph) fd;
		((!)destination).store_undo_state ();
		
		if (internal) {
			foreach (Path p in internal_clipboard) {
				((!)destination).add_path (p);
			}
		} else {
			svg = MainWindow.native_window.get_clipboard_data ();
			if (svg != "") {
				ImportSvg.import_svg_data (svg);
			}
		}
		
		((!)destination).update_view ();			
	}

}

}
