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

public class StrokeTool : Tool {
	
	public StrokeTool (string tool_tip) {
		select_action.connect((self) => {
			stroke_selected_paths ();
		});
	}
	
	public static void set_stroke_for_selected_paths (double width) {
		Glyph g = MainWindow.get_current_glyph ();
			
		foreach (Path p in g.active_paths) {
			p.set_stroke (width);
		}
		
		GlyphCanvas.redraw ();
	}

	/** Create strokes for the selected outlines. */
	void stroke_selected_paths () {
		Glyph g = MainWindow.get_current_glyph ();
		List<Path> paths = new List<Path> ();
		
		foreach (Path p in g.active_paths) {
			paths.append (get_stroke (p, p.stroke));
			paths.append (get_stroke (p, -1 * p.stroke));
		}
		
		foreach (Path np in paths) {
			g.add_path (np);
		}
	}
	
	public static Path get_stroke (Path p, double thickness) {
		Path new_path;
		Path stroked;

		new_path = add_tangent_points (p);
		stroked = change_stroke_width (new_path, thickness);
		
		stroked.reverse ();
		return stroked;
	}

	static Path add_tangent_points (Path p) {
		Path new_path = new Path ();
		int steps = 3;
		
		p.create_list ();
		p.all_vectors ((start, stop, px, py, handle_x0, handle_x1, handle_y0, handle_y1, position) => {
			EditPoint ep;
			PointType right, left;
			
			ep = new EditPoint (px, py);
			
			right = start.get_right_handle ().type;
			left = stop.get_right_handle ().type;
			
			if (right == PointType.LINE_QUADRATIC && left == PointType.LINE_QUADRATIC) {
				ep.get_right_handle ().set_point_type (PointType.LINE_QUADRATIC);
				ep.get_left_handle ().set_point_type (PointType.LINE_QUADRATIC);
				ep.type = PointType.QUADRATIC;
			} else if (right == PointType.LINE_CUBIC && left == PointType.LINE_CUBIC) {
				ep.get_right_handle ().set_point_type (PointType.LINE_CUBIC);
				ep.get_left_handle ().set_point_type (PointType.LINE_CUBIC);
				ep.type = PointType.LINE_CUBIC;
			} else if (right == PointType.LINE_DOUBLE_CURVE && left == PointType.LINE_DOUBLE_CURVE) {
				ep.get_right_handle ().set_point_type (PointType.LINE_DOUBLE_CURVE);
				ep.get_left_handle ().set_point_type (PointType.LINE_DOUBLE_CURVE);
				ep.type = PointType.DOUBLE_CURVE;
				
				if (position == 0) {
					ep.left_handle = start.left_handle.copy ();
					ep.right_handle = start.right_handle.copy ();
				
					ep.get_left_handle ().length *= 0.833;
					ep.get_right_handle ().length *= 0.833;

				} else {
					ep.get_left_handle ().set_point_type (PointType.CUBIC);
					ep.get_right_handle ().set_point_type (PointType.CUBIC);
						
					ep.get_left_handle ().parent = ep;
					ep.get_right_handle ().parent = ep;
					
					ep.get_left_handle ().move_to_coordinate (handle_x0, handle_y0);
					ep.get_right_handle ().move_to_coordinate (handle_x1, handle_y1);
				}
				
			} else if (right == PointType.DOUBLE_CURVE || left == PointType.DOUBLE_CURVE) {
				ep.get_left_handle ().move_to_coordinate (handle_x1, handle_y1);
				ep.get_right_handle ().move_to_coordinate (handle_x0, handle_y0);

				ep.get_left_handle ().set_point_type (PointType.DOUBLE_CURVE);	
				ep.get_right_handle ().set_point_type (PointType.DOUBLE_CURVE);
				
				ep.type = PointType.DOUBLE_CURVE;
			} else if (right == PointType.QUADRATIC) {		
				ep.get_right_handle ().move_to_coordinate (handle_x0, handle_y0);
				
				ep.get_left_handle ().set_point_type (PointType.QUADRATIC);	
				ep.get_right_handle ().set_point_type (PointType.QUADRATIC);
				
				ep.get_left_handle ().move_to_coordinate_internal (0, 0);
				
				ep.type = PointType.QUADRATIC;				
			} else {
				
				if (position == 0) {
					ep.left_handle = start.left_handle.copy ();
					ep.right_handle = start.right_handle.copy ();
				
					ep.get_left_handle ().length *= 0.833;
					ep.get_right_handle ().length *= 0.833;

				} else {
					ep.get_left_handle ().set_point_type (PointType.CUBIC);
					ep.get_right_handle ().set_point_type (PointType.CUBIC);
						
					ep.get_left_handle ().parent = ep;
					ep.get_right_handle ().parent = ep;
					
					ep.get_left_handle ().move_to_coordinate (handle_x0, handle_y0);
					ep.get_right_handle ().move_to_coordinate (handle_x1, handle_y1);
				}

				ep.type = PointType.LINE_CUBIC;
			}
			ep.get_left_handle ().parent = ep;
			ep.get_right_handle ().parent = ep;
			
			new_path.add_point (ep);
			
			return true;
		}, steps);
		
		new_path.create_list ();
		
		foreach (EditPoint e in new_path.points) {			
			e.get_left_handle ().length /= 2;	
			e.get_right_handle ().length /= 2;
		}
		
		return new_path;
	}

