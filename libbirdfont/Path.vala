/*
    Copyright (C) 2012, 2013, 2014, 2015 Johan Mattsson

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

public class Path : GLib.Object {
	
	public Gee.ArrayList<EditPoint> points {
		get  {
			if (control_points == null) {
				control_points = new  Gee.ArrayList<EditPoint> ();
				BirdFontFile.parse_path_data (point_data, this);
				point_data = "";
			}
			
			return (!) control_points;
		}
		
		set {
			control_points = value;
		}
	}

	public Gee.ArrayList<EditPoint>? control_points = null;

	EditPoint? last_point = null;
	
	/** Path boundaries */
	public double xmax = Glyph.CANVAS_MIN;
	public double xmin = Glyph.CANVAS_MAX;
	public double ymax = Glyph.CANVAS_MIN;
	public double ymin = Glyph.CANVAS_MAX;

	/** Stroke width */
	public double stroke = 0;
	public LineCap line_cap = LineCap.BUTT;
	public PathList? full_stroke = null;
	PathList? fast_stroke = null;
	StrokeTask? stroke_creator;
	
	/** Fill property for closed paths with stroke. */
	public bool fill = false;

	bool edit = true;
	bool open = true;
	
	public bool direction_is_set = false;
	bool no_derived_direction = false;
	bool clockwise_direction = true;

	// Iterate over each pixel in a path
	public delegate bool RasterIterator (double x, double y, double step);
	
	public delegate bool SegmentIterator (EditPoint start, EditPoint stop);
	
	/** The stroke of an outline when the path is not filled. */
	public static double stroke_width = 0;
	public static bool show_all_line_handles = true;
	public static bool fill_open_path {get; set;}
	
	public double rotation = 0;
	public double skew = 0;
	
	public bool hide_end_handle = true;
	public bool highlight_last_segment = false;
	
	public string point_data = "";

	public Color? color = null;
	public Color? stroke_color = null;

	public Gradient? gradient = null;

	public Path () {	
		string width;
		
		if (unlikely (stroke_width < 1)) {
			width = Preferences.get ("stroke_width");
			if (width != "") {
				stroke_width = double.parse (width);
			}
		}

		if (stroke_width < 1) {
			stroke_width = 1;
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

	public EditPoint get_last_visible_point () {
		EditPoint e;
		
		if (unlikely (points.size == 0)) {
			warning ("No point");
			return new EditPoint ();
		}
		
		for (int i = points.size - 1; i >= 0; i--) {
			e = points.get (i);
			if (e.type != PointType.HIDDEN) {
				return e;
			}
		}
		
		warning ("Only hidden points");
		return new EditPoint ();
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
		
		Theme.color (cr, "Default Background");
		cr.set_line_width (2);
		cr.rectangle (x, y, x2 - x, y2 - y);
		cr.stroke ();
		
		cr.restore ();
	}

	public void draw_outline (Context cr) {
		unowned EditPoint? n = null;
		unowned EditPoint en;
		unowned EditPoint em;
		int i;
		
		if (points.size < 2) {
			return;
		}
		
		cr.new_path ();
		
		// draw lines
		i = 0;
		foreach (EditPoint e in points) {
			if (n != null) {
				en = (!) n;
				if (!highlight_last_segment || i != points.size - 1) {
					draw_next (en, e, cr);
				}
			}
			
			n = e;
			i++;
		}

		// close path
		if (!is_open () && n != null) {
			if (highlight_last_segment) {
				cr.stroke ();
				en = points.get (points.size - 1).get_link_item ();
				em = points.get (0).get_link_item ();
				draw_next (en, em, cr);
				cr.stroke ();
			} else {	
				en = (!) n;
				em = points.get (0).get_link_item ();
				draw_next (en, em, cr);
				cr.stroke ();
			}
		} else {
			cr.stroke ();
		}

		// draw highlighted segment			
		if (highlight_last_segment && points.size >= 2) {
			draw_next (points.get (points.size - 2), points.get (points.size - 1), cr, true);
			cr.stroke ();
		}
	}
	
	public void draw_edit_points (Context cr) {		
		if (is_editable ()) {
			// control points for curvature
			foreach (EditPoint e in points) {
				if (show_all_line_handles || e.selected_point || e.selected_handle > 0) {
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
	public void draw_path (Context cr, Glyph glyph, Color? color = null) {
		unowned EditPoint? n = null;
		unowned EditPoint en;
		unowned EditPoint em;
		Color c;
		double center_x, center_y;
		double ex, ey;
		
		if (points.size == 0){
			return;
		}

		center_x = glyph.allocation.width / 2.0;
		center_y = glyph.allocation.height / 2.0;

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
		
		if (this.color != null) {
			c = (!) this.color;
			cr.set_source_rgba (c.r, c.g, c.b, c.a);
		} else if (color != null) {
			c = (!) color;
			cr.set_source_rgba (c.r, c.g, c.b, c.a);
		} else {
			if (is_clockwise ()) {
				Theme.color_opacity (cr, "Selected Objects", 0.4);
			} else {
				Theme.color_opacity (cr, "Selected Objects", 0.8);
			}	
		}
	}

	public void draw_orientation_arrow (Context cr, double opacity) {
		EditPoint top = new EditPoint ();
		double max = Glyph.CANVAS_MIN;
		Text arrow;
		double x, y, angle;
		double size = 50 * Glyph.ivz ();
		
		foreach (EditPoint e in points) {
			if (e.y > max) {
				max = e.y;
				top = e;
			}
		}
		
		arrow = new Text ("orientation_arrow", size);
		arrow.load_font ("icons.bf");
		arrow.use_cache (false);
		
		Theme.text_color_opacity (arrow, "Highlighted 1", opacity);

		angle = top.get_right_handle ().angle;
		x = Glyph.xc () + top.x + cos (angle + PI / 2) * 10 * Glyph.ivz ();	
		y = Glyph.yc () - top.y - sin (angle + PI / 2) * 10 * Glyph.ivz ();
		
		if (points.size > 0) {
			cr.save ();
			cr.translate (x, y);
			cr.rotate (-angle);
			cr.translate (-x, -y); 
			
			arrow.draw_at_baseline (cr, x, y);
			
			cr.restore ();
		}
	}

	private void draw_next (EditPoint e, EditPoint en, Context cr, bool highlighted = false) {
		PointType r = e.get_right_handle ().type;
		PointType l = en.get_left_handle ().type;
		
		if (r == PointType.DOUBLE_CURVE || l == PointType.DOUBLE_CURVE) {
			draw_double_curve (e, en, cr, highlighted);
		} else {
			draw_curve (e, en, cr, highlighted);
		}
	}
	
	private static void draw_double_curve (EditPoint e, EditPoint en, Context cr, bool highlighted) {
		EditPoint middle;
		double x, y;
		
		x = e.get_right_handle ().x + (en.get_left_handle ().x - e.get_right_handle ().x) / 2;
		y = e.get_right_handle ().y + (en.get_left_handle ().y - e.get_right_handle ().y) / 2;
		
		middle = new EditPoint (x, y, PointType.DOUBLE_CURVE);
		middle.right_handle = en.get_left_handle ().copy ();
		
		middle.right_handle.type = PointType.DOUBLE_CURVE;
		middle.left_handle.type = PointType.DOUBLE_CURVE;
		
		draw_curve (e, middle, cr, highlighted);
		draw_curve (middle, en, cr, highlighted);		
	}
		
	private static void draw_curve (EditPoint e, EditPoint en, Context cr, bool highlighted = false, double alpha = 1) {
		Glyph g = MainWindow.get_current_glyph ();
		double xa, ya, xb, yb, xc, yc, xd, yd;
		PointType t = e.get_right_handle ().type;
		PointType u = en.get_left_handle ().type;
		
		get_bezier_points (e, en, out xa, out ya, out xb, out yb, out xc, out yc, out xd, out yd);

		if (!highlighted) {
			Theme.color (cr, "Stroke Color");
		} else {
			Theme.color (cr, "Highlighted Guide");
		}
		
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
		
		Theme.color (cr, "Handle Color");
		cr.set_line_width (1.7 * (stroke_width / g.view_zoom));

		cr.line_to (ax, ay);
		cr.line_to (bx, by);
		
		cr.stroke ();
	}
	
	public void draw_edit_point  (EditPoint e, Context cr) {
		draw_edit_point_center (e, cr);
	}
	
	public void draw_edit_point_handles (EditPoint e, Context cr) {
		Color color_left = Theme.get_color ("Control Point Handle");
		Color color_right = Theme.get_color ("Control Point Handle");
		EditPoint handle_right = e.get_right_handle ().get_point ();
		EditPoint handle_left = e.get_left_handle ().get_point ();

		cr.stroke ();
		
		if (e.type != PointType.HIDDEN) {
			if (e.get_right_handle ().selected) {
				color_right = Theme.get_color ("Selected Control Point Handle");
			} else if (e.get_right_handle ().active) {
				color_right = Theme.get_color ("Active Handle");
			} else {
				color_right = Theme.get_color ("Control Point Handle");
			}
			
			if (e.get_left_handle ().selected) {
				color_left = Theme.get_color ("Selected Control Point Handle");
			} else if (e.get_left_handle ().active) {
				color_left = Theme.get_color ("Active Handle");
			} else {
				color_left = Theme.get_color ("Control Point Handle");
			}

			if (e.get_right_handle ().selected) {
				color_right = Theme.get_color ("Selected Control Point Handle");
			} else if (e.get_right_handle ().active) {
				color_right = Theme.get_color ("Active Handle");
			} else {
				color_right = Theme.get_color ("Control Point Handle");
			}
			
			if (!hide_end_handle || !(is_open () && e == points.get (points.size - 1))) {
				draw_line (handle_right, e, cr, 0.15);
				draw_control_point (cr, e.get_right_handle ().x, e.get_right_handle ().y, color_right);
			}
			
			if (!(is_open () && e == points.get (0))) {
				draw_line (handle_left, e, cr, 0.15);
				draw_control_point (cr, e.get_left_handle ().x, e.get_left_handle ().y, color_left);
			}
		}
	}

	public static void draw_edit_point_center (EditPoint e, Context cr) {
		Color c;
		
		if (e.type != PointType.HIDDEN) {
			if (e.type == PointType.CUBIC || e.type == PointType.LINE_CUBIC) {
				if (e.is_selected ()) {
					if (e.active_point) {
						if (e.color != null) {
							c = (!) e.color;
						} else  {
							c = Theme.get_color ("Selected Active Cubic Control Point");
						}
					} else {
						if (e.color != null) {
							c = (!) e.color;
						} else  {
							c = Theme.get_color ("Selected Cubic Control Point");
						}						
					}
				} else {
					if (e.active_point) {
						if (e.color != null) {
							c = (!) e.color;
						} else  {
							c = Theme.get_color ("Active Cubic Control Point");
						}	
					} else {
						if (e.color != null) {
							c = (!) e.color;
						} else  {
							c = Theme.get_color ("Cubic Control Point");
						}
					}
				}
			} else {
				if (e.is_selected ()) {
					if (e.active_point) {
						if (e.color != null) {
							c = (!) e.color;
						} else  {
							c = Theme.get_color ("Selected Active Quadratic Control Point");
						}
					} else {
						if (e.color != null) {
							c = (!) e.color;
						} else  {
							c = Theme.get_color ("Selected Quadratic Control Point");
						}
					}
				} else {
					if (e.active_point) {
						if (e.color != null) {
							c = (!) e.color;
						} else  {
							c = Theme.get_color ("Active Quadratic Control Point");
						}
					} else {
						if (e.color != null) {
							c = (!) e.color;
						} else  {
							c = Theme.get_color ("Quadratic Control Point");
						}
					}
				}
			}
			
			draw_control_point (cr, e.x, e.y, c);
		} 
	}
	
	public static void draw_control_point (Context cr, double x, double y, Color color, double size = 3.5) {
		Glyph g = MainWindow.get_current_glyph ();
		double ivz = 1 / g.view_zoom;
		double width = size * Math.sqrt (stroke_width) * ivz;
		double xc = g.allocation.width / 2.0;
		double yc = g.allocation.height / 2.0;

		cr.save ();

		x = xc + x; 
		y = yc - y;

		cr.set_source_rgba (color.r, color.g, color.b, color.a);
		
		cr.move_to (x, y);
		cr.arc (x, y, width, 0, 2 * Math.PI);
		cr.close_path ();
		cr.fill ();
		
		cr.restore ();
	}
	
	/** Set direction for this path to clockwise for outline and 
	 * counter clockwise for inline paths.
	 */
	public bool force_direction (Direction direction) {
		bool c = (direction == Direction.CLOCKWISE);
		bool d = is_clockwise ();
		direction_is_set = true;
		
		if (c != d) {
			this.reverse ();
		}
		
		d = is_clockwise ();
		if (unlikely (d != c)) {
			warning ("Failed to set direction for path in force_direction.");
			return true;
		}
				
		return false;
	}

	/** Switch direction from clockwise path to counter clockwise path or vise versa. */
	public bool reverse () {
		bool direction = is_clockwise ();

		if (no_derived_direction) {
			clockwise_direction = !clockwise_direction;
		}
		
		reverse_points ();
		
		if (unlikely (direction == is_clockwise ())) {
			return false;
		}
		
		return true;
	}

	private void reverse_points () requires (points.size > 0) {
		EditPointHandle t;
		EditPoint e;
		Gee.ArrayList<EditPoint> new_points;
		
		new_points = new Gee.ArrayList<EditPoint> ();
		
		for (int i = points.size - 1; i >= 0 ; i--) {
			e = points.get (i);
			
			t = e.right_handle;
			e.right_handle = e.left_handle;
			e.left_handle = t;
			
			new_points.add (e);
		}
		
		points = new_points;
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
		Path p;
		
		if (unlikely (points.size <= 2)) {
			no_derived_direction = true;
			return clockwise_direction;
		}

		if (unlikely (points.size == 2)) {
			p = copy ();
			all_segments ((a, b) => {
				double px, py;
				double step;
				EditPoint new_point;
				
				step = 0.3;
				
				Path.get_point_for_step (a, b, step, out px, out py);
				
				new_point = new EditPoint (px, py);
				new_point.prev = a;
				new_point.next = b;
				
				p.insert_new_point_on_path (new_point, step);
				
				return true;
			});
			
			return p.is_clockwise ();
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

		if (gradient != null) {
			new_path.gradient = ((!) gradient).copy ();
		}
		
		if (color != null) {
			new_path.color = ((!) color).copy ();
		}

		if (stroke_color != null) {
			new_path.stroke_color = ((!) stroke_color).copy ();
		}
		
		new_path.fill = fill;
		new_path.edit = edit;
		new_path.open = open;
		new_path.stroke = stroke;
		new_path.line_cap = line_cap;
		new_path.skew = skew;
		new_path.fill = fill;
		new_path.direction_is_set = direction_is_set;
		new_path.create_list ();
		
		new_path.hide_end_handle = hide_end_handle;
		new_path.highlight_last_segment = highlight_last_segment;
		
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
	
	public static double point_distance (EditPoint p1, EditPoint p2) {
		return distance (p1.x, p2.x, p1.y, p2.y);
	}
	
	public static double distance (double ax, double bx, double ay, double by) {
		return Math.fabs (Math.sqrt (Math.pow (ax - bx, 2) + Math.pow (ay - by, 2)));
	}

	public static double distance_to_point (EditPoint a, EditPoint b) {
		return distance (a.x, b.x, a.y, b.y);
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

	public Path flatten (int steps = 10) {
		Path flat = new Path ();

		all_of_path ((x, y, t) => {
			EditPoint ep = flat.add (x, y);
			ep.type = PointType.LINE_QUADRATIC;
			ep.get_right_handle ().type = PointType.LINE_QUADRATIC;
			ep.get_left_handle ().type = PointType.LINE_QUADRATIC;
			return true;
		}, steps); // FIXME: g.view_zoom
		
		if (!is_open ()) {
			flat.close ();
		}
		
		flat.update_region_boundaries ();
		
		return flat;
	}
	
	/** Variable precision */
	public bool is_over_coordinate_var (double x, double y) {
		int insides = 0;
		Path path;
		
		if (stroke > 0) {
			foreach (Path p in get_stroke_fast ().paths) {
				path = p.flatten ();
				if (StrokeTool.is_inside (new EditPoint (x, y), path)) {
					insides++;
				}
			}
			
			if (insides > 0 && is_filled ()) {
				return true;
			}
			
			if (insides % 2 == 1) {
				return true;
			}
		} else if (is_over_boundry (x, y)) {
			path = flatten ();
			return StrokeTool.is_inside (new EditPoint (x, y), path);
		}
		
		return false;
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
		EditPoint previous_point;
		
		if (points.size == 0) {
			points.add (p);
			p.prev = p;	
			p.next = p;
		} else {
			previous_point = points.get (points.size - 1);
			points.add (p);
			p.prev = previous_point;
			p.next = previous_point.next;
		}
		
		last_point = p;
		
		return p;
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
		
		if (gradient != null) {
			Gradient g = (!) gradient;
			g.x1 += delta_x;
			g.x2 += delta_x;
			g.y1 += delta_y;
			g.y2 += delta_y;
		}
		
		update_region_boundaries ();
	}
	
	private void update_region_boundaries_for_segment (EditPoint a, EditPoint b) {
		EditPointHandle left_handle;
		EditPointHandle right_handle;
		int steps = 10;
		
		right_handle = a.get_right_handle ();
		left_handle = b.get_left_handle ();
	
		if (a.x > xmax || b.x > xmax || left_handle.x > xmax || right_handle.x > xmax) {
			all_of (a, b, (cx, cy) => {
				if (cx > xmax) {
					this.xmax = cx;
				}
				return true;
			}, steps);
		}
		
		if (a.x < xmin || b.x < xmin || left_handle.x < xmin || right_handle.x < xmin) {
			all_of (a, b, (cx, cy) => {
				if (cx < xmin) {
					this.xmin = cx;
				}
				return true;
			}, steps);
		}

		if (a.y > ymax || b.y > ymax || left_handle.y > xmax || right_handle.y > xmax) {
			all_of (a, b, (cx, cy) => {
				if (cy > ymax) {
					this.ymax = cy;
				}
				return true;
			}, steps);
		}

		if (a.y < ymin || b.y < ymin || left_handle.y < xmin || right_handle.y < xmin) {
			all_of (a, b, (cx, cy) => {
				if (cy < ymin) {
					this.ymin = cy;
				}
				return true;
			}, steps);
		}
	}

	public void update_region_boundaries () {	
		PathList s;
		
		xmax = Glyph.CANVAS_MIN;
		xmin = Glyph.CANVAS_MAX;
		ymax = Glyph.CANVAS_MIN;
		ymin = Glyph.CANVAS_MAX;
		
		if (points.size == 0) {
			xmax = 0;
			xmin = 0;
			ymax = 0;
			ymin = 0;
		}
		
		if (stroke == 0) {
			all_segments ((a, b) => {
				update_region_boundaries_for_segment (a, b);
				return true;
			});
		} else {
			s = get_stroke_fast ();
			foreach (Path p in s.paths) {
				p.all_segments ((a, b) => {
					update_region_boundaries_for_segment (a, b);
					return true;
				});
			}
		}
		
		if (points.size == 1) {
			EditPoint e = points.get (0);
			xmax = e.x;
			xmin = e.x;
			ymax = e.y;
			ymin = e.y;
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
		EditPoint prev;
		EditPoint first;
		PointType left;
		PointType right;
		double x, y;
		Gee.ArrayList<EditPoint> middle_points = new Gee.ArrayList<EditPoint> ();
		Gee.ArrayList<EditPoint> first_points = new Gee.ArrayList<EditPoint> ();
		
		first = is_open () ? points.get (0) : points.get (points.size - 1);
		
		foreach (EditPoint next in points) {
			left = first.get_right_handle ().type;
			right = next.get_left_handle ().type;

			if (next != first && (right == PointType.DOUBLE_CURVE || left == PointType.DOUBLE_CURVE)) {
					
				first.get_right_handle ().type = PointType.QUADRATIC;

				// half way between handles
				x = first.get_right_handle ().x + (next.get_left_handle ().x - first.get_right_handle ().x) / 2;
				y = first.get_right_handle ().y + (next.get_left_handle ().y - first.get_right_handle ().y) / 2;
				
				hidden = new EditPoint (x, y, PointType.QUADRATIC);		
				hidden.get_right_handle ().type = PointType.QUADRATIC;
				hidden.get_left_handle ().type = PointType.QUADRATIC;
				hidden.type = PointType.QUADRATIC;
				
				hidden.right_handle.move_to_coordinate_internal (next.get_left_handle ().x, next.get_left_handle ().y);
				
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
		
		create_list ();

		prev = get_last_point ();
		foreach (EditPoint ep in points) {
			if (ep.type == PointType.QUADRATIC) {
				x = prev.get_right_handle ().x;
				y = prev.get_right_handle ().y;
				ep.get_left_handle ().move_to_coordinate (x, y);
			}
			
			prev = ep;
		}
	}

	/** Convert quadratic bezier points to cubic representation of the glyph
	 * for ttf-export.
	 */ 
	public Path get_quadratic_points () {
		PointConverter converter;
		converter = new PointConverter (this);		
		return converter.get_quadratic_path ();
	}

	public void insert_new_point_on_path (EditPoint ep, double t = -1, bool move_point_to_path = false) {
		EditPoint start, stop;
		double x0, x1, y0, y1;
		double position, min;
		PointType left, right;
		double closest_x = 0;
		double closest_y = 0;
		
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
					closest_x = cx;
					closest_y = cy;
				}
				
				return true;
			});
			
			if (move_point_to_path) {
				ep.x = closest_x;
				ep.y = closest_y;
			}
		} else {
			position = t;
		}
		
		if (right == PointType.DOUBLE_CURVE || left == PointType.DOUBLE_CURVE) {
			double_bezier_vector (position, start.x, start.get_right_handle ().x, stop.get_left_handle ().x, stop.x, out x0, out x1);
			double_bezier_vector (position, start.y, start.get_right_handle ().y, stop.get_left_handle ().y, stop.y, out y0, out y1);

			ep.get_left_handle ().set_point_type (PointType.DOUBLE_CURVE);	
			ep.get_right_handle ().set_point_type (PointType.DOUBLE_CURVE);
						
			ep.get_left_handle ().move_to_coordinate (x0, y0);
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
		} else {
			warning (@"Point types: $right and $left in insert_new_point_on_path");
		}

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
			
	/** Get a point on the this path closest to x and y coordinates.
	 * Don't look for a point in the segment skip_previous to skip_next.
	 */
	public void get_closest_point_on_path (EditPoint edit_point, double x, double y,
		EditPoint? skip_previous = null, EditPoint? skip_next = null,
		int steps = -1) {
		return_if_fail (points.size >= 1);
		
		double min = double.MAX;
		double n = 0;
		bool g = false;
		
		double ox = 0;
		double oy = 0;
		
		EditPoint prev = points.get (points.size - 1);
		EditPoint i = points.get (0);

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
				i = points.get (0);
				prev = points.get (points.size - 1);
				exit = true;
			} else {
				break;
			}

			if (skip_previous == prev) {
				continue;
			}

			if (prev.prev != null && skip_previous == prev.get_prev ()) {
				continue;
			}
			
			if (skip_next == i) {
				continue;
			}

			if (prev.next != null && skip_next == prev.get_next ()) {
				continue;
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
			}, steps);
			
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
		
		edit_point.type = previous.type;
		edit_point.get_left_handle ().type = previous.get_right_handle ().type;
		edit_point.get_right_handle ().type = next.get_left_handle ().type;
	}

	public static bool all_of (EditPoint start, EditPoint stop,
			RasterIterator iter, int steps = -1,
			double min_t = 0, double max_t = 1) {
				
		PointType right = PenTool.to_curve (start.get_right_handle ().type);
		PointType left = PenTool.to_curve (stop.get_left_handle ().type);
		
		if (steps == -1) {
			steps = (int) (10 * get_length_from (start, stop));
		}
		
		if (right == PointType.DOUBLE_CURVE || left == PointType.DOUBLE_CURVE) {
			return all_of_double (start.x, start.y, start.get_right_handle ().x, start.get_right_handle ().y, stop.get_left_handle ().x, stop.get_left_handle ().y, stop.x, stop.y, iter, steps, min_t, max_t);
		} else if (right == PointType.QUADRATIC && left == PointType.QUADRATIC) {
			return all_of_quadratic_curve (start.x, start.y, start.get_right_handle ().x, start.get_right_handle ().y, stop.x, stop.y, iter, steps,  min_t, max_t);
		} else if (right == PointType.CUBIC && left == PointType.CUBIC) {
			return all_of_curve (start.x, start.y, start.get_right_handle ().x, start.get_right_handle ().y, stop.get_left_handle ().x, stop.get_left_handle ().y, stop.x, stop.y, iter, steps,  min_t, max_t);
		}
		
		if (start.x == stop.x && start.y == stop.y) {
			warning ("Zero length.");
			return true;
		}
		
		warning (@"Mixed point types in segment $(start.x),$(start.y) to $(stop.x),$(stop.y) right: $(right), left: $(left) (start: $(start.type), stop: $(stop.type))");
		return all_of_quadratic_curve (start.x, start.y, start.get_right_handle ().x, start.get_right_handle ().x, stop.x, stop.y, iter, steps);
	}

	public static void get_point_for_step (EditPoint start, EditPoint stop, double step, 
		out double x, out  double y) {
		
		PointType right =  PenTool.to_curve (start.type);
		PointType left =  PenTool.to_curve (stop.type);
		
		if (right == PointType.DOUBLE_CURVE || left == PointType.DOUBLE_CURVE) {
			x = double_bezier_path (step, start.x, start.get_right_handle ().x, stop.get_left_handle ().x, stop.x);
			y = double_bezier_path (step, start.y, start.get_right_handle ().y, stop.get_left_handle ().y, stop.y);
		} else if (right == PointType.QUADRATIC && left == PointType.QUADRATIC) {
			x = quadratic_bezier_path (step, start.x, start.get_right_handle ().x, stop.x);
			y = quadratic_bezier_path (step, start.y, start.get_right_handle ().y, stop.y);
		} else if (right == PointType.CUBIC && left == PointType.CUBIC) {
			x = bezier_path (step, start.x, start.get_right_handle ().x, stop.get_left_handle ().x, stop.x);
			y = bezier_path (step, start.y, start.get_right_handle ().y, stop.get_left_handle ().y, stop.y);	
		} else if (right == PointType.HIDDEN && left == PointType.HIDDEN) {
			x = bezier_path (step, start.x, start.get_right_handle ().x, stop.get_left_handle ().x, stop.x);
			y = bezier_path (step, start.y, start.get_right_handle ().y, stop.get_left_handle ().y, stop.y);	
		} else {
			warning (@"Mixed point types in segment $(start.x),$(start.y) to $(stop.x),$(stop.y) right: $(right), left: $(left) (start: $(start.type), stop: $(stop.type))");
			x = bezier_path (step, start.x, start.get_right_handle ().x, stop.get_left_handle ().x, stop.x);
			y = bezier_path (step, start.y, start.get_right_handle ().y, stop.get_left_handle ().y, stop.y);	
		}
	}

	private static bool all_of_double (double x0, double y0, double x1, double y1, double x2, double y2, double x3, double y3, 
			RasterIterator iter, double steps = 400, double min_t = 0, double max_t = 1) {
				
		double px = x1;
		double py = y1;
		
		double t;
		double middle_x, middle_y;
		double double_step;
		
		middle_x = x1 + (x2 - x1) / 2;
		middle_y = y1 + (y2 - y1) / 2;
		
		for (int i = 0; i < steps; i++) {
			t = i / steps + min_t;
			
			px = quadratic_bezier_path (t, x0, x1, middle_x);
			py = quadratic_bezier_path (t, y0, y1, middle_y);
			
			double_step = t /  2;

			if (double_step > max_t) {
				return false;
			}
						
			if (!iter (px, py, double_step)) {
				return false;
			}	
		}
		
		for (int i = 0; i < steps; i++) {
			t = i / steps + min_t;
			
			px = quadratic_bezier_path (t, middle_x, x2, x3);
			py = quadratic_bezier_path (t, middle_y, y2, y3);
			
			double_step = 0.5 + t / 2;

			if (double_step > max_t) {
				return false;
			}
						
			if (!iter (px, py, double_step)) {
				return false;
			}
		}	
		
		return true;	
	}
		
	private static bool all_of_quadratic_curve (double x0, double y0, double x1, double y1, double x2, double y2,
			RasterIterator iter, double steps = 400, double min_t = 0, double max_t = 1) {
		double px = x1;
		double py = y1;
		
		double t;
		
		for (int i = 0; i < steps; i++) {
			t = i / steps + min_t;
			
			px = quadratic_bezier_path (t, x0, x1, x2);
			py = quadratic_bezier_path (t, y0, y1, y2);
			
			if (t > max_t) {
				return false;
			}
			
			if (!iter (px, py, t)) {
				return false;
			}
		}
		
		return true;
	}

	private static bool all_of_curve (double x0, double y0, double x1, double y1, double x2, double y2, double x3, double y3,
			RasterIterator iter, double steps = 400, double min_t = 0, double max_t = 1) {
		double px = x1;
		double py = y1;
		
		double t;
		
		for (int i = 0; i < steps; i++) {
			t = i / steps + min_t;
			
			px = bezier_path (t, x0, x1, x2, x3);
			py = bezier_path (t, y0, y1, y2, y3);

			if (t > max_t) {
				return false;
			}
						
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

	public static void get_handles_for_step (EditPoint start, EditPoint stop, double step,
		out double x1, out double y1, out double x2, out double y2) {
			
		PointType right =  PenTool.to_curve (start.type);
		PointType left =  PenTool.to_curve (stop.type);
		
		if (right == PointType.DOUBLE_CURVE || left == PointType.DOUBLE_CURVE) {
			double_bezier_vector (step, start.x, start.get_right_handle ().x, stop.get_left_handle ().x, stop.x, out x1, out x2); // FIXME: swap parameter?
			double_bezier_vector (step, start.y, start.get_right_handle ().y, stop.get_left_handle ().y, stop.y, out y1, out y2);
		} else if (right == PointType.QUADRATIC && left == PointType.QUADRATIC) {
			x1 = quadratic_bezier_vector (step, start.x, start.get_right_handle ().x, stop.x);
			y1 = quadratic_bezier_vector (step, start.y, start.get_right_handle ().y, stop.y);
			x2 = x1;
			y2 = y1;
		} else if (right == PointType.CUBIC && left == PointType.CUBIC) {
			bezier_vector (step, start.x, start.get_right_handle ().x, stop.get_left_handle ().x, stop.x, out x1, out x2);
			bezier_vector (step, start.y, start.get_right_handle ().y, stop.get_left_handle ().y, stop.y, out y1, out y2);	
		} else if (right == PointType.HIDDEN && left == PointType.HIDDEN) {
			bezier_vector (step, start.x, start.get_right_handle ().x, stop.get_left_handle ().x, stop.x, out x1, out x2);
			bezier_vector (step, start.y, start.get_right_handle ().y, stop.get_left_handle ().y, stop.y, out y1, out y2);	
		} else {
			warning (@"Mixed point types in segment $(start.x),$(start.y) to $(stop.x),$(stop.y) right: $(right), left: $(left) (start: $(start.type), stop: $(stop.type))");
			bezier_vector (step, start.x, start.get_right_handle ().x, stop.get_left_handle ().x, stop.x, out x1, out x2);
			bezier_vector (step, start.y, start.get_right_handle ().y, stop.get_left_handle ().y, stop.y, out y1, out y2);	
		}
	}
	
	public void plot (Context cr, WidgetAllocation allocation, double view_zoom) {
			double px = 0, py = 0;
			double xc = allocation.width / 2.0;
			double yc = allocation.height / 2.0;

			cr.save ();
			
			all_of_path ((x, y) => {
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
		
		remaining_points.stroke = stroke;
		current_path.stroke = stroke;
		
		if (!has_deleted_point ()) {
			return path_list;
		}
		
		if (points.size == 1) {
			points.remove_at (0);
			return path_list;
		}
		
		// set start position to a point that will be removed	
		for (i = 0; i < points.size; i++) {
			p = points.get (i);
						
			if (p.deleted) {
				index = i;
				i++;
				ep = p;
				break;
			}
		}
		
		// don't tie end points on the open path
		if (points.size > 1) {
			p = points.get (1);
			p.convert_to_curve ();
			p.set_reflective_handles (false);
			p.set_tie_handle (false);
		}

		if (points.size > 0) {
			p = points.get (points.size - 1);
			p.convert_to_curve ();
			p.set_reflective_handles (false);
			p.set_tie_handle (false);
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
		
	public void set_new_start (EditPoint ep) 
	requires (points.size > 0) {
		Gee.ArrayList<EditPoint> list = new Gee.ArrayList<EditPoint> ();
		int start = 0;
		
		for (int i = 0; i < points.size; i++) {
			if (ep == points.get (i)) {
				start = i;
			}
		}
		
		for (int i = start; i < points.size; i++) {
			list.add (points.get (i));
		}

		for (int i = 0; i < start; i++) {
			list.add (points.get (i));
		}
				
		control_points = list;
	}
	
	public void append_path (Path path) {
		if (points.size == 0 || path.points.size == 0) {
			warning ("No points");
			return;
		}

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
	
		rotation += theta;
		rotation %= 2 * PI;
		
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

	public void init_point_type (PointType pt = PointType.NONE) {
		PointType type;
		
		if (pt == PointType.NONE) {
			pt = DrawingTools.point_type;
		}
		
		switch (pt) {
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

	/** Finx intersection point for two straight lines. */
	public static void find_intersection_point (EditPoint p1, EditPoint p2, EditPoint q1, EditPoint q2, out double point_x, out double point_y) {
		find_intersection (p1.x, p1.y, p2.x, p2.y, q1.x, q1.y, q2.x, q2.y, out point_x, out point_y);
	}
		
	public void add_extrema () {
		double x0, y0, x1, y1, x2, y2, x3, y3;
		double minx, maxx, miny, maxy;
		
		if (unlikely (points.size < 2)) {
			warning (@"Missing points, $(points.size) points in path.");
			return;
		}
		
		minx = Glyph.CANVAS_MAX;
		miny = Glyph.CANVAS_MAX;
		maxx = Glyph.CANVAS_MIN;
		maxy = Glyph.CANVAS_MIN;
		
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
	
	public EditPoint insert_new_point_on_path_at (double x, double y) {
		EditPoint ep = new EditPoint ();
		EditPoint prev, next;
		bool exists;
		
		if (points.size < 2) {
			warning ("Can't add extrema to just one point.");
			return ep;
		}
		
		get_closest_point_on_path (ep, x, y);

		next = (ep.next == null) ? points.get (0) : ep.get_next ();
		prev = (ep.prev == null) ? points.get (points.size - 1) : ep.get_prev ();
		
		exists = prev.x == ep.x && prev.y == ep.y;
		exists |= next.x == ep.x && next.y == ep.y;
		
		if (!exists) {
			insert_new_point_on_path (ep);
		}
		
		return ep;
	}
	
	public static bool is_counter (PathList pl, Path path) {
		return counters (pl, path) % 2 != 0;
	}

	public static int counters (PathList pl, Path path) {
		int inside_count = 0;
		bool inside;
		PathList lines = new PathList ();
		
		lines = pl;
		
		/** // FIXME: Check automatic orientation.
		foreach (Path p in pl.paths) {
			lines.add (SvgParser.get_lines (p));
		}
		*/
		
		foreach (Path p in lines.paths) {
			if (p.points.size > 1 && p != path 
				&& path.boundaries_intersecting (p)) {
					
				inside = false;
				foreach (EditPoint ep in path.points) {
					if (SvgParser.is_inside (ep, p)) {
						inside = true;
					}
				}

				if (inside) {
					inside_count++; 
				}
			}
		}
		
		return inside_count;
	}
	
	public bool boundaries_intersecting (Path p) {
		return in_boundaries (p.xmin, p.xmax, p.ymin, p.ymax);
	}
	
	public bool in_boundaries (double other_xmin, double other_xmax, double other_ymin, double other_ymax) {
		return ((xmin <= other_xmin <= xmax) || (xmin <= other_xmax <= xmax)
			|| (other_xmin <= xmin <= other_xmax) || (other_xmin <= xmax <= other_xmax))
			&& ((ymin <= other_ymin <= ymax) || (ymin <= other_ymax <= ymax)
			|| (other_ymin <= ymin <= other_ymax) || (other_ymin <= ymax <= other_ymax));
	}
	
	/** @param t smallest distance to other points. */
	public void remove_points_on_points (double t = 0.00001) {
		Gee.ArrayList<EditPoint> remove = new Gee.ArrayList<EditPoint> ();
		EditPoint n;
		EditPointHandle hr, h;
		double t3 = t / 3;
		
		if (points.size == 0) {
			return;
		}

		for (int i = 0; i < points.size + 1; i++) {
			EditPoint ep = points.get (i % points.size);
			if (ep.get_right_handle ().length < t3
				&& ep.get_left_handle ().length < t3
				&& !is_endpoint (ep)
				&& (ep.flags & EditPoint.CURVE_KEEP) == 0
				&& (ep.flags & EditPoint.SEGMENT_END) == 0) {
				ep.deleted = true;
			}
		}
		
		remove_deleted_points ();
		
		for (int i = 0; i < points.size + 1; i++) {
			EditPoint ep = points.get (i % points.size);
			n = points.get ((i + 1) % points.size);
			
			if (Path.distance_to_point (n, ep) < t) {
				remove.add (ep);
			}
		}
		
		create_list ();

		foreach (EditPoint r in remove) {
			if (points.size == 0) {
				return;
			}
			
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
			
			if (h.length < t) {
				h.length = t;
				h.angle = n.get_right_handle ().angle - PI;
			}
			
			create_list ();
		}
		
		recalculate_linear_handles ();
	}
	
	public bool is_endpoint (EditPoint ep) {
		if (points.size == 0) {
			return false;
		}
		
		return ep == points.get (0) || ep == points.get (points.size - 1);
	}
	
	public void remove_deleted_points () {
		Gee.ArrayList<EditPoint> p = new Gee.ArrayList<EditPoint> ();
		
		foreach (EditPoint ep in points) {
			if (ep.deleted) {
				p.add (ep);
			}
		}
		
		foreach (EditPoint e in p) {
			points.remove (e);
		}
		
		create_list ();
	}

	public static void find_closes_point_in_segment (EditPoint ep0, EditPoint ep1,
			double px, double py,
			out double nx, out double ny,
			double max_step = 200) {
								
		double min_distance = double.MAX;
		double npx, npy;
		double min_t, max_t;
		double rmin_t, rmax_t;
		bool found;
		int step;
		
		npx = 0;
		npy = 0;
		
		min_t = 0;
		max_t = 1;
		
		rmin_t = 0;
		rmax_t = 1;

		for (step = 3; step <= max_step; step *= 2) {
			found = false;
			min_distance = double.MAX;
			Path.all_of (ep0, ep1, (xa, ya, ta) => {
				double d = Path.distance (px, xa, py, ya);
				
				if (d < min_distance) {
					min_distance = d;
					npx = xa;
					npy = ya;
					rmin_t = ta - 1.0 / step;
					rmax_t = ta + 1.0 / step;
					found = true;
				}
				
				return true;
			}, step, min_t, max_t);

			if (!found) {
				rmin_t = 1 - (1.0 / step);
				rmax_t = 1;
			}

			min_t = (rmin_t > 0) ? rmin_t : 0;
			max_t = (rmax_t < 1) ? rmax_t : 1;
		}

		nx = npx;
		ny = npy;
	}
	
	public void reset_stroke () {
		full_stroke = null;
		fast_stroke = null;
	}
	
	public void create_full_stroke () {
		if (stroke <= 0) {
			return;
		}
		
		print(@"Create full stroke for $(points.size) points.\n");
		StrokeTask task = new StrokeTask (this);
		MainWindow.native_window.run_non_blocking_background_thread (task);
		
		stop_stroke_creator ();
		stroke_creator = task;
	}

	public void stop_stroke_creator () {
		if (stroke_creator != null) {
			((!) stroke_creator).cancel ();
		}	
	}

	public PathList get_stroke () {
		if (full_stroke == null) {
			StrokeTool s = new StrokeTool ();
			full_stroke = s.get_stroke (this, stroke);
		}
		
		return (!) full_stroke;
	}
	
	public PathList get_stroke_fast () {
		if (full_stroke != null) {
			return (!) full_stroke;
		}

		if (fast_stroke != null) {
			return (!) fast_stroke;
		}
		
		StrokeTool s = new StrokeTool ();
		Test t = new Test.time ("fast stroke");
		fast_stroke = s.get_stroke_fast (this, stroke);
		t.print();
		
		return (!) fast_stroke;
	}
	
	// Callback for path simplifier
	public void add_cubic_bezier_points (double x0, double y0, double x1, double y1,
		double x2, double y2, double x3, double y3) {
			
		EditPoint start;
		EditPoint end;

		if (points.size > 0) {
			start = get_last_point ();
		} else {
			start = add (x0, y0);
		}
		
		end = add (x3, y3);
		
		start.set_point_type (PointType.CUBIC);
		end.set_point_type (PointType.CUBIC);
		
		start.convert_to_curve ();
		end.convert_to_curve ();
		
		start.get_right_handle ().move_to_coordinate (x1, y1);
		end.get_left_handle ().move_to_coordinate (x2, y2);
	}
}

}
