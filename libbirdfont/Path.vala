/*
    Copyright (C) 2012, 2013, 2014 Johan Mattsson

    This library is free software; you can redistribute it and/or modify 
    it under the terms of the GNU Lesser General Public License as 
    published by the Free Software Foundation; either version 3 of the 
    License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful, but 
    WITHOUT ANY WARRANTY; without even the implied warranty of 
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
    Lesser General Public License for more details.
*/

using Cairo;
using Math;

namespace BirdFont {

public enum Direction {
	CLOCKWISE,
	COUNTER_CLOCKWISE
}

public class Path {
	
	public Gee.ArrayList<EditPoint> points;

	EditPoint? last_point = null;
	
	/** Path boundaries */
	public double xmax = double.MIN;
	public double xmin = double.MAX;
	public double ymax = double.MIN;
	public double ymin = double.MAX;

	/** Stroke width */
	public double stroke = 0;
	
	/** Fill property for closed paths with stroke. */
	public bool fill = false;

	bool edit = true;
	bool open = true;
	
	bool direction_is_set = false;
	bool no_derived_direction = false;
	bool clockwise_direction = true;

	// Iterate over each pixel in a path
	public delegate bool RasterIterator (double x, double y, double step);
	
	public delegate bool SegmentIterator (EditPoint start, EditPoint stop);
	
	private static ImageSurface? edit_point_image = null;
	private static ImageSurface? active_edit_point_image = null;
	
	private static ImageSurface? edit_point_handle_image = null;
	private static ImageSurface? active_edit_point_handle_image = null;
	private static ImageSurface? selected_edit_point_handle_image = null;

	private static ImageSurface? selected_edit_point_image = null;
	private static ImageSurface? active_selected_edit_point_image = null;

	private static ImageSurface? cubic_edit_point_image = null;
	private static ImageSurface? cubic_active_edit_point_image = null;

	private static ImageSurface? cubic_selected_edit_point_image = null;
	private static ImageSurface? cubic_active_selected_edit_point_image = null;
	
	Path quadratic_path; // quadratic points for TrueType export
	Gee.ArrayList<EditPoint> new_quadratic_points;
	
	public static double line_color_r = 0;
	public static double line_color_g = 0;
	public static double line_color_b = 0;
	public static double line_color_a = 1;

	public static double handle_color_r = 0;
	public static double handle_color_g = 0;
	public static double handle_color_b = 0;
	public static double handle_color_a = 1;

	public static double fill_color_r = 0;
	public static double fill_color_g = 0;
	public static double fill_color_b = 0;
	public static double fill_color_a = 1;
	
	/** The stroke of an outline when the path is not filled. */
	public static double stroke_width = 1;
	public static bool show_all_line_handles = true;
	public static bool fill_open_path = false;
	
	public Path () {	
		string width;
		points = new Gee.ArrayList<EditPoint> ();
		new_quadratic_points = new Gee.ArrayList<EditPoint> ();
		
		if (edit_point_image == null) {
			edit_point_image = Icons.get_icon ("edit_point.png");
			active_edit_point_image = Icons.get_icon ("active_edit_point.png");
			edit_point_handle_image = Icons.get_icon ("edit_point_handle.png");
			active_edit_point_handle_image = Icons.get_icon ("active_edit_point_handle.png");
			selected_edit_point_handle_image = Icons.get_icon ("selected_edit_point_handle.png");
			selected_edit_point_image = Icons.get_icon ("selected_edit_point.png");
			active_selected_edit_point_image = Icons.get_icon ("active_selected_edit_point.png");
			cubic_edit_point_image = Icons.get_icon ("edit_point_cubic.png");
			cubic_active_edit_point_image = Icons.get_icon ("active_edit_point_cubic.png");
			cubic_selected_edit_point_image = Icons.get_icon ("selected_edit_point_cubic.png");
			cubic_active_selected_edit_point_image  = Icons.get_icon ("active_selected_edit_point_cubic.png");
	
			width = Preferences.get ("stroke_width");
			if (width != "") {
				stroke_width = double.parse (width);

				line_color_r = double.parse (Preferences.get ("line_color_r"));
				line_color_g = double.parse (Preferences.get ("line_color_g"));
				line_color_b = double.parse (Preferences.get ("line_color_b"));
				line_color_a = double.parse (Preferences.get ("line_color_a"));

				handle_color_r = double.parse (Preferences.get ("handle_color_r"));
				handle_color_g = double.parse (Preferences.get ("handle_color_g"));
				handle_color_b = double.parse (Preferences.get ("handle_color_b"));
				handle_color_a = double.parse (Preferences.get ("handle_color_a"));

				fill_color_r = double.parse (Preferences.get ("fill_color_r"));
				fill_color_g = double.parse (Preferences.get ("fill_color_g"));
				fill_color_b = double.parse (Preferences.get ("fill_color_b"));
				fill_color_a = double.parse (Preferences.get ("fill_color_a"));
			}
		}
	}

	public bool is_filled () {
		return fill;
	}

	public void set_fill (bool f) {
		fill = f;
	}

	public EditPoint get_first_point () {
		if (unlikely (points.size == 0)) {
			warning ("No point");
			return new EditPoint ();
		}
		
		return points.get (0);
	}

	public EditPoint get_last_point () {
		if (unlikely (points.size == 0)) {
			warning ("No point");
			return new EditPoint ();
		}
		
		return points.get (points.size - 1);
	}

	public bool has_direction () {
		return direction_is_set;
	}

	public bool empty () {
		return points.size == 0;
	}

	public void set_stroke (double width) {
		stroke = width;	
	}

	public void draw_boundaries  (Context cr) {
		double x = Glyph.reverse_path_coordinate_x (xmin); 
		double y = Glyph.reverse_path_coordinate_y (ymin);
		double x2 = Glyph.reverse_path_coordinate_x (xmax);
		double y2 = Glyph.reverse_path_coordinate_y (ymax);
		
		cr.save ();
		
		cr.set_source_rgba (0, 0, 0.3, 1);
		cr.set_line_width (2);
		cr.rectangle (x, y, x2 - x, y2 - y);
		cr.stroke ();
		
		cr.restore ();
	}

	public void draw_outline (Context cr) {
		unowned EditPoint? n = null;
		unowned EditPoint en;
		unowned EditPoint em;
		
		if (points.size < 2) {
			return;
		}
		
		cr.new_path ();
		
		// draw lines
		foreach (EditPoint e in points) {
			if (n != null) {
				en = (!) n;
				draw_next (en, e, cr);
			}
			
			n = e;
		}

		// close path
		if (!is_open () && n != null) {
			en = (!) n;
			em = points.get (0).get_link_item ();
			draw_next (en, em, cr);
		}

		cr.stroke ();
	}
	
	public void draw_edit_points (Context cr) {		
		if (is_editable ()) {
			// control points for curvature
			foreach (EditPoint e in points) {
				if (show_all_line_handles || e.selected || e.selected_handle > 0) {
					draw_edit_point_handles (e, cr);
				}
			}
						
			// control points
			foreach (EditPoint e in points) {
				draw_edit_point (e, cr);
			}
		}
	}

