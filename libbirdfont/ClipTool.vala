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

	public static void copy () {
		FontDisplay fd = MainWindow.get_current_display ();
		NativeWindow native_window;
		string svg;
		string inkscape_svg;
		
		if (fd is OverView) {
			// TODO: copy glyphs in overview
		} 
		
		if (fd is Glyph) {	
			native_window = MainWindow.native_window;
			
			// copy only if paths are selected
			if (MainWindow.get_current_glyph ().active_paths.length () == 0) {
				return;
			}
			
			// several clipboards does not work on windows
			if (!BirdFont.win32) {
				svg = ExportTool.export_selected_paths_to_string ();
				native_window.set_clipboard (svg);
			}
			
			inkscape_svg = ExportTool.export_selected_paths_to_inkscape_clipboard ();
			native_window.set_inkscape_clipboard (inkscape_svg);
		}

	}

	public static void paste () {
		FontDisplay fd = MainWindow.get_current_display ();
		Glyph? destination = null;
		string svg;

		// paste from clipboard		
		if (fd is Glyph) {
			destination = (Glyph) fd;
			
			((!)destination).store_undo_state ();
			
			svg = MainWindow.native_window.get_clipboard_data ();
			
			if (svg != "") {
				ImportSvg.import_svg_data (svg);
			}
			
			((!)destination).update_view ();
		}
	}

}

}
