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

public class ClipTool : Tool {

	static Glyph? glyph = null; 
	static List<Path> path = new List<Path> ();

	public static void copy () {
		Font font = Supplement.get_current_font ();
		OverView overview  = MainWindow.get_overview ();
		FontDisplay fd = MainWindow.get_current_display ();
		string gc;
		Glyph g = MainWindow.get_current_glyph ();

		glyph = null;

		while (path.length () > 0) {
			path.remove_link (path.first ());
		}
					
		if (fd is OverView) {
			gc = overview.get_selected_char ();
			glyph = font.get_glyph (gc);
		} 
		
		if (fd is Glyph) {
			foreach (Path p in g.active_paths) {
				path.append (p.copy ());
			}

			if (path.length () == 0) {
				glyph = g.copy ();
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
		Path inserted;
		
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

			if (destination == glyph) {
				return;
			}
			
			((!)destination).store_undo_state ();
			
			if (glyph != null) {
				foreach (Path p in ((!)glyph).path_list) {
					inserted = p.copy ();
					((!)destination).add_path (inserted);
				}
			}

			foreach (Path p in path) {
				inserted = p.copy ();
				((!)destination).add_path (inserted);
			}
			
			((!)destination).update_view ();
		}
	}

}

}