	/** Add all control points for a path to the cairo context.
	 * Call Context.new_path (); before this method and Context.fill ()
	 * to show the path.
	 */
	public void draw_path (Context cr, Color? color = null) {
		unowned EditPoint? n = null;
		unowned EditPoint en;
		unowned EditPoint em;
		Color c;
		Glyph g;
		double center_x, center_y;
		double ex, ey;

		if (points.size == 0){
			return;
		}

		g = MainWindow.get_current_glyph ();
		
		center_x = g.allocation.width / 2.0;
		center_y = g.allocation.height / 2.0;

		ex = center_x + points.get (0).x;
		ey = center_y - points.get (0).y;
		
		cr.move_to (ex, ey);
		
		// draw lines
		foreach (EditPoint e in points) {
			if (n != null) {
				en = (!) n;
				draw_next (en, e, cr);
			}
			
			n = e;
		}
		
		// close path
		if (!is_open () && points.size >= 2 && n != null) {
			en = (!) n;
			em = points.get (0).get_link_item ();
			draw_next (en, em, cr);
		}

		// fill path
		cr.close_path ();
		
		if (color != null) {
			c = (!) color;
			cr.set_source_rgba (c.r, c.g, c.b, c.a);
		} else {
			if (is_clockwise ()) {
				cr.set_source_rgba (80/255.0, 95/255.0, 137/255.0, 0.5);
			} else {
				cr.set_source_rgba (144/255.0, 145/255.0, 236/255.0, 0.5);
			}
		}
	}

	private void draw_next (EditPoint e, EditPoint en, Context cr) {
		PointType r = e.get_right_handle ().type;
		PointType l = en.get_left_handle ().type;
		
		if (r == PointType.DOUBLE_CURVE || l == PointType.DOUBLE_CURVE) {
			draw_double_curve (e, en, cr);
		} else {
			draw_curve (e, en, cr);
		}
	}
	
	private static void draw_double_curve (EditPoint e, EditPoint en, Context cr) {
		EditPoint middle;
		double x, y;
		
		x = e.get_right_handle ().x + (en.get_left_handle ().x - e.get_right_handle ().x) / 2;
		y = e.get_right_handle ().y + (en.get_left_handle ().y - e.get_right_handle ().y) / 2;
		
		middle = new EditPoint (x, y, PointType.DOUBLE_CURVE);
		middle.right_handle = en.get_left_handle ().copy ();
		
		middle.right_handle.type = PointType.DOUBLE_CURVE;
		middle.left_handle.type = PointType.DOUBLE_CURVE;
		
		draw_curve (e, middle, cr);
		draw_curve (middle, en, cr);		
	}
		
	private static void draw_curve (EditPoint e, EditPoint en, Context cr, double alpha = 1) {
		Glyph g = MainWindow.get_current_glyph ();
		double xa, ya, xb, yb, xc, yc, xd, yd;
		PointType t = e.get_right_handle ().type;
		PointType u = en.get_left_handle ().type;
		
		get_bezier_points (e, en, out xa, out ya, out xb, out yb, out xc, out yc, out xd, out yd);

		cr.set_source_rgba (line_color_r, line_color_g, line_color_b, line_color_a);
		cr.set_line_width (stroke_width / g.view_zoom);
		
		cr.line_to (xa, ya); // this point makes sense only if it is in the first or last position

		if (t == PointType.QUADRATIC || t == PointType.LINE_QUADRATIC || t == PointType.DOUBLE_CURVE || u == PointType.QUADRATIC || u == PointType.LINE_QUADRATIC || u == PointType.DOUBLE_CURVE) {
			cr.curve_to ((xa + 2 * xb) / 3, (ya + 2 * yb) / 3, (xd + 2 * xb) / 3, (yd + 2 * yb) / 3, xd, yd);		
		} else {
			cr.curve_to (xb, yb, xc, yc, xd, yd);
		}
	}
	
	/** Curve relative to window center. */
	public static void get_bezier_points (EditPoint e, EditPoint en, out double xa, out double ya, out double xb, out double yb, out double xc, out double yc, out double xd, out double yd) {
		Glyph g = MainWindow.get_current_glyph ();
		
		double center_x, center_y;
		
		center_x = g.allocation.width / 2.0;
		center_y = g.allocation.height / 2.0;
				
		xa = center_x + e.x;
		ya = center_y - e.y;

		xb = center_x + e.get_right_handle ().x;
		yb = center_y - e.get_right_handle ().y;
		
		xc = center_x + en.get_left_handle ().x;
		yc = center_y - en.get_left_handle ().y;
		
		xd = center_x + en.x;
		yd = center_y - en.y;		
	}

	/** Curve absolute glyph data. */
	public static void get_abs_bezier_points (EditPoint e, EditPoint en, out double xa, out double ya, out double xb, out double yb, out double xc, out double yc, out double xd, out double yd) {
		xa =  + e.x;
		ya =  - e.y;

		xb =  + e.get_right_handle ().x;
		yb =  - e.get_right_handle ().y;
		
		xc =  + en.get_left_handle ().x;
		yc =  - en.get_left_handle ().y;
		
		xd =  + en.x;
		yd =  - en.y;		
	}
		
	/** Line points relative to centrum. */
	public static void get_line_points (EditPoint e, EditPoint en, out double xa, out double ya, out double xb, out double yb) {
		double xc = Glyph.xc ();
		double yc = Glyph.yc ();
		
		xa = xc + e.x;
		ya = yc - e.y;
		
		xb = xc + en.x;
		yb = yc - en.y;
	}
		
	public void draw_line (EditPoint e, EditPoint en, Context cr, double alpha = 1) { 
		Glyph g = MainWindow.get_current_glyph ();
		double ax, ay, bx, by;

		get_line_points (e, en, out ax, out ay, out bx, out by);
	
		cr.set_source_rgba (handle_color_r, handle_color_g, handle_color_b, handle_color_a);
		cr.set_line_width (1.7 * (stroke_width / g.view_zoom));

		cr.line_to (ax, ay);
		cr.line_to (bx, by);
		
		cr.stroke ();
	}
	
	public void draw_edit_point  (EditPoint e, Context cr) {
		draw_edit_point_center (e, cr);
	}
	
	public void draw_edit_point_handles (EditPoint e, Context cr)
		requires (active_edit_point_handle_image != null && edit_point_handle_image != null)
	{
		ImageSurface img_right, img_left;

		EditPoint handle_right = e.get_right_handle ().get_point ();
		EditPoint handle_left = e.get_left_handle ().get_point ();

		cr.stroke ();
		
		if (e.type != PointType.HIDDEN) {
			if (e.get_right_handle ().selected) {
				img_right = (!) selected_edit_point_handle_image;
			} else if (e.get_right_handle ().active) {
				img_right = (!) active_edit_point_handle_image;
			} else {
				img_right = (!) edit_point_handle_image;
			}
			
			if (e.get_left_handle ().selected) {
				img_left = (!) selected_edit_point_handle_image;
			} else if (e.get_left_handle ().active) {
				img_left = (!) active_edit_point_handle_image;
			} else {
				img_left = (!) edit_point_handle_image;
			}

			if (!(is_open () && e == points.get (points.size - 1))) {
				draw_line (handle_right, e, cr, 0.15);
				draw_image (cr, img_right, e.get_right_handle ().x, e.get_right_handle ().y);
			}
			
			if (!(is_open () && e == points.get (0))) {
				draw_line (handle_left, e, cr, 0.15);
				draw_image (cr, img_left, e.get_left_handle ().x, e.get_left_handle ().y);
			}
		}
	}

