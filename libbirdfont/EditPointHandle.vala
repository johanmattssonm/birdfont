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
		
public class EditPointHandle  {
		
	public double length;
	public EditPoint parent;
	public PointType type;
	EditPoint? visual_handle = null;
	static EditPoint none = new EditPoint ();
	public bool active;
	public bool selected;

	public double angle;

	public EditPointHandle.empty() {
		this.parent = none;
		this.angle = 0;
		this.length = 10;
		this.type = PointType.NONE;
		this.active = false;
		this.selected = false;
	}
	
	public EditPointHandle (EditPoint parent, double angle, double length) {
		this.parent = parent;
		this.angle = angle;
		this.length = length;
		this.type = PointType.LINE_CUBIC;
		this.active = false;
		this.selected = false;
	}

	public EditPointHandle copy () {
		EditPointHandle n = new EditPointHandle.empty ();
		n.angle = angle;
		n.length = length;
		n.parent = parent;
		n.type = type;
		n.active = active;
		n.selected = selected;
		return n;
	}

	public void convert_to_line () {
		switch (type) {
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
				break;
		}
	}

	public void set_point_type (PointType point_type) {
		type = point_type;
	}

	public double x () {
		double r = px ();
		
		if (unlikely (r <= -100000)) {
			print_position ();
			move_to (0, 0);
		}
	
		return r;
	}
	
	public double y () {
		double r = py ();
		
		if (unlikely (r <= -100000)) {
			print_position ();
			move_to (0, 0);
		}
		
		return r;
	}
	
	double px () {
		assert ((EditPoint?) parent != null);
		return cos (angle) * length + parent.x;
	}

	double py () {
		assert ((EditPoint?) parent != null);
		return sin (angle) * length + parent.y;
	}
		
	internal void print_position () {
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

	bool is_left_handle () {
		return parent.get_left_handle () == this;
	}

	public void move_to_coordinate (double x, double y) {
		move_to_coordinate_internal (x, y);
		
		if (parent.tie_handles) {
			tie_handle ();
		}
		
		if (parent.reflective_handles) {
			tie_handle ();
			process_symmetrical_handle ();
		}
		
		process_connected_handle ();
	}
		
	public void move_to_coordinate_internal (double x, double y) {
		double a, b, c;

		a = parent.x - x;
		b = parent.y - y;
		c = a * a + b * b;
		
		if (unlikely(c == 0)) {
			angle = 0; // FIXME: this should be a different point type without line handles
			length = 0;
			return;
		}
		
		length = sqrt (fabs (c));	
		
		if (c < 0) length = -length;
	
		if (y < parent.y) {
			angle = acos (a / length) + PI;
		} else {
			angle = -acos (a / length) + PI;
		}
	}
	
	public void process_connected_handle () {
		EditPointHandle h;
		
		if (unlikely (type == PointType.NONE)) {
			warning ("Invalid type.");
		}
		
		if (type == PointType.QUADRATIC) {
			if (!is_left_handle ()) {
				if (parent.next != null) {
					h = ((!)parent.next).data.get_left_handle ();
					h.type = PointType.QUADRATIC;
					h.move_to_coordinate_internal (px (), py ());
					h.parent.set_tie_handle (false);
				}
			} else {
				if (parent.prev != null) {
					h = ((!)parent.prev).data.get_right_handle ();
					h.type = PointType.QUADRATIC;
					h.move_to_coordinate_internal (px (), py ());
					h.parent.set_tie_handle (false);
				}
			}
		}
	}

	public void process_symmetrical_handle () {
		if (is_left_handle ()) {
			parent.get_right_handle ().length = length;
			parent.get_right_handle ().process_connected_handle ();
		} else {
			parent.get_left_handle ().length = length;
			parent.get_left_handle ().process_connected_handle ();
		}
		
		process_connected_handle ();
	}

	public void tie_handle () {
		if (is_left_handle ()) {
			parent.get_right_handle ().angle = angle - PI;
			parent.get_right_handle ().process_connected_handle ();
		} else {
			parent.get_left_handle ().angle = angle - PI;
			parent.get_left_handle ().process_connected_handle ();
		}
		
		process_connected_handle ();
	}
	
	public void move_delta (double dx, double dy) {
		double px = px () + dx * Glyph.ivz ();
		double py = py () - dy * Glyph.ivz ();
		move_to_coordinate (px, py);
	}
	
	public void move_to (double x, double y) {
		EditPoint.to_coordinate (ref x, ref y);
		move_to_coordinate (x, y);
	}
}

}
