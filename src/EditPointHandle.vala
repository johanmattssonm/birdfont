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
		
class EditPointHandle  {
	
	public double angle;
	public double length;
	
	public EditPoint parent;
	
	public PointType type;
	
	EditPoint? visual_handle = null;

	static EditPoint none = new EditPoint ();

	public bool active;

	public EditPointHandle.empty() {
		this.parent = none;
		this.angle = 0;
		this.length = 10;
		this.type = PointType.LINE;
		this.active = false;
	}
	
	public EditPointHandle (EditPoint parent, double angle, double length) {
		this.parent = parent;
		this.angle = angle;
		this.length = length;
		this.type = PointType.LINE;
		this.active = false;
	}

	public void set_point_type (PointType point_type) {
		type = point_type;
	}

	public double x () {
		double r = px ();
		
		if (unlikely (r <= -100000)) {
			print_position ();
		}
	
		return r;
	}
	
	public double y () {
		double r = py ();
		
		if (unlikely (r <= -100000)) {
			print_position ();
		}
		
		return r;
	}
	
	double px () {
		return cos (angle) * length + parent.x;
	}

	double py () {
		return sin (angle) * length + parent.y;
	}
		
	void print_position () {
			warning (@"\nEdit point handle at position $(px ()),$(py ()) is not valid.\n"
				+ @"Type: $(parent.type), "
				+ @"Index: $(parent.get_index ()) of $(parent.get_list ().length ())\n"
				+ @"Angle: $angle, Length: $length.");	
	}
	
	public EditPoint get_point () {
		EditPoint p;
		
		if (visual_handle == null) {
			visual_handle = new EditPoint (0, 0);
		}
	
		p = (!) visual_handle;
		p.x = x ();
		p.y = y ();
		
		return p;
	}
	
	public void move_to_coordinate (double x, double y) {
		double a, b, c;

		a = parent.x - x;
		b = parent.y - y;
		c = a * a + b * b;
		
		if (c == 0) {
			return;
		}
		
		length = sqrt (fabs (c));	
		
		if (c < 0) length = -length;
	
		if (y < parent.y) {
			angle = acos (a / length) + PI;
		} else {
			angle = -acos (a / length) + PI;
		}
		
		if (parent.tie_handles) {
			tie_handle ();
		}
	}

	private void tie_handle () {
		if (this == parent.get_left_handle ()) {
			parent.get_right_handle ().angle = angle - PI;
		} else {
			parent.get_left_handle ().angle = angle - PI;
		}
	}
	
	public void move_to (double x, double y) {
		EditPoint.to_coordinate (ref x, ref y);
		move_to_coordinate (x, y);
	}
}

}