	public static void draw_edit_point_center (EditPoint e, Context cr) 
		requires (active_edit_point_image != null && edit_point_image != null)
	{	
		ImageSurface img;
		
		if (e.type != PointType.HIDDEN) {
			if (e.type == PointType.CUBIC || e.type == PointType.LINE_CUBIC) {
				if (e.is_selected ()) {
					img = (e.active) ? (!) cubic_active_selected_edit_point_image : (!) cubic_selected_edit_point_image;
				} else {
					img = (e.active) ? (!) cubic_active_edit_point_image : (!) cubic_edit_point_image;
				}
			} else {
				if (e.is_selected ()) {
					img = (e.active) ? (!) active_selected_edit_point_image : (!) selected_edit_point_image;
				} else {
					img = (e.active) ? (!) active_edit_point_image : (!) edit_point_image;
				}
			}
			draw_image (cr, img, e.x, e.y);
		} 
	}
	
	public static void draw_image (Context cr, ImageSurface img, double x, double y) {
		Glyph g = MainWindow.get_current_glyph ();
		double r = 1.0 / 10.0;
		
		double width = Math.sqrt (stroke_width);
		
		double ivz = 1 / g.view_zoom;
		double ivs = 1 / width;

		double xc = g.allocation.width / 2.0;
		double yc = g.allocation.height / 2.0;

		cr.save ();
		cr.scale (ivz * width * r, ivz * width * r);
		
		x = xc + x - (width * r * img.get_width () / 2.0) * ivz; 
		y = yc - y - (width * r * img.get_height () / 2.0) * ivz;
		
		cr.set_source_surface (img, x * g.view_zoom * ivs * 1/r, y * g.view_zoom * ivs * 1/r);
		cr.paint ();
		cr.restore ();
	}
	
	/** Set direction for this path to clockwise for outline and 
	 * counter clockwise for inline paths.
	 */
	public bool force_direction (Direction direction) {
		bool c = (direction == Direction.CLOCKWISE);
		direction_is_set = true;
		
		if (c != is_clockwise ()) {
			this.reverse ();
		}
		
		if (unlikely (is_clockwise () != c)) {
			warning ("Failed to set direction for path in force_direction.");
			return true;
		}
				
		return false;
	}

	/** Switch direction from clockwise path to counter clockwise path or vise versa. */
	public void reverse () {
		bool direction = is_clockwise ();

		if (no_derived_direction) {
			clockwise_direction = !clockwise_direction;
		}
		
		reverse_points ();
		
		if (unlikely (direction == is_clockwise ())) {
			stderr.printf ("Error: Direction did not change after reversing path.\n");
			stderr.printf (@"Length: $(points.size)\n");
			stderr.printf (@"No particular direction can be derived: $no_derived_direction \n");
			warning ("Path.reverse () failed.\n");
		}
	}

	private void reverse_points () requires (points.size > 0) {
		EditPointHandle t;
		Path p = copy ();
		EditPoint e;
		
		create_list ();	
		
		points.clear ();
		
		for (int i = p.points.size - 1; i >= 0 ; i--) {
			e = p.points.get (i);
			
			t = e.right_handle;
			e.right_handle = e.left_handle;
			e.left_handle = t;
			
			add_point (e);
		}
		
		create_list ();
	}

	public void print_all_points () {
		int i = 0;
		foreach (EditPoint p in points) {
			++i;
			string t = (p.type == PointType.END) ? " endpoint" : "";
			stdout.printf (@"Point $i at ($(p.x), $(p.y)) $t \n");
		}
	}
	
	private double clockwise_sum () {
		double sum = 0;
		
		return_val_if_fail (points.size >= 3, 0);
		
		foreach (EditPoint e in points) {
			sum += e.get_direction ();
		}
		
		return sum;
	}
	
	public bool is_clockwise () {
		double s;
		
		if (unlikely (points.size <= 2)) {
			no_derived_direction = true;
			return clockwise_direction;
		}
		
		s = clockwise_sum ();
		
		if (s == 0) {
			no_derived_direction = true;
			return clockwise_direction;	
		}
		
		return s > 0;
	}
	
	public bool is_editable () {
		return edit;
	}

	/** Show control points on outline path. */
	public void set_editable (bool e) {
		edit = e;
	}
	
	public bool is_open () {
		return open;
	}

	/** Resize path relative to bottom left coordinates. */
	public void resize (double ratio) {	
		foreach (EditPoint p in points) {
			p.x *= ratio;
			p.y *= ratio;
			p.right_handle.length *= ratio;
			p.left_handle.length *= ratio;
		}
		
		xmin *= ratio;	
		xmax *= ratio;
		ymin *= ratio;
		ymax *= ratio;
	}

	public void scale (double scale_x, double scale_y) {		
		foreach (EditPoint p in points) {
			p.right_handle.length *= scale_x * scale_y;
			p.left_handle.length *= scale_x * scale_y;
		}
		
		foreach (EditPoint p in points) {
			p.x *= scale_x;
			p.y *= scale_y;
		}
		
		xmin *= scale_x;	
		xmax *= scale_x;
		ymin *= scale_y;
		ymax *= scale_y;
	}
	
	public Path copy () {
		Path new_path = new Path ();
		EditPoint p;
		
		foreach (EditPoint ep in points) {
			p = ep.copy ();
			new_path.add_point (p);
		}
		
		new_path.edit = edit;
		new_path.open = open;
		new_path.stroke = stroke;
		new_path.fill = fill;
		new_path.direction_is_set = direction_is_set;
		new_path.create_list ();
		
		return new_path;
	}	
	
	public bool is_over (double x, double y) {
		Glyph g = MainWindow.get_current_glyph ();
		
		x = x * Glyph.ivz () + g.view_offset_x - Glyph.xc ();
		y = y * Glyph.ivz () + g.view_offset_y - Glyph.yc ();

		y *= -1;
		
		return is_over_coordinate (x, y);
	}
	
	public bool is_over_coordinate (double x, double y) {
		return is_over_coordinate_var (x, y);
	}
	
	public static double distance (double ax, double bx, double ay, double by) {
		return Math.fabs (Math.sqrt (Math.pow (ax - bx, 2) + Math.pow (ay - by, 2)));
	}
	
	public static double distance_pixels (double x1, double y1, double x2, double y2) {
		return distance (Glyph.path_coordinate_x (x1),
			Glyph.path_coordinate_x (x2),
			Glyph.path_coordinate_x (y1),
			Glyph.path_coordinate_x (y2));
	}
	
	public static double get_length_from (EditPoint a, EditPoint b) {
		double x, y;
		
		x = Math.fabs (a.x - a.get_right_handle ().x);
		x += Math.fabs (a.get_right_handle ().x - b.get_left_handle ().x );
		x += Math.fabs (b.get_left_handle ().x - b.x);

		y = Math.fabs (a.y - a.get_right_handle ().y);
		y += Math.fabs (a.get_right_handle ().y - b.get_left_handle ().y);
		y += Math.fabs (b.get_left_handle ().y - b.y);
		
		return Math.fabs (Math.sqrt (x * x + y * y));
	} 

	/** Variable precision */
	public bool is_over_coordinate_var (double x, double y) {
		PathList pathlist;
		bool in_path = false;
		int width;
		ClickMap click_map;
		int px, py;
		int click_x, click_y;
		
		if (points.size < 2) {
			return false;
		}

		if (stroke > 0) {
			pathlist = StrokeTool.get_stroke (this, stroke);
			
			if (pathlist.paths.size > 1) {
				if (pathlist.paths.get (1).is_over_coordinate_var (x, y)) {
					return false;
				}
			}
			
			return pathlist.get_first_path ().is_over_coordinate_var (x, y);
		}	
		
		if (!is_over_boundry (x, y)) {
			return false;
		}
		
		
		// generate a rasterized image of the object
		width = 160;
		click_map = new ClickMap (width);
		px = 0;
		py = 0;
		
		click_map.create_click_map (this);

		click_x = (int) (width * ((x - xmin) / (xmax - xmin)));
		click_y = (int) (width * ((y - ymin) / (ymax - ymin)));

		in_path = click_map.get_value (click_x, click_y) != '\0';
		
		click_map.set_value (click_x, click_y, 'X');
		
		return in_path;
	}
	
