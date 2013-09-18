/*
    Copyright (C) 2012 2013 Johan Mattsson

    This library is free software; you can redistribute it and/or modify 
    it under the terms of the GNU Lesser General Public License as 
    published by the Free Software Foundation; either version 3 of the 
    License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful, but 
    WITHOUT ANY WARRANTY; without even the implied warranty of 
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
    Lesser General Public License for more details.
*/

using Math;
using Cairo;

namespace BirdFont {

class MoveTool : Tool {

	static bool move_path = false;
	static bool moved = false;
	static double last_x = 0;
	static double last_y = 0;
	
	static double selection_x = 0;
	static double selection_y = 0;	
	static bool group_selection= false;
	
	static double selection_box_width = 0;
	static double selection_box_height = 0;
	static double selection_box_center_x = 0;
	static double selection_box_center_y = 0;
	
	public MoveTool (string n) {
		base (n, t_("Move paths"), 'm', CTRL);

		select_action.connect((self) => {
		});

		deselect_action.connect((self) => {
		});
				
		press_action.connect((self, b, x, y) => {
			press (b, x, y);
		});

		release_action.connect((self, b, x, y) => {
			release (b, x, y);
		});
		
		move_action.connect ((self, x, y)	 => {
			move (x, y);
		});
		
		key_press_action.connect ((self, keyval) => {
			key_press (keyval);
		});
		
		draw_action.connect ((self, cr, glyph) => {
			draw_actions (cr);
		});
	}

	public static void draw_actions (Context cr) {
		if (group_selection) {
			draw_selection_box (cr);
		}
	}
	
	public static void key_press (uint32 keyval) {
		Glyph g = MainWindow.get_current_glyph ();
		
		// delete selected paths
		if (keyval == Key.DEL || keyval == Key.BACK_SPACE) {
			foreach (Path p in g.active_paths) {
				g.path_list.remove (p);
				g.update_view ();
			}

			while (g.active_paths.length () > 0) {
				g.active_paths.remove_link (g.active_paths.first ());
			}
		}
		
		if (is_arrow_key (keyval)) {
			move_selected_paths (keyval);
		}
	}
	
	public static void move (int x, int y) {
		Glyph glyph = MainWindow.get_current_glyph ();
		double dx = last_x - x;
		double dy = last_y - y; 
		double p = PenTool.precision;
		
		if (move_path && (fabs(dx) > 0 || fabs (dy) > 0)) {
			moved = true;
			foreach (Path path in glyph.active_paths) {
				path.move (Glyph.ivz () * -dx * p, Glyph.ivz () * dy * p);
			}
		}

		last_x = x;
		last_y = y;

		GlyphCanvas.redraw ();
	}
	
	public static void release (int b, int x, int y) {
		Glyph glyph = MainWindow.get_current_glyph ();
		
		move_path = false;
		
		if (GridTool.is_visible () && moved) {
			foreach (Path p in glyph.active_paths) {
				tie_path_to_grid (p, x, y);
			}
		} else if (GridTool.has_ttf_grid ()) {
			foreach (Path p in glyph.active_paths) {
				tie_path_to_ttf_grid (p, x, y);
			}
		} 
		
		if (group_selection) {
			select_group ();
		}
		
		group_selection = false;
		moved = false;	
	}
		
	public static void press (int b, int x, int y) {
		Glyph glyph = MainWindow.get_current_glyph ();
					
		glyph.store_undo_state ();
		group_selection = false;
				
		if (!glyph.is_over_selected_path (x, y)) {
			if (!glyph.select_path (x, y)) {
				glyph.clear_active_paths ();
			}
		}
		
		move_path = true;

		update_selection_boundries ();
					
		last_x = x;
		last_y = y;
		
		if (glyph.active_paths.length () == 0) {
			group_selection = true;
			selection_x = x;
			selection_y = y;	
		}
		
		update_boundries_for_selection ();	
	}
	
	static void select_group () {
		double x1 = Glyph.path_coordinate_x (Math.fmin (selection_x, last_x));
		double y1 = Glyph.path_coordinate_y (Math.fmin (selection_y, last_y));
		double x2 = Glyph.path_coordinate_x (Math.fmax (selection_x, last_x));
		double y2 = Glyph.path_coordinate_y (Math.fmax (selection_y, last_y));
		Glyph glyph = MainWindow.get_current_glyph ();
		
		glyph.clear_active_paths ();
		
		foreach (Path p in glyph.path_list) {
			if (p.xmin > x1 && p.xmax < x2 && p.ymin < y1 && p.ymax > y2) {
				if (p.points.length () > 0) {
					glyph.active_paths.append (p);
				}
			}
		}
	}
	
