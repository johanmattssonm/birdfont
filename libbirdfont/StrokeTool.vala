/*
    Copyright (C) 2014 2015 Johan Mattsson

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
	
	public StrokeTool (string tooltip) {
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
		}
		
		foreach (Path np in paths.paths) {
			g.add_path (np);
		}
	}
	
	public static PathList get_stroke (Path path, double thickness) {
		Path p = path.copy ();
		PathList pl;

		pl = get_stroke_outline (p, thickness);	
		
		return pl;	
	}
	
	public static PathList get_stroke_outline (Path p, double thickness) {
		Path counter, outline, merged;
		PathList paths = new PathList ();
				
		if (!p.is_open () && p.is_filled ()) {
			outline = create_stroke (p, thickness);
			outline.close ();
			paths.add (outline);
			outline.update_region_boundaries ();
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
			
			outline.update_region_boundaries ();
			counter.update_region_boundaries ();
		} else if (p.is_open ()) {
			outline = create_stroke (p, thickness);
			counter = create_stroke (p, -1 * thickness);
			merged = merge_strokes (p, outline, counter, thickness);

			if (p.is_clockwise ()) {
				merged.force_direction (Direction.CLOCKWISE);
			} else {
				merged.force_direction (Direction.COUNTER_CLOCKWISE);
			}
			
			merged.update_region_boundaries ();
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

		counter.reverse ();
		merged = stroke.copy ();

		if (path.is_open ()) {
			merged.delete_last_point ();
			counter.delete_first_point ();
			merged.delete_last_point ();
			counter.delete_first_point ();
		}
		
		merged.append_path (counter);

		merged.close ();
		merged.create_list ();
		merged.recalculate_linear_handles ();

		return merged;
	}
	
	static Path create_stroke (Path p, double thickness) {
		Path stroked;
		
		if (p.points.size >= 2) {
			stroked = p.copy ();
			stroked = generate_stroke (stroked, thickness);

			if (!p.is_open ()) {
				stroked.reverse ();
				stroked.close ();
			}
		} else {
			// TODO: create stroke for a path with one point
			warning ("One point.");
			stroked = new Path ();
		}

		return stroked;
	}

	static Path generate_stroke (Path p, double thickness) {
		Path stroked = new Path ();
		EditPoint start = new EditPoint ();
		EditPoint end;
		EditPoint previous;
		int i;
		
		previous = p.get_last_point ().copy ();
		move_segment (start, previous, thickness);
		
		i = 0;
		foreach (EditPoint ep in p.points) {	
			start = ep.copy ();
			end = ep.get_next ().copy ();
			
			move_segment (start, end, thickness);

			if (end.get_left_handle ().length > 0 && end.get_right_handle ().length > 0) {
				if (!p.is_open () || (i != 0 && i != p.points.size - 1)) { // FIXME: first point i=0
					add_corner (stroked, previous, start, ep.copy (), thickness);
				}
			}
			
			stroked.add_point (start);
			
			if (end.get_left_handle ().length > 0) {
				stroked.add_point (end);
			}

			// open ends around corner
			start.get_left_handle ().convert_to_line (); 
			end.get_right_handle ().convert_to_line ();
			
			previous = end;
			
			i++;
		}

		stroked.recalculate_linear_handles ();
		
		return remove_intersections (stroked);
	}

	static void move_segment (EditPoint stroke_start, EditPoint stroke_stop, double thickness) {
		EditPointHandle r, l;
		double m, n;
		double qx, qy;
		
		stroke_start.set_tie_handle (false);
		stroke_stop.set_tie_handle (false);

		r = stroke_start.get_right_handle ();
		l = stroke_stop.get_left_handle ();
		
		m = cos (r.angle + PI / 2) * thickness;
		n = sin (r.angle + PI / 2) * thickness;
		
		stroke_start.get_right_handle ().move_to_coordinate_delta (m, n);
		stroke_start.get_left_handle ().move_to_coordinate_delta (m, n);
		
		stroke_start.independent_x += m;
		stroke_start.independent_y += n;
		
		qx = cos (l.angle - PI / 2) * thickness;
		qy = sin (l.angle - PI / 2) * thickness;

		stroke_stop.get_right_handle ().move_to_coordinate_delta (qx, qy);
		stroke_stop.get_left_handle ().move_to_coordinate_delta (qx, qy);
		
		stroke_stop.independent_x += qx;
		stroke_stop.independent_y += qy;
	}

	static void add_corner (Path stroked, EditPoint previous, EditPoint next,
		EditPoint original, double stroke_width) {
		
		double ratio;
		double distance;
		EditPoint corner;
		double corner_x, corner_y;
		EditPointHandle previous_handle;
		EditPointHandle next_handle;
		EditPoint cutoff1, cutoff2;
		
		previous_handle = previous.get_left_handle ();
		next_handle = next.get_right_handle ();
		
		previous_handle.angle += PI;
		next_handle.angle += PI;
		
		Path.find_intersection_handle (previous_handle, next_handle, out corner_x, out corner_y);
		corner = new EditPoint (corner_x, corner_y, previous.type);
		corner.convert_to_line ();
		
		previous_handle.angle -= PI;
		next_handle.angle -= PI;
		
		distance = Path.distance_to_point (corner, original);
		ratio = 1.5 * fabs (stroke_width) / distance; // FIXME: cutoff parameter
		
		double r = original.get_right_handle ().angle;
		double l = original.get_left_handle ().angle;
		double angle = atan2 (sin (l - r), cos (l - r));
		
		if (false) { //FIXME: && angle > PI
			if (ratio > 1) {
				stroked.add_point (corner);	
			} else {
				cutoff1 = new EditPoint ();
				cutoff1.set_point_type (previous.type);
				cutoff1.convert_to_line ();

				cutoff2 = new EditPoint ();
				cutoff2.set_point_type (previous.type);
				cutoff2.convert_to_line ();
				
				cutoff1.x = previous.x + (corner.x - previous.x) * ratio;
				cutoff1.y = previous.y + (corner.y - previous.y) * ratio;

				cutoff2.x = next.x + (corner.x - next.x) * ratio;
				cutoff2.y = next.y + (corner.y - next.y) * ratio;

				cutoff1 = stroked.add_point (cutoff1);
				cutoff2 = stroked.add_point (cutoff2);
				
				cutoff1.recalculate_linear_handles ();
				cutoff2.recalculate_linear_handles ();
			}	
		}		
	}
	
	static Path remove_intersections (Path path) {
		Path remaining_points = path;
		int i = 0;
		
		while (add_self_intersection_points (remaining_points)) {
			foreach (EditPoint p in remaining_points.points) {
					
				if ((p.flags & EditPoint.INTERSECTION) > 0) {
					p.deleted = true;
					p.color = new Color (1, 0, 0, 1);
					print ("DELETE\n" + p.to_string ());
				} 
			}
			
			remaining_points = get_remaining_points (remaining_points);
			
			if (i == 0) {
				warning ("end");
				break;
			}
			
			i++;
		}
		
		return remaining_points;
	}

	static Path get_remaining_points (Path old_path) {
		Path new_path;
		PathList pl;
		
		old_path.create_list ();
		
		if (!old_path.has_deleted_point ()) {
			return old_path;
		}

		pl = old_path.process_deleted_points ();
	
		if (pl.paths.size == 0) {
			return old_path;
		}

		new_path = new Path ();
		foreach (Path pn in pl.paths) {
			print (@"pn.points.size: $(pn.points.size)   new_path.points.size: $(new_path.points.size)\n");
			if (pn.points.size > new_path.points.size) {
				new_path = pn;
			}
		}
		
		print (@"after new_path: $(new_path.points.size)\n"); 		
	
		new_path.reopen ();
		
		return get_remaining_points (new_path);
	}

	static bool add_self_intersection_points (Path path) {
		bool intersection = false;
		
		path.all_segments ((ep1, ep2) => {
			double ix, iy;
			
			EditPoint p1;
			EditPoint p2;

			if (ep2 == path.get_last_point ()) {
				return false; // FIXME: LATS TO FIRST CASE
			}
			
			if (segment_intersects (path, ep1, ep2, out ix, out iy, out p1, out p2)) {

				add_intersection (path, ep1.get_prev (), ep1, ix, iy); 

				// FIXME: last to first
				add_intersection (path, p1, p2, ix, iy); 
				
				intersection = true;
				
				return false;
			}
			
			return true;
		});
		
		return intersection;
	}
	
	static void add_intersection (Path path, EditPoint prev, EditPoint next, double px, double py) {
		Gee.ArrayList<EditPoint> n = new Gee.ArrayList<EditPoint> ();
		EditPoint ep1 = new EditPoint ();
		EditPoint ep2 = new EditPoint ();
		EditPoint ep3 = new EditPoint ();
		
		ep1.prev = prev;
		ep1.next = ep2;
		ep1.flags |= EditPoint.NEW_CORNER;
		ep1.type = PointType.CUBIC;
		ep1.x = px;
		ep1.y = py;
		n.add (ep1);

		ep2.prev = ep1;
		ep2.next = ep3;
		ep2.flags |= EditPoint.INTERSECTION;
		ep2.type = PointType.QUADRATIC;
		ep2.x = px;
		ep2.y = py;
		n.add (ep2);

		ep3.prev = ep2;
		ep3.next = next;
		ep3.flags |= EditPoint.NEW_CORNER;
		ep3.type = PointType.CUBIC;
		ep3.x = px;
		ep3.y = py;
		n.add (ep3);
						
		print ("NEW:\n");
		foreach (EditPoint np in n) {
			np = path.add_point_after (np, np.prev);
			path.create_list ();
			
			print ("\n");
			/*
			if  (np.prev != null && np.next != null) {
				print (np.get_prev ().to_string ());
				print (np.to_string ());
				print (np.get_next ().to_string ());
			}
			*/
		}
		
		path.recalculate_linear_handles ();
	}

	static bool segment_intersects (Path path, EditPoint ep, EditPoint next,
		out double ix, out double iy,
		out EditPoint ia, out EditPoint ib) {
		EditPoint p1, p2;
		double cross_x, cross_y;
		
		ix = 0;
		iy = 0;
				
		ia = new EditPoint ();
		ib = new EditPoint ();
		
		if (path.points.size == 0) {
			return false;
		}
		
		// FIXME: last to first
		for (int i = 2; i < path.points.size - 2; i++) {
			p1 = path.points.get (i - 1);
			p2 = path.points.get (i);
			
			Path.find_intersection_point (ep, next, p1, p2, out cross_x, out cross_y);
	
			if (Glyph.CANVAS_MIN < cross_x < Glyph.CANVAS_MAX
				&& Glyph.CANVAS_MIN < cross_y < Glyph.CANVAS_MAX) {

				if (!((ep.x == cross_x && ep.y == cross_y)
					|| (next.x == cross_x && next.y == cross_y)
					|| (p1.x == cross_x && p1.y == cross_y) 
					|| (p2.x == cross_x && p2.y == cross_y))) {

					// iterate to find intersection.					
					ix = cross_x;
					iy = cross_y;
					
					ia = p1;
					ib = p2;
					
					return true;
				}
			}
		}
		
		return false;
	}
	
	static bool is_line (double x1, double y1, double x2, double y2, double x3, double y3) {
		return 0.001 < (x2 - x1) * (x3 - x1 ) + (y2 - y1) * (y3 - y1) < 0.001;
	}
}

}