	public bool is_over_boundry (double x, double y) {
		if (unlikely (ymin == double.MAX || ymin == 10000)) {
			warning ("bounding box is not calculated, run update_region_boundaries first.");
			update_region_boundaries ();
		}

		return (ymin <= y <= ymax) && (xmin <= x <= xmax);
	}

	public bool has_overlapping_boundry (Path p) {
		return !(xmax <= p.xmin || ymax <= p.ymin) || (xmin >= p.xmax || ymin >= p.ymax);
	}
	
	// FIXME: DELETE?
	public EditPoint delete_first_point () {
		EditPoint r;
		int size;
		
		size = points.size;
		if (unlikely (size == 0)) {
			warning ("No points in path.");
			return new EditPoint ();
		}
		
		r = points.get (0);
		points.remove_at (0);
		
		if (size > 1) {
			r.get_next ().prev = null;
		}
		
		return r;
	}
		
	public EditPoint delete_last_point () {
		EditPoint r;
		int size;
		
		size = points.size;
		if (unlikely (size == 0)) {
			warning ("No points in path.");
			return new EditPoint ();
		}
		
		r = points.get (size - 1);
		points.remove_at (size - 1);
		
		if (size > 1) {
			r.get_prev ().next = null;
			
			if (r.next != null) {
				r.get_next ().prev = null;
			}
		}
		
		return r;
	}
	
	public EditPoint add (double x, double y) {
		if (points.size > 0) {
			return add_after (x, y, points.get (points.size - 1));
		}
		
		return add_after (x, y, null);
	}

	public EditPoint add_point (EditPoint p) {
		if (points.size > 0) {
			return add_point_after (p, points.get (points.size - 1));
		}
		
		return add_point_after (p, null);
	}

	/** Insert a new point after @param previous_point and return a reference 
	 * to the new item in list.
	 */
	public EditPoint add_after (double x, double y, EditPoint? previous_point) {
		EditPoint p = new EditPoint (x, y, PointType.NONE);	
		return add_point_after (p, previous_point);
	}
	
	/** @return a list item pointing to the new point */
	public EditPoint add_point_after (EditPoint p, EditPoint? previous_point) {
		int prev_index;

		if (unlikely (previous_point == null && points.size != 0)) {
			warning ("previous_point == null");
			previous_point = points.get (points.size - 1).get_link_item ();
		}

		if (points.size == 0) {
			points.add (p);
			p.prev = points.get (0).get_link_item ();
			p.next = points.get (0).get_link_item ();
		} else {
			p.prev = (!) previous_point;
			p.next = ((!) previous_point).next;
			
			prev_index = points.index_of ((!) previous_point);
			
			if (unlikely (!(0 <= prev_index < points.size))) {
				warning ("no previous point");
			}
			
			points.insert (prev_index + 1, p);			
		}
		
		last_point = p;
		
		return p;
	}

	public void recalculate_linear_handles () {
		foreach (EditPoint e in points) {
			e.recalculate_linear_handles ();
		}
	}

	public void close () {
		open = false;
		edit = false;

		create_list ();
		
		if (points.size > 2) {
			points.get (0).recalculate_linear_handles ();
			points.get (points.size - 1).recalculate_linear_handles ();
		}
	}
	
	public void reopen () {
		open = true;
		edit = true;
	}
	
	/** Move path. */
	public void move (double delta_x, double delta_y) {
		foreach (EditPoint ep in points) {
			ep.x += delta_x;
			ep.y += delta_y;
		}
		
		update_region_boundaries ();
	}

	private void update_region_boundaries_for_point (EditPoint p) {
		EditPointHandle left_handle;
		EditPointHandle right_handle;
		
		left_handle = p.get_left_handle ();
		right_handle = p.get_right_handle ();
	
		if (p.x > xmax) {
			xmax = p.x;
		}
		
		if (p.x < xmin) {
			xmin = p.x;
		}

		if (p.y > ymax) {
			ymax = p.y;
		}

		if (p.y < ymin) {
			ymin = p.y;
		}
		
		update_region_boundaries_for_handle (left_handle);
		update_region_boundaries_for_handle (right_handle);
	}

	private void update_region_boundaries_for_handle (EditPointHandle h) {
		if (h.x > xmax) {
			xmax = h.x;
		}

		if (h.x < xmin) {
			xmin = h.x;
		}

		if (h.y > ymax) {
			ymax = h.y;
		}

		if (h.y < ymin) {
			ymin = h.y;
		}
	}

	public void update_region_boundaries () {
		PathList paths;
		
		xmax = -10000;
		xmin = 10000;
		ymax = -10000;
		ymin = 10000;
		
		if (points.size == 0) {
			xmax = 0;
			xmin = 0;
			ymax = 0;
			ymin = 0;
		}

		foreach (EditPoint p in points) {
			update_region_boundaries_for_point (p);
		}
		
		if (stroke > 0) {
			xmax += stroke;
			ymax += stroke;
			xmin -= stroke;
			ymin -= stroke;
		}
	}
		
	/** Test if @param path is a valid outline for this object. */	
	public bool test_is_outline (Path path) {
		assert (false);
		return this.test_is_outline_of_path (path) && path.test_is_outline_of_path (this);
	}
	
	private bool test_is_outline_of_path (Path outline)
		requires (outline.points.size >= 2 || points.size >= 2)
	{	
		// rather slow use it for testing, only
		unowned EditPoint i = outline.points.get (0).get_link_item ();
		unowned EditPoint prev = outline.points.get (outline.points.size - 1).get_link_item ();

		double tolerance = 1;
		bool g = false;
		
		EditPoint ep = new EditPoint (0, 0);
		double min = double.MAX;
		
		while (true) {
			min = 10000;
			 
			all_of (prev, i, (cx, cy) => {
					get_closest_point_on_path (ep, cx, cy);

					double n = pow (ep.x - cx, 2) + pow (cy - ep.y, 2);
					
					if (n < min) min = n;
					
					if (n < tolerance) {
						g = true;
						return false;
					}

					return true;
				});
			
			if (!g) {
				critical (@"this path does not seem to be the outline. (min $min)");
			}
			
			g = false;
			
			if (i == outline.points.get (outline.points.size - 1)) {
				break;
			}
				
			i = i.get_next ();
		}
		
		return true;
	}

