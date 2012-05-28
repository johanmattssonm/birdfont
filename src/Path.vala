/*
    Copyright (C) 2012 Johan Mattsson

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
using Gtk;
using Gdk;
using Math;

namespace Supplement {

enum Direction {
	CLOCKWISE,
	COUNTER_CLOCKWISE
}

class Path {
	
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

	bool no_derived_direction = false;
	bool clockwise_direction = true;

	delegate bool RasterIterator (double x, double y); // iterate over each pixel at a given zoom level

	public double r = 0;
	public double g = 0;
	public double b = 0;
	public double a = 1;

	private string? name = null;
	
	bool selected = false;
	
	public Path () {
	}

	public void set_color (double r, double g, double b, double a) {
		this.r = r;
		this.g = g;
		this.b = b;
		this.a = a;
	}

	public void set_name (string n) {
		name = n;
	}
	
	public string get_name () {
		return (name == null) ? "NO_NAME" : (!) name;
	}

	public double get_width () {
		return_if_fail (xmax != double.MIN && xmin != double.MAX);
		return (xmax - xmin);
	}

	public bool empty () {
		return points.length () == 0;
	}

	public void set_selected (bool s) {
		selected = s;
	}

	public bool is_selected () {
		return selected;
	}
	
	public void draw_edit_points (Context cr, Allocation allocation, double view_zoom) {
		unowned List<EditPoint> ep = points;
		
		unowned EditPoint? n = null;
		unowned EditPoint en;
		unowned EditPoint em;
		
		cr.new_path ();
					
		// draw lines
		foreach (EditPoint e in ep) {
			if (n != null) {
				en = (!) n;
				draw_next (e, en, cr);
			}
			
			n = e;
		}
		
		// close path
		if (!is_open () && ep.length () >= 2) {
			en = (!)n;
			em = ep.first ().data;
			
			draw_next (em, en, cr);
		}

		if (is_selected ()) {
			// fill path
			cr.close_path ();
			cr.set_source_rgba (r, g, b, a);
			cr.fill ();
		}

		cr.stroke ();
		
		// control points for curvature
		foreach (EditPoint e in ep) {
			if (e.get_active_handle () || e.selected_handle > 0)
				draw_edit_point_handles (e, cr);
		}
					
		// control points
		foreach (EditPoint e in ep) {
			draw_edit_point (e, cr);
		}
		
	}
	
	private void draw_next (EditPoint e, EditPoint en, Context cr) {

		if (en.type == PointType.CURVE || e.type == PointType.CURVE) {
			draw_curve (e, en, cr);
		}	else if (en.type == PointType.LINE && e.type == PointType.LINE) {
			draw_line (e, en, cr);
		} else if (unlikely (en.type != PointType.CURVE)) {
			warning (@"PointType is $(en.type)");
		}
		
	}
	
	private static void draw_curve (EditPoint e, EditPoint en, Context cr, double alpha = 1) {
		Glyph g = MainWindow.get_current_glyph ();
		double xa, ya, xb, yb, xc, yc, xd, yd;
		
		get_bezier_points (e, en, out xa, out ya, out xb, out yb, out xc, out yc, out xd, out yd);

		cr.set_source_rgba (0, 0, 0, alpha);
		cr.set_line_width (1 * (1/g.view_zoom));
		
		cr.line_to (xa, ya); // this point makes sense only if it is the first or last position, the other points are meaning less don't export them

		cr.curve_to (xb, yb, xc, yc, xd, yd);
	}
	
	private static void print_curve (EditPoint e, EditPoint en) {
		double xa, ya, xb, yb, xc, yc, xd, yd;
		
		get_bezier_points (e, en, out xa, out ya, out xb, out yb, out xc, out yc, out xd, out yd);

		stdout.printf ("L");
		
		stdout.printf ("%s ",  round (xa));
		stdout.printf ("%s ",  round (ya));	
		
		stdout.printf ("\n");

		stdout.printf ("C");

		stdout.printf ("%s ", round (xb));
		stdout.printf ("%s ", round (yb));
		
		stdout.printf ("%s ", round (xc));
		stdout.printf ("%s ", round (yc));	
		
		stdout.printf ("%s ", round (xd));
		stdout.printf ("%s ", round (yd));	
		
		stdout.printf ("\n");
	}
	
	/** Curve relative to window center. */
	public static void get_bezier_points (EditPoint e, EditPoint en, out double xa, out double ya, out double xb, out double yb, out double xc, out double yc, out double xd, out double yd) {
		Glyph g = MainWindow.get_current_glyph ();
		
		double center_x, center_y;
		
		center_x = g.allocation.width / 2.0;
		center_y = g.allocation.height / 2.0;
				
		xa = center_x + en.x;
		ya = center_y - en.y;

		xb = center_x + en.get_right_handle ().x ();
		yb = center_y - en.get_right_handle ().y ();
		
		xc = center_x + e.get_left_handle ().x ();
		yc = center_y - e.get_left_handle ().y ();
		
		xd = center_x + e.x;
		yd = center_y - e.y;		
	}

	/** Curve absolute glyph data. */
	public static void get_abs_bezier_points (EditPoint e, EditPoint en, out double xa, out double ya, out double xb, out double yb, out double xc, out double yc, out double xd, out double yd) {
		xa =  + en.x;
		ya =  - en.y;

		xb =  + en.get_right_handle ().x ();
		yb =  - en.get_right_handle ().y ();
		
		xc =  + e.get_left_handle ().x ();
		yc =  - e.get_left_handle ().y ();
		
		xd =  + e.x;
		yd =  - e.y;		
	}
		
	/** Line points relative to center. */
	public static void get_line_points (EditPoint e, EditPoint en, out double xa, out double ya, out double xb, out double yb) {
		Glyph g = MainWindow.get_current_glyph ();
		
		double xc = g.allocation.width / 2.0;
		double yc = g.allocation.height / 2.0;
		
		xa = xc + en.x;
		ya = yc - en.y;
		
		xb = xc + e.x;
		yb = yc - e.y;
	}

	public static void get_abs_line_points (EditPoint e, EditPoint en, out double xa, out double ya, out double xb, out double yb) {
		Glyph g = MainWindow.get_current_glyph ();
		
		xa = en.x;
		ya = en.y;
		
		xb = e.x;
		yb = e.y;
	}
		
	public void draw_line (EditPoint e, EditPoint en, Context cr, double alpha = 1) { 
		Glyph g = MainWindow.get_current_glyph ();
		
		double xc = g.allocation.width / 2.0;
		double yc = g.allocation.height / 2.0;
		
		double ax, ay, bx, by;

		get_line_points (e, en, out ax, out ay, out bx, out by);
	
		cr.set_source_rgba (0.4, 0.4, 0.4, alpha);
		cr.set_line_width (1 * (1/g.view_zoom));

		cr.line_to (ax, ay);
	
		cr.line_to (bx, by);

	}
	
	public void draw_edit_point  (EditPoint e, Context cr) {
		draw_edit_point_center (e, cr);
	}
	
	public void draw_edit_point_handles (EditPoint e, Context cr) {
		EditPoint handle_right = e.get_right_handle ().get_point ();
		EditPoint handle_left = e.get_left_handle ().get_point ();
			
		draw_line (handle_right, e, cr, 0.15);
		draw_line (handle_left, e, cr, 0.15);
		
		cr.stroke ();
		
		draw_edit_point_center (handle_right, cr);
		draw_edit_point_center (handle_left, cr);
	}
	
	
	public static void draw_edit_point_center (EditPoint e, Context cr) {
		Glyph g = MainWindow.get_current_glyph ();
		
		double ivz = 1 / g.view_zoom;

		double xc = g.allocation.width / 2.0;
		double yc = g.allocation.height / 2.0;

		double p = e.x;
			
		double h = g.allocation.height * ivz + g.view_offset_y;
		
		double x = xc + e.x;
		double y = yc - e.y + 0.5;

		if (e.active) 
			cr.set_source_rgba (1, 0, 0, 1);
		else
			cr.set_source_rgba (e.r, e.g, e.b, e.a);

		cr.set_line_width (3 * ivz);	
		
		cr.new_path ();
		
		cr.move_to (x - 0.7 * ivz, y - 0.7 * ivz - 0.5);
		cr.line_to (x + 0.7 * ivz, y + 0.7 * ivz - 0.5);
		
		cr.move_to (x + 0.7 * ivz, y - 0.7 * ivz - 0.5);
		cr.line_to (x - 0.7 * ivz, y + 0.7 * ivz - 0.5);
		
		cr.close_path ();

		//cr.fill_preserve ();
		cr.stroke ();

	}
	
	public bool merge (Path? u) {
		bool err;
		int intersections; 

		Path union;
		Path merged;
		
		if (u == null) return false;
		
		union = (!) u;
		
		// skip empty path and objects that does't overlap
		if (!is_valid_union (union)) {
			return false;
		}

		// add intersecting points
		intersections = prepare_merge (union);
				
		if (intersections == 0) {
			return false;
		}

		// all outline paths are drawn clockwise
		err = force_union_directions (union);
		
		if (err) {
			return false;
		}
				
		// FIXME DELETE
		//print (@"DIR $(union.is_clockwise ())\n");
		//union.force_direction (Direction.COUNTER_CLOCKWISE);
		//print (@"DIR2  $(union.is_clockwise ())\n");
		
		// create new paths
		merged = create_merged_path (this, union);

		// path is crossing it self or a new inside appeared
		/*
		if (merged.is_crossing_own_path ()) {
			if (this.is_crossing_own_path ()) {
				warning ("this.is_crossing_own_path ()");
				// TODO: split it and find some good way to deal with it
			} else {
				warning ("merged.is_crossing_own_path ()");
				return false;
			}
		}
		*/

		// add merged points to this path
		this.remove_all_edit_points ();
		union.remove_all_edit_points ();
		replace_path (merged);
		
		this.set_editable (true);
		union.set_editable (true);
		merged.set_editable (true);
		
		return true;
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
	
	private static unowned List<EditPoint>? first_outside (Path source, Path union) {
		unowned List<EditPoint> p = source.points.first ();
		bool begins_outside = false;
		for (int i = 0; i < p.length (); i++) {
			if (!union.is_over (p.data.x, p.data.y) && !union.has_edit_point (p.data)) {
				return p; // a good place to start
			}
			
			p = p.next;
		}
		
		return null;
	}
	
	private bool force_union_directions (Path union) {
		bool r;
		
		r = force_union_direction (union); // do force direction
		r = force_union_direction (union); // check result, direction should not change
		
		if (unlikely (!r)) {
			warning ("Path direction is still not correct.");
		}
		
		return true;
	}
	
	private bool force_union_direction (Path union) {
		EditPoint? e;
		unowned List<EditPoint>? ed;
		EditPoint ep;
		EditPoint next;
		
		create_list ();
		union.create_list ();
		
		foreach (var p in points) {
			e = union.get_edit_point_at (p.x, p.y);
			
			if (e != null) {
				ep = (!) e;
				ed = ep.get_next ();
				
				if (unlikely (ed != null)) {
					warning ("next edit point is null");
					return false;
				}
				
				next = ((!)ed).data;
				
				if (is_over (ep.x, ep.y)) {
					union.reverse ();
					return false;
				}
			}
		}
		
		return true;
	}
	
	private static Path create_merged_path (Path source, Path union) {
		Path merged = new Path ();
		
		uint ml = union.points.length () + source.points.length ();
		
		unowned List<EditPoint> p;
		unowned List<EditPoint> eli;
		
		unowned List<EditPoint>? fou;
		Path? swap;
		
		// begin outside.
		fou = first_outside (source, union);
		if (fou == null) {
			swap = union;
			union = source;
			source = (!) swap;
		}
		
		fou = first_outside (source, union);
		return_if_fail (fou != null);
		
		p = (!) fou;
		eli = p;
		
		// create a new path from this path + union
		bool u = false;
		uint i = 0;
				
		while (true) {
			if (i == ml) break;
			if (++i == ml) { // FIXME: do something better
				break;
			}
						
			if (!merged.has_edit_point_at (p.data.x, p.data.y)) {
				merged.add (p.data.x, p.data.y);
			}
		
			eli = (!u) ? union.points : source.points;
			
			int tni = 0;			
			foreach (var t in eli) {
				
				if (p.data.x == t.x && p.data.y == t.y) {
					p = eli.nth (tni);
					u = !u;					
					break;
				}
				
				tni++;
			}
			
			if (p == p.last ()) p = p.first ();
			else p = p.next;
		}
		
		return merged;	
	}
		
	private bool has_edit_point_at (double x, double y) {
		foreach (var p in points) {
			if (p.x == x && p.y == y) return true;
		}
		
		return false;
	}

	private EditPoint? get_edit_point_at (double x, double y) {
		foreach (var p in points) {
			if (p.x == x && p.y == y) return p;
		}
				
		return null;
	}
		
	private void remove_all_edit_points () {
		while (points.length () > 0) {
			points.remove_link (points.first ());
		}
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
	
	/** Returns true if this path can be merged with @param union */ 
	private bool is_valid_union (Path union) {
		if (union == this) {
			warning ("Path can't union with it self.");
			return false;
		}
		
		if (union.points.length () <= 2 || points.length () <= 2) {
			return false;
		}

		if (!has_overlapping_boundry (union)) {
			return false;
		}

		return true;
	}
	
	/** Set direction for this path to clockwise for outline and 
	 * counter clockwise for inline paths.
	 */
	public bool force_direction (Direction direction) {
		bool c = (direction == Direction.CLOCKWISE);
		
		if (c != is_clockwise ()) {
			this.reverse ();
		}
		
		if (unlikely (is_clockwise () != c)) {
			warning ("Failed to set direction for path in force_direction.");
			return true;
		}
		
		return false;
	}
 	
	/** Add start and stop points to union from intersecting lines. 
	 * @return number of new intersecting points
	 */
	private int prepare_merge (Path union) 
		requires (union.points.length () >= 2)
	{				
		unowned List<EditPoint> lep = union.points.first ();
		unowned List<EditPoint> lprev = union.points.last ();

		List<IntersectionList> inter = new List<IntersectionList> ();
		int count = 0;
		
		while (true) {
			IntersectionList il = get_all_crossing_paths (lprev.data, lep.data);
			inter.append (il);

			if (lep == union.points.last ()) break;
			
			lprev = lep;
			lep = lep.next;
		}

		foreach (var ins in inter) {
			foreach (var ip in ins.points) {
				add_point_on_path (ip.x, ip.y);
				union.add_point_on_path (ip.x, ip.y);
				count++;
			}
		}
		
		return count;
	}

	/** Returns true if this path crosses it self some where. */
	public bool is_crossing_own_path () {
		unowned List<EditPoint> lep;
		unowned List<EditPoint> lprev;
				
		if (points.length () <= 2) return false;
		
		lep = points.first ();
		lprev = points.last ();

		while (true) {
			if (get_all_crossing_paths (lprev.data, lep.data).points.length () > 0) {
				return true;
			}

			if (lep == points.last ()) break;
			
			lprev = lep;
			lep = lep.next;
		}

		return false;
	}

	public void delete_edit_point (EditPoint e) {
		foreach (var p in points) {
			if (likely (p == e)) {
				points.remove (p);
			}
		}
		
		warning ("Edit point does not exist.");
	}
	
// TODO: Move classes
class Intersection : GLib.Object {
	public double x;
	public double y;
	
	public Intersection (double x, double y) {
		this.x = x;
		this.y = y;
	}
	
}

class IntersectionList : GLib.Object {
	public List<Intersection> points = new List<Intersection> ();
	
	public IntersectionList () {	
	}
	
	public void add (double x, double y) {
		if (points.length () > 0 && points.last().data.x == x && points.last().data.y == y) {
			return;
		}
		
		points.append (new Intersection (x, y));
	}
		
	public void delete_control_point_at (double x, double y) {
		foreach (var p in points) {
			if (p.x == x && p.y == y) {
				points.remove (p);
			}
		}
	}	
}

	private static bool line_is_duplicate (EditPoint a_start, EditPoint a_stop, EditPoint b_start, EditPoint b_stop) {
		return line_is_duplicate_comparaton (a_start, a_stop, b_start, b_stop)
			  || line_is_duplicate_comparaton (a_stop, a_start, b_start, b_stop); // swap and compare
	}

	private static bool line_is_duplicate_comparaton (EditPoint a_start, EditPoint a_stop, EditPoint b_start, EditPoint b_stop) {
		return (a_start.x == b_start.x && a_start.y == b_start.y && a_stop.x == b_stop.x && a_stop.y == b_stop.y);
	}
	
	/** Returns a list of all points where curves in this path crosses 
	 * line from @param start to @param stop
	 */
	private IntersectionList get_all_crossing_paths (EditPoint start, EditPoint stop) {
		IntersectionList il = new IntersectionList ();
		
		unowned List<EditPoint> prev = points.last ();
		unowned List<EditPoint> ep = points.first ();
				
		double new_x;
		double new_y;

		return_val_if_fail (points.length () >= 2, new IntersectionList ());

		while (true) {

			bool r = false; // fixme: optimize (don't iterate + stop iteration)
			double min = double.MAX;
			
			new_x = double.MAX;
			new_y = double.MAX;
						
			all_of (prev.data, ep.data, (tx, ty) => {
				all_of (start, stop, (cx, cy) => {
						double n = pow (tx - cx, 2) + pow (ty - cy, 2);
						
						if (n < min && n < 1) { // TODO: add variable tolerance
							r = true;
							min = n;

							// this point is a better coordinate, replace the last one
							il.delete_control_point_at (new_x, new_y);
			
							new_x = cx;
							new_y = cy;

							//il.add_unique (new_x, new_y); // add a new point
							il.add (new_x, new_y); // add a new point
						}
						
						// Look for the next one a long this path
						if (n > 1) {
							min = double.MAX;
						}
						
						return true;
					}, 5);
					
					return true;
				}, 5);
			
			
			if (ep == points.last ()) break;
			
			prev = ep;
			ep = ep.next;
		}

		return il;
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

	private int index (EditPoint ep) {
		int i = 0;
		
		foreach (var p in points) {
			if (ep.x == p.x && ep.y == p.y) {
				return i;
			}
			
			i++;
		}
		
		return -1;
	}

	public void print_all_points () {
		int i = 0;
		foreach (var p in points) {
			++i;
			string t = (p.type == PointType.END) ? " endpoint" : "";
			stdout.printf (@"Point $i at ($(p.x), $(p.y)) $t \n");
		}
	}
	
	private bool is_clockwise_top () {
		EditPoint top_point = new EditPoint (1000, 1000);
		
		return_if_fail (points.length () >= 3);
		
		create_list ();
		
		foreach (EditPoint ep in points) {
			if (ep.y < top_point.y) {
				top_point = ep;
			}
		}
		
		return (top_point.get_prev ().data.x < top_point.get_next ().data.x);
	}
	
	public bool is_clockwise () {
		if (unlikely (points.length () <= 2)) {
			no_derived_direction = true;
			return clockwise_direction;
		}
		
		return is_clockwise_top ();
	}
	
	private static uint num_positions (uint i_xmax, uint i_ymax, uint i_xmin, uint i_ymin) {
		List<uint> i = new List<uint> ();
		
		if (i.index (i_xmax) == -1) i.append (i_xmax);
		if (i.index (i_ymax) == -1) i.append (i_ymax);
		if (i.index (i_xmin) == -1) i.append (i_xmin);
		if (i.index (i_ymin) == -1) i.append (i_ymin);

		return i.length ();
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
	
	public void resize (double ratio) {
		double w, h, cx, cy;
		
		update_region_boundries ();
		
		w = Math.fabs(xmax - xmin);
		h = Math.fabs(ymax - ymin);
		cx = w / 2 + xmin; 
		cy = h / 2 + ymin;
		
		if (ratio == 1) return;
		
		if (ratio < 1) {
			ratio = 1 - ratio;
			
			foreach (var p in points) {
				if (p.x < cx)
					p.x += (cx - p.x) * ratio;
				else
					p.x -= (p.x - cx) * ratio;

				if (p.y > cy)
					p.y += (cy - p.y) * ratio;
				else
					p.y -= (p.y - cy) * ratio;				
			}
				
		} else {
			ratio = ratio - 1;
			
			foreach (var p in points) {
				if (p.x < cx)
					p.x -= (cx - p.x) * ratio;
				else
					p.x += (p.x - cx) * ratio;

				if (p.y > cy)
					p.y -= (cy - p.y) * ratio;
				else
					p.y += (p.y - cy) * ratio;				
			}
			
		}
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
		if (!is_over_boundry (x, y)) {
			return false;
		}

		return true;
	}

	bool in_line_region (EditPoint ep, EditPoint e, double x, double y) {
		Glyph g = MainWindow.get_current_glyph ();
		
		x = x * Glyph.ivz () + g.view_offset_x - Glyph.xc ();
		y = y * Glyph.ivz () + g.view_offset_y - Glyph.yc ();

		y *= -1;
		
		return ((ep.x <= x <= e.x || e.x <= x <= ep.x) && (ep.y <= y <= e.y || e.y <= y <= ep.y));
	}

	public bool is_over_boundry (double x, double y) {
		Glyph g = MainWindow.get_current_glyph ();
		
		x = x * Glyph.ivz () + g.view_offset_x - Glyph.xc ();
		y = y * Glyph.ivz () + g.view_offset_y - Glyph.yc ();

		y *= -1;
				
		return (ymin <= y <= ymax) && (xmin <= x <= xmax);
	}

	public bool has_overlapping_boundry (Path p) {
		return !(xmax < p.xmin || ymax < p.ymin) || (xmin > p.xmax || ymin > p.ymax);
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
		EditPoint p = new EditPoint (x, y, PointType.LINE);	
		return add_point_after (p, previous_point);
	}
	
	public unowned List<EditPoint> add_point_after (EditPoint p, List<EditPoint>? previous_point) {
		unowned List<EditPoint> np;
		unowned List<EditPoint>? op;
		int prev_index;

		if (points.length () > 0 && previous_point != null && ((!)previous_point).data.type == PointType.END) {
			points.delete_link ((!) previous_point);
		}

		if (unlikely (previous_point == null && points.length () != 0)) warning ("previous_point == null");

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
				
		update_region_boundries ();
		
		return np;
		
	}
	
	public void add_point_on_path (double x, double y) {
		EditPoint e = new EditPoint (0, 0);
		get_closest_point_on_path (e, x, y);
		add_after (x, y, e.prev);
	}
	
	public void close () {
		open = false;
		edit = false;
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
	
	/** Move edit point. */	
	public void move_last_point (double x, double y) {
		return_if_fail (last_point != null);
		((!) last_point).set_position (x, y);
		update_region_boundries ();
	}
	
	/** Move path. */
	public void move (double delta_x, double delta_y) {
		foreach (var ep in points) {
			ep.x += delta_x;
			ep.y += delta_y; // kanske -y
		}
		
		update_region_boundries ();
	}
	
	/** Remove intersection. */
	public void cut_path (Path exclution) {
		if (!has_intersection (exclution)) {
			stderr.printf ("No intersec in cut path.\n");
			return;
		}
		
		if (points.length () < 1 || exclution.points.length () < 1) {
			stderr.printf ("No intersection in cut path: %u %u\n", points.length (), exclution.points.length ());
		}
		
		EditPoint prev_tp = points.last  ().data;
		EditPoint prev_ep = exclution.points.last  ().data;
		foreach (EditPoint ep in exclution.points) {
				
			int insert_index = 0;
			foreach (EditPoint tp in points) {
				
				if (point_in_range ((!) prev_tp, ep, tp)) {
					EditPoint? ip = get_intersect_point (prev_tp, tp, prev_ep, ep);
					if (ip == null) {
						stderr.printf ("No intersecting point to cut from.\n");
						continue;
					}
					
					EditPoint inter_start = (!) ip;
					
					points.insert (inter_start, insert_index);
				} else {
					stderr.printf ("No point in range\n");
				}
				
				insert_index++;
				prev_tp = tp;
			}
			
			prev_ep = ep;
		} 
	}

	/** Test if @param path is a valid outline for this object. */	
	public bool test_is_outline (Path path) {
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
	
	/** Get a point on the this path closest to x and y coordinates. */
	public void get_closest_point_on_path (EditPoint edit_point, double x, double y) {
		return_if_fail (points.length () != 0);
		
		double min = double.MAX;
		double n = 0;
		bool g = false;
		
		double ox = 0;
		double oy = 0;
		
		unowned List<EditPoint> i = points.first ();
		unowned List<EditPoint> prev = i.next;

		bool done = false;
		bool exit = false;
		
		unowned List<EditPoint>? previous_point = null;
		unowned List<EditPoint>? next_point = null;
		
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
			
			all_of (prev.data, i.data, (cx, cy) => {
					n = pow (x - cx, 2) + pow (y - cy, 2);
					
					if (n < min) {
						min = n;
						
						ox = cx;
						oy = cy;
					
						previous_point = prev;
						next_point = i;
							
						g = true;
					}
					
					return true;
				});
		}

		edit_point.set_position (ox, oy);
		edit_point.prev = previous_point;
		edit_point.next = next_point;

		if (unlikely (!g)) {
			warning (@"Error: Got no coordinates for point on path. Num points $(points.length ())\n");
		}
	}

	// TODO: Find a clever mathematical solutions instead
	private void all_of (EditPoint start, EditPoint stop, RasterIterator iter, int steps = 400) {
		int n = steps;
		
		double px;
		double py;

		double rx, qx;
		double ry, qy;

		double sx = (stop.x - start.x) / n;
		double sy = (stop.y - start.y) / n;

		if (false && start.type == PointType.LINE && stop.type == PointType.LINE) {
			all_of_line (start.x, start.y, stop.x, stop.y, iter, steps);
		} else {
			all_of_curve (start.x, start.y, start.get_right_handle ().x (), start.get_right_handle ().y (), start.get_left_handle ().x (), start.get_left_handle ().y (), stop.x, stop.y, iter, steps);
		}

	}

	private void all_of_curve (double x0, double y0, double x1, double y1, double x2, double y2, double x3, double y3, RasterIterator iter, int steps = 400) {
		double px = x1;
		double py = y1;
		
		double t;
		double s = steps;
		
		for (int i = 0; i < steps; i++) {
			t = i / s;
			
			px = pow (1 - t, 3) * x0;
			px += 3 * pow (1 - t, 2) * t * x1;
			px += 3 * pow (1 - t, 2) * pow (t, 2) * x2;
			px += pow (t, 3) * x3;

			py = pow (1 - t, 3) * y0;
			py += 3 * pow (1 - t, 2) * t * y1;
			py += 3 * pow (1 - t, 2) * pow (t, 2) * y2;
			py += pow (t, 3) * y3;
			
			if (!iter (px, py)) {
				return;
			}
			
		}	
	}

	private void all_of_line (double x1, double y1, double x2, double y2, RasterIterator iter, int steps = 400) {
		int n = steps;
		
		double px = x1;
		double py = y1;

		double sx = (x2 - x1) / n;
		double sy = (y2 - y1) / n;

		for (int i = 0; i < n; i++) {
			
			if (!iter (px, py)) {
				return;
			}
			
			px += sx;
			py += sy;
		}

	}
	
	private EditPoint? get_intersect_point (EditPoint a_start, EditPoint a_stop, EditPoint b_start, EditPoint b_stop) {
		double ax = a_start.x;
		double ny = a_start.y;
		
		double bx = b_start.x;
		
		int n = 100;
		
		double a_step_x = (a_stop.x - a_start.x) / n;
		double b_step_x = (b_stop.x - b_start.x) / n;

		bool d = !(ax > bx);

		for (int i = 0; i < n; i++) {
			
			// if (nx > x.x) { // Nästan grekiskt, kolla parabol	
			// eller bx > ax åt andra hållet
			if (d && ax > bx) { // överklart klart, asymptotiskt 
				return new EditPoint (ax, a_start.y * n/100.0);  // fixme do y to
			}

			if (!d && ax < bx) {
				return new EditPoint (ax, a_start.y * n/100.0);
			}
			
			ax += a_step_x;
			bx += b_step_x;
		}

		return null;
	}
	
	private bool point_in_range (EditPoint x, EditPoint a, EditPoint b) {
		return in_range (x.x, a.x, b.x) && in_range (x.y, a.y, b.y);
	}
	
	private bool in_range (double x, double ma, double mb) {
		return (ma < x < mb) || (ma > x > mb);
	}
	
	private bool has_intersection (Path p) {
		return p.has_intersecting_point (this) || this.has_intersecting_point (p);
	}

	private bool has_intersecting_point (Path p) {
		return (is_over (p.xmin, p.ymin) || is_over (p.xmax, p.ymax));
	}
	
	public void update_region_boundries () {
		unowned List<EditPoint> i = points.first ();
		unowned List<EditPoint> prev = points.last ();

		if (points.length () == 0) {
			xmax = 0;
			xmin = 0;
			ymax = 0;
			ymin = 0;			
		}

		xmax = -10000;
		xmin = 10000;
		ymax = -10000;
		ymin = 10000;

		double txmax = -10000;
		double txmin = 10000;
		double tymax = -10000;
		double tymin = 10000;

		bool new_val = false;
		
		while (i != points.last ()) {
						
			all_of (prev.data, i.data, (cx, cy) => {
					
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

			prev = i;
			i = i.next;
		}

		xmax = txmax;
		xmin = txmin;
		ymax = tymax;
		ymin = tymin;

		// Fixa:
		// print (@"updated \n");

		if (unlikely (!new_val)) {
			// only one point, what should we do? probably skip it.
		} else if (unlikely (!got_region_boundries ())) {
			warning (@"No new region boundries.\nPoints.length: $(points.length ())");
			print_boundries ();
		}
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
		unowned List<EditPoint> ep = points;
		
		if (points.length () == 0) {
			return;
		}
		
		if (points.length () == 1) {
			ep.data.next = points.first ();
			ep.data.prev = points.last ();
			return;
		}
		
		ep.data.next = ep.next;
		ep.data.prev = ep.last ();
		
		while (ep != ep.last ()) {
			ep.data.next = ep.next;
			ep.data.prev = ep.prev;
			ep = ep.next;
		}
		
		ep.data.next = ep.first ();
		ep.data.prev = ep.prev;
	}
	
	public void set_new_start (EditPoint ep) {
		List<EditPoint> list = new List<EditPoint> ();
		uint len = points.length ();
		unowned List<EditPoint> iter = points.first ();
		
		foreach (var it in points) {
			if (it == ep) {
				break;
			}
			
			iter = iter.next;
		}
		
		for (uint i = 0; i < len; i++) {
			list.append (iter.data);
			
			if (iter == iter.last ())
				iter = iter.first ();
			else
				iter = iter.next;
		
		}
		
		points = (owned) list;
	}
	
}

}
