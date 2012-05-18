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

class ClipTool : Tool {

	static Glyph? glyph = null; 
	static Path? path = null; 

	public static void copy () {
		Font font = Supplement.get_current_font ();
		OverView overview  = MainWindow.get_overview ();
		FontDisplay fd = MainWindow.get_current_display ();
		string gc;
		
		if (fd is OverView) {
			gc = overview.get_selected_char ();
			
			print (@"SELECTED: $gc \n");
			
			glyph = font.get_glyph (gc);
			path = null;
		}

		if (fd is Glyph) {
			glyph = null;
			path = MainWindow.get_current_glyph ().active_path;
			
			if (path == null) {
				glyph = MainWindow.get_current_glyph ();
			}
		}

	}

	public static void paste () {
		Font font = Supplement.get_current_font ();
		OverView overview  = MainWindow.get_overview ();
		FontDisplay fd = MainWindow.get_current_display ();
		string gc;
		Glyph? destination = null;
		unichar new_char;
				
		if (fd is OverView) {
			gc = overview.get_selected_char ();
			destination = font.get_glyph (gc);
		
			if (destination == null) {
				new_char = gc.get_char (0);
				destination = new Glyph (gc, new_char) ;
				font.add_glyph ((!) destination);
			}
		}
		
		if (fd is Glyph) {
			destination = (Glyph) fd;
		}
		
		return_if_fail (destination != null);

		if (destination == glyph) {
			return;
		}
			
		if (glyph != null) {
			foreach (Path p in ((!)glyph).path_list) {
				((!)destination).add_path (p.copy ());
			}
		}

		if (path != null) {
			((!)destination).add_path (((!)path).copy ());
		}
		
	}

}

}