	/** Add the extra point between line handles for double curve. */
	public void add_hidden_double_points () requires (points.size > 1) {
		EditPoint hidden;
		EditPoint first = points.get (points.size - 1);
		PointType left;
		PointType right;
		double x, y;
		Gee.ArrayList<EditPoint> middle_points = new Gee.ArrayList<EditPoint> ();
		Gee.ArrayList<EditPoint> first_points = new Gee.ArrayList<EditPoint> ();
		
		foreach (EditPoint next in points) {
			left = first.get_right_handle ().type;
			right = next.get_left_handle ().type;
						
			if (right == PointType.DOUBLE_CURVE || left == PointType.DOUBLE_CURVE) {
				first.get_right_handle ().type = PointType.QUADRATIC;

				// half way between handles
				x = first.get_right_handle ().x + (next.get_left_handle ().x - first.get_right_handle ().x) / 2;
				y = first.get_right_handle ().y + (next.get_left_handle ().y - first.get_right_handle ().y) / 2;
				
				hidden = new EditPoint (x, y, PointType.QUADRATIC);
				hidden.right_handle.move_to_coordinate_internal (next.get_left_handle ().x, next.get_left_handle ().y);
				hidden.get_right_handle ().type = PointType.QUADRATIC;
				
				hidden.get_left_handle ().type = PointType.QUADRATIC;
				hidden.type = PointType.QUADRATIC;
				
				first.get_right_handle ().type = PointType.QUADRATIC;
				first.type = PointType.QUADRATIC;
				
				next.get_left_handle ().type = PointType.QUADRATIC;
				next.type = PointType.QUADRATIC;
				
				middle_points.add (hidden);
				first_points.add (first);
			}
			first = next;
		}
		
		for (int i = 0; i < middle_points.size; i++) {
			hidden = middle_points.get (i);
			add_point_after (middle_points.get (i), first_points.get (i));
		}
	}

	/** Convert quadratic bezier points to cubic representation of the glyph
	 * for ttf-export.
	 */ 
	public Path get_quadratic_points () {
		PointConverter converter = new PointConverter (this);
		return converter.get_quadratic_path ();
	}
	
	void convert_remaining_cubic (EditPoint ep, EditPoint prev) {
		double x, y;
		
		ep.set_tie_handle (true);
		
		if (ep.next != null) {
			((!) ep.next).set_tie_handle (false);
		}

		prev.get_left_handle ().type = PointType.QUADRATIC;
		prev.get_right_handle ().type = PointType.QUADRATIC;
		prev.get_right_handle ().move_delta (0.000001, 0.000001);
		
		x = prev.get_right_handle ().x;
		y = prev.get_right_handle ().y;
		
		ep.get_left_handle ().move_to_coordinate (ep.x - (ep.x - prev.x) / 2, 
			ep.y - (ep.y - prev.y) / 2);		
	}

	public void insert_new_point_on_path (EditPoint ep, double t = -1) {
		EditPoint start, stop;
		double x0, x1, y0, y1;
		double position, min;
		PointType left, right;
		
		if (ep.next == null || ep.prev == null) {
			warning ("missing point");
			return;
		}

		start = ep.get_prev ();
		stop = ep.get_next ();

		right = start.get_right_handle ().type;
		left = stop.get_left_handle ().type;
		
		if (right == PointType.CUBIC || left == PointType.CUBIC) {
			start.get_right_handle ().type = PointType.CUBIC;
			stop.get_left_handle ().type = PointType.CUBIC;
		}

		add_point_after (ep, ep.get_prev ());

		min = double.MAX;

		position = 0.5;
		
		if (t < 0) {
			all_of (start, stop, (cx, cy, t) => {
				double n = pow (ep.x - cx, 2) + pow (ep.y - cy, 2);
				
				if (n < min) {
					min = n;
					position = t;
				}
				
				return true;
			});
		} else {
			position = t;
		}
		
		if (right == PointType.DOUBLE_CURVE || left == PointType.DOUBLE_CURVE) {
			double_bezier_vector (position, start.x, start.get_right_handle ().x, stop.get_left_handle ().x, stop.x, out x0, out x1);
			double_bezier_vector (position, start.y, start.get_right_handle ().y, stop.get_left_handle ().y, stop.y, out y0, out y1);

			ep.get_left_handle ().set_point_type (PointType.DOUBLE_CURVE);	
			ep.get_right_handle ().set_point_type (PointType.DOUBLE_CURVE);
						
			ep.get_left_handle ().move_to_coordinate (x0, y0);  // FIXME: SWAPPED?
			ep.get_right_handle ().move_to_coordinate (x1, y1);

			ep.type = PointType.DOUBLE_CURVE;
		} else if (right == PointType.QUADRATIC) {		
			x0 = quadratic_bezier_vector (1 - position, stop.x, start.get_right_handle ().x, start.x);
			y0 = quadratic_bezier_vector (1 - position, stop.y, start.get_right_handle ().y, start.y);
			ep.get_right_handle ().move_to_coordinate (x0, y0);
			
			ep.get_left_handle ().set_point_type (PointType.QUADRATIC);	
			ep.get_right_handle ().set_point_type (PointType.QUADRATIC);
			
			ep.get_left_handle ().move_to_coordinate_internal (0, 0);
			
			ep.type = PointType.QUADRATIC;				
		} else if (right == PointType.CUBIC || left == PointType.CUBIC) {
			bezier_vector (position, start.x, start.get_right_handle ().x, stop.get_left_handle ().x, stop.x, out x0, out x1);
			bezier_vector (position, start.y, start.get_right_handle ().y, stop.get_left_handle ().y, stop.y, out y0, out y1);

			ep.get_left_handle ().set_point_type (PointType.CUBIC);
			ep.get_left_handle ().move_to_coordinate (x0, y0);
			
			ep.get_right_handle ().set_point_type (PointType.CUBIC);
			ep.get_right_handle ().move_to_coordinate (x1, y1);
			
			ep.type = PointType.LINE_CUBIC;
		} else if (right == PointType.LINE_QUADRATIC && left == PointType.LINE_QUADRATIC) {
			ep.get_right_handle ().set_point_type (PointType.LINE_QUADRATIC);
			ep.get_left_handle ().set_point_type (PointType.LINE_QUADRATIC);
			ep.type = PointType.QUADRATIC;
		} else if (right == PointType.LINE_CUBIC && left == PointType.LINE_CUBIC) {
			ep.get_right_handle ().set_point_type (PointType.LINE_CUBIC);
			ep.get_left_handle ().set_point_type (PointType.LINE_CUBIC);
			ep.type = PointType.LINE_CUBIC;
		} else if (right == PointType.LINE_DOUBLE_CURVE && left == PointType.LINE_DOUBLE_CURVE) {
			ep.get_right_handle ().set_point_type (PointType.LINE_DOUBLE_CURVE);
			ep.get_left_handle ().set_point_type (PointType.LINE_DOUBLE_CURVE);
			ep.type = PointType.DOUBLE_CURVE;
		} else 

		ep.get_left_handle ().parent = ep;
		ep.get_right_handle ().parent = ep;
		
		stop.get_left_handle ().length *= 1 - position;
		start.get_right_handle ().length *= position;

		if (right == PointType.QUADRATIC) { // update connected handle
			if (ep.prev != null) {
				ep.get_left_handle ().move_to_coordinate_internal (
					ep.get_prev ().right_handle.x, 
					ep.get_prev ().right_handle.y);

			} else {
				warning ("ep.prev is null for quadratic point");
			}
		}
		
		create_list ();
		foreach (EditPoint p in points) {
			p.recalculate_linear_handles ();
		}
	}
			
