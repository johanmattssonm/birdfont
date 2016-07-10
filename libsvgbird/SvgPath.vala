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
	
	double pen_position_x = 0;
	double pen_position_y = 0;
	
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
			move_to_start (cr, p);
			draw_points (cr, p);
			
			if (p.closed) {
				cr.close_path ();
			}
		}
	}

	public void move_to_start (Context cr, Points path) {
		int size = path.point_data.size;
		
		// points are padded up to 8 units
		return_if_fail (size % 8 == 0);
		return_if_fail (size >= 8);
		
		switch (path.get_point_type (0)) {
		case POINT_ARC:		
			cr.move_to (path.get_double (6), path.get_double (7));
			break;
		case POINT_CUBIC:
			cr.move_to (path.get_double (5), path.get_double (6));
			break;
		case POINT_LINE:
			cr.move_to (path.get_double (1), path.get_double (2));
			break;
		default:
			warning (@"Unknown type $(path.get_point_type (0))");
			break;
		}
	}

	public void draw_points (Context cr, Points path) {
		PointValue* points = path.point_data.data;
		int size = path.point_data.size;
		
		return_if_fail (size % 8 == 0);
	
		for (int i = 0; i < size; i += 8) {
			switch (points[i].type) {
			case POINT_ARC:		
				draw_arc (cr, points[i + 1].value, points[i + 2].value,
					points[i + 3].value, points[i + 4].value,
					points[i + 5].value, points[i + 6].value,
					points[i + 7].value);
					
				pen_position_x = points[i + 6].value;
				pen_position_y = points[i + 7].value;
				break;
			case POINT_CUBIC:
				cr.curve_to (points[i + 1].value, points[i + 2].value, 
					points[i + 3].value, points[i + 4].value,
					points[i + 5].value, points[i + 6].value);
				
				pen_position_x = points[i + 5].value;
				pen_position_y = points[i + 6].value;
				break;
			case POINT_LINE:
				cr.line_to (points[i + 1].value, points[i + 2].value);
				pen_position_x = points[i + 1].value;
				pen_position_y = points[i + 2].value;
				break;
			}
		}		
	}
				
	void draw_arc (Context cr,
		double rx, double ry, double rotation,
		double large_arc, double sweep,
		double x, double y) {

		double angle_start, angle_extent, cx, cy;
		
		get_arc_arguments (pen_position_x, pen_position_y, rx, ry,
					rotation, large_arc > 0, sweep > 0, x, y,
					out angle_start, out angle_extent,
					out cx, out cy);

		cr.save ();

		cr.translate (cx, cy);
		cr.rotate (rotation);
		cr.scale (rx, ry);
		
		double start_x = Math.cos (angle_start);
		double start_y = Math.sin (angle_start);
		cr.move_to (start_x, start_y);
		
		angle_start %= 2 * Math.PI;
		angle_extent %= 2 * Math.PI;
		
		if (angle_extent.is_normal () && angle_extent.is_normal ()) {
			if (angle_extent > 0) {
				cr.arc_negative (0, 0, 1, -angle_start, -angle_start - angle_extent);
			} else {
				cr.arc (0, 0, 1, -angle_start, -angle_start - angle_extent);
			}
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
