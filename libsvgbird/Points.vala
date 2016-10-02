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

public class Points : GLib.Object {
	public Doubles point_data = new Doubles.for_capacity (100);
	public bool closed;
	public delegate bool LineIterator (double start_x, double start_y, double end_x, double end_y, double step, int point_index);
	
	public int size {
		get {
			return point_data.size;
		}
	}
	
	public void set_type (int index, uchar p) {
		point_data.set_type (index, p);
	}
	
	public void set_double (int index, double p) {
		point_data.set_double (index, p);
	}

	public void insert_type (int index, uchar t) {
		point_data.insert_type (index, t);
	}
	
	public void insert (int index, double p) {
		point_data.insert (index, p);
	}
	
	public void add (double p) {
		point_data.add (p);
	}
	
	public void add_type (uchar type) {
		point_data.add_type (type);
	}

	public int add_cubic (double handle_x, double handle_y,
		double next_handle_x, double next_handle_y,
		double x, double y) {

		return insert_cubic (size, handle_x, handle_y,
			next_handle_x, next_handle_y, x, y);
	}

	public int insert_cubic (int position, double handle_x, double handle_y,
		double next_handle_x, double next_handle_y,
		double x, double y) {
		
		int index = position;
		
		if (size == 0) {
			index = 0;
			insert_type (index, POINT_LINE);
			insert (index + 1, x);
			insert (index + 2, y);
			insert (index + 3, 0);
			insert (index + 4, 0);
			insert (index + 5, 0);
			insert (index + 6, 0);
			insert (index + 7, 0);
		}
		
		index = position;
		insert_type (index, POINT_CUBIC);
		insert (index + 1, handle_x);
		insert (index + 2, handle_y);
		insert (index + 3, next_handle_x);
		insert (index + 4, next_handle_y);
		insert (index + 5, x);
		insert (index + 6, y);
		insert (index + 7, 0);

		return index;
	}
	
	public Points copy () {
		Points p = new Points ();
		p.point_data = point_data.copy ();
		p.closed = closed;
		return p;
	}

	public double get_double (int index) {
		return point_data.get_double (index);
	}

	public uchar get_point_type (int index) {
		return point_data.get_point_type (index);
	}

	public void all (LineIterator iter) {
		double previous_x;
		double previous_y;

		PointValue* points = point_data.data;
		int size = point_data.size;
		
		return_if_fail (size % 8 == 0);
	
		SvgPath.get_start (this, out previous_x, out previous_y);

		for (int i = 8; i < size; i += 8) {
			switch (points[i].type) {
			case POINT_ARC:		
				double rx = points[i + 1].value;
				double ry = points[i + 2].value;
				double rotation = points[i + 3].value;
				double large_arc = points[i + 4].value;
				double sweep = points[i + 5].value;
				double dest_x = points[i + 6].value;
				double dest_y = points[i + 7].value;

				double angle_start, angle_extent, cx, cy;
				
				get_arc_arguments (previous_x, previous_y, rx, ry,
							rotation, large_arc > 0, sweep > 0, dest_x, dest_y,
							out angle_start, out angle_extent,
							out cx, out cy);
							
				const int steps = 50;
				for (int step = 0; step < steps; step++) {
					double angle = angle_start + step * (angle_extent / steps);
					double next_x = cx + cos (angle);
					double next_y = cy + sin (angle);
					
					iter (previous_x, previous_y, next_x, next_y, step / steps, i);
							
					previous_x = next_x;
					previous_y = next_y;
				}
				break;
			case POINT_CUBIC:
				all_lines (previous_x, previous_y,
					points[i + 1].value, points[i + 2].value,
					points[i + 3].value, points[i + 4].value,
					points[i + 5].value, points[i + 6].value,
					iter,
					i);

				previous_x = points[i + 5].value;
				previous_y = points[i + 6].value;
				break;
			case POINT_LINE:
				double x = points[i + 1].value;
				double y = points[i + 2].value;
				
				iter (previous_x, previous_y, x, y, 1, i);
				
				previous_x = x;
				previous_y = y;
				break;
			}
		}
	}
			
	private static bool all_lines (double x0, double y0, double x1, double y1, double x2, double y2, double x3, double y3,
			LineIterator iter, int index = 0, double steps = 400) {
		double px = x1;
		double py = y1;
		
		double t;
		
		double previous_x = px;
		double previous_y = py;
		
		for (int i = 0; i < steps; i++) {
			t = i / steps;
			
			px = bezier_path (t, x0, x1, x2, x3);
			py = bezier_path (t, y0, y1, y2, y3);
						
			if (!iter (previous_x, previous_y, px, py, t, index)) {
				return false;
			}
			
			previous_x = px;
			previous_y = py;
		}
		
		return true;
	}

	public static double bezier_path (double step, double p0, double p1, double p2, double p3) {
		double q0, q1, q2;
		double r0, r1;

		q0 = step * (p1 - p0) + p0;
		q1 = step * (p2 - p1) + p1;
		q2 = step * (p3 - p2) + p2;

		r0 = step * (q1 - q0) + q0;
		r1 = step * (q2 - q1) + q1;

		return step * (r1 - r0) + r0;
	}

	public static void bezier_vector (double step, double p0, double p1, double p2, double p3, out double a0, out double a1) {
		double q0, q1, q2;

		q0 = step * (p1 - p0) + p0;
		q1 = step * (p2 - p1) + p1;
		q2 = step * (p3 - p2) + p2;

		a0 = step * (q1 - q0) + q0;
		a1 = step * (q2 - q1) + q1;
	}
}

}

