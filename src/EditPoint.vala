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

enum PointType {
	NORMAL,
	LINE,
	CURVE,
	DOUBLE_CURVE,
	END,
	FLOATING
}

class EditPoint {
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
	bool active_handle = false;
	
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
		EditPointHandle h;
		unowned EditPoint n;
		double nx, ny;
		
		return_if_fail (type == PointType.LINE);

		if (prev == null && next != null) {
			prev = get_next ().last ();
		}

		// left handle
		if (prev != null) {
			n = get_prev ().data;
			h = get_left_handle ();
			
			nx = x + ((n.x - x) / 3);
			ny = y + ((n.y - y) / 3);
			
			h.move_to_coordinate (nx, ny);	
			
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
			
			nx = x + ((n.x - x) / 3);
			ny = y + ((n.y - y) / 3);
			
			h.move_to_coordinate (nx, ny);
			
			// on the other side
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

	public void set_point_type (PointType point_type) {
		type = point_type;
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

		new_point.left_handle.angle = left_handle.angle;
		new_point.left_handle.length = left_handle.length;		

		return new_point;
	}

	public bool get_active_handle () {
		return active_handle;	
	}
		
	public void set_active_handle (bool a) {
		active_handle = a;	
	}
	
	public bool is_close (double x, double y) {
		return get_close_distance (x, y) < double.MAX;
	}

	public double get_close_distance (double x, double y, double m = 15) {
		Glyph g = MainWindow.get_current_glyph ();
		
		double xt, yt, d;
		double ivz = 1 / g.view_zoom;
		
		double xc = (g.allocation.width / 2.0);
		double yc = (g.allocation.height / 2.0);
		
		m /= g.view_zoom;
		
		x *= ivz;
		y *= ivz;

		xt = x - xc + g.view_offset_x;
		yt = yc - y - g.view_offset_y;		
		
		d = Math.sqrt (Math.pow (this.x - xt, 2) + Math.pow (this.y - yt, 2));
		
		if (d < m) return d;
		
		return double.MAX;
	}

	public EditPointHandle get_left_handle () {
		return left_handle;
	}
	
	public EditPointHandle get_right_handle () {
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
