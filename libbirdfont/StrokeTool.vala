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
		PathList paths = new PathList ();
		
		foreach (Path p in g.active_paths) {
			paths.append (get_stroke (p, p.stroke));
			paths.add (add_tangent_points (p));
		}
		
		foreach (Path np in paths.paths) {
			g.add_path (np);
		}
	}
	
	public static PathList get_stroke (Path p, double thickness) {
		Path counter, outline, merged;
		PathList paths = new PathList ();
		
		if (!p.is_open () && p.is_filled ()) {
			outline = create_stroke (p, thickness);
			outline.close ();
			paths.add (outline);
		} else if (!p.is_open () && !p.is_filled ()) {
			
			outline = create_stroke (p, thickness);
			counter = create_stroke (p, -1 * thickness);
			
			paths.add (outline);
			paths.add (counter);
			
			if (p.is_clockwise ()) {
				outline.force_direction (Direction.CLOCKWISE);
			} else {
				outline.force_direction (Direction.COUNTER_CLOCKWISE);
			}
			
			if (outline.is_clockwise ()) {
				counter.force_direction (Direction.COUNTER_CLOCKWISE);
			} else {
				counter.force_direction (Direction.CLOCKWISE);
			}
			
		} else if (p.is_open ()) {
			outline = create_stroke (p, thickness);
			counter = create_stroke (p, -1 * thickness);
			merged = merge_strokes (p, outline, counter, thickness);
			
			if (p.is_clockwise ()) {
				merged.force_direction (Direction.CLOCKWISE);
			} else {
				merged.force_direction (Direction.COUNTER_CLOCKWISE);
			}
			
			paths.add (merged);
		} else {
			warning ("Can not create stroke.");
			paths.add (p);
		}

		return paths;
	}
	
	/** Create one stroke from the outline and counter stroke and close the 
	 * open endings.
	 * 
	 * @param path the path to create stroke for
	 * @param stroke for the outline of path
	 * @param stroke for the counter path
	 */
	static Path merge_strokes (Path path, Path stroke, Path counter, double thickness) {
		Path merged;
		EditPoint corner1, corner2;
		EditPoint corner3, corner4;
		EditPoint end;
		double angle;
		
		if (path.points.length () < 2) {
			warning ("Missing points.");
			return stroke;
		}
		
		if (stroke.points.length () < 4) {
			warning ("Missing points.");
			return stroke;
		}

		if (counter.points.length () < 4) {
			warning ("Missing points.");
			return stroke;
		}
		
		// end of stroke
		end = path.get_last_point ();
		corner1 = stroke.get_last_point ();
		angle = end.get_left_handle ().angle;
		corner1.x = end.x + cos (angle - PI / 2) * 2 * thickness;
		corner1.y = end.y + sin (angle - PI / 2) * 2 * thickness;		

		corner2 = counter.get_last_point ();
		corner2.x = end.x + cos (angle + PI / 2) * 2 * thickness;
		corner2.y = end.y + sin (angle + PI / 2) * 2 * thickness;

		// the other end
		end = path.get_first_point ();
		corner3 = stroke.get_first_point ();
		angle = end.get_right_handle ().angle;
		corner3.x = end.x + cos (angle + PI / 2) * 2 * thickness;
		corner3.y = end.y + sin (angle + PI / 2) * 2 * thickness;		

		corner4 = counter.get_first_point ();
		corner4.x = end.x + cos (angle - PI / 2) * 2 * thickness;
		corner4.y = end.y + sin (angle - PI / 2) * 2 * thickness;
		
		corner1.get_right_handle ().convert_to_line ();
		corner2.get_left_handle ().convert_to_line ();
		corner3.get_right_handle ().convert_to_line ();
		corner4.get_left_handle ().convert_to_line ();
				
		counter.reverse ();

		// Append the other part of the stroke
		merged = stroke.copy ();
		merged.append_path (counter);
		corner2 = merged.points.last ().data;
		
		merged.close ();
		merged.create_list ();
		merged.recalculate_linear_handles ();
								
		return merged;
	}
	
	static Path create_stroke (Path p, double thickness) {
		Path new_path;
		Path stroked;
		
		new_path = add_tangent_points (p);
		
		if (new_path.points.length () >= 2) {
			stroked = change_stroke_width (new_path, thickness);
			
			if (!p.is_open ()) {
				stroked.reverse ();
				stroked.close ();
			}
		} else {
			// TODO: create stroke for path with one point
			warning ("One point.");
			stroked = new Path ();
		}
		
		return stroked;
	}

	static bool has_double_points (Path p) {
		foreach (EditPoint ep in p.points) {
			if (ep.type == PointType.DOUBLE_CURVE) {
				return true;
			}
		}
		return false;
	}

	static Path add_tangent_points (Path p) {
		Path path;
		int steps = 2;
		List<EditPoint> new_points = new List<EditPoint> ();
		
		EditPoint nep;
		EditPoint? previous = null;
		
		path = (has_double_points (p)) ? 
			p.get_quadratic_points () : p.copy ();
		
		path.all_segments ((start, stop) => {
			EditPoint? prev = null;
			double length = Path.get_length_from (start, stop);
			
			steps = (int) (length / 10);

			if (start.type == PointType.DOUBLE_CURVE || stop.type == PointType.DOUBLE_CURVE) {
				warning ("Invalid point type.");
			}
			
			if (steps > 1) {
				Path.all_of (start, stop, (x, y, step) => {
					EditPoint ep = new EditPoint ();

					if (0 < step < 1) {
						ep.set_position (x, y);
						
						// Stop processing when the first hidden point is found.
					/*	if (start.type == PointType.HIDDEN || stop.type == PointType.HIDDEN) {
							// FIXME: Rename tracker points 
							return true;
						}
					*/
						
						return_val_if_fail (prev != null, false);

						ep.prev = ((!) prev).get_link_item ();
						ep.next = start.get_next ();
						
						ep.type = PenTool.to_curve (start.type);
						
						if (unlikely (ep.next == null || ep.prev == null)) {
							warning ("No points on segment.");
							return false;
						}

						new_points.append (ep);
					}
					
					if (step <= 0) {
						prev = start;
						new_points.append (start);
					} else if (step >= 1) {
						prev = stop;
						new_points.append (stop);
					} else {
						prev = ep;
					}
					
					return true;
				}, steps);				
			}
			
			return true;
		});
	
		while (new_points.length () > 0) {
			nep = new_points.first ().data;
			
			if (previous != null) {
				nep.prev = ((!) previous).get_link_item ();
			}
			
			if (!path.has_point (nep)) {
				return_if_fail (nep.prev != null);				
				path.insert_new_point_on_path (nep);
			}
			
			previous = nep;

			new_points.remove_link (new_points.first ());
			path.create_list ();
		}
		
		path.create_list ();
		
		return path;
	}

	/** Shrink or expand the outline. */
	static Path change_stroke_width (Path new_path, double thickness) {
		double px, py, nx, ny, dnx, dny, counter_dnx, counter_dny;	
		double space_left, space_right;
		Path stroked = new Path ();		
		EditPoint ep;
		bool clockwise;
		bool end_point; // first and last point
		uint k;
		uint npoints;
		double distance_to_counter, distance_to_path;
		PointSelection ps;
		double handle_x, handle_y;
		EditPointHandle h1, h2;
				
		clockwise = new_path.is_clockwise ();
		
		end_point = true;
		k = 0;
		npoints = new_path.points.length ();
		
		if (npoints < 2) {
			warning ("npoints < 2");
			return new_path;
		}
		
		foreach (EditPoint e in new_path.points) {
			ep = e.copy ();
			
			ps = new PointSelection (e, new_path);
			get_new_position_delta (ps, clockwise, thickness, out dnx, out dny);
			get_new_position_delta (ps, clockwise, thickness, out counter_dnx, out counter_dny);
				
			end_point = (k == 0 || k == npoints - 1);
			k++;
			
			px = ep.x;
			py = ep.y;
			
			if (!end_point) {
				ep.x += dnx;
				ep.y += dny;
			}
			
			if (ep.type == PointType.HIDDEN) {
				break;
			}
			
			nx = ep.x;
			ny = ep.y;
			
			space_left = get_space_difference (new_path, e, e.get_prev ().data, thickness, clockwise);
			space_right = get_space_difference (new_path, e, e.get_next ().data, thickness, clockwise);
		
			distance_to_counter = Path.distance (nx, px + counter_dnx, ny, py + counter_dny);
			distance_to_path = Path.distance (px, nx, py, ny);
			
			if (new_path.is_open () && end_point) {
				// open end point
				stroked.add (e.x, e.y);
			} else {
				if (distance_to_path >= fabs (2 * thickness) - 0.1) {
					// smooth curve
					ep.get_left_handle ().length += space_left / 3; 
					ep.get_right_handle ().length += space_right / 3;
					stroked.add_point (ep);
				} else if (distance_to_path < fabs (2 * thickness) && (space_left + space_right) > 0) {
					// sharp corner
					add_corner_nodes (new_path, stroked, e, clockwise, thickness, end_point, nx, ny);
				} else if (distance_to_path < fabs (2 * thickness) && (space_left + space_right) < 0) {
					if (!new_path.is_open () || (new_path.is_open () && !ps.is_endpoint ())) {
						// wide corner
						corner_position (e, clockwise, thickness, stroked);
					}
				} else {
					ep.get_left_handle ().length += space_left / 3; 
					ep.get_right_handle ().length += space_right / 3;
					stroked.add_point (ep);

					warning ("Stroke might become distorted");
				}
			}
		}
		
		// FIXME. remove?
		stroked.get_first_point ().set_point_type (stroked.get_first_point ().get_next ().data.type);
		stroked.get_last_point ().set_point_type (stroked.get_last_point ().get_prev ().data.type);
		
		stroked.create_list ();
		foreach (EditPoint e in stroked.points) {
			e.recalculate_linear_handles ();
		}
		
		foreach (EditPoint e in stroked.points) {
			if (e.type == PointType.QUADRATIC && e.next != null) {
				h1 = e.get_right_handle ();
				h2 = e.get_next ().data.get_left_handle ();
				Path.find_intersection_handle (h1, h2, out handle_x, out handle_y);
				// FIXME:
				//h1.move_to_coordinate_internal (handle_x, handle_y);						
				//h2.move_to_coordinate_internal (handle_x, handle_y);
			}
		}
			
		return stroked;
	}
		
	/** Add a corner node for sharp corners. */
	static void corner_position (EditPoint ep, bool clockwise, double thickness, Path p) {
		EditPoint corner = ep.copy ();
		double x1, x3;
		double y1, y3;
		double lx1, lx2, lx3, lx4;
		double ly1, ly2, ly3, ly4;
		double k1, k2;
		double n1, n2;
		double posx, posy;
		EditPointHandle h1, h2;

		h1 = ep.get_right_handle ();
		h2 = ep.get_left_handle ();
		
		x1 = ep.x + cos (h1.angle + PI / 2) * 2 * thickness;
		y1 = ep.y + sin (h1.angle + PI / 2) * 2 * thickness;

		x3 = ep.x + cos (h2.angle - PI / 2) * 2 * thickness;
		y3 = ep.y + sin (h2.angle - PI / 2) * 2 * thickness;

		k1 = sin (h1.angle) / cos (h1.angle);
		n1 = y1;

		k2 = sin (h2.angle) / cos (h2.angle);
		n2 = y3;
		
		lx1 = -50 + x1;
		ly1 = k1 * -50 + n1;
		lx2 = 100 + x1;
		ly2 = k1 * 100 + n1;
		lx3 = -50 + x3;
		ly3 = k2 * -50 + n2;
		lx4 = 100 + x3;
		ly4 = k2 * 100 + n2;

		Path.find_intersection (lx1, ly1, lx2, ly2, lx3, ly3, lx4, ly4, out posx, out posy);
		
		corner.x = posx;
		corner.y = posy;

		if (Path.distance (ep.x, posx, ep.y, posy) > fabs (10 * thickness)) {
			add_corner_end (ep, p, x3, y3);
		} else {
			p.add_point (corner);
		}
	}

	// TODO: elaborated stroke endings
	static void add_corner_end (EditPoint e, Path path, double next_x, double next_y) {
		EditPoint ep;
		double px = e.x + (e.x - next_x) / 2;
		double py = e.y + (e.y - next_y) / 2;
		ep = path.add (px, py);
		ep.set_point_type (ep.get_prev ().data.type);
		ep.get_right_handle ().convert_to_line ();
		ep.get_left_handle ().convert_to_line ();
		ep.recalculate_linear_handles ();
	}

	/** Sharp corner that need two extra points to be built. */
	public static void add_corner_nodes (Path path, Path stroked, EditPoint e, bool clockwise, double thickness, bool end_point, double nx, double ny) {
		EditPoint corner1, corner2, swap_corner;
		
		// add new points in order to preserve the stroke
		corner1 = e.copy ();
		stroked.add_point (corner1);
	
		corner2 = e.copy ();
		stroked.get_closest_point_on_path (corner2, nx, ny); // FIXME: optimize

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
		// FIXME: this should move the point not create a new point
		if (!path.is_open () || (path.is_open () && !end_point)) {
			corner_position (e, clockwise, thickness, stroked);
		} 
	}

	public static void get_new_position (PointSelection ps, bool clockwise, double thickness, out double strokex, out double strokey) {
		double sx, sy;
		get_new_position_delta (ps, clockwise, thickness, out sx, out sy);
		strokex = sx + ps.point.x;
		strokey = sy + ps.point.y;	
	}

	static void get_new_position_delta (PointSelection ps, bool clockwise, double thickness, out double strokex, out double strokey) {
			double ra, la;
			double avg_angle;
			double angle;
			
			double m, n, o, p;
			double ldnx, ldny;
			
			bool end_node = ps.is_first () || ps.is_last ();
			EditPoint e = ps.point;
			
			if (!end_node) {
				e.recalculate_linear_handles ();
			}
			
			ra = e.get_right_handle ().angle;
			la = e.get_left_handle ().angle;
			
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

			if (end_node) {
				strokex = 0;
				strokey = 0;
			} else {
				strokex = ldnx;
				strokey = ldny;
			}
	}
	
	static double get_space_difference (Path p, EditPoint ep0, EditPoint ep1, double stroke, bool clockwise) {
		double p0x, p0y, p1x, p1y;
		double d1, d2;
		
		get_new_position (new PointSelection (ep0, p), clockwise, stroke, out p0x, out p0y);
		get_new_position (new PointSelection (ep1, p), clockwise, stroke, out p1x, out p1y);
		
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