	/** Get a point on the this path closest to x and y coordinates. */
	public void get_closest_point_on_path (EditPoint edit_point, double x, double y) {
		return_if_fail (points.size >= 1);
		
		double min = double.MAX;
		double n = 0;
		bool g = false;
		
		double ox = 0;
		double oy = 0;
		
		EditPoint prev = points.get (points.size - 1).get_link_item ();
		EditPoint i = points.get (0).get_link_item ();

		bool done = false;
		bool exit = false;
		bool first = true;
		
		EditPoint? previous_point = null;
		EditPoint? next_point = null;

		EditPoint previous;
		EditPoint next;
		double step = 0;

		if (points.size == 0) {
			warning ("Empty path.");
			return;
		}

		if (points.size == 1) {
			edit_point.x = i.x;
			edit_point.y = i.y;
			
			edit_point.prev = i;
			edit_point.next = i;
			return;
		}
		
		edit_point.x = i.x;
		edit_point.y = i.y;
		
		create_list ();
		
		while (!exit) {
			if (!first && i == points.get (points.size - 1)) {
				done = true;
			}
			
			if (!done) {
				i = i.get_next ();
				prev = i.get_prev ();
			}	else if (done && !is_open ()) {
				i = points.get (0).get_link_item ();
				prev = points.get (points.size - 1).get_link_item ();
				exit = true;
			} else {
				break;
			}
			
			all_of (prev, i, (cx, cy, t) => {
				n = pow (x - cx, 2) + pow (y - cy, 2);
				
				if (n < min) {
					min = n;
					
					ox = cx;
					oy = cy;
				
					previous_point = i.prev;
					next_point = i;
					
					step = t;
					
					g = true;
				}
				
				return true;
			});
			
			first = false;
		}

		if (previous_point == null && is_open ()) {
			previous_point = points.get (points.size - 1).get_link_item ();
		}
		
		if (previous_point == null) {
			warning (@"previous_point == null, points.size: $(points.size)");
			return;
		}
		
		if (next_point == null) {
			warning ("next_point != null");
			return;
		}

		previous = (!) previous_point;
		next = (!) next_point;

		edit_point.prev = previous_point;
		edit_point.next = next_point;
		
		edit_point.set_position (ox, oy);
	}

	public static bool all_of (EditPoint start, EditPoint stop, RasterIterator iter, int steps = -1) {
		PointType right = PenTool.to_curve (start.get_right_handle ().type);
		PointType left = PenTool.to_curve (stop.get_left_handle ().type);
		
		if (steps == -1) {
			steps = (int) (10 * get_length_from (start, stop));
		}
		
		if (right == PointType.DOUBLE_CURVE || left == PointType.DOUBLE_CURVE) {
			return all_of_double (start.x, start.y, start.get_right_handle ().x, start.get_right_handle ().y, stop.get_left_handle ().x, stop.get_left_handle ().y, stop.x, stop.y, iter, steps);
		} else if (right == PointType.QUADRATIC && left == PointType.QUADRATIC) {
			return all_of_quadratic_curve (start.x, start.y, start.get_right_handle ().x, start.get_right_handle ().y, stop.x, stop.y, iter, steps);
		} else if (right == PointType.CUBIC && left == PointType.CUBIC) {
			return all_of_curve (start.x, start.y, start.get_right_handle ().x, start.get_right_handle ().y, stop.get_left_handle ().x, stop.get_left_handle ().y, stop.x, stop.y, iter, steps);
		}
		
		warning (@"Mixed point types in segment $(start.x),$(start.y) to $(stop.x),$(stop.y)");
		return all_of_quadratic_curve (start.x, start.y, start.get_right_handle ().x, start.get_right_handle ().x, stop.x, stop.y, iter, steps);
	}

	public static void get_point_for_step (EditPoint start, EditPoint stop, double step, out double x, out double y) {
		// FIXME: Types
		x = bezier_path (step, start.x, start.get_right_handle ().x, stop.get_left_handle ().x, stop.x);
		y = bezier_path (step, start.y, start.get_right_handle ().y, stop.get_left_handle ().y, stop.y);	
	}

	private static bool all_of_double (double x0, double y0, double x1, double y1, double x2, double y2, double x3, double y3, RasterIterator iter, double steps = 400) {
		double px = x1;
		double py = y1;
		
		double t;
		double middle_x, middle_y;
		double double_step;
		
		middle_x = x1 + (x2 - x1) / 2;
		middle_y = y1 + (y2 - y1) / 2;
		
		for (int i = 0; i < steps; i++) {
			t = i / steps;
			
			px = quadratic_bezier_path (t, x0, x1, middle_x);
			py = quadratic_bezier_path (t, y0, y1, middle_y);
			
			double_step = t / 2;
			
			if (!iter (px, py, double_step)) {
				return false;
			}
			
		}
		
		for (int i = 0; i < steps; i++) {
			t = i / steps;
			
			px = quadratic_bezier_path (t, middle_x, x2, x3);
			py = quadratic_bezier_path (t, middle_y, y2, y3);
			
			double_step = 0.5 + t / 2;
			
			if (!iter (px, py, double_step)) {
				return false;
			}
		}	
		
		return true;	
	}
		
	private static bool all_of_quadratic_curve (double x0, double y0, double x1, double y1, double x2, double y2, RasterIterator iter, double steps = 400) {
		double px = x1;
		double py = y1;
		
		double t;
		
		for (int i = 0; i < steps; i++) {
			t = i / steps;
			
			px = quadratic_bezier_path (t, x0, x1, x2);
			py = quadratic_bezier_path (t, y0, y1, y2);
			
			if (!iter (px, py, t)) {
				return false;
			}
		}
		
		return true;
	}

	private static bool all_of_curve (double x0, double y0, double x1, double y1, double x2, double y2, double x3, double y3, RasterIterator iter, double steps = 400) {
		double px = x1;
		double py = y1;
		
		double t;
		
		for (int i = 0; i < steps; i++) {
			t = i / steps;
			
			px = bezier_path (t, x0, x1, x2, x3);
			py = bezier_path (t, y0, y1, y2, y3);
			
			if (!iter (px, py, t)) {
				return false;
			}
		}
		
		return true;
	}

	public bool all_segments (SegmentIterator iter) {
		unowned EditPoint i, next;
		
		if (points.size < 2) {
			return false;
		}

		for (int j = 0; j < points.size - 1; j++) {
			i = points.get (j).get_link_item ();
			next = i.get_next ();
			if (!iter (i, next)) {
				return false;
			}
		}
		
		if (!is_open ()) {
			return iter (points.get (points.size - 1), points.get (0));
		}
		
		return true;
	}

	public void all_of_path (RasterIterator iter, int steps = -1) {
		all_segments ((start, stop) => {
			return all_of (start, stop, iter, steps);
		});
	}
	
	public static double bezier_path (double step, double p0, double p1, double p2, double p3) {
		double q0, q1, q2;
		double r0, r1;

		q0 = step * (p1 - p0) + p0;
		q1 = step * (p2 - p1) + p1;
		q2 = step * (p3 - p2) + p2;

		r0 = step * (q1 - q0) + q0;
		r1 = step * (q2 - q1) + q1;

		return step * (r1 - r0) + r0;
	}

	public static void bezier_vector (double step, double p0, double p1, double p2, double p3, out double a0, out double a1) {
		double q0, q1, q2;

		q0 = step * (p1 - p0) + p0;
		q1 = step * (p2 - p1) + p1;
		q2 = step * (p3 - p2) + p2;

		a0 = step * (q1 - q0) + q0;
		a1 = step * (q2 - q1) + q1;
	}

	public static double quadratic_bezier_vector (double step, double p0, double p1, double p2) {
		return step * (p1 - p0) + p0;
	}
	
	public static double quadratic_bezier_path (double step, double p0, double p1, double p2) {
		double q0 = step * (p1 - p0) + p0;
		double q1 = step * (p2 - p1) + p1;
		
		return step * (q1 - q0) + q0;
	}
	
