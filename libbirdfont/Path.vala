/*
    Copyright (C) 2012, 2013 Johan Mattsson

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
	
	public List<EditPoint> points;

	EditPoint? last_point = null;
	EditPoint? second_last_point = null;

	/** Region boundaries */
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
	
	// Iterate over all points in a rasterized path and compute a vector 
	// for each point
	public delegate bool VectorIterator (EditPoint start, EditPoint stop, 
		double x, double y, double hx0, double hx1, double dy0, double dy1, 
		double step);
	
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
	List<EditPoint> new_quadratic_points;
	
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
		points = new List<EditPoint> ();
		new_quadratic_points = new List<EditPoint> ();
		
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
		if (unlikely (points.length () == 0)) {
			warning ("No point");
			return new EditPoint ();
		}
		
		return points.first ().data;
	}

	public EditPoint get_last_point () {
		if (unlikely (points.length () == 0)) {
			warning ("No point");
			return new EditPoint ();
		}
		
		return points.last ().data;
	}

	public bool has_direction () {
		return direction_is_set;
	}

	public bool empty () {
		return points.length () == 0;
	}

	public void set_stroke (double width) {
		stroke = width;	
	}

	public void draw_boundaries  (Context cr, WidgetAllocation allocation, double view_zoom) {
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

	public void draw_outline (Context cr, WidgetAllocation allocation, double view_zoom) {
		unowned List<EditPoint> ep = points;
		
		unowned EditPoint? n = null;
		unowned EditPoint en;
		unowned EditPoint em;
		
		if (ep.length () < 2) {
			return;
		}
		
		cr.new_path ();
		
		// draw lines
		foreach (EditPoint e in ep) {
			if (n != null) {
				en = (!) n;
				draw_next (en, e, cr);
			}
			
			n = e;
		}

		// close path
		if (!is_open () && n != null) {
			en = (!) n;
			em = ep.first ().data;
			draw_next (en, em, cr);
		}

		cr.stroke ();
	}
	
	public void draw_edit_points (Context cr, WidgetAllocation allocation, double view_zoom) {
		unowned List<EditPoint> ep = points;
		
		if (is_editable ()) {
			// control points for curvature
			foreach (EditPoint e in ep) {
				if (show_all_line_handles || e.selected || e.selected_handle > 0) {
					draw_edit_point_handles (e, cr);
				}
			}
						
			// control points
			foreach (EditPoint e in ep) {
				draw_edit_point (e, cr);
			}
		}
	}

	public void fill_path (Context cr, WidgetAllocation allocation, double view_zoom) {
		unowned List<EditPoint> ep = points;
		
		unowned EditPoint? n = null;
		unowned EditPoint en;
		unowned EditPoint em;
		cr.new_path ();
					
		// draw lines
		foreach (EditPoint e in ep) {
			if (n != null) {
				en = (!) n;
				draw_next (en, e, cr);
			}
			
			n = e;
		}
		
		// close path
		if (!is_open () && ep.length () >= 2 && n != null) {
			en = (!) n;
			em = ep.first ().data;
			draw_next (en, em, cr);
		}

		// fill path
		cr.close_path ();
			
		if (is_clockwise ()) {
			cr.set_source_rgba (80/255.0, 95/255.0, 137/255.0, 0.5);
		} else {
			cr.set_source_rgba (144/255.0, 145/255.0, 236/255.0, 0.5);
		}
		
		cr.fill ();
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
		
		x = e.get_right_handle ().x () + (en.get_left_handle ().x () - e.get_right_handle ().x ()) / 2;
		y = e.get_right_handle ().y () + (en.get_left_handle ().y () - e.get_right_handle ().y ()) / 2;
		
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
		
		cr.line_to (xa, ya); // this point makes sense only if it is the first or last position, the other points are meaningless don't export them

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

		xb = center_x + e.get_right_handle ().x ();
		yb = center_y - e.get_right_handle ().y ();
		
		xc = center_x + en.get_left_handle ().x ();
		yc = center_y - en.get_left_handle ().y ();
		
		xd = center_x + en.x;
		yd = center_y - en.y;		
	}

	/** Curve absolute glyph data. */
	public static void get_abs_bezier_points (EditPoint e, EditPoint en, out double xa, out double ya, out double xb, out double yb, out double xc, out double yc, out double xd, out double yd) {
		xa =  + e.x;
		ya =  - e.y;

		xb =  + e.get_right_handle ().x ();
		yb =  - e.get_right_handle ().y ();
		
		xc =  + en.get_left_handle ().x ();
		yc =  - en.get_left_handle ().y ();
		
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

			if (!(is_open () && e == points.last ().data)) {
				draw_line (handle_right, e, cr, 0.15);
				draw_image (cr, img_right, e.get_right_handle ().x (), e.get_right_handle ().y ());
			}
			
			if (!(is_open () && e == points.first ().data)) {
				draw_line (handle_left, e, cr, 0.15);
				draw_image (cr, img_left, e.get_left_handle ().x (), e.get_left_handle ().y ());
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
	
	/** Returns true if there is an edit point at (p.x, p.y). */
	private bool has_edit_point (EditPoint p) {
		foreach (var t in points) {
			if (p.x == t.x && p.y == t.y) {
				return true;
			}
		}
		return false;
	}
	
	/** Replace edit points in this path with @param new_path.points. */
	public void replace_path (Path new_path) {
		while (points.length () > 0) {
			points.remove_link (points.first ());
		}
		
		foreach (var np in new_path.points) {
			add (np.x, np.y);
		}
		
		close ();
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
			stderr.printf (@"Length: $(points.length ())\n");
			stderr.printf (@"No particular direction can be derived: $no_derived_direction \n");
			warning ("Path.reverse () failed.\n");
		}
	}

	private void reverse_points () {
		EditPointHandle t;
		Path p = copy ();
		unowned List<EditPoint> e;
		
		create_list ();	
		
		while (points.length () > 0) {
			points.remove_link (points.first ());
		}
		
		e = p.points.last ();
		while (!is_null (e) && !is_null (e.data)) {
			t = e.data.right_handle;
			e.data.right_handle = e.data.left_handle;
			e.data.left_handle = t;
			
			add_point (e.data);
			
			if (is_null (e.prev)) {
				break;
			} else {
				e = e.prev;
			}
		}

		create_list ();
	}

	public void print_all_points () {
		int i = 0;
		foreach (var p in points) {
			++i;
			string t = (p.type == PointType.END) ? " endpoint" : "";
			stdout.printf (@"Point $i at ($(p.x), $(p.y)) $t \n");
		}
	}
	
	private double clockwise_sum () {
		double sum = 0;
		
		return_val_if_fail (points.length () >= 3, 0);
		
		foreach (EditPoint e in points) {
			sum += e.get_direction ();
		}
		
		return sum;
	}
	
	public bool is_clockwise () {
		double s;
		
		if (unlikely (points.length () <= 2)) {
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
	
	private bool direction_x (EditPoint start, EditPoint stop) {
		return (start.x < stop.x);
	}

	private bool direction_y (EditPoint start, EditPoint stop) {
		return (start.y < stop.y);
	}
	
	public void thinner (double ratio) 
		requires (points.length () > 2)
	{		
		update_region_boundaries ();
		
		double w = Math.fabs(xmax - xmin);
		double h = Math.fabs(ymax - ymin);
		double cx = w / 2 + xmin; 
		double cy = h / 2 + ymin;
		
		ratio = 1 - ratio;

		unowned List<EditPoint> i = points.first ();
		unowned List<EditPoint> prev = points.last ();
		
		bool dirx = true;
		bool ldirx = direction_x (prev.data, i.data);
		bool ndirx;

		bool diry = true;
		bool ldiry = direction_y (prev.data, i.data);
		bool ndiry;
		
		while (true) {
			ndirx = direction_x (prev.data, i.data);
			
			if (ndirx != ldirx) {
				dirx = !dirx;
			}
			
			ldirx = ndirx;

			ndiry = direction_y (prev.data, i.data);
			
			if (ndiry != ldiry) {
				diry = !diry;
			}
			
			ldiry = ndiry;
			
			EditPoint p = i.data;
			
			if (dirx) {
				if (p.x < cx)
					p.x += (cx - p.x) * ratio;
				else
					p.x -= (p.x - cx) * ratio;
			} else {
				if (p.x < cx)
					p.x += (cx - p.x) * ratio * 2;
				else
					p.x -= (p.x - cx) * ratio * 2;
			}

			// err borde vara -y
			if (p.y < cy && diry || p.y > cy && ! diry)
				p.y += (cy - p.y) * ratio;
			else
				p.y -= (p.y - cy) * ratio;	
			
			if (i == points.last ()) {
				break;
			}
			
			prev = i;
			i = i.next;
		}
	}

	/** Resize path relative to bottom left coordinates. */
	public void resize (double ratio) {	
		foreach (var p in points) {
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
	
	public Path copy () {
		Path new_path = new Path ();
		EditPoint p;
		
		foreach (var ep in points) {
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
		return is_over_coordinate_var (x, y, 0.1);
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
	
	private static double get_length_from (EditPoint a, EditPoint b) {
		double x, y;
		
		x = Math.fabs (a.x - a.get_right_handle ().x ());
		x += Math.fabs (a.get_right_handle ().x () - b.get_left_handle ().x ());
		x += Math.fabs (b.get_left_handle ().x () - b.x);

		y = Math.fabs (a.y - a.get_right_handle ().y ());
		y += Math.fabs (a.get_right_handle ().y () - b.get_left_handle ().y ());
		y += Math.fabs (b.get_left_handle ().y () - b.y);
		
		return Math.fabs (Math.sqrt (x * x + y * y));
	} 
	
	/** Variable precision */
	public bool is_over_coordinate_var (double x, double y, double tolerance) {
		List<EditPoint> ycoordinates = new List<EditPoint> ();
		double last = 0;
		bool on_edge = false;
		double last_x = 0;
		Path path;
		PathList pathlist;
		
		if (points.length () < 2) {
			return false;
		}
		
		if (stroke > 0) {
			pathlist = StrokeTool.get_stroke (this, stroke);
			path = pathlist.get_first_path ();
		} else {
			path = this;
		}
		
		if (!path.is_over_boundry_precision (x, y, tolerance)) {
			return false;
		}

		foreach (EditPoint e in path.points) {
			if (distance (e.x, x, e.y, y) < tolerance) {
				return true;
			}
		}

		path.all_of_path ((cx, cy, ct) => {
			double distance = Math.fabs (Math.sqrt (Math.pow (cx - x, 2) + Math.pow (cy - y, 2)));
			
			if (distance < tolerance) {
				on_edge = true;
				return false;
			}
			
			if (Math.fabs (cx - x) < tolerance && Math.fabs (last - cy) > 2 * tolerance) {
				ycoordinates.append (new EditPoint (cx, cy));
				last = cy;
			}
			
			last_x = cx;
			return true;
		});

		if (on_edge) {
			return true;
		}

		if (ycoordinates.length () == 0) {
			warning ("No ycoordinates is empty");
			return true;
		}

		ycoordinates.sort ((a, b) => {
			return (a.y < b.y) ? 1 : -1;
		});
		
		for (int i = 0; i < ycoordinates.length () - 1; i++) {
			if (Math.fabs (ycoordinates.nth (i).data.y - ycoordinates.nth (i + 1).data.y) < 4 * tolerance) {
				ycoordinates.remove_link (ycoordinates.nth (i));
			}
		}
		
		if (unlikely (ycoordinates.length () % 2 != 0)) {
			warning (@"not an even number of coordinates ($(ycoordinates.length ()))");
			stderr.printf (@"(ymin <= y <= ymax) && (xmin <= x <= xmax);\n");
			stderr.printf (@"($ymin <= $y <= $ymax) && ($xmin <= $x <= $xmax);\n");
		
			stderr.printf (@"tolerance: $(tolerance)\n");
			
			stderr.printf ("ycoordinates:\n");
			foreach (EditPoint e in ycoordinates) {
				stderr.printf (@"$(e.y)\n");
			}

			if (ycoordinates.length () != 0) {
				ycoordinates.append (ycoordinates.last ().data.copy ());
			}
			
			return true;
		}
		
		for (unowned List<EditPoint> e = ycoordinates.first (); true; e = e.next) {
			return_val_if_fail (!is_null (e) || !is_null (e.data), true);
			
			if (y <= e.data.y + tolerance) {
				return_val_if_fail (!is_null (e.next) || !is_null (e.data), true);
				
				e = e.next;

				if (y >= e.data.y - tolerance) {
					return true;
				}
			}
			
			if (e == ycoordinates.last ()) {
				break;
			}
		}

		return false;
	}
	
	public bool is_over_boundry_precision (double x, double y, double p) {
		if (unlikely (ymin == double.MAX || ymin == 10000)) {
			update_region_boundaries ();
		}
		
		return (ymin - p <= y <= ymax + p) && (xmin - p <= x <= xmax + p);
	}
	
	public bool is_over_boundry (double x, double y) {
		if (unlikely (ymin == double.MAX)) {
			warning ("bounding box is not calculated, run update_region_boundaries first.");
		}

		return (ymin <= y <= ymax) && (xmin <= x <= xmax);
	}

	public bool has_overlapping_boundry (Path p) {
		return !(xmax <= p.xmin || ymax <= p.ymin) || (xmin >= p.xmax || ymin >= p.ymax);
	}
	
	public EditPoint delete_last_point () {
		unowned List<EditPoint> p;
		EditPoint r;
		uint len;
		
		len = points.length ();
		if (unlikely (len == 0)) {
			warning ("No points in path.");
			return new EditPoint ();
		}
		
		p = points.last ();
		r = p.data;
		points.remove_link (p);
		
		if (len > 1) {
			r.get_prev ().data.next = null;
			
			if (r.next != null) {
				r.get_next ().data.prev = null;
			}
		}
		
		return r;
	}
	
	public EditPoint add (double x, double y) {
		return add_after (x, y, points.last ()).data;
	}

	public EditPoint add_point (EditPoint p) {
		return add_point_after (p, points.last ()).data;
	}

	/** Insert a new point after @param previous_point and return a reference 
	 * to the new item in list.
	 */
	public unowned List<EditPoint> add_after (double x, double y, List<EditPoint>? previous_point) {
		EditPoint p = new EditPoint (x, y, PointType.NONE);	
		return add_point_after (p, previous_point);
	}
	
	/** @return a list item pointing to the new point */
	public unowned List<EditPoint> add_point_after (EditPoint p, List<EditPoint>? previous_point) {
		unowned List<EditPoint> np;
		int prev_index;

		if (points.length () > 0 && previous_point != null && ((!)previous_point).data.type == PointType.END) {
			points.delete_link ((!) previous_point);
		}

		if (unlikely (previous_point == null && points.length () != 0)) {
			warning ("previous_point == null");
		}

		if (points.length () == 0) {
			points.append (p);
			np = points.last ();
			p.prev = points.last ();
			p.next = points.last ();
		} else {
			p.prev = (!) previous_point;
			p.next = ((!) previous_point).next;

			points.insert_before (((!) previous_point).next, p);
			
			prev_index = points.position ((!) previous_point);
			np = points.nth (prev_index + 1);
			
			if (unlikely (p.prev == null)) {
				warning ("Prev point is null");
			}
		}
		
		second_last_point = last_point;
		last_point = p;
		
		return np;
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
		
		if (points.length () > 2) {
			points.first ().data.recalculate_linear_handles ();
			points.last ().data.recalculate_linear_handles ();
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
		if (h.x () > xmax) {
			xmax = h.x ();
		}

		if (h.x () < xmin) {
			xmin = h.x ();
		}

		if (h.y () > ymax) {
			ymax = h.y ();
		}

		if (h.y () < ymin) {
			ymin = h.y ();
		}
	}

	public void update_region_boundaries () {
		xmax = -10000;
		xmin = 10000;
		ymax = -10000;
		ymin = 10000;
		
		if (points.length () == 0) {
			xmax = 0;
			xmin = 0;
			ymax = 0;
			ymin = 0;
		}

		foreach (EditPoint p in points) {
			update_region_boundaries_for_point (p);
		}
	}
		
	/** Test if @param path is a valid outline for this object. */	
	public bool test_is_outline (Path path) {
		assert (false);
		return this.test_is_outline_of_path (path) && path.test_is_outline_of_path (this);
	}
	
	private bool test_is_outline_of_path (Path outline)
		requires (outline.points.length () >= 2 || points.length () >= 2)
	{	
		// rather slow use it for testing, only
		unowned List<EditPoint> i = outline.points.first ();
		unowned List<EditPoint> prev = i.last ();

		double tolerance = 1;
		bool g = false;
		
		EditPoint ep = new EditPoint (0, 0);
		double min = double.MAX;
		
		while (true) {
			min = 10000;
			 
			all_of (prev.data, i.data, (cx, cy) => {
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
			
			if (i == i.last ()) {
				break;
			}
				
			i = i.next;
		}
		
		return true;
	}

	/** Add the extra point between line handles for double curve. */
	void add_hidden_double_points () requires (points.length () > 1) {
		EditPoint hidden;
		unowned List<EditPoint> first = points.last ();
		PointType left;
		PointType right;
		double x, y;

		for (unowned List<EditPoint> next = points.first (); !is_null (next); next = next.next ) {
			left = first.data.get_right_handle ().type;
			right = next.data.get_left_handle ().type;
			if (right == PointType.DOUBLE_CURVE || left == PointType.DOUBLE_CURVE) {
				first.data.get_right_handle ().type = PointType.QUADRATIC;

				// half the way between handles
				x = first.data.get_right_handle ().x () + (next.data.get_left_handle ().x () - first.data.get_right_handle ().x ()) / 2;
				y = first.data.get_right_handle ().y () + (next.data.get_left_handle ().y () - first.data.get_right_handle ().y ()) / 2;
				
				hidden = new EditPoint (x, y, PointType.QUADRATIC);
				hidden.right_handle = next.data.get_left_handle ().copy ();
				hidden.get_right_handle ().type = PointType.QUADRATIC;
				hidden.type = PointType.QUADRATIC;
				
				first.data.get_right_handle ().type = PointType.QUADRATIC;
				first.data.type = PointType.QUADRATIC;
				
				add_point_after (hidden, first);
			}
			first = next;
		}
	}

	/** Convert quadratic bezier points to cubic representation of the glyph
	 * for ttf-export.
	 */ 
	public Path get_quadratic_points () {
		unowned List<EditPoint> i, next;
		
		quadratic_path = new Path ();
		
		while (new_quadratic_points.length () > 0) {
			new_quadratic_points.remove_link (new_quadratic_points.first ());
		}

		if (points.length () < 2) {
			warning ("Less than 2 points in path.");
			return quadratic_path;
		}
		
		i = points.first ();
		next = i.next;

		while (i != points.last ()) {
			if (i.data.get_right_handle ().type == PointType.CUBIC 
				|| next.data.get_left_handle ().type == PointType.CUBIC) {
				add_quadratic_points (i.data, next.data);
			} else {
				quadratic_path.add_point (i.data.copy ());
			}
			
			i = i.next;
			next = i.next;
		}
		
		if (points.last ().data.get_right_handle ().type == PointType.CUBIC 
			||  points.first ().data.get_left_handle ().type == PointType.CUBIC) {
			add_quadratic_points (points.last ().data, points.first ().data);
		} else {
			quadratic_path.add_point (points.last ().data.copy ());
		}

		if (quadratic_path.points.length () < 2) {
			warning ("Less than 2 points in quadratic path.");
			return new Path ();
		}

		quadratic_path.add_hidden_double_points ();

		quadratic_path.close ();
		quadratic_path.create_list ();
		process_quadratic_handles ();
		
		quadratic_path.close ();
		quadratic_path.create_list ();
		process_cubic_handles ();
		
		quadratic_path.close ();
		
		return quadratic_path;
	}
	
	private void add_quadratic_points (EditPoint start, EditPoint stop) {
		int steps;
		EditPoint prev =  new EditPoint ();
		int added_points = 0;

		if (points.length () < 2) {
			return;
		}

		steps = (int) (0.8 * get_length_from (start, stop));
		
		if (steps == 0) {
			steps = 1;
		}
		
		// create quadratic paths
		all_of (start, stop, (x, y, step) => {
			double prev_step = 0;
			EditPoint e =  new EditPoint ();
			
			if (step == 1) {
				return true;
			}
			
			e = new EditPoint (x, y, PointType.QUADRATIC);
			added_points++;

			prev_step = step;
			prev = e;

			quadratic_path.add_point (e);
			prev = quadratic_path.points.last ().data;
			
			prev.type = PointType.LINE_QUADRATIC;
			prev.get_left_handle ().type = PointType.LINE_QUADRATIC;
			prev.get_right_handle ().type = PointType.LINE_QUADRATIC;
			prev.recalculate_linear_handles ();
			
			new_quadratic_points.append (prev);
			return true;
		}, steps);
		
		quadratic_path.close ();
	}

	void process_cubic_handles () 
		requires (quadratic_path.points.length () > 0) {	
		
		EditPoint prev = quadratic_path.points.last ().data;
		quadratic_path.close ();
		foreach (EditPoint ep in quadratic_path.points) {
			if (ep.type == PointType.CUBIC) {
				convert_remaining_cubic (ep, prev);
			} 

			if (ep.type == PointType.LINE_CUBIC) {
				convert_remaining_cubic (ep, prev);
			}
			
			prev = ep;
		}
	}
	
	void convert_remaining_cubic (EditPoint ep, EditPoint prev) {
		double x, y;
		
		ep.set_tie_handle (true);
		
		if (ep.next != null) {
			((!) ep.next).data.set_tie_handle (false);
		}

		prev.get_left_handle ().type = PointType.QUADRATIC;
		prev.get_right_handle ().type = PointType.QUADRATIC;
		prev.get_right_handle ().move_delta (0.000001, 0.000001);
		
		x = prev.get_right_handle ().x ();
		y = prev.get_right_handle ().y ();
		
		ep.get_left_handle ().move_to_coordinate (ep.x - (ep.x - prev.x) / 2, 
			ep.y - (ep.y - prev.y) / 2);		
	}
	
	void process_quadratic_handles () {	
		for (int t = 0; t < 2; t++) {
			foreach (EditPoint ep in new_quadratic_points) {	
				if (!is_null (ep.next) && !is_null (ep.next) 
					&& ((!)ep.next).data.type != PointType.CUBIC
					&& ((!)ep.next).data.type != PointType.LINE_CUBIC
					&& !is_null (ep.prev) 
					&& ((!)ep.prev).data.type != PointType.CUBIC
					&& ((!)ep.prev).data.type != PointType.LINE_CUBIC) {
						
					ep.set_tie_handle (true);
					ep.process_tied_handle ();
				}
			}
		}
	}

	public void insert_new_point_on_path (EditPoint ep) {
		EditPoint start, stop;
		double x0, x1, y0, y1;
		double position, min;
		PointType left, right;
		
		if (ep.next == null || ep.prev == null) {
			warning ("missing point");
			return;
		}

		start = ep.get_prev ().data;
		stop = ep.get_next ().data;

		right = start.get_right_handle ().type;
		left = stop.get_left_handle ().type;
		
		if (right == PointType.CUBIC || left == PointType.CUBIC) {
			start.get_right_handle ().type = PointType.CUBIC;
			stop.get_left_handle ().type = PointType.CUBIC;
		}

		add_point_after (ep, ep.get_prev ());

		min = double.MAX;

		position = 0.5;

		all_of (start, stop, (cx, cy, t) => {
			double n = pow (ep.x - cx, 2) + pow (ep.y - cy, 2);
			
			if (n < min) {
				min = n;
				position = t;
			}
			
			return true;
		});

		if (right == PointType.LINE_QUADRATIC && left == PointType.LINE_QUADRATIC) {
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
		} else if (right == PointType.DOUBLE_CURVE || left == PointType.DOUBLE_CURVE) {
			double_bezier_vector (position, start.x, start.get_right_handle ().x (), stop.get_left_handle ().x (), stop.x, out x0, out x1);
			double_bezier_vector (position, start.y, start.get_right_handle ().y (), stop.get_left_handle ().y (), stop.y, out y0, out y1);
			
			ep.get_left_handle ().move_to_coordinate (x1, y1);
			ep.get_right_handle ().move_to_coordinate (x0, y0);

			ep.get_left_handle ().set_point_type (PointType.DOUBLE_CURVE);	
			ep.get_right_handle ().set_point_type (PointType.DOUBLE_CURVE);
			ep.type = PointType.DOUBLE_CURVE;
		} else if (right == PointType.QUADRATIC) {		
			x0 = quadratic_bezier_vector (1 - position, stop.x, start.get_right_handle ().x (), start.x);
			y0 = quadratic_bezier_vector (1 - position, stop.y, start.get_right_handle ().y (), start.y);
			ep.get_right_handle ().move_to_coordinate (x0, y0);
			
			ep.get_left_handle ().set_point_type (PointType.QUADRATIC);	
			ep.get_right_handle ().set_point_type (PointType.QUADRATIC);
			
			ep.get_left_handle ().move_to_coordinate_internal (0, 0);
			
			ep.type = PointType.QUADRATIC;				
		} else {
			bezier_vector (position, start.x, start.get_right_handle ().x (), stop.get_left_handle ().x (), stop.x, out x0, out x1);
			bezier_vector (position, start.y, start.get_right_handle ().y (), stop.get_left_handle ().y (), stop.y, out y0, out y1);

			ep.get_left_handle ().set_point_type (PointType.CUBIC);
			ep.get_left_handle ().move_to_coordinate (x0, y0);
			
			ep.get_right_handle ().set_point_type (PointType.CUBIC);
			ep.get_right_handle ().move_to_coordinate (x1, y1);
			
			ep.type = PointType.LINE_CUBIC;
		}

		ep.get_left_handle ().parent = ep;
		ep.get_right_handle ().parent = ep;
		
		stop.get_left_handle ().length *= 1 - position;
		start.get_right_handle ().length *= position;

		if (right == PointType.QUADRATIC) { // update connected handle
			if (ep.prev != null) {
				ep.get_left_handle ().move_to_coordinate_internal (
					ep.get_prev ().data.right_handle.x (), 
					ep.get_prev ().data.right_handle.y ());

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
		return_if_fail (points.length () != 0);
		
		double min = double.MAX;
		double n = 0;
		bool g = false;
		
		double ox = 0;
		double oy = 0;
		
		double handle_x0, handle_x1;
		double handle_y0, handle_y1;
		
		unowned List<EditPoint> i = points.first ();
		unowned List<EditPoint> prev = i.next;

		bool done = false;
		bool exit = false;
		
		unowned List<EditPoint>? previous_point = null;
		unowned List<EditPoint>? next_point = null;

		EditPoint previous;
		EditPoint next;
		double step = 0;

		if (points.length () == 0) {
			warning ("Empty path.");
			return;
		}

		if (points.length () == 1) {
			edit_point.x = i.data.x;
			edit_point.y = i.data.y;
			
			edit_point.prev = i;
			edit_point.next = i;
			
			exit = true;
			return;
		}
		
		if (points.length () != 1) {
			edit_point.x = i.data.x;
			edit_point.y = i.data.y;
		}
		
		while (!exit) {
			
			if (i == points.last ()) {
				done = true;
			}
			
			if (!done) {
				i = i.next;
				prev = i.prev;
			}	else if (done && !is_open ()) {
				i = points.first ();
				prev = points.last ();
				exit = true;
			} else {
				break;
			}
			
			all_of (prev.data, i.data, (cx, cy, t) => {
				n = pow (x - cx, 2) + pow (y - cy, 2);
				
				if (n < min) {
					min = n;
					
					ox = cx;
					oy = cy;
				
					previous_point = prev;
					next_point = i;
					
					step = t;
					
					g = true;
				}
				
				return true;
			});
		}

		if (previous_point == null && is_open ()) {
			previous_point = points.last ();
		}
		
		if (previous_point == null) {
			warning (@"previous_point == null, points.length (): $(points.length ())");
			return;
		}
		
		if (next_point == null) {
			warning ("next_point != null");
			return;
		}

		previous = ((!) previous_point).data;
		next = ((!) next_point).data;

		// FIXME: delete
		bezier_vector (step, previous.x, previous.get_right_handle ().x (), next.get_left_handle ().x (), next.x, out handle_x0, out handle_x1);
		bezier_vector (step, previous.y, previous.get_right_handle ().y (), next.get_left_handle ().y (), next.y, out handle_y0, out handle_y1);

		edit_point.prev = previous_point;
		edit_point.next = next_point;
		
		edit_point.set_position (ox, oy);
	}

	public static void all_of (EditPoint start, EditPoint stop, RasterIterator iter, int steps = -1) {
		PointType right = start.get_right_handle ().type;
		PointType left = stop.get_left_handle ().type;
		
		if (steps == -1) {
			steps = (int) (10 * get_length_from (start, stop));
		}
		
		if (right == PointType.DOUBLE_CURVE || left == PointType.DOUBLE_CURVE) {
			all_of_double (start.x, start.y, start.get_right_handle ().x (), start.get_right_handle ().y (), stop.get_left_handle ().x (), stop.get_left_handle ().y (), stop.x, stop.y, iter, steps);
		} else if (right == PointType.QUADRATIC) {
			all_of_quadratic_curve (start.x, start.y, start.get_right_handle ().x (), start.get_right_handle ().y (), stop.x, stop.y, iter, steps);
		} else {
			all_of_curve (start.x, start.y, start.get_right_handle ().x (), start.get_right_handle ().y (), stop.get_left_handle ().x (), stop.get_left_handle ().y (), stop.x, stop.y, iter, steps);
		}
	}

	public static void get_point_for_step (EditPoint start, EditPoint stop, double step, out double x, out double y) {
		// FIXME: Types
		x = bezier_path (step, start.x, start.get_right_handle ().x (), stop.get_left_handle ().x (), stop.x);
		y = bezier_path (step, start.y, start.get_right_handle ().y (), stop.get_left_handle ().y (), stop.y);	
	}

	private static void all_of_double (double x0, double y0, double x1, double y1, double x2, double y2, double x3, double y3, RasterIterator iter, double steps = 400) {
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
				return;
			}
			
		}
		
		for (int i = 0; i < steps; i++) {
			t = i / steps;
			
			px = quadratic_bezier_path (t, middle_x, x2, x3);
			py = quadratic_bezier_path (t, middle_y, y2, y3);
			
			double_step = 0.5 + t / 2;
			
			if (!iter (px, py, double_step)) {
				return;
			}
			
		}		
	}
		
	private static void all_of_quadratic_curve (double x0, double y0, double x1, double y1, double x2, double y2, RasterIterator iter, double steps = 400) {
		double px = x1;
		double py = y1;
		
		double t;
		
		for (int i = 0; i < steps; i++) {
			t = i / steps;
			
			px = quadratic_bezier_path (t, x0, x1, x2);
			py = quadratic_bezier_path (t, y0, y1, y2);
			
			if (!iter (px, py, t)) {
				return;
			}
			
		}			
	}

	private static void all_of_curve (double x0, double y0, double x1, double y1, double x2, double y2, double x3, double y3, RasterIterator iter, double steps = 400) {
		double px = x1;
		double py = y1;
		
		double t;
		
		for (int i = 0; i < steps; i++) {
			t = i / steps;
			
			px = bezier_path (t, x0, x1, x2, x3);
			py = bezier_path (t, y0, y1, y2, y3);
			
			if (!iter (px, py, t)) {
				return;
			}
			
		}	
	}

	public void all_segments (SegmentIterator iter) {
		unowned List<EditPoint> i, next;
		
		if (points.length () < 2) {
			return;
		}

		i = points.first ();
		next = i.next;

		while (i != points.last ()) {
			iter (i.data, next.data);
			i = i.next;
			next = i.next;
		}
		
		if (!is_open ()) {
			iter (points.last ().data, points.first ().data);
		}		
	}

	public void all_of_path (RasterIterator iter, int steps = -1) {
		all_segments ((start, stop) => {
			all_of (start, stop, iter, steps);
			return true;
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
		
		if (step < 0.5) {
			return quadratic_bezier_path (2 * step, p0, p1, middle);
		}
		
		return quadratic_bezier_path (2 * (step - 0.5), middle, p2, p3);
	}
	
	public static void double_bezier_vector (double step, double p0, double p1, double p2, double p3, out double a0, out double a1) {
		double b0, b1, c0, c1, d0, d1;
	
		// set angle
		b0 = double_bezier_path (step - 0.00001, p0, p1, p2, p3);
		c0 = double_bezier_path (step - 0.00002, p0, p1, p2, p3);

		b1 = double_bezier_path (step + 0.00001, p0, p1, p2, p3);
		c1 = double_bezier_path (step + 0.00002, p0, p1, p2, p3);
		
		// adjust length
		d0 = b0 + (b0 - c0) * 25000 * (1 - step);
		d1 = b1 + (b1 - c1) * 25000 * step;
		
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
		unowned List<EditPoint> prev = points.last ();
		unowned List<EditPoint> ep = points.first ();
		
		if (points.length () == 0) {
			return;
		}
		
		if (points.length () == 1) {
			ep.data.next = null;
			ep.data.prev = null;
			return;
		}
		
		ep.data.next = ep.next;
		ep.data.prev = points.last ();
		prev = ep;
		
		assert (ep.data.next != null);
		assert (ep.data.prev != null);
		
		while (ep != ep.last ()) {
			ep.data.next = ep.next;
			ep.data.prev = prev;
			prev = ep;
			
			assert (ep.data.next != null);
			assert (ep.data.prev != null);
		
			ep = ep.next;
		}
		
		ep.data.next = points.first ();
		ep.data.prev = prev;
		assert (ep.data.prev != null);

		points.first ().data.prev = points.last ();
	}

	public bool has_point (EditPoint ep) {
		foreach (EditPoint p in points) {
			if (p == ep) {
				return true;
			}
		}
		return false;
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
		requires (points.length () > 0)
	{
		unowned List<EditPoint>? pl = null;
		EditPoint p;
		EditPoint ep = new EditPoint ();
		Path current_path = new Path ();
		Path remaining_points = new Path ();
		PathList path_list = new PathList ();
		uint i;
		
		if (!has_deleted_point ()) { 
			return path_list;
		}
		
		if (points.length () == 1) {
			points.delete_link (points.first ());
			return path_list;
		}
		
		// set start position to the point that will be removed	
		for (i = 0; i < points.length (); i++) {
			pl = points.nth (i);
			return_val_if_fail (pl != null, remaining_points);
			p = ((!)pl).data;
			
			if (p.deleted) {
				i++;
				ep = p;
				break;
			}
		}

		// copy points after the deleted point
		while (i < points.length ()) {
			pl = points.nth (i);
			return_val_if_fail (pl != null, remaining_points);
			p = ((!)pl).data;
			current_path.add_point (p);
			i++;
		}

		// copy points before the deleted point
		i = 0;
		while (i < points.length ()) {
			pl = points.nth (i);
			return_val_if_fail (pl != null, remaining_points);
			p = ((!)pl).data;
			if (p == ep) {
				break;
			} else {
				remaining_points.add_point (p);
			}
			
			i++;
		}
		
		// merge if we still only have one path
		if (!is_open ()) {
			foreach (EditPoint point in remaining_points.points) {
				current_path.add_point (point.copy ());
			}
			
			if (current_path.points.length () > 0) {
				ep = current_path.points.first ().data;
				ep.set_tie_handle (false);
				ep.set_reflective_handles (false);
				ep.get_left_handle ().type = PenTool.to_line (ep.type);
				ep.type = PenTool.to_curve (ep.type);
				path_list.paths.append (current_path);
				
				if (!is_null (current_path.points.last ())) {
					ep = current_path.points.last ().data;
					ep.get_right_handle ().type = PenTool.to_line (ep.type);
					ep.type = PenTool.to_curve (ep.get_right_handle ().type);
				}
			}
		} else {
			if (current_path.points.length () > 0) {
				ep = current_path.points.first ().data;
				ep.set_tie_handle (false);
				ep.set_reflective_handles (false);
				ep.get_left_handle ().type = PenTool.to_line (ep.type);
				ep.type = PenTool.to_curve (ep.type);
				set_new_start (current_path.points.first ().data);
				path_list.paths.append (current_path);
				
				if (!is_null (current_path.points.last ())) {
					ep = current_path.points.last ().data;
					ep.get_right_handle ().type = PenTool.to_line (ep.type);
					ep.type = PenTool.to_curve (ep.get_right_handle ().type);
				}
			}
			
			if (remaining_points.points.length () > 0) {
				remaining_points.points.first ().data.set_tie_handle (false);
				remaining_points.points.first ().data.set_reflective_handles (false);
				remaining_points.points.first ().data.type = remaining_points.points.first ().data.type;
				set_new_start (remaining_points.points.first ().data);
				path_list.paths.append (remaining_points);
				
				if (!is_null (current_path.points.last ())) {
					ep = current_path.points.last ().data;
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
		List<EditPoint> list = new List<EditPoint> ();
		uint len = points.length ();
		unowned List<EditPoint> iter = points.first ();
		unowned List<EditPoint>? ni = null;
		bool found = false;

		foreach (EditPoint it in points) {
			if (it == ep) {
				found = true;
				break;
			}
			
			iter = iter.next;
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
			list.append (iter.data);
			
			if (iter == iter.last ())
				iter = iter.first ();
			else
				iter = iter.next;
		
		}
		
		while (points.length () > 0) {
			points.remove_link (points.first ());
		}
		
		foreach (EditPoint p in list) {
			points.append (p);
		}
		
	}
	
	public static PathList merge (Path p0, Path p1) {
		bool done;
		PathList path_list;
		
		done = try_merge (p0.copy(), p1.copy(), out path_list);
		
		if (!done) {
			warning ("failed to merge paths");
		}
		
		return path_list;
	}
	
	private static bool try_merge (Path p0, Path p1, out PathList path_list) {
		EditPoint e;
		IntersectionList il;
		int i;
		Path np;
		
		unowned List<Path> pi;
		
		il = IntersectionList.create_intersection_list (p0, p1);
		
		path_list = new PathList ();
		
		if (p0 == p1) {
			return false;
		}
		
		// add editpoints on intersections 
		p0.update_region_boundaries ();
		p1.update_region_boundaries ();
		foreach (Intersection inter in il.points) {
			e = new EditPoint ();
			p0.get_closest_point_on_path (e, inter.x, inter.y);
			inter.editpoint_a = e;
			
			e = inter.editpoint_a;
			if (!p0.has_edit_point (e)) {
				p0.insert_new_point_on_path (e);
			}

			e = new EditPoint ();
			p1.get_closest_point_on_path (e, inter.x, inter.y);
			inter.editpoint_b = e;
			inter.editpoint_b.x = inter.editpoint_a.x;
			inter.editpoint_b.y = inter.editpoint_a.y;
			
			e = inter.editpoint_b;
			if (!p1.has_edit_point (e)) {
				p1.insert_new_point_on_path (e);
			}
			
			inter.editpoint_a.type = PenTool.to_curve (inter.editpoint_a.get_right_handle ().type);
			inter.editpoint_b.type = PenTool.to_curve (inter.editpoint_b.get_right_handle ().type);
		}
			
		if (il.points.length () < 2) {
			return false;
		}
		
		//path_list.paths.append (p0);
		//path_list.paths.append (p1);
		//return false;
		
		// get all parts
		foreach (Intersection inter in il.points) {
			p0.set_new_start (inter.editpoint_a);
			get_merge_part (il, p0, p1, out np);
			path_list.paths.append (np);
		}
		
		foreach (Path pp in path_list.paths) {
			pp.update_region_boundaries ();
		}

		// remove duplicate paths
		for (i = 0; i < path_list.paths.length (); i++) {
			pi = path_list.paths.nth (i);

			if (is_duplicated (path_list, pi.data)) {
				path_list.paths.remove_link (pi);
				--i;			
			}
		}
		
		// remove paths contained in other paths
		for (i = 0; i < path_list.paths.length (); i++) {
			pi = path_list.paths.nth (i);
			
			if (pi.data.is_clockwise () && is_clasped (path_list, pi.data)) {
				path_list.paths.remove_link (pi);
				i--;
			}
		}
	
		return true;
	}
	
	private static bool is_duplicated (PathList pl, Path p) {
		bool duplicate = false;
		foreach (Path pd in pl.paths) {
			if (pd == p) {
				continue;
			}
			
			if (is_duplicated_path (p, pd)) {
				duplicate = true;
			}
		}
		
		return duplicate;
	}
	
	private static bool is_duplicated_path (Path p0, Path p1) {
		bool eq;
		
		assert (p1 != p0);	
		
		foreach (EditPoint ep in p0.points) {
			eq = false;
			
			foreach (EditPoint e in p1.points) {
				eq = (Math.fabs (ep.x - e.x) < 0.04 && Math.fabs (ep.y - e.y) < 0.04);
				
				if (eq) {
					break;
				}
			}
			
			if (eq) {
				continue;
			} else {
				return false;
			}
		}
		
		return true;
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
			if (!outside.is_over_coordinate_var (e.x, e.y, 0.5)) { // point may be off curve in both paths
				i = false;
				break;
			}
		}
		return i;
	}
	
	private static bool get_merge_part (IntersectionList il, Path p0, Path p1, out Path new_path) {
		EditPoint ex;
		EditPoint ix;
		EditPoint en;
		uint offset_i = 0;
		uint offset_j;
		uint len_i;
		int i, j;
		uint len_j;
		Path np = new Path ();
		Intersection s = new Intersection (0, 0, 1);
		
		ex = p0.points.last ().data;
		ix = p0.points.last ().data;
		len_i = p0.points.length ();
		
		for (i = 0; i < p0.points.length (); i++) {
			ex = p0.points.nth ((i + offset_i) % len_i).data;

			if (ex == p0.points.first ().data && i != 0) {	
				s = (!) il.get_intersection (ex);	
				break;
			}

			// add new point for path a
			if (np.has_edit_point (ex)) {
				// SPLIT
				warning ("Merged path need split");
				np.close ();
				new_path = np;
				
				return false;
			} else {
				en = ex.copy ();
				np.add_point (en);
				en.recalculate_linear_handles ();
			}
			
			// swap paths
			if (il.has_edit_point (ex)) {
				s = (!) il.get_intersection (ex);
			
				en.type = PointType.CUBIC;
				en.right_handle.type = PointType.CUBIC;
				en.right_handle.angle  = s.editpoint_b.right_handle.angle;
				en.right_handle.length = s.editpoint_b.right_handle.length;
							
				// read until we find ex
				for (j = 0; j < p1.points.length (); j++) {
					ix = p1.points.nth (j).data;
					
					if (ix == s.editpoint_b) {
						break;
					}
				}
				
				offset_j = j + 1;
				len_j = p1.points.length ();
				for (j = 0; j < p1.points.length (); j++) {
					
					ix = p1.points.nth ((j + offset_j) % len_j).data;
					
					// add
					if (np.has_edit_point (ix)) {
						// SPLIT
						warning ("Merged path need split");
						np.close ();
						new_path = np;
						
						break;
					} else {
						en = ix.copy ();
						np.add_point (en);
						ix.recalculate_linear_handles ();
					}
					
					if (il.has_edit_point (ix)) {
						s = (!) il.get_intersection (ix);
						break;
					}
				}

				en.type = PointType.CUBIC;
				en.right_handle.type = PointType.CUBIC;
				en.right_handle.angle  = s.editpoint_a.right_handle.angle;
				en.right_handle.length = s.editpoint_a.right_handle.length;
								
				if (j == p0.points.length ()) {
					np.close ();
					new_path = np;
					return true;
				}

				// skip to next intersection
				int k;
				for (k = 0; k < p0.points.length (); k++) {
					ix = p0.points.nth (k).data; 

					if (ix == s.editpoint_a) {
						break;
					}
				}
				
				if (k == p0.points.length ()) {
					new_path = np;
					return true;
				}
				
				offset_i = 0;
				i = k;
			}
		}

		new_path = np;
		
		return true;	
	}

	public void append_path (Path path) {
		if (points.length () == 0 || path.points.length () == 0) {
			warning ("No points");
			return;
		}

		points.last ().data.right_handle.type = path.points.first ().data.type;
		points.last ().data.right_handle.move_to_coordinate (
			path.points.first ().data.right_handle.x (),
			path.points.first ().data.right_handle.y ());
			
		path.points.first ().data.right_handle.type = 
			points.last ().data.right_handle.type;

		path.points.first ().data.recalculate_linear_handles ();
		points.last ().data.recalculate_linear_handles ();
		
		// FIXME: path.points.remove_link (path.points.first ());
		
		// copy remaining points
		foreach (EditPoint p in path.points) {
			add_point (p.copy ());
		}
		
		// close path
		while (path.points.length () > 0) {
			path.points.remove_link (path.points.first ());
		}
		
		//close ();
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
			
			lx = hl.x ();
			ly = hl.y ();
			rx = hr.x ();
			ry = hr.y ();
						
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
			
			lx = hl.x ();
			ly = hl.y ();
			rx = hr.x ();
			ry = hr.y ();
						
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
}

}
