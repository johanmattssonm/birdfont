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
		Path counter, outline, merged;
		
		if (!p.is_open ()) {
			merged = create_stroke (p, thickness);
		} else {
			outline = create_stroke (p, thickness);
			counter = create_stroke (p, -1 * thickness);
			merged = merge_strokes (outline, counter);
		}
		
		return merged;
	}
	
	/** Create one stroke from the outline and counter stroke and close the 
	 * open endings.
	 */
	static Path merge_strokes (Path stroke, Path counter) {
		Glyph g;
		Path merged = stroke.copy ();

		if (stroke.points.length () < 3) {
			warning ("Missing points.");
			return merged;
		}

		if (counter.points.length () < 3) {
			warning ("Missing points.");
			return merged;
		}
						
		counter.reverse ();
		
		counter.get_last_point ().get_right_handle ().convert_to_line ();
		counter.get_first_point ().get_left_handle ().convert_to_line ();

		merged.get_last_point ().get_right_handle ().convert_to_line ();
		merged.get_first_point ().get_left_handle ().convert_to_line ();
				
		merged.append_path (counter);
		merged.close ();
		merged.recalculate_linear_handles ();
		
		return merged;
	}
	
	static Path create_stroke (Path p, double thickness) {
		Path new_path;
		Path stroked;

		new_path = add_tangent_points (p);
		
		if (new_path.points.length () >= 2) {
			stroked = change_stroke_width (new_path, thickness);

			if (p.is_open ()) {
				remove_end_corner (stroked);
			} else {
				stroked.reverse ();
				stroked.close ();
			}
		} else {
			// TODO: create stroke for path with one point
			stroked = new Path ();
		}
		
		return stroked;
	}

	static void remove_end_corner (Path stroked) {
		if (stroked.points.length () < 4) {
			warning ("points < 4");
			return;
		}
		
		stroked.points.remove_link (stroked.points.last ());
		stroked.points.remove_link (stroked.points.last ());
		
		//stroked.points.remove_link (stroked.points.first ());
		stroked.points.remove_link (stroked.points.first ());
	}

	static Path add_tangent_points (Path p) {
		Path path = p.copy ();
		int steps = 4;
		List<EditPoint> new_points = new List<EditPoint> ();
		
		EditPoint nep;
		EditPoint? previous = null;
		
		path.all_segments ((start, stop) => {
			EditPoint? prev = null;
			Path.all_of (start, stop, (x, y, step) => {
					EditPoint ep = new EditPoint ();

					if (0 < step < 1) {
						//new_path.get_closest_point_on_path (ep, x, y);
						ep.set_position (x, y);
						
						// Stop processing when the first hidden point is found.
						if (start.type == PointType.HIDDEN || stop.type == PointType.HIDDEN) {
							return false;
						}
						
						return_val_if_fail (prev != null, false);

						ep.prev = ((!) prev).get_link_item ();
						ep.next = start.get_next ();
						
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
				
				return true;
			});

		while (new_points.length () > 0) {
			nep = new_points.first ().data;
			
			if (previous != null) {
				nep.prev = ((!) previous).get_link_item ();
			}
			
			if (!path.has_point (nep)) {
				path.insert_new_point_on_path (nep);
				return_if_fail (nep.prev != null);
			}
			
			previous = nep;

			new_points.remove_link (new_points.first ());
			path.create_list ();
		}
		
		while (path.points.length () > 0 && path.points.last ().data.type == PointType.HIDDEN) {
			path.delete_last_point ();
		}
		
		path.create_list ();
		
		return path;
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
		
		if (npoints < 2) {
			warning ("npoints < 2");
			return new_path;
		}
		
		foreach (EditPoint e in new_path.points) {
			ep = e.copy ();
			
			get_new_position (e, clockwise, thickness, out nx, out ny);

			end_point = (k == 0 || k == npoints - 1);
			k++;
			
			if (ep.type != PointType.HIDDEN) {
				ep.x = nx;
				ep.y = ny;
			} else {
				break;
			}
			
			if (e.is_corner ()) {
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
			double avg_angle;
			double angle;
			
			double m, n, o, p;
			double ldnx, ldny;
						
			e.recalculate_linear_handles ();
			
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
