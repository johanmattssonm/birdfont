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
using Math;

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

	public override bool is_over (double point_x, double point_y) {
		bool inside = false;
		
		if (is_over_boundaries (point_x, point_y)) {
			to_object_view (ref point_x, ref point_y);
			
			foreach (Points p in points) {
				if (is_over_points (p, point_x, point_y)) {
					inside = !inside;
				}
			}
		}
		
		return inside;
	}
	
	public static bool is_over_points (Points p, double point_x, double point_y) {
		bool inside = false;
	
		p.all ((start_x, start_y, end_x, end_y) => {
			is_inside (ref inside, point_x, point_y, start_x, start_y, end_x, end_y);
			return true;
		});

		return inside;
	}

	static void is_inside (ref bool inside, double point_x, double point_y, 
		double prev_x, double prev_y, double next_x, double next_y) {
		if  ((next_y > point_y) != (prev_y > point_y) 
			&& point_x < (prev_x - next_x) * (point_y - next_y) / (prev_y - next_y) + next_x) {
			inside = !inside;
		}
	}
	
	public override void draw_outline (Context cr) {
		foreach (Points p in points) {
			double x, y;
			
			get_start (p, out x, out y);
			cr.move_to (x, y);
			
			draw_points (cr, p);
			
			if (p.closed) {
				cr.close_path ();
			}
		}
	}

	public static void get_start (Points path, out double x, out double y) {
		int size = path.point_data.size;
		
		x = 0;
		y = 0;
		
		// points are padded up to 8 units
		return_if_fail (size % 8 == 0);
		return_if_fail (size >= 8);
		
		switch (path.get_point_type (0) & POINT_TYPE) {
		case POINT_ARC:
			x = path.get_double (6);
			y = path.get_double (7);
			break;
		case POINT_CUBIC:
			x = path.get_double (5);
			y = path.get_double (6);
			break;
		case POINT_LINE:
			x = path.get_double (1);
			y = path.get_double (2);
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
			switch (points[i].type & POINT_TYPE) {
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