	/** Shrink or expand the outline. */
	static Path change_stroke_width (Path new_path, double thickness) {
		double nx, ny;	
		double stroke_thickness;
		double space_left, space_right;
		Path stroked = new Path ();		
		EditPoint ep, corner1, corner2, corner3, swap_corner;
		bool clockwise;
		bool end_point; // first and last point
		uint k;
		uint npoints;

		double middle_x, middle_y;
		double corner_thickness_left, corner_thickness_right;
		double middle_point_position;
								
		clockwise = new_path.is_clockwise ();
		
		end_point = true;
		k = 0;
		npoints = new_path.points.length ();
		
		foreach (EditPoint e in new_path.points) {	
			ep = e.copy ();
			
			get_new_position (e, clockwise, thickness, out nx, out ny);

			end_point = (k == 0 || k == npoints - 1);
			k++;

			ep.x = nx;
			ep.y = ny;

			if (e.is_corner ()) {
				// add new points in order to preserve the stroke
				corner1 = e.copy ();
				stroked.add_point (corner1);
				
				corner2 = e.copy ();
				stroked.get_closest_point_on_path (corner2, nx, ny);

				if (end_point) {
					swap_corner = corner1;
					corner1 = corner2;
					corner2 = swap_corner;
				}

				if (end_point) {
					stroked.insert_new_point_on_path (corner1);
				} else {
					stroked.insert_new_point_on_path (corner2);
				}
				
			
				corner1.x += cos (e.get_right_handle ().angle + PI / 2) * 2 * thickness;
				corner1.y += sin (e.get_right_handle ().angle + PI / 2) * 2 * thickness;

				corner2.x += cos (e.get_left_handle ().angle - PI / 2) * 2 * thickness;
				corner2.y += sin (e.get_left_handle ().angle - PI / 2) * 2 * thickness;

				// fill the gap

				corner3 = e.copy ();
				middle_x = corner1.x + (corner2.x - corner1.x) / 2;
				middle_y = corner1.y + (corner2.y - corner1.y) / 2;
				stroked.get_closest_point_on_path (corner3, middle_x, middle_y);
				stroked.insert_new_point_on_path (corner3);
				
				corner_thickness_right = thickness * ((e.get_right_handle ().angle - PI) / (2 * PI));
				corner_thickness_left = thickness * ((e.get_left_handle ().angle) / (2 * PI));

				middle_point_position = 2 * thickness;
				middle_point_position *= 1 / sin (e.get_corner_angle ());
				
				corner3.x = e.x;
				corner3.y = e.y;
				
				corner3.x += middle_point_position * cos (e.get_right_handle ().angle - PI);
				corner3.y += middle_point_position * sin (e.get_right_handle ().angle - PI);

				corner3.x += middle_point_position * cos (e.get_left_handle ().angle - PI);
				corner3.y += middle_point_position * sin (e.get_left_handle ().angle - PI);
			
			} else {
				stroke_thickness = fabs (thickness) * 0.04; // FIXME: 0.04

				space_left = get_space_difference (e, e.get_prev ().data, thickness, clockwise);
				space_right = get_space_difference (e, e.get_next ().data, thickness, clockwise);

				ep.get_left_handle ().length += space_left / 3;
				ep.get_right_handle ().length += space_right / 3;
				
				stroked.add_point (ep);
			}
		}
	
		foreach (EditPoint e in stroked.points) {
			e.recalculate_linear_handles ();
		}
	
		return stroked;
	}

	public static void get_new_position (EditPoint e, bool clockwise, double thickness, out double strokex, out double strokey) {
		double sx, sy;
		get_new_position_delta (e, clockwise, thickness, out sx, out sy);
		strokex = sx + e.x;
		strokey = sy + e.y;	
	}

	public static void get_new_position_delta (EditPoint e, bool clockwise, double thickness, out double strokex, out double strokey) {
			double ra, la;
			double len_tot;
			double len_r, len_l;
			
			double avg_angle;
			double angle;
			
			double m, n, o, p;
			double ldnx, ldny;
						
			e.recalculate_linear_handles ();
			
			ra = e.get_right_handle ().angle;
			la = e.get_left_handle ().angle;
			
			len_r = e.get_right_handle ().length;
			len_l = e.get_left_handle ().length;
			
			len_tot = len_r + len_l;
			
			avg_angle = (la + ra + PI) / 2.0;

			while (avg_angle > 2 * PI) {
				avg_angle -= 2 * PI;
			}
									
			angle = avg_angle - PI / 2;
			
			m = cos (ra + PI / 2) * thickness;
			n = sin (ra + PI / 2) * thickness;
			
			o = cos (la - PI / 2) * thickness;
			p = sin (la - PI / 2) * thickness;

			ldnx = m + o;
			ldny = n + p;
			
			strokex = ldnx;
			strokey = ldny;
	}
	
	static double get_space_difference (EditPoint ep0, EditPoint ep1, double stroke, bool clockwise) {
		double p0x, p0y, p1x, p1y;
		double d1, d2;
		
		get_new_position (ep0, clockwise, stroke, out p0x, out p0y);
		get_new_position (ep1, clockwise, stroke, out p1x, out p1y);
		
		d1 = Path.distance (ep0.x, ep1.x, ep0.y, ep1.y);
		d2 = Path.distance (p0x, p1x, p0y, p1y);
		
		return d2 - d1;
	}

	public static double length_adjustment (double lx, double ldx, double ly, double ldy, double l) {
		double a = sqrt (pow (ldx, 2) + pow (ldy, 2)) / fabs (l);	
		return a;
	}
}

}
