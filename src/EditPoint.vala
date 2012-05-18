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

enum PointDirection {
	NONE,
	UP_RIGHT,
	DOWN_RIGHT,
	UP_LEFT,
	DOWN_LEFT
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

	public PointDirection direction = PointDirection.NONE;
	
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

	public void set_point_type (PointType point_type) {
		type = point_type;
	}

	public EditPoint copy () {
		EditPoint new_point = new EditPoint ();
		
		new_point.x = x;
		new_point.y = y;
		
		new_point.type = type;
		new_point.direction = direction;
		
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
	
	// Fixa: ta bort färgmarkeringarna
	public void set_direction () {
		EditPoint pep = this.get_next ().data;
		EditPoint ep = this;

		if (pep.x < ep.x) {
			
			if (pep.y < ep.y) {	
				ep.direction = PointDirection.DOWN_LEFT;
				ep.set_color (1,1,0,1); // gul 
			} else {
				ep.direction = PointDirection.UP_LEFT;
				ep.set_color (1,0,0,1); // röd
			}
			
		} else {

			if (pep.y < ep.y) {
				ep.direction = PointDirection.DOWN_RIGHT;
				ep.set_color (0,1,0,1); // grön
			} else {
				ep.direction = PointDirection.UP_RIGHT;
				ep.set_color (0,1,1,1); // ljusblå
			}
			
		}	
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
