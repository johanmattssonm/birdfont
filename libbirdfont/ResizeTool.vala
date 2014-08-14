/*
    Copyright (C) 2013 Johan Mattsson

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

public class ResizeTool : Tool {
	
	bool resize_path = false;
	Path? resized_path = null;
	double last_resize_y;

	ImageSurface? resize_handle;

	static double selection_box_width = 0;
	static double selection_box_height = 0;
	static double selection_box_center_x = 0;
	static double selection_box_center_y = 0;

	static bool rotate_path = false;
	static double last_rotate_y;
	static double rotation = 0;
	static double last_rotate = 0;
	
	public signal void objects_rotated (double angle);
	public signal void objects_resized (double width, double height);
	
	public ResizeTool (string n) {
		base (n, t_("Resize and rotate paths"));
		
		resize_handle = Icons.get_icon ("resize_handle.png");
	
		select_action.connect((self) => {
		});

		deselect_action.connect((self) => {
		});
				
		press_action.connect((self, b, x, y) => {
			Path last_path;
			Glyph glyph;
			
			glyph = MainWindow.get_current_glyph ();
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

			foreach (Path p in glyph.active_paths) {
				if (is_over_rotate_handle (p, x, y)) {
					rotate_path = true;
					return;
				}
			}

			if (glyph.active_paths.size > 0) {
				last_path = glyph.active_paths.get (glyph.active_paths.size - 1);
				last_rotate = last_path.rotation ;
			}
					
			rotation = last_rotate;
			last_rotate_y = y;


			MoveTool.press (b, x, y);
		});

		release_action.connect((self, b, x, y) => {
			resize_path = false;
			rotate_path = false;
			DrawingTools.move_tool.release (b, x, y);
		});
		
		move_action.connect ((self, x, y)	 => {
			if (resize_path && can_resize (x, y)) {
				resize (x, y);
			}

			if (rotate_path) {
				rotate (x, y);
			}

			if (!rotate_path) {
				MoveTool.update_boundaries_for_selection ();
				MoveTool.get_selection_box_boundaries (out selection_box_center_x,
					out selection_box_center_y, out selection_box_width,
					out selection_box_height);	
			}
		
			GlyphCanvas.redraw ();
			DrawingTools.move_tool.move (x, y);
		});
		
		draw_action.connect ((self, cr, glyph) => {
			Glyph g = MainWindow.get_current_glyph ();
			ImageSurface resize_img = (!) resize_handle;
			
			foreach (Path p in g.active_paths) {
				cr.set_source_surface (resize_img, Glyph.reverse_path_coordinate_x (p.xmax) - 10, Glyph.reverse_path_coordinate_y (p.ymax) - 10);
				cr.paint ();
			}
			
			if (g.active_paths.size > 0) {
				draw_rotate_handle (cr);
			}
		
			MoveTool.draw_actions (cr);
		});
		
		key_press_action.connect ((self, keyval) => {
			DrawingTools.move_tool.key_press (keyval);
		});
		
	}

	public void signal_objects_rotated () {
		objects_rotated (rotation * (180 / PI));
	}

	public void rotate_selected_paths (double angle, double cx, double cy) {
		Glyph glyph = MainWindow.get_current_glyph ();  
		double dx, dy, xc2, yc2, w, h;
		Path last_path;
		foreach (Path p in glyph.active_paths) {
			p.rotate (angle, cx, cy);
		}

		MoveTool.get_selection_box_boundaries (out xc2, out yc2, out w, out h); 

		dx = -(xc2 - cx);
		dy = -(yc2 - cy);
		
		foreach (Path p in glyph.active_paths) {
			p.move (dx, dy);
		}
		
		last_rotate = rotation;
		
		MoveTool.update_selection_boundaries ();
		
		if (glyph.active_paths.size > 0) {
			last_path = glyph.active_paths.get (glyph.active_paths.size - 1);
			rotation = last_path.rotation;
			
			if (rotation > PI) {
				rotation -= 2 * PI;
			}
			
			last_rotate = rotation;
			signal_objects_rotated ();
		}
	}
	
	/** Move rotate handle to pixel x,y. */
	void rotate (double x, double y) {
		double cx, cy, xc, yc, a, b;		
		
		cx = Glyph.reverse_path_coordinate_x (selection_box_center_x);
		cy = Glyph.reverse_path_coordinate_y (selection_box_center_y);
		xc = selection_box_center_x;
		yc = selection_box_center_y;
		
		a = x - cx;
		b = y - cy;
		
		rotation = atan (b / a);
		
		if (a < 0) {
			rotation += PI;
		}
		
		rotate_selected_paths (rotation - last_rotate, selection_box_center_x, selection_box_center_y);
	}

	static bool is_over_rotate_handle (Path p, double x, double y) {
		double cx, cy, hx, hy;
		double size = 10;
		bool inx, iny;
		
		cx = Glyph.reverse_path_coordinate_x (selection_box_center_x);
		cy = Glyph.reverse_path_coordinate_y (selection_box_center_y);

		hx = cos (rotation) * 75;
		hy = sin (rotation) * 75;

		inx = x - size * MainWindow.units <= cx + hx - 2.5 <= x + size * MainWindow.units;
		iny = y - size * MainWindow.units <= cy + hy - 2.5 <= y + size * MainWindow.units;
		
		return inx && iny;
	}
	
	static void draw_rotate_handle (Context cr) {
		double cx, cy, hx, hy;
		
		cx = Glyph.reverse_path_coordinate_x (selection_box_center_x);
		cy = Glyph.reverse_path_coordinate_y (selection_box_center_y);
		
		cr.save ();
		
		cr.set_source_rgba (0, 0, 0.3, 1);
		cr.rectangle (cx - 2.5, cy - 2.5, 5, 5);
		cr.fill ();

		hx = cos (rotation) * 75;
		hy = sin (rotation) * 75;

		cr.set_line_width (1);
		cr.move_to (cx, cy);
		cr.line_to (cx + hx, cy + hy);
		cr.stroke ();

		cr.set_source_rgba (0, 0, 0.3, 1);
		cr.rectangle (cx + hx - 2.5, cy + hy - 2.5, 5, 5);
		cr.fill ();
					
		cr.restore ();				
	}

	double get_resize_ratio (double x, double y) {
		double ratio;
		double h;
		Path rp;
		
		return_val_if_fail (!is_null (resized_path), 0);
		rp = (!) resized_path;
		h = rp.xmax - rp.xmin;

		ratio = 1;
		ratio -= 0.5 * PenTool.precision * (Glyph.path_coordinate_y (last_resize_y) - Glyph.path_coordinate_y (y)) / h;		

		return ratio;
	}

	public void resize_selected_paths (double ratio) {
		Path rp;
		double resize_pos_x = 0;
		double resize_pos_y = 0;
		Glyph glyph = MainWindow.get_current_glyph ();
		double selection_minx, selection_miny, dx, dy;
		
		get_selection_min (out resize_pos_x, out resize_pos_y);
		
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
		
		if (glyph.active_paths.size > 0) {
			MoveTool.get_selection_box_boundaries (out selection_box_center_x,
					out selection_box_center_y, out selection_box_width,
					out selection_box_height);	
			objects_resized (selection_box_width, selection_box_height);
		}
	}

	/** Move resize handle to pixel x,y. */
	void resize (double x, double y) {
		double ratio;
		
		ratio = get_resize_ratio (x, y);
		resize_selected_paths (ratio);
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
			
			if (selected_path.points.size <= 1) {
				continue;
			}
			
			if (h * ratio < 1 || w * ratio < 1) {
				return false;
			}
		}
		
		return true;
	}

	bool is_over_resize_handle (Path p, double x, double y) {
		double handle_x = Math.fabs (Glyph.reverse_path_coordinate_x (p.xmax)); 
		double handle_y = Math.fabs (Glyph.reverse_path_coordinate_y (p.ymax));
		return fabs (handle_x - x + 10) < 20 * MainWindow.units && fabs (handle_y - y + 10) < 20 * MainWindow.units;
	}
}

}
