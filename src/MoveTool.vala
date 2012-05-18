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

class MoveTool : Tool {

	bool move_path = false;

	public MoveTool (string n) {
		base (n, "Move paths", 'm', CTRL);
	
		select_action.connect((self) => {
		});

		deselect_action.connect((self) => {
			Glyph glyph = MainWindow.get_current_glyph ();

			foreach (Path p in glyph.path_list) {
				p.set_color (0, 0, 0, 1);
				p.set_selected (false);
			}
		});
				
		press_action.connect((self, b, x, y) => {
			Glyph glyph = MainWindow.get_current_glyph ();
			Path path;
			
			glyph.store_undo_state ();
			
			glyph.move_path_begin (x, y);
			
			if (glyph.active_path == null) {
				return;
			}
			
			move_path = true;
			
			foreach (Path p in glyph.path_list) {
				p.set_color (0, 0, 0, 1);
				p.set_selected (false);
			}
			
			return_if_fail (glyph.active_path != null);
			
			path = (!) glyph.active_path;
			
			if (path.is_clockwise ()) {
				path.set_color (0.2, 0.2, 0.4, 0.8);
				path.set_selected (true);
			} else {
				path.set_color (0.5, 0.5, 0.7, 0.8);
				path.set_selected (true);
			}
			
		});

		release_action.connect((self, b, x, y) => {
			Glyph glyph = MainWindow.get_current_glyph ();
			move_path = false;
			
					
			if (GridTool.is_visible () && glyph.active_path != null) {
				tie_path_to_grid ((!) glyph.active_path, x, y);
			}
			
		});
		
		move_action.connect ((self, x, y)	 => {
			if (move_path) {
				Glyph glyph = MainWindow.get_current_glyph ();
				glyph.move_selected_path (x, y);
				MainWindow.get_glyph_canvas ().redraw ();
			}
		});
	}

	void tie_path_to_grid (Path p, double x, double y) {
		double sx, sy, qx, qy;	
		
		// tie to grid
		sx = p.xmax;
		sy = p.ymax;
		qx = p.xmin;
		qy = p.ymin;
		
		GridTool.tie_coordinate (ref sx, ref sy);
		GridTool.tie_coordinate (ref qx, ref qy);
		
		if (Math.fabs (qy - p.ymin) < Math.fabs (sy - p.ymax)) {
			p.move (0, qy - p.ymin);
		} else {
			p.move (0, sy - p.ymax);
		}

		if (Math.fabs (qx - p.xmin) < Math.fabs (sx - p.xmax)) {
			p.move (qx - p.xmin, 0);
		} else {
			p.move (sx - p.xmax, 0);
		}		
	}

}

}
