/*
	Copyright (C) 2013 2015 Johan Mattsson

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
	double last_resize_x;

	bool move_paths = false;

	static double selection_box_width = 0;
	static double selection_box_height = 0;
	static double selection_box_center_x = 0;
	static double selection_box_center_y = 0;

	static bool rotate_path = false;
	static double last_rotate_y;
	static double rotation = 0;
	static double last_rotate = 0;
	
	public double last_skew = 0;
	
	public signal void objects_rotated (double angle);
	public signal void objects_resized (double width, double height);
	
	public ResizeTool (string n) {
		base (n, t_("Resize and rotate paths"));
	
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
					last_resize_x = x;
					last_resize_y = y;
					return;
				}
			}
			
			if (resized_path != null) {
				if (is_over_resize_handle ((!) resized_path, x, y)) {
					resize_path = true;
					last_resize_x = x;
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
			last_resize_x = x;
			last_rotate_y = y;
			
			DrawingTools.move_tool.press (b, x, y);
			
			move_paths = true;
			
			update_selection_box ();
		});

		release_action.connect((self, b, x, y) => {
			resize_path = false;
			rotate_path = false;
			move_paths = false;
			DrawingTools.move_tool.release (b, x, y);
			update_selection_box ();
			GlyphCanvas.redraw ();
			
			foreach (Path p in MainWindow.get_current_glyph ().active_paths) {
				p.create_full_stroke ();
			}
		});
		
		move_action.connect ((self, x, y)	 => {
			Glyph glyph;
			
			if (resize_path && can_resize (x, y)) {
				resize (x, y);
			}

			if (rotate_path) {
				rotate (x, y);
			}

			if (move_paths || rotate_path || resize_path) {
				glyph = MainWindow.get_current_glyph ();
				
				foreach (Path selected_path in glyph.active_paths) {
					selected_path.reset_stroke ();
				}
				
				update_selection_box ();
				GlyphCanvas.redraw ();
			}
			
			DrawingTools.move_tool.move (x, y);
		});
		
		draw_action.connect ((self, cr, glyph) => {
			Text handle;
			Glyph g = MainWindow.get_current_glyph ();
			
			if (!rotate_path) {
				handle = new Text ("resize_handle", 60 * MainWindow.units);
				handle.load_font ("icons.bf");
				
				get_reseize_handle_position (out handle.widget_x, out handle.widget_y);
				
				handle.widget_x -= handle.get_sidebearing_extent () / 2;
				handle.widget_y -= handle.get_height () / 2;
				
				Theme.text_color (handle, "Highlighted 1");
				handle.draw (cr);
			}
			
			if (!resize_path && g.active_paths.size > 0) {
				draw_rotate_handle (cr);
			}
		
			MoveTool.draw_actions (cr);
		});
		
		key_press_action.connect ((self, keyval) => {
			DrawingTools.move_tool.key_down (keyval);
		});
	}

	public static void get_reseize_handle_position (out double px, out double py) {
		px = Glyph.reverse_path_coordinate_x (selection_box_center_x + selection_box_width / 2);
		py = Glyph.reverse_path_coordinate_y (selection_box_center_y + selection_box_height / 2);
	}

	public static double get_rotated_handle_length () {
		double s, hx, hy;
		double d;

		s = fmin (selection_box_width, selection_box_height) * 1.1;
		d = (s / Glyph.ivz ()) / 2;

		hx = cos (rotation) * d;
		hy = sin (rotation) * d;
		
		return d;
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

		hx = cos (rotation) * get_rotated_handle_length ();
		hy = sin (rotation) * get_rotated_handle_length ();

		inx = x - size * MainWindow.units <= cx + hx - 2.5 <= x + size * MainWindow.units;
		iny = y - size * MainWindow.units <= cy + hy - 2.5 <= y + size * MainWindow.units;
		
		return inx && iny;
	}
	
	static void draw_rotate_handle (Context cr) {
		double cx, cy, hx, hy;
		
		cx = Glyph.reverse_path_coordinate_x (selection_box_center_x);
		cy = Glyph.reverse_path_coordinate_y (selection_box_center_y);
		
		cr.save ();
		Theme.color (cr, "Highlighted 1");
		cr.rectangle (cx - 2.5, cy - 2.5, 5, 5);
		cr.fill ();

		hx = cos (rotation) * get_rotated_handle_length ();
		hy = sin (rotation) * get_rotated_handle_length ();
	
		cr.set_line_width (1);
		cr.move_to (cx, cy);
		cr.line_to (cx + hx, cy + hy);
		cr.stroke ();

		Theme.color (cr, "Highlighted 1");
		cr.rectangle (cx + hx - 2.5, cy + hy - 2.5, 5, 5);
		cr.fill ();
					
		cr.restore ();
	}
	
	double get_resize_ratio (double px, double py) {
		double ratio, x, y, w, h;
		
		Glyph glyph = MainWindow.get_current_glyph ();
		glyph.selection_boundaries (out x, out y, out w, out h);
		
		ratio = 1;
		
		if (Math.fabs (last_resize_y - py) > Math.fabs (last_resize_x - px)) {
			ratio = 1 + (Glyph.path_coordinate_y (py) 
				- Glyph.path_coordinate_y (last_resize_y)) / h;
		} else {
			ratio = 1 + (Glyph.path_coordinate_x (px) 
				- Glyph.path_coordinate_x (last_resize_x)) / w;
		}
		
		return ratio;
	}

	public void resize_selected_paths (double ratio) {
		Glyph g = MainWindow.get_current_glyph ();
		resize_glyph (g, ratio, true);
	}
	
	public void resize_glyph (Glyph glyph, double ratio, bool selected = true) {
		double resize_pos_x = 0;
		double resize_pos_y = 0;
		double selection_minx, selection_miny, dx, dy;
		
		if (!selected) {
			glyph.clear_active_paths ();
			
			foreach (Path path in glyph.get_visible_paths ()) {
				glyph.add_active_path (null, path);
			}
		}
		
		get_selection_min (out resize_pos_x, out resize_pos_y);
		
		// resize paths
		foreach (Path selected_path in glyph.active_paths) {
			selected_path.resize (ratio);
			selected_path.reset_stroke ();
		}
		
		// move paths relative to the updated xmin and xmax
		get_selection_min (out selection_minx, out selection_miny);
		dx = resize_pos_x - selection_minx;
		dy = resize_pos_y - selection_miny;
		
		foreach (Path selected_path in glyph.active_paths) {
			selected_path.move (dx, dy);			
		}
		
		if (glyph.active_paths.size > 0) {
			update_selection_box ();
			objects_resized (selection_box_width, selection_box_height);
		}

		if (!selected) {
			double w;
			w = (ratio * glyph.get_width () - glyph.get_width ()) / 2.0;
			glyph.left_limit -= w; 
			glyph.right_limit += w;
			glyph.clear_active_paths ();
			glyph.remove_lines ();
			glyph.add_help_lines ();
		}
	}

	void update_selection_box () {
		MoveTool.update_boundaries_for_selection ();
		MoveTool.get_selection_box_boundaries (out selection_box_center_x,
				out selection_box_center_y, out selection_box_width,
				out selection_box_height);
	}

	/** Move resize handle to pixel x,y. */
	void resize (double px, double py) {
		double ratio;
		
		ratio = get_resize_ratio (px, py);
		
		if (ratio != 1) {
			resize_selected_paths (ratio);
			last_resize_x = px;
			last_resize_y = py;
		}
	}

	public void full_height () {
		double xc, yc, w, h;
		Glyph glyph = MainWindow.get_current_glyph ();
		Font font = BirdFont.get_current_font ();

		MoveTool.update_boundaries_for_selection ();
		MoveTool.get_selection_box_boundaries (out xc, out yc, out w, out h);

		//compute scale
		double font_height = font.top_position - font.base_line;
		double scale = font_height / h;

		resize_selected_paths (scale);
		PenTool.reset_stroke ();

		MoveTool.update_boundaries_for_selection ();
		font.touch ();

		MoveTool.get_selection_box_boundaries (out selection_box_center_x,
											   out selection_box_center_y,
											   out selection_box_width,
											   out selection_box_height);
		
		DrawingTools.move_tool.move_to_baseline ();
		
		objects_resized (selection_box_width, selection_box_height);
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
		double handle_x, handle_y;
		get_reseize_handle_position (out handle_x, out handle_y);
		return Path.distance (handle_x, x, handle_y, y) < 12 * MainWindow.units;
	}

	public void skew (double skew) {
		Glyph glyph = MainWindow.get_current_glyph ();
		skew_glyph (glyph, skew, last_skew, true);
		last_skew = skew;
	}
	
	public void skew_glyph (Glyph glyph, double skew, double last_skew,
		bool selected_paths) {
		
		double dx, nx, nw, dw, x, y, w, h;
		double s = (skew - last_skew) / 100.0;

		if (!selected_paths) {
			glyph.clear_active_paths ();
			
			foreach (Path path in glyph.get_visible_paths ()) {
				glyph.add_active_path (null, path);
			}
		}

		glyph.selection_boundaries (out x, out y, out w, out h);
	
		foreach (Path path in glyph.active_paths) {
			SvgParser.apply_matrix (path, 1, 0, s, 1, 0, 0);
			path.skew = skew;
			path.update_region_boundaries ();
		}
		
		glyph.selection_boundaries (out nx, out y, out nw, out h);
		
		dx = -(nx - x);
		
		foreach (Path p in glyph.active_paths) {
			p.move (dx, 0);
			p.reset_stroke ();
		}
		
		dw = (nw - w);
		glyph.right_limit += dw;
		glyph.remove_lines ();
		glyph.add_help_lines ();		

		if (!selected_paths) {
			glyph.clear_active_paths ();
		}
	}
}

}
