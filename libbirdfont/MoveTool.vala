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

using Math;
using Cairo;

namespace BirdFont {

class MoveTool : Tool {

	bool move_path = false;
	double last_x = 0;
	double last_y = 0;

	bool resize_path = false;
	Path? resized_path = null;
	double last_resize_y;
	
	ImageSurface? resize_handle;
	
	public MoveTool (string n) {
		base (n, _("Move paths"), 'm', CTRL);
		
		resize_handle = Icons.get_icon ("resize_handle.png");
	
		select_action.connect((self) => {
		});

		deselect_action.connect((self) => {
			Glyph glyph = MainWindow.get_current_glyph ();
			glyph.clear_active_paths ();
		});
				
		press_action.connect((self, b, x, y) => {
			Glyph glyph = MainWindow.get_current_glyph ();
						
			glyph.store_undo_state ();
			
			foreach (Path p in glyph.active_paths) {
				if (is_over_resize_handle (p, x, y)) {
					resize_path = true;
					resized_path = p;
					last_resize_y = y;
					return;
				}
			}
			
			if (resized_path != null) {
				if (is_over_resize_handle ((!) resized_path, x, y)) {
					resize_path = true;
					last_resize_y = y;
					return;					
				}
			}
			
			if (!glyph.is_over_selected_path (x, y)) {
				if (!glyph.select_path (x, y)) {
					glyph.clear_active_paths ();
				}
			}
			
			move_path = true;
				
			last_x = x;
			last_y = y;
		});

		release_action.connect((self, b, x, y) => {
			Glyph glyph = MainWindow.get_current_glyph ();
			
			move_path = false;
			resize_path = false;
				
			if (GridTool.is_visible ()) {
				foreach (Path p in glyph.active_paths) {
					tie_path_to_grid (p, x, y);
				}
			}
		});
		
		move_action.connect ((self, x, y)	 => {
			Glyph glyph = MainWindow.get_current_glyph ();
			double dx = last_x - x;
			double dy = last_y - y; 
			double p = PenTool.precision;
			
			if (move_path) {
				foreach (Path path in glyph.active_paths) {
					path.move (Glyph.ivz () * -dx * p, Glyph.ivz () * dy * p);
				}
			}
			
			if (resize_path && can_resize (x, y)) {
				resize (x, y);
			}

			last_x = x;
			last_y = y;

			MainWindow.get_glyph_canvas ().redraw ();
		});
		
		key_press_action.connect ((self, keyval) => {
			Glyph g = MainWindow.get_current_glyph ();
			
			// delete selected paths
			if (keyval == Key.DEL) {
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
		});
		
		draw_action.connect ((self, cr, glyph) => {
			Glyph g = MainWindow.get_current_glyph ();
			ImageSurface img = (!) resize_handle;
		
			foreach (Path p in g.active_paths) {
				cr.set_source_surface (img, Glyph.reverse_path_coordinate_x (p.xmax) - 10, Glyph.reverse_path_coordinate_y (p.ymax) - 10);
				cr.paint ();	
			}
		});
	}

	void move_selected_paths (uint key) {
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

	double get_resize_ratio (double x, double y) {
		double ratio;
		double h;
		Path rp;
		
		return_val_if_fail (!is_null (resized_path), 0);
		rp = (!) resized_path;
		h = rp.xmax - rp.xmin;

		ratio = 1;
		ratio -= 0.7 * PenTool.precision * (Glyph.path_coordinate_y (last_resize_y) - Glyph.path_coordinate_y (y)) / h;		

		return ratio;
	}

	/** Move resize handle to pixel x,y. */
	void resize (double x, double y) {
		Path rp;
		double ratio;
		double resize_pos_x = 0;
		double resize_pos_y = 0;
		Glyph glyph = MainWindow.get_current_glyph ();
		double selection_minx, selection_miny, dx, dy;
		
		ratio = get_resize_ratio (x, y);

		return_if_fail (!is_null (resized_path));
		rp = (!) resized_path;
		get_selection_min (out resize_pos_x, out resize_pos_y);
		
		foreach (Path selected_path in glyph.active_paths) {
			selected_path.resize (ratio);
		}
		
		// resize paths
		foreach (Path selected_path in glyph.active_paths) {
			selected_path.resize (ratio);
		}
		
		// move paths relative to the updated xmin and xmax
		get_selection_min (out selection_minx, out selection_miny);
		dx = resize_pos_x - selection_minx;
		dy = resize_pos_y - selection_miny;
		foreach (Path selected_path in glyph.active_paths) {
			selected_path.move (dx, dy);
		}
		
		last_resize_y = y;
	}

	void get_selection_min (out double x, out double y) {
		Glyph glyph = MainWindow.get_current_glyph ();
		x = double.MAX;
		y = double.MAX;
		foreach (Path p in glyph.active_paths) {
			if (p.xmin < x) {
				x = p.xmin;
			}
			
			if (p.ymin < y) {
				y = p.ymin;
			}
		}
	}

	bool can_resize (double x, double y) {
		Glyph glyph = MainWindow.get_current_glyph ();
		double h, w;
		double ratio = get_resize_ratio (x, y);
		
		foreach (Path selected_path in glyph.active_paths) {
			h = selected_path.ymax - selected_path.ymin;
			w = selected_path.xmax - selected_path.xmin;
			
			if (h * ratio < 1 || w * ratio < 1) {
				return false;
			}
		}
		
		return true;
	}

	bool is_over_resize_handle (Path p, double x, double y) {
		double handle_x = Math.fabs (Glyph.reverse_path_coordinate_x (p.xmax)); 
		double handle_y = Math.fabs (Glyph.reverse_path_coordinate_y (p.ymax));
		return fabs (handle_x - x + 10) < 20 && fabs (handle_y - y + 10) < 20;
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
