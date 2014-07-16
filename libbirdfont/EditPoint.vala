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
	FLOATING,
	HIDDEN
}

public class EditPoint : GLib.Object {
	
	public double x;
	public double y;
	public PointType type;
	
	public unowned EditPoint? prev = null;
	public unowned EditPoint? next = null;

	public bool active = false;
	public bool selected = false;
	public bool deleted = false;
	
	public int selected_handle = 0;
	
	public EditPointHandle right_handle;
	public EditPointHandle left_handle;
	
	public bool tie_handles = false;
	public bool reflective_handles = false;

	/** Set new position for control point without moving handles. */
	public double independent_x {
		get { 
			return x;
		}
		
		set { 
			double d = value - x;
			x = value;
			right_handle.x -= d;
			left_handle.x -= d;
		}
	}

	public double independent_y {
		get {
			return y;	
		}
		
		set { 
			double d = value - y;
			y = value;
			right_handle.y -= d;
			left_handle.y -= d;
		}
	}
	
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

	public void set_point_type (PointType t) {
		type = t;
	}

	public double get_corner_angle () {
		double l, r, a;
		
		l = get_left_handle ().angle;
		r = get_right_handle ().angle;
		a = fabs (l - r);

		if (l > r) {
			return 2 * PI - a;
		}
		
		return a;
	}
		
	public bool equals (EditPoint e) {
		return e.x == x 
			&& e.y == y 
			&& get_right_handle ().x == e.get_right_handle ().x
			&& get_right_handle ().y == e.get_right_handle ().y
			&& get_left_handle ().x == e.get_left_handle ().x
			&& get_left_handle ().y == e.get_left_handle ().y;
	}

	/** Make handles symmetrical. */
	public void set_reflective_handles (bool symmetrical) {
		reflective_handles = symmetrical;
	}

	/** Flip handles if next point on path is in the other direction. 
	 *  Used to recalculate handles after new point is inserted on a path.
	 */
	public void recalculate_handles (double px, double py) {
		double dr, dl;
		EditPointHandle t;
		
		if (next == null || get_next ().next != null) {
				return;
		}
		
		px = get_next ().get_next ().x;
		py = get_next ().get_next ().y;
		
		dr = Math.sqrt (Math.pow (px - right_handle.x, 2) + Math.pow (py - right_handle.y, 2));
		dl = Math.sqrt (Math.pow (px - left_handle.x, 2) + Math.pow (py - left_handle.y, 2));

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
			// FIXME: prev = get_next ().last ();
		}

		// left handle
		if (prev != null) {
			n = get_prev ();
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

			if (h.type == PointType.LINE_QUADRATIC) {
				nx = x + ((n.x - x) / 2);
				ny = y + ((n.y - y) / 2);
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

			if (h.type == PointType.LINE_QUADRATIC) {
				nx = n.x + ((x - n.x) / 2);
				ny = n.y + ((y - n.y) / 2);	
				h.move_to_coordinate (nx, ny);
			}
		}

		// right handle
		if (next != null) {
			n = get_next ();
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

			if (h.type == PointType.LINE_QUADRATIC) {
				nx = n.x + ((x - n.x) / 2);
				ny = n.y + ((y - n.y) / 2);
				
				h.move_to_coordinate (nx, ny);
			}
		}
	}
	
	public bool is_clockwise () {
		return get_direction () >= 0;
	}
	
	public double get_direction () {
		if (prev == null) {
			return 0;
		}
		
		// FIXME:
		return (x - get_prev ().x) * (y + get_prev ().y);
	}
	
	public void set_tie_handle (bool tie) {
		tie_handles = tie;
	}
	
	public void process_symmetrical_handles () {
		process_tied_handle ();
		right_handle.process_symmetrical_handle ();
		left_handle.process_symmetrical_handle ();
	}
	
	public static void convert_from_line_to_curve (EditPointHandle h) {
		switch (h.type) {
			case PointType.LINE_QUADRATIC:
				h.type = PointType.QUADRATIC;
				break;
			case PointType.LINE_DOUBLE_CURVE:
				h.type = PointType.DOUBLE_CURVE;
				break;
			case PointType.LINE_CUBIC:
				h.type = PointType.CUBIC;
				break;
			default:
				break;
		}
	}

	/** This can only be performed if the path has been closed. */
	public void process_tied_handle () 
	requires (next != null && prev != null) {
		double a, b, c, length, angle;
		EditPointHandle eh;
		EditPointHandle prev_rh, next_lh;
		
		eh = right_handle;
		
		a = left_handle.x - right_handle.x;
		b = left_handle.y - right_handle.y;
		c = a * a + b * b;
		
		if (c == 0) {
			return;
		}
		
		length = sqrt (fabs (c));
		
		if (right_handle.y < left_handle.y) {
			angle = acos (a / length) + PI;
		} else {
			angle = -acos (a / length) + PI;
		}
		
		prev_rh = get_prev ().get_right_handle ();
		next_lh = get_next ().get_left_handle ();	
		
		convert_from_line_to_curve (next_lh);
		convert_from_line_to_curve (prev_rh);
		convert_from_line_to_curve (left_handle);
		convert_from_line_to_curve (right_handle);	
		
		right_handle.angle = angle;
		left_handle.angle = angle - PI;

		set_tie_handle (true);
		eh.move_to_coordinate (right_handle.x, right_handle.y);
	}

	public EditPoint copy () {
		EditPoint new_point = new EditPoint ();
		
		new_point.x = x;
		new_point.y = y;
		
		new_point.type = type;
		new_point.deleted = deleted;
		new_point.selected = selected;
		
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
	
	public unowned EditPoint get_prev () {
		if (unlikely (prev == null)) {
			warning ("EditPoint.prev is null");
		}
		
		return (!) prev;
	}

	public unowned EditPoint get_next () {
		if (unlikely (next == null)) {
			warning ("EditPoint.next is null");
		}
		
		return (!) next;
	}
	
	public unowned EditPoint get_link_item () {
		return this;
	}
		
	public void set_position (double tx, double ty) {
		EditPoint p, n;
		
		x = tx;
		y = ty;
		
		if (unlikely (tx.is_nan () || ty.is_nan ())) {
			warning (@"Invalid point at ($tx,$ty).");
			x = 0;
			y = 0;
		}
		
		// move connected quadratic handle
		if (right_handle.type == PointType.QUADRATIC) {
			if (next != null) {
				n = get_next ();
				n.set_tie_handle (false);
				n.set_reflective_handles (false);
				n.left_handle.move_to_coordinate_internal (right_handle.x, right_handle.y);
			}
		}
		
		if (left_handle.type == PointType.QUADRATIC) {
			if (prev != null && !get_prev ().is_selected ()) {
				p = get_prev ();
				p.set_tie_handle (false);
				p.set_reflective_handles (false);
				p.right_handle.move_to_coordinate (left_handle.x, left_handle.y);
			}
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
}

}