	public static void update_selection_boundries () {
		get_selection_box_boundries (out selection_box_center_x,
			out selection_box_center_y, out selection_box_width,
			out selection_box_height);	
	}

	static void draw_selection_box (Context cr) {
		double x = Math.fmin (selection_x, last_x);
		double y = Math.fmin (selection_y, last_y);

		double w = Math.fabs (selection_x - last_x);
		double h = Math.fabs (selection_y - last_y);
		
		cr.save ();
		
		cr.set_source_rgba (0, 0, 0.3, 1);
		cr.set_line_width (2);
		cr.rectangle (x, y, w, h);
		cr.stroke ();
		
		cr.restore ();
	}
	
	public static void get_selection_box_boundries (out double x, out double y, out double w, out double h) {
		double px, py, px2, py2;
		Glyph glyph = MainWindow.get_current_glyph ();
		
		px = 10000;
		py = 10000;
		px2 = -10000;
		py2 = -10000;
		
		foreach (Path p in glyph.active_paths) {
			if (px > p.xmin) {
				px = p.xmin;
			} 

			if (py > p.ymin) {
				py = p.ymin;
			}

			if (px2 < p.xmax) {
				px2 = p.xmax;
			}
			
			if (py2 < p.ymax) {
				py2 = p.ymax;
			}
		}
		
		w = px2 - px;
		h = py2 - py;
		x = px + (w / 2);
		y = py + (h / 2);
	}
	
	static void move_selected_paths (uint key) {
		Glyph glyph = MainWindow.get_current_glyph ();
		double x, y;
		
		x = 0;
		y = 0;
		
		switch (key) {
			case Key.UP:
				y = 1;
				break;
			case Key.DOWN:
				y = -1;
				break;
			case Key.LEFT:
				x = -1;
				break;
			case Key.RIGHT:
				x = 1;
				break;
			default:
				break;
		}
		
		foreach (Path path in glyph.active_paths) {
			path.move (x * Glyph.ivz (), y * Glyph.ivz ());
		}
		
		glyph.redraw_area (0, 0, glyph.allocation.width, glyph.allocation.height);
	}

	static void tie_path_to_ttf_grid (Path p, double x, double y) {
		tie_path_to_grid (p, x, y, true);
	} 

	static void tie_path_to_grid (Path p, double x, double y, bool ttf_grid = false) {
		double sx, sy, qx, qy;	
		
		// tie to grid
		sx = p.xmax;
		sy = p.ymax;
		qx = p.xmin;
		qy = p.ymin;
		
		if (ttf_grid) {
			GridTool.ttf_grid_coordinate (ref sx, ref sy);
			GridTool.ttf_grid_coordinate (ref qx, ref qy);
		} else {
			GridTool.tie_coordinate (ref sx, ref sy);
			GridTool.tie_coordinate (ref qx, ref qy);
		}
		
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
	
	public static void update_boundries_for_selection () {
		Glyph glyph = MainWindow.get_current_glyph ();
		foreach (Path p in glyph.active_paths) {
			p.update_region_boundries ();
		}
	}
	
	public static void flip_vertical () {
		flip (true);
	}
	
	public static void flip_horizontal () {
		flip (false);
	}

	public static void flip (bool vertical) {
		double xc, yc, xc2, yc2, w, h;		
		double dx, dy;
		Glyph glyph = MainWindow.get_current_glyph ();  
		
		xc = selection_box_center_x;
		yc = selection_box_center_y;

		foreach (Path p in glyph.active_paths) {
			if (vertical) {
				p.flip_vertical ();
			} else {
				p.flip_horizontal ();
			}
			
			p.reverse ();
		}

		get_selection_box_boundries (out xc2, out yc2, out w, out h); 

		dx = -(xc2 - xc);
		dy = -(yc2 - yc);
		
		foreach (Path p in glyph.active_paths) {
			p.move (dx, dy);
		}
		
		update_selection_boundries ();	
	}
}

}
