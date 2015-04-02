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
		
		remove_self_intersections (stroked);
		
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
		
		return stroked;
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
		
		distance = Path.distance_to_point (corner, original);
		
		ratio = fabs (stroke_width) / distance;
				
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
			
			stroked.add_point (cutoff1);
			stroked.add_point (cutoff2);
		}

		previous_handle.angle -= PI;
		next_handle.angle -= PI;
	}

	static void remove_self_intersections (Path p) {
		bool keep = true;
		
		add_self_intersection_points (p);
	
		// FIXME: set start on non intersecting point
		foreach (EditPoint ep in p.points) {
			if ((ep.flags & EditPoint.INTERSECTION) > 0) {
				print (@"Inter $(ep)");
				keep = !keep;
			}
			
			if (!keep && (ep.flags & EditPoint.INTERSECTION) == 0) {
				ep.deleted = true;
				ep.type = PointType.CUBIC;
			}
		}
		
		p.remove_deleted_points ();
	}

	static void add_self_intersection_points (Path path) {
		Gee.ArrayList<EditPoint> n = new Gee.ArrayList<EditPoint> ();
		
		path.all_segments ((ep1, ep2) => {
			double ix, iy;
			EditPoint nep;
			EditPoint nep2;
			EditPoint p1;
			EditPoint p2;
			
			if (segment_intersects (path, ep1, ep2, out ix, out iy, out p1, out p2)) {
				nep = new EditPoint ();
				nep.prev = ep1;
				nep.next = ep2;
				
				nep.x = ix;
				nep.y = iy;
				
				n.add (nep);
				
				nep2 = new EditPoint ();
				nep2.prev = p1;
				nep2.next = p2;
				
				nep2.x = ix;
				nep2.y = iy;
				
				n.add (nep2);
			}
			
			return true;
		});
		
		foreach (EditPoint np in n) {
			path.insert_new_point_on_path (np, -1, true);
			np.type = PointType.QUADRATIC;
			np.flags |= EditPoint.INTERSECTION;
		}
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
		for (int i = 1; i < path.points.size - 2; i++) {
			p1 = path.points.get (i - 1);
			p2 = path.points.get (i);
			
			Path.find_intersection_point (ep, next, p1, p2, out cross_x, out cross_y);
	
			if ((p1.x < cross_x < p2.x || p1.x > cross_x > p2.x)
				&& (p1.y < cross_y < p2.y || p1.y > cross_y > p2.y)
				&& (ep.x < cross_x < next.x || ep.x > cross_x > next.x)
				&& (ep.y < cross_y < next.y || ep.y > cross_y > next.y)) {
					
				// iterate to find intersection.					
				ix = cross_x;
				iy = cross_y;
				
				ia = p1;
				ib = p2;
				
				return true;
			}
		}
		
		return false;
	}
}

}

