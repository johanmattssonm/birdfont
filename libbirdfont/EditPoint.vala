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

using Math;

namespace BirdFont {

public enum PointType {
	NONE,
	NORMAL,
	LINE,
	CURVE,
	QUADRATIC,
	DOUBLE_CURVE,
	END,
	FLOATING
}

public class EditPoint {
	
	public double x;
	public double y;
	public PointType type;
	
	public double r = 1;
	public double g = 0;
	public double b = 0;
	public double a = 1;
	
	public unowned List<EditPoint>? prev = null;
	public unowned List<EditPoint>? next = null;

	public bool active = false;
	public bool selected = false;
		
	public int selected_handle = 0;
	
	public EditPointHandle right_handle;
	public EditPointHandle left_handle;
	
	public bool tie_handles = false;
	
	public EditPoint (double nx = 0, double ny = 0, PointType nt = PointType.LINE) {
		x = nx;
		y = ny;
		type = nt;
		active = false;
		
		set_active (true);
		
		if (nt == PointType.FLOATING) {
			r = 1;
			g = 1;
			b = 0;
			a = 1;
			active = false;
		}
	
		right_handle = new EditPointHandle (this, 0, 7);
		left_handle = new EditPointHandle (this, PI, 7);

		if (unlikely (nx.is_nan () || ny.is_nan ())) {
			warning (@"Invalid point at ($nx,$ny).");
			x = 0;
			y = 0;
		}
	}

	/** Flip handles if next point on path is in the other direction. 
	 *  Used to recalculate handles after new point is inserted on a path.
	 */
	public void recalculate_handles (double px, double py) {
		double dr, dl;
		EditPointHandle t;
		
		if (next == null || ((!)next).length () < 2) {
				return;
		}
		
		px = get_next ().nth (1).data.x;
		py = get_next ().nth (1).data.y;
		
		dr = Math.sqrt (Math.pow (px - right_handle.x (), 2) + Math.pow (py - right_handle.y (), 2));
		dl = Math.sqrt (Math.pow (px - left_handle.x (), 2) + Math.pow (py - left_handle.y (), 2));

		// flip handles
		if (dl < dr) {
			t = right_handle;
			right_handle = left_handle;
			left_handle = t;
		}		
	}
		
	/** Set bezier points for linear paths. */
	public void recalculate_linear_handles () {
		unowned EditPointHandle h;
		unowned EditPoint n;
		double nx, ny;

		if (prev == null && next != null) {
			prev = get_next ().last ();
		}

		// left handle
		if (prev != null) {
			n = get_prev ().data;
			h = get_left_handle ();
			
			if (h.type == PointType.LINE) {
				nx = x + ((n.x - x) / 3);
				ny = y + ((n.y - y) / 3);
			
				h.move_to_coordinate (nx, ny);
			}

			h = n.get_right_handle ();
			
			// on the other side
			h = n.get_right_handle ();
			
			if (h.type == PointType.LINE) {
				nx = n.x + ((x - n.x) / 3);
				ny = n.y + ((y - n.y) / 3);
			
				h.move_to_coordinate (nx, ny);
			}
		}

		// right handle
		if (next != null) {
			n = get_next ().data;
			h = get_right_handle ();
			
			if (h.type == PointType.LINE) {
				nx = x + ((n.x - x) / 3);
				ny = y + ((n.y - y) / 3);
				
				h.move_to_coordinate (nx, ny);
			}

			h = n.get_left_handle ();
			
			if (h.type == PointType.LINE) {
				nx = n.x + ((x - n.x) / 3);
				ny = n.y + ((y - n.y) / 3);

				h.move_to_coordinate (nx, ny);
			}
		}
	}
	
	public void set_tie_handle (bool t) {
		tie_handles = t;
	}

	public void process_tied_handle () {
		double a, b, c, length, angle;
		EditPointHandle eh;
		
		eh = right_handle;
		
		a = left_handle.x () - right_handle.x ();
		b = left_handle.y () - right_handle.y ();
		c = a * a + b * b;
		
		if (c == 0) {
			return;
		}
		
		length = sqrt (fabs (c));
		
		if (right_handle.y () < left_handle.y ()) {
			angle = acos (a / length) + PI;
		} else {
			angle = -acos (a / length) + PI;
		}
		
		left_handle.type = PointType.CURVE;
		right_handle.type = PointType.CURVE;
		
		right_handle.angle = angle;
		left_handle.angle = angle;

		set_tie_handle (true);
		eh.move_to_coordinate (right_handle.x (), right_handle.y ());
	}

	public EditPoint copy () {
		EditPoint new_point = new EditPoint ();
		
		new_point.x = x;
		new_point.y = y;
		
		new_point.type = type;
		new_point.set_color (r, g, b, a);
		
		new_point.tie_handles = tie_handles;
		
		new_point.right_handle.angle = right_handle.angle;
		new_point.right_handle.length = right_handle.length;
		new_point.right_handle.type = right_handle.type;

		new_point.left_handle.angle = left_handle.angle;
		new_point.left_handle.length = left_handle.length;		
		new_point.left_handle.type = left_handle.type;

		return new_point;
	}

	public double get_distance (double x, double y) {
		return Path.distance (this.x, x, this.y, y);
	}

	public unowned EditPointHandle get_left_handle () {
		return left_handle;
	}
	
	public unowned EditPointHandle get_right_handle () {
		return right_handle;
	}
	
	public void set_color (double r, double g, double b, double a) {
		this.r = r;
		this.g = g;
		this.b = b;
		this.a = a;
	}
	
	public unowned List<EditPoint> get_prev () {
		if (prev == null && next != null && get_next ().prev == get_next ().first ()) {
			prev = get_next ().last ();
		}
		
		if (unlikely (prev == null)) {
			warning ("EditPoint.prev is null");
		}
		
		return (!) prev;
	}

	public unowned List<EditPoint> get_next () {
		if (unlikely (next == null)) {
			warning ("EditPoint.next is null");
		}
		
		return (!) next;
	}
	
	public unowned List<EditPoint> get_list () {
		return get_next ().first ();
	}
	
	public void set_position (double tx, double ty) {
		x = tx;
		y = ty;

		if (unlikely (tx.is_nan () || ty.is_nan ())) {
			warning (@"Invalid point at ($tx,$ty).");
			x = 0;
			y = 0;
		}
	}
	
	public static void to_coordinate (ref double x, ref double y) {
		double xc, yc, xt, yt, ivz;
		Glyph g = MainWindow.get_current_glyph ();
		
		ivz = 1 / g.view_zoom;
		
		xc = (g.allocation.width / 2.0);
		yc = (g.allocation.height / 2.0);
				
		x *= ivz;
		y *= ivz;

		xt = x - xc + g.view_offset_x;
		yt = yc - y - g.view_offset_y;		
		
		x = xt;
		y = yt;
	}
	
	public bool is_selected () {
		return selected;
	}
	
	public void set_selected (bool s) {
		selected = s;
	}
	
	public bool set_active (bool active) {
		bool update = (this.active != active);
		
		if (update) {
			this.active = active;
		
			if (active) {
				r = 0.5;
				g = 0;
				b = 1;
				a = 1;
			} else {
				r = 0;
				g = 1;
				b = 0.5;
				a = 1;
			}
		}
		
		return update;
	}
	
	public int get_index () {
		int i = -1;
		
		if (next == null) return i;
	
		foreach (var d in get_next ().first ()) {
			i++;
			
			if (this == d) {
				return i;
			}
		}
		
		return i;
	}
}

}
