/*
    Copyright (C) 2012, 2013 Johan Mattsson

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

using Cairo;
using Math;

namespace BirdFont {

public enum Direction {
	CLOCKWISE,
	COUNTER_CLOCKWISE
}

public class Path {
	
	public List<EditPoint> points = new List<EditPoint> ();

	EditPoint? last_point = null;
	EditPoint? second_last_point = null;

	/** Region boundries */
	public double xmax = double.MIN;
	public double xmin = double.MAX;
	public double ymax = double.MIN;
	public double ymin = double.MAX;

	bool edit = true;
	bool open = true;
	bool direction_is_set = false;

	bool no_derived_direction = false;
	bool clockwise_direction = true;

	public delegate bool RasterIterator (double x, double y, double step); // iterate over each pixel at a given zoom level
	
	private static ImageSurface? edit_point_image = null;
	private static ImageSurface? active_edit_point_image = null;
	
	private static ImageSurface? edit_point_handle_image = null;
	private static ImageSurface? active_edit_point_handle_image = null;

	private static ImageSurface? selected_edit_point_image = null;
	private static ImageSurface? active_selected_edit_point_image = null;
	
	Path quadratic_path; // quadratic points for TrueType export
	
	public static double line_color_r = 0;
	public static double line_color_g = 0;
	public static double line_color_b = 0;
	public static double line_color_a = 1;

	public static double handle_color_r = 0;
	public static double handle_color_g = 0;
	public static double handle_color_b = 0;
	public static double handle_color_a = 1;
		
	public static double stroke_width = 1;
	
	public Path () {
		string width;
		
		if (edit_point_image == null) {
			edit_point_image = Icons.get_icon ("edit_point.png");
			active_edit_point_image = Icons.get_icon ("active_edit_point.png");
			edit_point_handle_image = Icons.get_icon ("edit_point_handle.png");
			active_edit_point_handle_image = Icons.get_icon ("active_edit_point_handle.png");
			selected_edit_point_image  = Icons.get_icon ("selected_edit_point.png");
			active_selected_edit_point_image = Icons.get_icon ("active_selected_edit_point.png");
		
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
			}
		}
	}

	public bool has_direction () {
		return direction_is_set;
	}

	public bool empty () {
		return points.length () == 0;
	}

	public void draw_outline (Context cr, Allocation allocation, double view_zoom) {
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
	
	public void draw_edit_points (Context cr, Allocation allocation, double view_zoom) {
		unowned List<EditPoint> ep = points;
		
		if (is_editable ()) {
			// control points for curvature
			foreach (EditPoint e in ep) {
				if (e.selected || e.selected_handle > 0)
					draw_edit_point_handles (e, cr);
			}
						
			// control points
			foreach (EditPoint e in ep) {
				draw_edit_point (e, cr);
			}
		}
	}

	public void fill_path (Context cr, Allocation allocation, double view_zoom) {
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
		
	/** Line points relative to center. */
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

		PointType type = e.get_left_handle ().type;

		cr.stroke ();
		
		img_right = (e.get_right_handle ().active) ? (!) active_edit_point_handle_image : (!) edit_point_handle_image;
		img_left = (e.get_left_handle ().active) ? (!) active_edit_point_handle_image : (!) edit_point_handle_image;
		
		if (!(is_open () && e == points.last ().data)) {
			draw_line (handle_right, e, cr, 0.15);
			draw_img_center (cr, img_right, e.get_right_handle ().x (), e.get_right_handle ().y ());
		}
		
		if (!(is_open () && e == points.first ().data) && type != PointType.QUADRATIC && type != PointType.LINE_QUADRATIC) {
			draw_line (handle_left, e, cr, 0.15);
			draw_img_center (cr, img_left, e.get_left_handle ().x (), e.get_left_handle ().y ());
		}
	}

	public static void draw_edit_point_center (EditPoint e, Context cr) 
		requires (active_edit_point_image != null && edit_point_image != null)
	{	
		ImageSurface img;
		
		if (e.is_selected ()) {
			img = (e.active) ? (!) active_selected_edit_point_image : (!) selected_edit_point_image;
		} else {
			img = (e.active) ? (!) active_edit_point_image : (!) edit_point_image;
		}
		
		draw_img_center (cr, img, e.x, e.y);
	}
	
	public static void draw_img_center (Context cr, ImageSurface img, double x, double y) {
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
		points.reverse ();
		
		EditPointHandle t;
		foreach (var e in points) {
			t = e.right_handle;
			e.right_handle = e.left_handle;
			e.left_handle = t;
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
		return_val_if_fail (points.length () >= 3, 0);
		
		double sum = 0;
		EditPoint prev = points.last ().data;
		foreach (EditPoint e in points) {
			sum += (e.x - prev.x) * (e.y + prev.y);
			prev = e;
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
		update_region_boundries ();
		
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

	/** Resize path relative to bottom left coordinates.
	 * @param cx xmin position during resize
	 * @param cy ymin position during resize
	 */
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
		
		foreach (var ep in points) {
			new_path.add_point (ep.copy ());
		}
		
		new_path.edit = edit;
		new_path.open = open;
	
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

		if (points.length () < 3) {
			return false;
		}
		
		if (!is_over_boundry_precision (x, y, tolerance)) {
			return false;
		}

		foreach (EditPoint e in points) {
			if (distance (e.x, x, e.y, y) < tolerance) {
				return true;
			}
		}

		all_of_path ((cx, cy, ct) => {
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

			ycoordinates.append (ycoordinates.last ().data.copy ());
			
			return true;
		}
		
		for (unowned List<EditPoint> e = ycoordinates.first (); true; e = e.next) {
			return_val_if_fail (!is_null (e), true);
			
			if (y <= e.data.y + tolerance) {
				return_val_if_fail (!is_null (e.next), true);
				
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
			update_region_boundries ();
		}
		
		return (ymin - p <= y <= ymax + p) && (xmin - p <= x <= xmax + p);
	}
	
	public bool is_over_boundry (double x, double y) {
		if (unlikely (ymin == double.MAX)) {
			warning ("bounding box is not calculated, run update_region_boundries first.");
		}

		return (ymin <= y <= ymax) && (xmin <= x <= xmax);
	}

	public bool has_overlapping_boundry (Path p) {
		return !(xmax <= p.xmin || ymax <= p.ymin) || (xmin >= p.xmax || ymin >= p.ymax);
	}
	
	public void add (double x, double y) {
		add_after (x, y, points.last ());
	}

	public void add_point (EditPoint p) {
		add_point_after (p, points.last ());
	}

	/** Insert a new point after @param previous_point and return a reference 
	 * to the new item in list.
	 */
	public unowned List<EditPoint> add_after (double x, double y, List<EditPoint>? previous_point) {
		EditPoint p = new EditPoint (x, y);	
		return add_point_after (p, previous_point);
	}
	
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
		}
		
		second_last_point = last_point;
		last_point = p;
		
		PenTool.set_default_handle_positions ();
		
		if (p.prev != null && p.get_prev ().data.right_handle.type == PointType.QUADRATIC) {
			p.left_handle.type = PointType.QUADRATIC;
			p.right_handle.type = PointType.LINE_QUADRATIC;
		} else if (Toolbox.get_selected_point_type () == PointType.QUADRATIC) {
			p.left_handle.type = PointType.LINE_QUADRATIC;
			p.right_handle.type = PointType.LINE_QUADRATIC;
			p.type = PointType.LINE_QUADRATIC;
		} else if (Toolbox.get_selected_point_type () == PointType.DOUBLE_CURVE) {
			p.left_handle.type = PointType.LINE_DOUBLE_CURVE;
			p.right_handle.type = PointType.LINE_DOUBLE_CURVE;
			p.type = PointType.DOUBLE_CURVE;
		}
		
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
	
	public EditPoint? get_last_point () {
		return last_point;
	}

	public EditPoint? get_second_last_point () {
		return second_last_point;
	}
	
	/** Move path. */
	public void move (double delta_x, double delta_y) {
		foreach (var ep in points) {
			ep.x += delta_x;
			ep.y += delta_y;
		}
		
		update_region_boundries ();
	}

	public void update_region_boundries () {
		if (points.length () == 0) {
			xmax = 0;
			xmin = 0;
			ymax = 0;
			ymin = 0;			
		}

		// inside and outside in vala lambda functions reveals a tricky problem
		// (look at c code). that's the reason for the !new_val expression

		xmax = -10000;
		xmin = 10000;
		ymax = -10000;
		ymin = 10000;

		double txmax = -10000;
		double txmin = 10000;
		double tymax = -10000;
		double tymin = 10000;

		bool new_val = false;
			
		all_of_path ((cx, cy) => {	
			if (!new_val) {
				txmax = cx;
				txmin = cx;
				tymax = cy;
				tymin = cy;
				new_val = true;
			}
			
			if (cx < txmin) {
				txmin = cx;
			}

			if (cx > txmax) {
				txmax = cx;
			}
			
			if (cy < tymin) {
				tymin = cy;
			}

			if (cy > tymax) {
				tymax = cy;
			}

			return true;
		});
				
		xmax = txmax;
		xmin = txmin;
		ymax = tymax;
		ymin = tymin;

		if (unlikely (!new_val)) {
			// only one point
		} else if (unlikely (!got_region_boundries ())) {
			warning (@"No new region boundries.\nPoints.length: $(points.length ())");
			print_boundries ();
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

	/** Convert quadratic bezier points to cubic representation of the glyph
	 * suitable for ttf-export.
	 */ 
	public Path get_quadratic_points () {
		EditPoint middle = new EditPoint ();
		unowned List<EditPoint> e;
		EditPointHandle last;
		EditPoint first;
		
		quadratic_path = copy ();

		// split all cubic curves in smaller sections	
		for (int i = 0; quadratic_path.split_cubic_curves (this); i++) {
			if (i == 5) {
				warning ("Too many points in converted path.");
				break;
			}
		}

		// estimate quatdratic form
		middle.prev = quadratic_path.points.last ();
		middle.next = quadratic_path.points.first ();
		
		if (middle.get_right_handle ().type == PointType.CUBIC) {
			convert_to_quadratic (quadratic_path, middle);
		}
		
		e = (!) quadratic_path.points.first ();
		while (e != quadratic_path.points.last ().prev) {
			middle.prev = e;
			middle.next = e.next;
			
			if (middle.get_right_handle ().type == PointType.CUBIC) {
				convert_to_quadratic (quadratic_path, middle);
			}

			e = (!) e.next;
		}

		last = quadratic_path.points.last ().data.get_right_handle ();
		if (last.type == PointType.QUADRATIC) {
			first = quadratic_path.points.first ().data;
			quadratic_path.points.append (first);
		}
		quadratic_path.close ();
		
		return quadratic_path;
	}
	
	private bool split (Path cubic, EditPoint start, EditPoint stop) {
		double curve_x, curve_y, cx, cy, qx, qy, nx, ny, distance;
				
		estimate_quadratic (start, stop, out curve_x, out curve_y);
	
		qx = quadratic_bezier_path (0.75, start.x, curve_x, stop.x);
		qy = quadratic_bezier_path (0.75, start.y, curve_y, stop.y);

		cx = bezier_path (0.75, start.x, start.get_right_handle ().x (), stop.get_left_handle ().x (), stop.x);
		cy = bezier_path (0.75, start.y, start.get_right_handle ().y (), stop.get_left_handle ().y (), stop.y);

		distance = Math.sqrt (Math.pow (cx - qx, 2) + Math.pow (cy - qy, 2));

		nx = bezier_path (0.5, start.x, start.get_right_handle ().x (), stop.get_left_handle ().x (), stop.x);
		ny = bezier_path (0.5, start.y, start.get_right_handle ().y (), stop.get_left_handle ().y (), stop.y);

		if (Math.fabs (distance) > 0.01) {
			EditPoint new_edit_point = new EditPoint (nx, ny, PointType.CUBIC);

			new_edit_point.next = start.get_next ();
			new_edit_point.prev = start.get_next ().data.get_prev ();
			
			insert_new_point_on_path (new_edit_point);
			create_list ();

			return true;	
		}
		
		return false;
	}
	
	private bool split_cubic_curves (Path cubic) requires (points.length () > 2) {
		EditPoint start = points.last ().data;
		int i = 0;
		bool n = false;
		
		foreach (EditPoint stop in points) {
			if (start.get_right_handle ().type == PointType.CUBIC) {
				if (split (cubic, start, stop)) {
					n = true;
				}
			}
			start = stop;			
		}
		
		return n;
	}
	
	void convert_to_quadratic (Path cubic_path, EditPoint middle) {
		double curve_x, curve_y;	
		EditPointHandle eh;
		
		EditPoint start = middle.get_prev ().data;
		EditPoint stop = middle.get_next ().data;

		estimate_quadratic (start, stop, out curve_x, out curve_y);
		
		eh = start.get_left_handle ();
		eh.set_point_type (PointType.NONE);
		eh.length = 0;
		
		eh = start.get_right_handle ();
		eh.set_point_type (PointType.QUADRATIC);
		eh.move_to_coordinate (curve_x, curve_y);
	}

	public void split_cubic_in_parts (Path cubic_path) {
		int j = 0;
		while (split_all_cubic_in_half (cubic_path)) {
			j++;
			
			if (j > 5) {
				warning ("too many iterations in split path");
				break;
			}
		}	
	}

	public bool split_all_cubic_in_half (Path cubic_path) {
		EditPoint middle = new EditPoint ();
		unowned List<EditPoint> e;
		bool need_split = false;
		uint len = cubic_path.points.length ();
	
		if (len < 2) {
			return false;
		}

		middle.prev = cubic_path.points.last ();
		middle.next = cubic_path.points.first ();
		
		if (split_cubic_in_half (cubic_path, middle)) {
			need_split = true;
		}
			
		e = (!) cubic_path.points.first ();
		for (uint i = 0; i < len - 1; i++) {
			middle.prev = e;
			middle.next = e.next;
			
			middle.get_prev ().data.recalculate_linear_handles ();
			middle.get_next ().data.recalculate_linear_handles ();
			
			if (split_cubic_in_half (cubic_path, middle)) {
				e = (!) e.next.next;
				need_split = true;
			} else {
				e = (!) e.next;
			}

		}
				
		return need_split;	
	}

	public void estimate_quadratic (EditPoint start, EditPoint stop, out double curve_x, out double curve_y) {
		curve_x = -0.25 * start.x + 0.75 *  stop.get_left_handle ().x () + 0.75 * start.get_right_handle ().x () - 0.25 * stop.x;
		curve_y = -0.25 * start.y + 0.75 *  stop.get_left_handle ().y () + 0.75 * start.get_right_handle ().y () - 0.25 * stop.y;		
	}

	bool split_cubic_in_half (Path cubic_path, EditPoint middle) {
		double curve_x, curve_y, cx, cy, qx, qy, nx, ny, distance;	
		EditPoint start;
		EditPoint stop;
		PointType rt = middle.get_right_handle ().type;

		if (rt != PointType.CUBIC) {
			warning ("Expecting cubic path");
		}
		
		start = middle.get_prev ().data;
		stop = middle.get_next ().data;
		
		estimate_quadratic (start, stop, out curve_x, out curve_y);
	
		qx = quadratic_bezier_path (0.75, start.x, curve_x, stop.x);
		qy = quadratic_bezier_path (0.75, start.y, curve_y, stop.y);

		cx = bezier_path (0.75, start.x, start.get_right_handle ().x (), stop.get_left_handle ().x (), stop.x);
		cy = bezier_path (0.75, start.y, start.get_right_handle ().y (), stop.get_left_handle ().y (), stop.y);

		distance = Math.sqrt (Math.pow (cx - qx, 2) + Math.pow (cy - qy, 2));

		nx = bezier_path (0.5, start.x, start.get_right_handle ().x (), stop.get_left_handle ().x (), stop.x);
		ny = bezier_path (0.5, start.y, start.get_right_handle ().y (), stop.get_left_handle ().y (), stop.y);

		if (Math.fabs (distance) > 0.01) {
			EditPoint new_edit_point = new EditPoint (nx, ny, PointType.CUBIC);

			new_edit_point.next = middle.get_next ();
			new_edit_point.prev = middle.get_prev ();
			cubic_path.insert_new_point_on_path (new_edit_point);
			cubic_path.create_list ();

			return true;	
		}
		
		return false;
	}

	public void insert_new_point_on_path (EditPoint? epp) {
		EditPoint start, stop;
		double x0, x1, y0, y1;
		double position, min;
		
		EditPoint ep;

		if (epp == null) {
			return;
		}

		ep = (!) epp;

		start = ep.get_prev ().data;
		stop = ep.get_next ().data;

		if (start.get_right_handle ().type == PointType.CUBIC || stop.get_left_handle ().type  == PointType.CUBIC) {
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

		// this is a point on a line
		
		if (start.get_right_handle ().type == PointType.LINE_QUADRATIC && stop.get_left_handle ().type  == PointType.LINE_QUADRATIC) {
			ep.get_right_handle ().set_point_type (PointType.LINE_QUADRATIC);
			ep.get_left_handle ().set_point_type (PointType.LINE_QUADRATIC);
			ep.recalculate_linear_handles ();
		} else if (start.get_right_handle ().type == PointType.LINE_CUBIC && stop.get_left_handle ().type  == PointType.LINE_CUBIC) {
			ep.get_right_handle ().set_point_type (PointType.LINE_CUBIC);
			ep.get_left_handle ().set_point_type (PointType.LINE_CUBIC);
			ep.recalculate_linear_handles ();
		} else if (start.get_right_handle ().type == PointType.QUADRATIC) { 
			x0 = quadratic_bezier_vector (1 - position, stop.x, start.get_right_handle ().x (), start.x);
			y0 = quadratic_bezier_vector (1 - position, stop.y, start.get_right_handle ().y (), start.y);
			ep.get_right_handle ().move_to_coordinate (x0, y0);
			
			ep.get_left_handle ().set_point_type (PointType.QUADRATIC);	
			ep.get_right_handle ().set_point_type (PointType.QUADRATIC);	
		} else {
			bezier_vector (position, start.x, start.get_right_handle ().x (), stop.get_left_handle ().x (), stop.x, out x0, out x1);
			bezier_vector (position, start.y, start.get_right_handle ().y (), stop.get_left_handle ().y (), stop.y, out y0, out y1);

			ep.get_left_handle ().set_point_type (PointType.CUBIC);
			ep.get_left_handle ().move_to_coordinate (x0, y0);
			
			ep.get_right_handle ().set_point_type (PointType.CUBIC);
			ep.get_right_handle ().move_to_coordinate (x1, y1);
		}

		ep.get_left_handle ().parent = ep;
		ep.get_right_handle ().parent = ep;
		
		stop.get_left_handle ().length *= 1 - position;
		start.get_right_handle ().length *= position;
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

		bezier_vector (step, previous.x, previous.get_right_handle ().x (), next.get_left_handle ().x (), next.x, out handle_x0, out handle_x1);
		bezier_vector (step, previous.y, previous.get_right_handle ().y (), next.get_left_handle ().y (), next.y, out handle_y0, out handle_y1);

		edit_point.prev = previous_point;
		edit_point.next = next_point;
		
		edit_point.set_position (ox, oy);
	}

	public static void all_of (EditPoint start, EditPoint stop, RasterIterator iter, int steps = -1) {
		if (steps == -1) {
			steps = (int) (10 * get_length_from (start, stop));
		}
		
		if (start.get_right_handle ().type == PointType.QUADRATIC) {
			all_of_quadratic_curve (start.x, start.y, start.get_right_handle ().x (), start.get_right_handle ().y (), stop.x, stop.y, iter, steps);
		} else {
			all_of_curve (start.x, start.y, start.get_right_handle ().x (), start.get_right_handle ().y (), stop.get_left_handle ().x (), stop.get_left_handle ().y (), stop.x, stop.y, iter, steps);
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

	private void all_of_path (RasterIterator iter) {
		unowned List<EditPoint> i, next;
		
		if (points.length () < 2) {
			return;
		}

		i = points.first ();
		next = i.next;

		while (i != points.last ()) {
			all_of (i.data, next.data, iter);
			i = i.next;
			next = i.next;
		}
		
		if (!is_open ()) {
			all_of (points.last ().data, points.first ().data, iter);
		}
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
			
	public void plot (Context cr, Allocation allocation, double view_zoom) {
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
	
	public void print_boundries () {
		stderr.printf (@"xmax $xmax \n");
		stderr.printf (@"xmin $xmin \n");
		stderr.printf (@"ymax $ymax \n");
		stderr.printf (@"ymin $ymin \n");		
	}
	
	public bool got_region_boundries () {
		return !(xmax == -10000 || xmin ==  10000 || ymax == -10000 || ymin ==  10000);
	}
	
	public void create_list () {
		unowned List<EditPoint> prev = points.last ();;
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

	public void delete_edit_point (EditPoint ep) 
		requires (points.length () > 0)
	{
			unowned List<EditPoint>? pl = null;
			EditPoint p;
			
			if (ep.prev != null) {
				set_new_start (ep);
			}
			
			p = points.first ().data;
			
			for (uint i = 0; i < points.length (); i++) {
				p = points.nth (i).data;
				
				if (p == ep) {
					p.prev = null;
					p.next = null;
					
					pl = points.nth (i);
					break;
				}
			}

			if (pl != null) {
				points.delete_link ((!) pl);
				reopen ();
				MainWindow.get_current_glyph ().add_active_path (this);
				create_list ();
			}
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
		p0.update_region_boundries ();
		p1.update_region_boundries ();
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
			pp.update_region_boundries ();
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
	
	private static bool is_clasped (PathList pl, Path p) {
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
			if (!outside.is_over_coordinate_var (e.x, e.y, 0.5)) { // high tolerance since point may be off curve in both paths
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
		EditPointHandle handle;
		EditPoint first;

		if (points.length () == 0) {
			warning ("No points");
			return;
		}

		if (!is_open () || !path.is_open ()) {
			warning ("Path is closed.");
		}

		// link points at the other end
		first = points.first ().data;
		handle = path.points.first ().data.right_handle;
		handle.type = PointType.CUBIC;
		handle.angle = first.right_handle.angle;
		handle.length = first.right_handle.length;
		path.points.remove_link (path.points.first ());
				
		// copy remaining points
		foreach (EditPoint p in path.points) {
			add_point (p.copy ());
		}

		// close path
		first = points.first ().data;
		points.remove_link (points.first ());
		handle = points.last ().data.right_handle;
		handle.type = PointType.CUBIC;
		handle.angle = first.right_handle.angle;
		handle.length = first.right_handle.length;
	
		while (path.points.length () > 0) {
			path.points.remove_link (path.points.first ());
		}
		
		close ();
	}
}

public class PathList : GLib.Object {
	public List<Path> paths = new List<Path> ();
	
	public PathList () {
	}
	
	public void clear () {
		while (paths.length () > 0) {
			paths.remove_link (paths.first ());
		}
	}
}

}