	public static double double_bezier_path (double step, double p0, double p1, double p2, double p3) {
		double middle = p1 + (p2 - p1) / 2;
		
		if (step == 0.5) {
			// FIXME: return the middle point
			warning ("Middle");
		}
		
		if (step < 0.5) {
			return quadratic_bezier_path (2 * step, p0, p1, middle);
		}
		
		return quadratic_bezier_path (2 * (step - 0.5), middle, p2, p3);
	}
	
	public static void double_bezier_vector (double step, double p0, double p1, double p2, double p3, out double a0, out double a1) {
		double b0, b1, c0, c1, d0, d1;
	
		if (unlikely (step <= 0 || step >= 1)) {
			warning (@"Bad step: $step");
			step += 0.00004;
		}

		// set angle
		b0 = double_bezier_path (step + 0.00001, p0, p1, p2, p3);
		c0 = double_bezier_path (step + 0.00002, p0, p1, p2, p3);

		b1 = double_bezier_path (step - 0.00001, p0, p1, p2, p3);
		c1 = double_bezier_path (step - 0.00002, p0, p1, p2, p3);
		
		// adjust length
		d0 = b0 + (b0 - c0) * 25000 * (step);
		d1 = b1 + (b1 - c1) * 25000 * (1 - step);
	
		a0 = d0;
		a1 = d1;
	}
	
	public void plot (Context cr, WidgetAllocation allocation, double view_zoom) {
			double px = 0, py = 0;
			double xc = allocation.width / 2.0;
			double yc = allocation.height / 2.0;

			cr.save ();
			
			all_of_path ((x, y) => {
				//cr.set_source_rgba (0.3, 0.3, 0.3, 1);
				cr.move_to (px + xc, -py + yc);
				cr.line_to (x + xc, -y + yc);
				
				px = x;
				py = y;
				
				return true;
			});

			cr.stroke ();
			cr.restore ();
	}
	
	public void print_boundaries () {
		stderr.printf (@"xmax $xmax \n");
		stderr.printf (@"xmin $xmin \n");
		stderr.printf (@"ymax $ymax \n");
		stderr.printf (@"ymin $ymin \n");		
	}
	
	public bool has_region_boundaries () {
		return !(xmax == -10000 || xmin ==  10000 || ymax == -10000 || ymin ==  10000);
	}
	
	public void create_list () {
		EditPoint ep;
		
		if (points.size == 0) {
			return;
		}
		
		if (points.size == 1) {
			ep = points.get (0);
			ep.next = null;
			ep.prev = null;
			return;
		}
		
		ep = points.get (0);
		ep.next = points.get (1).get_link_item ();
		ep.prev = points.get (points.size - 1).get_link_item ();

		for (int i = 1; i < points.size - 1; i++) {
			ep = points.get (i);
			ep.prev = points.get (i - 1).get_link_item ();
			ep.next = points.get (i + 1).get_link_item ();
		}
		
		ep = points.get (points.size - 1);
		ep.next = points.get (0).get_link_item ();
		ep.prev = points.get (points.size - 2).get_link_item ();
	}

	public bool has_point (EditPoint ep) {
		return points.contains (ep);
	}
	
	public bool has_deleted_point () {
		foreach (EditPoint p in points) {
			if (p.deleted) {
				return true;
			}
		}
		return false;
	}
	
	/** @return the remaining parts as a new path. */
	public PathList process_deleted_points () 
		requires (points.size > 0)
	{
		EditPoint p;
		EditPoint ep;
		Path current_path = new Path ();
		Path remaining_points = new Path ();
		PathList path_list = new PathList ();
		int i;
		int index = 0;
		
		if (!has_deleted_point ()) { 
			return path_list;
		}
		
		if (points.size == 1) {
			points.remove_at (0);
			return path_list;
		}
		
		// set start position to the point that will be removed	
		for (i = 0; i < points.size; i++) {
			p = points.get (i);
						
			if (p.deleted) {
				index = i;
				i++;
				ep = p;
				break;
			}
		}

		// copy points after the deleted point
		while (i < points.size) {
			p = points.get (i);
			current_path.add_point (p);
			i++;
		}

		// copy points before the deleted point
		for (i = 0; i < index; i++) {
			p = points.get (i);
			remaining_points.add_point (p);
		}
		
		// merge if we still only have one path
		if (!is_open ()) {
			foreach (EditPoint point in remaining_points.points) {
				current_path.add_point (point.copy ());
			}
			
			if (current_path.points.size > 0) {
				ep = current_path.points.get (0);
				ep.set_tie_handle (false);
				ep.set_reflective_handles (false);
				ep.get_left_handle ().type = PenTool.to_line (ep.type);
				ep.type = PenTool.to_curve (ep.type);
				path_list.add (current_path);
			
				ep = current_path.points.get (current_path.points.size - 1);
				ep.get_right_handle ().type = PenTool.to_line (ep.type);
				ep.type = PenTool.to_curve (ep.get_right_handle ().type);
			}
		} else {
			if (current_path.points.size > 0) {
				ep = current_path.points.get (0);
				ep.set_tie_handle (false);
				ep.set_reflective_handles (false);
				ep.get_left_handle ().type = PenTool.to_line (ep.type);
				ep.type = PenTool.to_curve (ep.type);
				set_new_start (current_path.points.get (0));
				path_list.add (current_path);
				
				ep = current_path.points.get (current_path.points.size - 1);
				ep.get_right_handle ().type = PenTool.to_line (ep.type);
				ep.type = PenTool.to_curve (ep.get_right_handle ().type);
			}
			
			if (remaining_points.points.size > 0) {
				remaining_points.points.get (0).set_tie_handle (false);
				remaining_points.points.get (0).set_reflective_handles (false);
				remaining_points.points.get (0).type = remaining_points.points.get (0).type;
				set_new_start (remaining_points.points.get (0));
				path_list.add (remaining_points);
				
				if (current_path.points.size > 0) {
					ep = current_path.points.get (current_path.points.size - 1);
					ep.get_right_handle ().type = PenTool.to_line (ep.type);
					ep.type = PenTool.to_curve (ep.get_right_handle ().type);
				}
			}
		}
		
		foreach (Path path in path_list.paths) {
			path.update_region_boundaries ();
		}
		
		return path_list;
	}
		
	public void set_new_start (EditPoint ep) {
		Gee.ArrayList<EditPoint> list = new Gee.ArrayList<EditPoint> ();
		uint len = points.size;
		EditPoint iter = points.get (0);
		EditPoint? ni = null;
		bool found = false;

		foreach (EditPoint it in points) {
			if (it == ep) {
				found = true;
				break;
			}
			
			iter = iter.get_next ();
			ni = (!) iter;
		}
		
		if (unlikely (!found)) {
			warning ("Could not find edit point.");
		}
		
		if (ni == null) {
			return;			
		}
		
		iter = (!) ni;
		
		for (uint i = 0; i < len; i++) {
			list.add (iter);
			
			if (iter == points.get (points.size - 1)) {
				iter = points.get (0).get_link_item ();
			} else {
				iter = iter.get_next ();
			}		
		}
		
		points.clear ();
		
		foreach (EditPoint p in list) {
			points.add (p);
		}
	}
	
	public void append_path (Path path) {
		if (points.size == 0 || path.points.size == 0) {
			warning ("No points");
			return;
		}

		path.points.get (0).recalculate_linear_handles ();
		points.get (points.size - 1).recalculate_linear_handles ();
		
		// copy remaining points
		foreach (EditPoint p in path.points) {
			add_point (p.copy ());
		}
		
		path.points.clear ();
	}

