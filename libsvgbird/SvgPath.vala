/*
	Copyright (C) 2016 Johan Mattsson

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

namespace SvgBird {

public class SvgPath : Object {	
	public Gee.ArrayList<Points> points = new Gee.ArrayList<Points> ();
	
	public SvgPath () {
	}

	public SvgPath.create_copy (SvgPath p) {
		Object.copy_attributes (p, this);
		
		foreach (Points point_data in p.points) {
			points.add (point_data.copy ());
		}
	}
	
	public override bool is_over (double x, double y) {
		return false;
	}
			
	public override void draw_outline (Context cr) {
		foreach (Points p in points) {
			cr.move_to (p.x, p.y);
			draw_points (cr, p);
			
			if (p.closed) {
				cr.close_path ();
			}
		}
	}

	public void draw_points (Context cr, Points path) {
		PointValue* points = path.point_data.data;
		int size = path.point_data.size;
		
		// points are padded up to 8 units
		return_if_fail (size % 8 == 0);
		
		for (int i = 0; i < size; i += 8) {
			switch (points[i].type) {
			case POINT_ARC:		
				draw_arc (cr, points[i + 1].value, points[i + 2].value,
					points[i + 3].value, points[i + 4].value,
					points[i + 5].value, points[i + 6].value,
					points[i + 7].value);
				break;
			case POINT_CUBIC:
				cr.curve_to (points[i + 1].value, points[i + 2].value, 
					points[i + 3].value, points[i + 4].value,
					points[i + 5].value, points[i + 6].value);
				break;
			case POINT_LINE:
				cr.line_to (points[i + 1].value, points[i + 2].value);
				break;
			}
		}		
	}

	static void draw_arc (Context cr,
		double x, double y,
		double rx, double ry,
		double angle_start, double angle_extent,
		double rotation) {
			
		cr.save ();
		cr.translate (x, y);
		cr.rotate (rotation);
		cr.scale (rx, ry);

		if (angle_extent > 0) {
			cr.arc_negative (0, 0, 1, -angle_start, -angle_start - angle_extent);
		} else {
			cr.arc (0, 0, 1, -angle_start, -angle_start - angle_extent);
		}
				
		cr.restore ();
	}

	public override void move (double dx, double dy) {
	}

	public override bool is_empty () {
		return false;
	}
	
	public override Object copy () {
		return new SvgPath.create_copy (this);
	}

	public override string to_string () {
		return "SvgPath";
	}
}

}
