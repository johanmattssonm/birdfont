/*
    Copyright (C) 2012 Johan Mattsson

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

namespace BirdFont {

public enum PointType {
	NONE,
	LINE_QUADRATIC,      // line with quadratic handle
	LINE_DOUBLE_CURVE,   // line with two quadratic handles
	LINE_CUBIC,          // line with cubic handles
	CUBIC,
	DOUBLE_CURVE,        // two quadratic points with a hidden point half way between the two line handles
	QUADRATIC,
	END,
	FLOATING
}

public class EditPoint {
	
	public double x;
	public double y;
	public PointType type;
	
	public unowned List<EditPoint>? prev = null;
	public unowned List<EditPoint>? next = null;

	public bool active = false;
	public bool selected = false;
		
	public int selected_handle = 0;
	
	public EditPointHandle right_handle;
	public EditPointHandle left_handle;
	
	public bool tie_handles = false;
	
	public EditPoint (double nx = 0, double ny = 0, PointType nt = PointType.NONE) {
		x = nx;
		y = ny;
		type = nt;
		active = false;
		
		set_active (true);
		
		if (nt == PointType.FLOATING) {
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
			
			if (h.type == PointType.LINE_CUBIC) {
				nx = x + ((n.x - x) / 3);
				ny = y + ((n.y - y) / 3);
				h.move_to_coordinate (nx, ny);
			}

			if (h.type == PointType.LINE_DOUBLE_CURVE) {
				nx = x + ((n.x - x) / 4);
				ny = y + ((n.y - y) / 4);
				h.move_to_coordinate (nx, ny);
			}
									
			// the other side
			h = n.get_right_handle ();
			
			if (h.type == PointType.LINE_DOUBLE_CURVE) {
				nx = n.x + ((x - n.x) / 4);
				ny = n.y + ((y - n.y) / 4);	
				h.move_to_coordinate (nx, ny);
				
			}
			
			if (h.type == PointType.LINE_CUBIC) {
				nx = n.x + ((x - n.x) / 3);
				ny = n.y + ((y - n.y) / 3);	
				h.move_to_coordinate (nx, ny);
			}
		}

		// right handle
		if (next != null) {
			n = get_next ().data;
			h = get_right_handle ();
			
			if (h.type == PointType.LINE_CUBIC) {
				nx = x + ((n.x - x) / 3);
				ny = y + ((n.y - y) / 3);
				
				h.move_to_coordinate (nx, ny);
			}

			if (h.type == PointType.LINE_DOUBLE_CURVE) {
				nx = x + ((n.x - x) / 4);
				ny = y + ((n.y - y) / 4);
				
				h.move_to_coordinate (nx, ny);
			}

			if (h.type == PointType.LINE_QUADRATIC) {
				nx = x + ((n.x - x) / 2);
				ny = y + ((n.y - y) / 2);
				
				h.move_to_coordinate (nx, ny);
			}

			h = n.get_left_handle ();
			
			if (h.type == PointType.LINE_CUBIC) {
				nx = n.x + ((x - n.x) / 3);
				ny = n.y + ((y - n.y) / 3);

				h.move_to_coordinate (nx, ny);
			}
			
			if (h.type == PointType.LINE_DOUBLE_CURVE) {
				nx = n.x + ((x - n.x) / 4);
				ny = n.y + ((y - n.y) / 4);

				h.move_to_coordinate (nx, ny);
			}
		}
	}
	
	public void set_tie_handle (bool t) {
		tie_handles = t;
	}

	public void process_tied_handle () 
	requires (next != null && prev != null) {
		double a, b, c, length, angle;
		EditPointHandle eh;
		EditPointHandle prev_rh, next_lh;
		
		eh = right_handle;
		
		if (left_handle.type == PointType.QUADRATIC) {
			left_handle.length = 0;
		}
		
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
		
		if (left_handle.type == PointType.QUADRATIC) {
			prev_rh = get_prev ().data.get_right_handle ();
			next_lh = get_next ().data.get_left_handle ();
			
			if (next_lh.type == PointType.QUADRATIC) {
				next_lh.type = PointType.DOUBLE_CURVE;
				next_lh.length *= 0.5;
			}

			left_handle.move_to_coordinate (prev_rh.x (), prev_rh.y ());
			left_handle.length *= 0.5;
			
			if (right_handle.type == PointType.QUADRATIC) {
				right_handle.length *= 0.5;
			}
			
			prev_rh.length *= 0.5;
			
			prev_rh.type = PointType.DOUBLE_CURVE;
			left_handle.type = PointType.DOUBLE_CURVE;
			right_handle.type = PointType.DOUBLE_CURVE;
		} else if (left_handle.type == PointType.LINE_DOUBLE_CURVE) {
			left_handle.type = PointType.DOUBLE_CURVE;
			right_handle.type = PointType.DOUBLE_CURVE;
			
			prev_rh = get_prev ().data.get_right_handle ();
			next_lh = get_next ().data.get_left_handle ();
			
			prev_rh.type = PointType.DOUBLE_CURVE;	
			next_lh.type = PointType.DOUBLE_CURVE;
		} else if (left_handle.type == PointType.LINE_CUBIC) {
			left_handle.type = PointType.CUBIC;
			right_handle.type = PointType.CUBIC;
		}
				
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