	/** Roatate around coordinate xc, xc. */
	public void rotate (double theta, double xc, double yc) {
		double a, radius;
		
		foreach (EditPoint ep in points) {
			radius = sqrt (pow (xc - ep.x, 2) + pow (yc + ep.y, 2));
			
			if (yc + ep.y  < 0) {
				radius = -radius;
			}
			
			a = acos ((ep.x - xc) / radius);
			
			ep.x = xc + cos (a - theta) * radius;
			ep.y = yc + sin (a - theta) * radius;
			
			ep.get_right_handle ().angle -= theta;
			ep.get_left_handle ().angle -= theta;
			
			while (ep.get_right_handle ().angle < 0) {
				ep.get_right_handle ().angle += 2 * PI;
			}

			while (ep.get_left_handle ().angle < 0) {
				ep.get_left_handle ().angle += 2 * PI;
			}
		}

		update_region_boundaries ();
	}
	
	public void flip_vertical () {
		EditPointHandle hl, hr;
		double lx, ly, rx, ry;

		foreach (EditPoint e in points) {
			hl = e.get_left_handle ();
			hr = e.get_right_handle ();
			
			lx = hl.x;
			ly = hl.y;
			rx = hr.x;
			ry = hr.y;
						
			e.y *= -1;
			
			hr.move_to_coordinate_internal (rx, -1 * ry);
			hl.move_to_coordinate_internal (lx, -1 * ly);
		}
		
		update_region_boundaries ();
	}

	public void flip_horizontal () {
		EditPointHandle hl, hr;
		double lx, ly, rx, ry;
		foreach (EditPoint e in points) {
			hl = e.get_left_handle ();
			hr = e.get_right_handle ();
			
			lx = hl.x;
			ly = hl.y;
			rx = hr.x;
			ry = hr.y;
						
			e.x *= -1;
			
			hr.move_to_coordinate_internal (-1 * rx, ry);
			hl.move_to_coordinate_internal (-1 * lx, ly);
		}
		
		update_region_boundaries ();
	}

	public void init_point_type () {
		PointType type;
		
		switch (DrawingTools.point_type) {
			case PointType.QUADRATIC:
				type = PointType.LINE_QUADRATIC;
				break;
			case PointType.DOUBLE_CURVE:
				type = PointType.LINE_DOUBLE_CURVE;
				break;
			case PointType.CUBIC:
				type = PointType.LINE_CUBIC;
				break;
			default:
				warning ("No type is set");
				type = PointType.LINE_CUBIC;
				break;
		}
				
		foreach (EditPoint ep in points) {
			ep.type = type;
			ep.get_right_handle ().type = type;
			ep.get_left_handle ().type = type;
		}		
	}
	
	public void convert_path_ending_to_line () {
		if (points.size < 2) {
			return;
		}
		
		get_first_point ().get_left_handle ().convert_to_line ();
		get_last_point ().get_right_handle ().convert_to_line ();		
	}
	
	public void print_all_types () {
		print (@"Control points:\n");
		foreach (EditPoint ep in points) {
			print (@"$(ep.type) L: $(ep.get_left_handle ().type) R: L: $(ep.get_right_handle ().type)\n");
		}
	}
	
	/** Find the point where two lines intersect. */
	public static void find_intersection (double x1, double y1, double x2, double y2, double x3, double y3, double x4, double y4,
		out double point_x, out double point_y) {
		point_x = ((x1 * y2 - y1 * x2) * (x3 - x4) - (x1 - x2) * (x3 * y4 - y3 * x4)) / ((x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4));
		point_y = ((x1 * y2 - y1 * x2) * (y3 - y4) - (y1 - y2) * (x3 * y4 - y3 * x4)) / ((x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4));
	}

	public static void find_intersection_handle (EditPointHandle h1, EditPointHandle h2, out double point_x, out double point_y) {
		find_intersection (h1.parent.x, h1.parent.y, h1.x, h1.y, h2.parent.x, h2.parent.y, h2.x, h2.y, out point_x, out point_y);
	}
	
	public void add_extrema () {
		double x0, y0, x1, y1, x2, y2, x3, y3;
		double minx, maxx, miny, maxy;
		
		if (unlikely (points.size < 2)) {
			warning (@"Missing points, $(points.size) points in path.");
			return;
		}
		
		minx = double.MAX;
		miny = double.MAX;
		maxx = double.MIN;
		maxy = double.MIN;
		
		x0 = 0;
		y0 = 0;	
		x1 = 0;
		y1 = 0;	
		x2 = 0;
		y2 = 0;
		x3 = 0;
		y3 = 0;
				
		all_of_path ((x, y) => {
			if (x < minx) {
				x0 = x;
				y0 = y;
				minx = x;
			}
			
			if (x > maxx) {
				x1 = x;
				y1 = y;
				maxx = x;
			}

			if (y < miny) {
				x2 = x;
				y2 = y;
				miny = y;
			}
					
			if (y > maxy) {
				x3 = x;
				y3 = y;
				maxy = y;
			}
			
			return true;
		});
		
		insert_new_point_on_path_at (x0 - 0.001, y0);
		insert_new_point_on_path_at (x1 + 0.001, y1);
		insert_new_point_on_path_at (x2, y2 - 0.001);
		insert_new_point_on_path_at (x3, y3 + 0.001);
	}
	
	public void insert_new_point_on_path_at (double x, double y) {
		EditPoint ep = new EditPoint ();
		EditPoint prev, next;
		bool exists;
		
		if (points.size < 2) {
			warning ("Can't add extrema to just one point.");
			return;
		}
		
		get_closest_point_on_path (ep, x, y);

		next = (ep.next == null) ? points.get (0) : ep.get_next ();
		prev = (ep.prev == null) ? points.get (points.size - 1) : ep.get_prev ();
		
		exists = prev.x == ep.x && prev.y == ep.y;
		exists |= next.x == ep.x && next.y == ep.y;
		
		if (!exists) {
			insert_new_point_on_path (ep);
		}
	}
	
	public static bool is_clasped (PathList pl, Path p) {
		foreach (Path o in pl.paths) {
			if (o == p) {
				continue;
			}
			
			if (is_clasped_path (o, p)) {
				return true;
			}
		}
		
		return false;
	}

	private static bool is_clasped_path (Path outside, Path inside) {
		bool i = true;
		foreach (EditPoint e in inside.points) {
			if (!outside.is_over_coordinate_var (e.x, e.y)) { // point may be off curve in both paths
				i = false;
				break;
			}
		}
		return i;
	}
	
	public void remove_points_on_points () {
		Gee.ArrayList<EditPoint> remove = new Gee.ArrayList<EditPoint> ();
		EditPoint n;
		EditPointHandle hr, h;
		
		if (points.size == 0) {
			return;
		}
		
		create_list ();
		
		foreach (EditPoint ep in points) {
			if (ep.next != null) {
				n = ep.get_next ();
			} else {
				warning ("next is null");
				n = points.get (0);
			}
				
			if (fabs (n.x - ep.x) < 0.00001 && fabs (n.y - ep.y) < 0.00001) {
				remove.add (ep);
			}
		}

		foreach (EditPoint r in remove) {
			if (r.next != null) {
				n = r.get_next ();
			} else {
				n = points.get (0);
			}
			
			points.remove (r);
			h = n.get_left_handle ();
			hr = r.get_left_handle ();
			h.length = hr.length;
			h.angle = hr.angle;
			h.type = hr.type;
			
			if (h.length < 0.00001) {
				h.length = 0.00001;
				h.angle = n.get_right_handle ().angle - PI;
			}
			
			create_list ();
		}
		
		recalculate_linear_handles ();
	}
}

}
