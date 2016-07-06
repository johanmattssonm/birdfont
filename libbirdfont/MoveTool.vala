/*
	Copyright (C) 2012 2013 2015 2016 Johan Mattsson

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

public class MoveTool : Tool {

	static bool move_path = false;
	static bool moved = false;
	static double last_x = 0;
	static double last_y = 0;
	
	static double selection_x = 0;
	static double selection_y = 0;	
	static bool group_selection= false;
	
	public static double selection_box_width = 0;
	public static double selection_box_height = 0;
	public static double selection_box_center_x = 0;
	public static double selection_box_center_y = 0;
	public static double selection_box_left = 0;
	public static double selection_box_top = 0;
	
	public signal void selection_changed ();
	public signal void objects_moved ();
	public signal void objects_deselected ();
	
	public MoveTool (string name) {
		base (name, t_("Move paths"));

		selection_changed.connect (() => {
			update_selection_boundaries ();
			redraw();
		});
		
		objects_deselected.connect (() => {
			update_selection_boundaries ();
			redraw();
		});
		
		select_action.connect((self) => {
			MainWindow.get_current_glyph ().close_path ();
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
			key_down (keyval);
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
	
	public void key_down (uint32 keyval) {
		Glyph g = MainWindow.get_current_glyph ();
		
		// delete selected paths
		if (keyval == Key.DEL || keyval == Key.BACK_SPACE) {
			
			if (g.active_paths.size > 0) {
				g.store_undo_state ();
			}
			
			foreach (SvgBird.Object p in g.active_paths) {
				g.layers.remove (p);
				g.update_view ();
			}

			g.active_paths.clear ();
		}
		
		if (is_arrow_key (keyval)) {
			move_selected_paths (keyval);
		}
	}
	
	public void move (int x, int y) {
		Glyph glyph = MainWindow.get_current_glyph ();
		double dx = Glyph.path_coordinate_x (last_x) - Glyph.path_coordinate_x (x);
		double dy = Glyph.path_coordinate_y (last_y) - Glyph.path_coordinate_y (y); 
		double delta_x, delta_y;
		
		if (!move_path) {
			return;
		}
		
		if (move_path && (fabs(dx) > 0 || fabs (dy) > 0)) {
			moved = true;

			delta_x = -dx;
			delta_y = -dy;
			
			foreach (SvgBird.Object object in glyph.active_paths) {
				object.move (delta_x, delta_y);
			}
		}

		last_x = x;
		last_y = y;

		update_selection_boundaries ();
		
		if (glyph.active_paths.size > 0) {
			objects_moved ();
		}
		
		BirdFont.get_current_font ().touch ();

		GlyphCanvas.redraw ();
		PenTool.reset_stroke ();
	}
	
	public void release (int b, int x, int y) {
		Glyph glyph = MainWindow.get_current_glyph ();
		
		move_path = false;
		
		if (GridTool.is_visible () && moved) {
			tie_paths_to_grid (glyph);
		} else if (GridTool.has_ttf_grid ()) {
			foreach (SvgBird.Object p in glyph.active_paths) {
				tie_path_to_ttf_grid (p);
			}
		} 
		
		if (group_selection) {
			select_group ();
		}
		
		group_selection = false;
		moved = false;
		
		if (glyph.active_paths.size > 0) {
			selection_changed ();
			objects_moved ();
			
			foreach (SvgBird.Object o in glyph.active_paths) {
				if (o is PathObject) {
					PathObject path = (PathObject) o;
					path.get_path ().create_full_stroke ();
				}
			}
		} else {
			objects_deselected ();
		}
	}
		
	public void press (int b, int x, int y) {
		Glyph glyph = MainWindow.get_current_glyph ();
		SvgBird.Object object;
		bool selected = false;
		SvgBird.Object? o;
		
		glyph.store_undo_state ();	
		double px = Glyph.path_coordinate_x (x);
		double py = Glyph.path_coordinate_y (y);
		o = glyph.get_object_at (px, py);

		if (o != null) {
			object = (!) o;
			selected = glyph.active_paths_contains (object);
 			
			if (!selected && !KeyBindings.has_shift ()) {
				glyph.clear_active_paths ();
			} 
			
			if (selected && KeyBindings.has_shift ()) {
				glyph.active_paths.remove (object);
			} else {
				glyph.add_active_object (object);
			}			
		} else if (!KeyBindings.has_shift ()) {
			glyph.clear_active_paths ();
		}

		update_selection_boundaries ();

		move_path = true;
		
		last_x = x;
		last_y = y;
		
		if (glyph.active_paths.size == 0) {
			group_selection = true;
			selection_x = x;
			selection_y = y;	
		}
		
		update_boundaries_for_selection ();
		selection_changed ();
		GlyphCanvas.redraw ();
	}
		
	void select_group () {
		double x1 = Glyph.path_coordinate_x (Math.fmin (selection_x, last_x));
		double y1 = Glyph.path_coordinate_y (Math.fmin (selection_y, last_y));
		double x2 = Glyph.path_coordinate_x (Math.fmax (selection_x, last_x));
		double y2 = Glyph.path_coordinate_y (Math.fmax (selection_y, last_y));
		Glyph glyph = MainWindow.get_current_glyph ();
		
		glyph.clear_active_paths ();
		
		foreach (SvgBird.Object p in glyph.get_objects_in_current_layer ()) {
			if (p.xmin > x1 && p.xmax < x2 && p.ymin < y1 && p.ymax > y2) {
				if (!p.is_empty ()) {
					glyph.add_active_object (p);
				}
			}
		}
		
		selection_changed ();
	}
	
	public static void update_selection_boundaries () {		
		get_selection_box_boundaries (out selection_box_center_x,
			out selection_box_center_y, out selection_box_width,
			out selection_box_height, out selection_box_left, 
			out selection_box_top);	
	}

	public void move_to_baseline () {
		Glyph glyph = MainWindow.get_current_glyph ();
		Font font = BirdFont.get_current_font ();
		double x, y, w, h, l, t;
		
		get_selection_box_boundaries (out x, out y, out w, out h, out l, out t);
		
		foreach (SvgBird.Object path in glyph.active_paths) {
			path.move (glyph.left_limit - x + w / 2, font.base_line - y + h / 2);
		}
		
		update_selection_boundaries ();
		objects_moved ();
		GlyphCanvas.redraw ();
	}
	
	public static void get_selection_box_boundaries (out double x, out double y, out double w, out double h,
		out double left, out double top) {
			
		double px, py, px2, py2;
		Glyph glyph = MainWindow.get_current_glyph ();
		
		px = 10000;
		py = 10000;
		px2 = -10000;
		py2 = -10000;
		top = 10000;
		left = 10000;

		foreach (SvgBird.Object o in glyph.active_paths) {
			if (top > o.top) {
				top = o.top;
			}

			if (left > o.left) {
				left = o.left;
			}
			
			if (px > o.xmin) {
				px = o.xmin;
			} 

			if (py > o.ymin) {
				py = o.ymin;
			}

			if (px2 < o.xmax) {
				px2 = o.xmax;
			}
			
			if (py2 < o.ymax) {
				py2 = o.ymax;
			}
		}
		
		w = px2 - px;
		h = py2 - py;
		x = px + (w / 2);
		y = py + (h / 2);
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
		
		foreach (SvgBird.Object path in glyph.active_paths) {
			path.move (x * Glyph.ivz (), y * Glyph.ivz ());
		}
		
		BirdFont.get_current_font ().touch ();
		PenTool.reset_stroke ();
		update_selection_boundaries ();
		objects_moved ();
		GlyphCanvas.redraw ();
	}

	static void tie_path_to_ttf_grid (SvgBird.Object p) {
		double sx, sy, qx, qy;	

		sx = p.xmax;
		sy = p.ymax;
		qx = p.xmin;
		qy = p.ymin;
		
		GridTool.ttf_grid_coordinate (ref sx, ref sy);
		GridTool.ttf_grid_coordinate (ref qx, ref qy);
	
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

	static void tie_paths_to_grid (Glyph g) {
		double sx, sy, qx, qy;	
		double dx_min, dx_max, dy_min, dy_max;;
		double maxx, maxy, minx, miny;
		
		update_selection_boundaries ();	
		
		// tie to grid
		maxx = selection_box_center_x + selection_box_width / 2;
		maxy = selection_box_center_y + selection_box_height / 2;
		minx = selection_box_center_x - selection_box_width / 2;
		miny = selection_box_center_y - selection_box_height / 2;
		
		sx = maxx;
		sy = maxy;
		qx = minx;
		qy = miny;
		
		GridTool.tie_coordinate (ref sx, ref sy);
		GridTool.tie_coordinate (ref qx, ref qy);
		
		dy_min = Math.fabs (qy - miny);
		dy_max = Math.fabs (sy - maxy);
		dx_min = Math.fabs (qx - minx);
		dx_max = Math.fabs (sx - maxx);
		
		foreach (SvgBird.Object p in g.active_paths) {
			if (dy_min < dy_max) {
				p.move (0, qy - miny);
			} else {
				p.move (0, sy - maxy);
			}

			if (dx_min < dx_max) {
				p.move (qx - minx, 0);
			} else {
				p.move (sx - maxx, 0);
			}
		}
		
		update_selection_boundaries ();		
	}
	
	public static void update_boundaries_for_selection () {
		Glyph glyph = MainWindow.get_current_glyph ();
		glyph.layers.update_boundaries_for_object ();
	}
	
	public static void flip_vertical () {
		DrawingTools.move_tool.flip (true);
	}
	
	public static void flip_horizontal () {
		DrawingTools.move_tool.flip (false);
	}

	public void flip (bool vertical) {
		Glyph glyph = MainWindow.get_current_glyph ();  
		
		update_selection_boundaries ();		
		
		foreach (SvgBird.Object object in glyph.active_paths) {
			Matrix matrix = Matrix.identity ();
			double x = 0;
			double y = 0;
			
			if (object is EmbeddedSvg) {
				EmbeddedSvg svg = (EmbeddedSvg) object;
				x = selection_box_left - svg.x + selection_box_width / 2;
				y = selection_box_top + svg.y + selection_box_height / 2;
			} else {			
				x = selection_box_center_x;
				y = selection_box_center_y;
			}
			
			matrix.translate (x, y);

			if (vertical) {
				matrix.scale (1, -1);
			} else {
				matrix.scale (-1, 1);
			}

			matrix.translate (-x, -y);
			
			SvgTransform transform = new SvgTransform.for_matrix (matrix);
			object.transforms.add (transform);
			object.transforms.collapse_transforms ();
			
			if (object is PathObject) {
				Path path = ((PathObject) object).get_path ();
				Matrix m = object.transforms.get_matrix ();
				object.transforms.clear ();
				path.transform (m);
				path.reverse ();
				object.move (0, 0);
			}
		}

		update_selection_boundaries ();
		objects_moved ();
		
		PenTool.reset_stroke ();
		BirdFont.get_current_font ().touch ();
	}
	
	public void select_all_paths () {
		Glyph g = MainWindow.get_current_glyph ();
		
		g.clear_active_paths ();
		foreach (SvgBird.Object p in g.get_objects_in_current_layer ()) {
			if (!p.is_empty ()) {
				g.add_active_object (p);
			}
		}
		
		g.update_view ();
		
		update_selection_boundaries ();
		objects_moved ();
		
		ResizeTool.update_selection_box ();
	}

	static void draw_selection_box (Context cr) {
		double x = Math.fmin (selection_x, last_x);
		double y = Math.fmin (selection_y, last_y);

		double w = Math.fabs (selection_x - last_x);
		double h = Math.fabs (selection_y - last_y);
		
		cr.save ();			
		Theme.color (cr, "Foreground 1");
		cr.set_line_width (2);
		cr.rectangle (x, y, w, h);
		cr.stroke ();
		cr.restore ();
	}

	public void convert_svg_to_monochrome () {
		ObjectGroup embedded_paths;
		Glyph glyph = MainWindow.get_current_glyph ();
		
		embedded_paths = new ObjectGroup ();

		foreach (SvgBird.Object object in glyph.active_paths) {
			if (object is EmbeddedSvg) {
				embedded_paths.add (object);
			}
		}
		
		convert_objects_to_monochrome_glyph (glyph, embedded_paths);
		GlyphCanvas.redraw ();
	}

	public void convert_glyph_to_monochrome (Glyph glyph) {
		ObjectGroup embedded_paths;
		
		embedded_paths = new ObjectGroup ();

		foreach (SvgBird.Object object in glyph.get_visible_objects ()) {
			if (object is EmbeddedSvg) {
				embedded_paths.add (object);
			}
		}
		
		convert_objects_to_monochrome_glyph (glyph, embedded_paths);
	}

	public void convert_objects_to_monochrome_glyph (Glyph glyph, ObjectGroup embedded_paths) {
		Font font = BirdFont.get_current_font ();

		foreach (SvgBird.Object object in embedded_paths) {
			if (object is EmbeddedSvg) {
				EmbeddedSvg svg = (EmbeddedSvg) object;
				glyph.clear_active_paths ();
				string transformed_svg_data = svg.get_transformed_svg_data ();
				SvgParser svg_parser = new SvgParser ();
				PathList path_list = svg_parser.import_svg_data_in_glyph (transformed_svg_data, glyph);
				glyph.delete_object (svg);

				foreach (Path path in path_list.paths) {
					path.move (svg.x - glyph.left_limit, svg.y - font.top_limit);
				}				
			}
		}
	}
}

}
