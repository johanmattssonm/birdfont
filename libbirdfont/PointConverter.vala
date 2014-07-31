/*
    Copyright (C) 2014 Johan Mattsson

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

namespace BirdFont {

/** A class for converting control points. */
public class PointConverter {

	Path original_path;
	Path quadratic_path;

	public PointConverter (Path path) {	
		original_path = path;
	}

	public Path get_quadratic_path () {
		int i;
		bool add_more_points = false;
		quadratic_path = original_path.copy ();
		
		estimated_cubic_path ();
		
		if (add_more_points) {
			warning ("Too many points in segment.");
		}
	
		quadratic_path.remove_points_on_points ();

		if (quadratic_path.points.size < 2) {
			return new Path ();
		}

		foreach (EditPoint e in quadratic_path.points) {
			if (e.get_right_handle ().type == PointType.CUBIC) {
				PenTool.convert_point_type (e, PointType.DOUBLE_CURVE);
			}
		}
	
		quadratic_path.add_hidden_double_points ();
					
		return quadratic_path;
	}

	public void estimated_cubic_path () {
		EditPoint segment_start;
		EditPoint segment_stop;
		EditPoint quadratic_segment_start;
		EditPoint quadratic_segment_stop;
		EditPoint e;
		double distance, step;
		int points_in_segment = 0;
		int size;

		if (quadratic_path.points.size <= 1) {
		}

		foreach (EditPoint ep in quadratic_path.points) {
			ep.set_tie_handle (false);
			ep.set_reflective_handles (false);
		}

		size = quadratic_path.points.size;
		segment_start = quadratic_path.get_first_point ();
		for (int i = 0; i < size; i++) {
			segment_stop = (i == size -1) 
				? quadratic_path.get_first_point () 
				: segment_start.get_next ();

			quadratic_segment_start = segment_start.copy ();
			quadratic_segment_stop = segment_stop.copy ();
			
			PenTool.convert_point_segment_type (quadratic_segment_start, quadratic_segment_stop, PointType.DOUBLE_CURVE);
			
			distance = 0;
			e = new EditPoint ();
			if (segment_start.get_right_handle ().is_line () 
					&& segment_stop.get_left_handle ().is_line ()) {
				// skipping line
			} else if (points_in_segment >= 10) {
				warning ("Too many points.");
			} else {
				find_largest_distance (segment_start, segment_stop, 
						quadratic_segment_start, quadratic_segment_stop, 
						out distance, out e, out step);
			}
			
			if (distance > 0.2) { //  range 0.1 - 0.4,
				quadratic_path.insert_new_point_on_path (e);
				points_in_segment++;
				size += 2; // the new point + segment start
			} else {
				points_in_segment = 0;
				segment_start = segment_stop;
			}
		}				
	}

	// TODO: Optimize
	public static void find_largest_distance (EditPoint a0, EditPoint a1, EditPoint b0, EditPoint b1, 
			out double distance, out EditPoint new_point, out double step) {
		double max_d;
		double min_d;
		int steps = (int) (1.6 * Path.get_length_from (a0, a1));
		double x_out, y_out;
		double step_out;
		double step_min;

		x_out = 0;
		y_out = 0;
		step_out = 0;
		
		distance = 0;

		new_point = new EditPoint ();
		new_point.prev = a0;
		new_point.next = a1;
		new_point.get_right_handle ().type = PointType.CUBIC;
		new_point.get_left_handle ().type = PointType.CUBIC;
		
		steps = 20; // FIXME: adjust to length
		
		if (a0.get_right_handle ().type == PointType.QUADRATIC 
				|| a1.get_left_handle ().type == PointType.QUADRATIC
				|| a0.get_right_handle ().type == PointType.LINE_QUADRATIC 
				|| a1.get_left_handle ().type == PointType.LINE_QUADRATIC) {
			return;		
		} 
		
		max_d = double.MIN;
		min_d = double.MAX;
		Path.all_of (a0, a1, (xa, ya, ta) => {
			
			min_d = double.MAX;
			Path.all_of (b0, b1, (xb, yb, tb) => {
				double d = Path.distance (xa, xb, ya, yb);
				
				if (d < min_d) {
					min_d = d;
				}
				
				return true;
			}, steps);
					
			if (min_d > max_d) {
				max_d = min_d;
				x_out = xa;
				y_out = ya;
				step_out = ta;
			}
			
			return true;
		}, steps);

		distance = max_d;
		new_point.x = x_out;
		new_point.y = y_out;
		step = step_out;
	}
}

}
