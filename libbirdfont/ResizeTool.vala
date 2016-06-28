/*
	Copyright (C) 2013 2015 2016 Johan Mattsson

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
using SvgBird;

namespace BirdFont {

public class ResizeTool : Tool {
	bool resize_path_proportional = false;
	bool resize_width = false;

	SvgBird.Object? resized_path = null;
	double last_resize_y;
	double last_resize_x;

	bool move_paths = false;

	static double selection_box_width = 0;
	static double selection_box_height = 0;
	static double selection_box_center_x = 0;
	static double selection_box_center_y = 0;
	static double selection_box_left = 0;
	static double selection_box_top = 0;
	
	static double resized_width = 0;
	static double resized_height = 0;
	static double resized_top = 0;
	static double resized_left = 0;
		
	static bool rotate_path = false;
	static double last_rotate_y;
	static double rotation = 0;
	public static double last_rotate = 0;
	
	public double last_skew = 0;
	
	public signal void objects_rotated (double angle);
	public signal void objects_resized (double width, double height);
	
	Text proportional_handle;
	Text horizontal_handle;
	
	public ResizeTool (string n) {
		base (n, t_("Resize and rotate paths"));

		proportional_handle = new Text ("resize_handle", 60);
		proportional_handle.load_font ("icons.bf");
		Theme.text_color (proportional_handle, "Highlighted 1");

		horizontal_handle = new Text ("resize_handle_horizontal", 60);
		horizontal_handle.load_font ("icons.bf");
		Theme.text_color (horizontal_handle, "Highlighted 1");
	
		DrawingTools.move_tool.selection_changed.connect (update_position);
		DrawingTools.move_tool.objects_moved.connect (update_position);
	
		select_action.connect((self) => {
		});

		deselect_action.connect((self) => {
		});
				
		press_action.connect((self, b, x, y) => {
			SvgBird.Object last_path;
			Glyph glyph;
			
			glyph = MainWindow.get_current_glyph ();
			glyph.store_undo_state ();
			
			foreach (SvgBird.Object p in glyph.active_paths) {
				if (is_over_resize_handle (p, x, y)) {
					resize_path_proportional = true;
					resized_path = p;
					last_resize_x = x;
					last_resize_y = y;
					return;
				}

				if (is_over_horizontal_resize_handle (p, x, y)) {
					resize_width = true;
					resized_path = p;
					last_resize_x = x;
					last_resize_y = y;
					return;					
				}
			}

			foreach (SvgBird.Object p in glyph.active_paths) {
				if (is_over_rotate_handle (p, x, y)) {
					rotate_path = true;
					return;
				}
			}

			if (glyph.active_paths.size > 0) {
				last_path = glyph.active_paths.get (glyph.active_paths.size - 1);
				last_rotate = last_path.transforms.rotation;
			}
					
			rotation = last_rotate;
			last_resize_x = x;
			last_rotate_y = y;
			
			if (!resize_path_proportional && !resize_width && !rotate_path) {
				DrawingTools.move_tool.press (b, x, y);
			}
			
			move_paths = true;
			
			update_selection_box ();
		});

		release_action.connect((self, b, x, y) => {
			resize_path_proportional = false;
			resize_width = false;
			rotate_path = false;
			move_paths = false;
			DrawingTools.move_tool.release (b, x, y);
			update_selection_box ();
			GlyphCanvas.redraw ();
			
			foreach (SvgBird.Object object in MainWindow.get_current_glyph ().active_paths) {
				if (object is PathObject) {
					PathObject path = (PathObject) object;
					Path p = path.get_path ();
					p.create_full_stroke ();
				} else {
					object.transforms.collapse_transforms ();
				}
			}			
		});
		
		move_action.connect ((self, x, y)	 => {
			Glyph glyph;
			
			if (resize_path_proportional && can_resize (x, y)) {
				resize_proportional (x, y);
			}

			if (resize_width && can_resize (x, y)) {
				resize_horizontal (x, y);
			}

			if (rotate_path) {
				rotate (x, y);
			}

			if (move_paths 
				|| rotate_path
				|| resize_path_proportional
				|| resize_width) {
				
				glyph = MainWindow.get_current_glyph ();				
				GlyphCanvas.redraw ();
			}
			
			DrawingTools.move_tool.move (x, y);
		});
		
		draw_action.connect ((self, cr, glyph) => {
			Text handle;
			Glyph g = MainWindow.get_current_glyph ();
			
			if (!move_paths) {
				if (!rotate_path) {
					if (!resize_width) {
						handle = proportional_handle;
						get_resize_handle_position (out handle.widget_x, out handle.widget_y);
						
						handle.widget_x -= handle.get_sidebearing_extent () / 2;
						handle.widget_y -= handle.get_height () / 2;
						
						handle.draw (cr);
					} 
					
					if (!resize_path_proportional) {
						handle = horizontal_handle;
						
						get_horizontal_reseize_handle_position (out handle.widget_x, 
							out handle.widget_y);
						
						handle.widget_x -= handle.get_sidebearing_extent () / 2;
						handle.widget_y -= handle.get_height () / 2;
						
						handle.draw (cr);
					}
				}

				if (!resize_path_proportional && !resize_width 
					&& g.active_paths.size > 0) {
					
					draw_rotate_handle (cr);
				}
			}
			
			MoveTool.draw_actions (cr);
		});
		
		key_press_action.connect ((self, keyval) => {
			DrawingTools.move_tool.key_down (keyval);
		});
	}

	public void update_position () {
		Glyph glyph = MainWindow.get_current_glyph ();
		SvgBird.Object path;
		
		if (glyph.active_paths.size > 0) {
			path = glyph.active_paths.get (glyph.active_paths.size - 1);
			
			if (path is PathObject) {
				last_rotate = ((PathObject) path).get_path ().rotation;
			} else {
				last_rotate = path.transforms.total_rotation;
			}
		}
		
		rotation = last_rotate;
		update_selection_box ();
		update_resized_boundaries ();
	}

	public static void get_resize_handle_position (out double px, out double py) {
		px = Glyph.reverse_path_coordinate_x (resized_left + resized_width);
		py = Glyph.reverse_path_coordinate_y (-resized_top);
	}

	public static void get_horizontal_reseize_handle_position (out double px, out double py) {
		px = Glyph.reverse_path_coordinate_x (resized_left + resized_width);
		px += 40;
		py = Glyph.reverse_path_coordinate_y (-resized_top - resized_height / 2);
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

	public void rotate_selected_paths (double angle, double cx, double cy) {
		Glyph glyph = MainWindow.get_current_glyph ();  
		double x, y;
		
		glyph.layers.update_boundaries_for_object ();
		
		foreach (SvgBird.Object p in glyph.active_paths) {
			if (p is EmbeddedSvg) {
				EmbeddedSvg svg = (EmbeddedSvg) p;
				x = selection_box_left - svg.x + selection_box_width / 2;
				y = selection_box_top + svg.y + selection_box_height / 2;
				p.transforms.rotate (angle, x, y);
				rotation = p.transforms.total_rotation;
			} else if (p is PathObject) {
				Path path = ((PathObject) p).get_path ();
				SvgTransforms transform = new SvgTransforms ();
				transform.rotate (-angle, selection_box_center_x, selection_box_center_y);
				Matrix matrix = transform.get_matrix ();
				path.transform (matrix);
				path.rotation += angle;
				rotation = path.rotation;
			}
		}

		last_rotate = rotation;

		if (glyph.active_paths.size > 0) {
			if (rotation > PI) {
				rotation -= 2 * PI;
			}
			
			if (last_rotate > PI) {
				last_rotate -= 2 * PI;
			}
			
			objects_rotated (rotation * (180 / PI));
		}
	}
	
	/** Move rotate handle to pixel x,y. */
	void rotate (double x, double y) {
		double a, b;		
		
		a = Glyph.path_coordinate_x (x) - selection_box_center_x;
		b = selection_box_center_y - Glyph.path_coordinate_y (y);
		
		rotation = atan2 (b, a);

		if (a == 0) {
			rotation = b > 0 ? PI / 2 : -PI / 2;
		}
		
		rotate_selected_paths (rotation - last_rotate, selection_box_center_x, selection_box_center_y);
	}

	static bool is_over_rotate_handle (SvgBird.Object p, double x, double y) {
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

		hx = cos (last_rotate) * get_rotated_handle_length ();
		hy = sin (last_rotate) * get_rotated_handle_length ();
	
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

	public void resize_selected_paths (double ratio_x, double ratio_y) {
		Glyph g = MainWindow.get_current_glyph ();
		resize_glyph (g, ratio_x, ratio_y, true);
	}
	
	public void resize_glyph (Glyph glyph, double ratio_x,
			double ratio_y, bool selected = true) {

		if (!selected) {
			glyph.clear_active_paths ();
			
			foreach (SvgBird.Object path in glyph.get_visible_objects ()) {
				glyph.add_active_object (path);
			}
		}
		
		foreach (SvgBird.Object p in glyph.active_paths) {
			if (p is EmbeddedSvg) {
				EmbeddedSvg svg = (EmbeddedSvg) p;
				x = selection_box_left - svg.x;
				y = selection_box_top + svg.y + selection_box_height;
				p.transforms.resize (ratio_x, ratio_y, x, y);
				glyph.layers.update_boundaries_for_object ();
			} else if (p is PathObject) {
				Path path = ((PathObject) p).get_path ();
				x = selection_box_center_x - selection_box_width / 2;
				y = selection_box_center_y - selection_box_height / 2;
				SvgTransforms transform = new SvgTransforms ();
				transform.resize (ratio_x, ratio_y, x, y);
				Matrix matrix = transform.get_matrix ();
				path.transform (matrix);
			}
		}
		
		if (glyph.active_paths.size > 0) {
			update_resized_boundaries ();
			objects_resized (resized_width, resized_height);
		}

		if (!selected) {
			double w;
			w = (ratio_x * glyph.get_width () - glyph.get_width ()) / 2.0;
			glyph.left_limit -= w; 
			glyph.right_limit += w;
			glyph.clear_active_paths ();
			glyph.remove_lines ();
			glyph.add_help_lines ();
		}
	}

	public static void update_selection_box () {
		update_resized_boundaries ();
		MoveTool.update_boundaries_for_selection ();
		MoveTool.get_selection_box_boundaries (out selection_box_center_x,
				out selection_box_center_y, out selection_box_width,
				out selection_box_height, out selection_box_left, out selection_box_top);
	}

	static void update_resized_boundaries () {
		Glyph glyph = MainWindow.get_current_glyph ();
		
		double left = 10000;
		double top = 10000;
		double bottom = -10000;
		double right = -10000;

		foreach (SvgBird.Object o in glyph.active_paths) {
			if (top > o.top) {
				top = o.top;
			}

			if (left > o.left) {
				left = o.left;
			}

			if (right < o.right) {
				right = o.right;
			}

			if (bottom < o.bottom) {
				bottom = o.bottom;
			}
		}

		resized_top = top;
		resized_left = left;		
		resized_width = right - left;
		resized_height = bottom - top;
	}

	/** Move resize handle to pixel x,y. */
	void resize_proportional (double px, double py) {
		double ratio;
		
		ratio = get_resize_ratio (px, py);
		
		if (ratio != 1) {
			resize_selected_paths (ratio, ratio);
			last_resize_x = px;
			last_resize_y = py;
		}
	}

	/** Move resize handle to pixel x,y. */
	void resize_horizontal (double px, double py) {
		double ratio, x, y, w, h;

		Glyph glyph = MainWindow.get_current_glyph ();
		glyph.selection_boundaries (out x, out y, out w, out h);
				
		ratio = 1 + (Glyph.path_coordinate_x (px) 
			- Glyph.path_coordinate_x (last_resize_x)) / w;
		
		if (ratio != 1) {
			resize_selected_paths (ratio, 1);
			last_resize_x = px;
			last_resize_y = py;
		}
	}

	bool can_resize (double x, double y) {
		Glyph glyph = MainWindow.get_current_glyph ();
		double h, w;
		double ratio = get_resize_ratio (x, y);
		
		foreach (SvgBird.Object selected_path in glyph.active_paths) {
			h = selected_path.ymax - selected_path.ymin;
			w = selected_path.xmax - selected_path.xmin;
			
			if (selected_path.is_empty ()) { // FIXME: test with one point
				continue;
			}
			
			if (h * ratio < 1 || w * ratio < 1) {
				return false;
			}
		}
		
		return true;
	}

	bool is_over_resize_handle (SvgBird.Object p, double x, double y) {
		double handle_x, handle_y;
		get_resize_handle_position (out handle_x, out handle_y);
		return Path.distance (handle_x, x, handle_y, y) < 12 * MainWindow.units;
	}

	bool is_over_horizontal_resize_handle (SvgBird.Object p, double x, double y) {
		double handle_x, handle_y;
		get_horizontal_reseize_handle_position (out handle_x, out handle_y);
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
			
			foreach (SvgBird.Object path in glyph.get_visible_objects ()) {
				glyph.add_active_object (path);
			}
		}

		glyph.selection_boundaries (out x, out y, out w, out h);
	
		foreach (SvgBird.Object path in glyph.active_paths) {
			if (path is PathObject) { // FIXME: other objects
				Path p = ((PathObject) path).get_path ();
				SvgParser.apply_matrix (p, 1, 0, s, 1, 0, 0);
				p.skew = skew;
				path.update_boundaries_for_object ();
			}
		}
		
		glyph.selection_boundaries (out nx, out y, out nw, out h);
		
		dx = -(nx - x);
		
		foreach (SvgBird.Object p in glyph.active_paths) {
			p.move (dx, 0);
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
