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
	
	static bool stroke_selected = false;
	static int iterations = 0;
	
	public StrokeTool (string tooltip) {
		iterations = 10;
		select_action.connect((self) => {
			stroke_selected = true;
			iterations++;
			stroke_selected_paths ();
			stroke_selected = false;
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
		PathList n;
		PathList o = new PathList ();
		Path original = path.copy ();
		
		original.remove_points_on_points ();
		
		n = get_stroke_outline (original, thickness);
		
		o = split_corners (n);
		remove_self_intersecting_corners (o);

		o = merge (o);
		
		PathList parts = new PathList ();
		foreach (Path p in o.paths) {
			parts.append (split (p));
		}
			
		return parts;
	}
	
	static bool is_corner_self_intersection (Path p) {
		EditPointHandle l, r;
		bool corner, i, remove;
		
		remove = false;
		i = false;
		p.remove_points_on_points ();
		foreach (EditPoint ep in p.points) {
			
			corner = (ep.flags & EditPoint.NEW_CORNER) > 0;

			if ((ep.flags & EditPoint.COUNTER_TO_OUTLINE) > 0) {
				return false;
			}
										
			if (corner || i) {
				l = ep.get_left_handle ();
				r = ep.get_right_handle ();
				
				if (fabs (l.angle - r.angle) < 0.005) { 
					ep.color = new Color (1,0,0,1);
					remove = true;
				} else ep.color = new Color (0,0,1,1);
			}
			
			i = corner && p.points.size == 4;
		}
		
		return remove;
	}
	
	static void remove_self_intersecting_corners (PathList pl) {
		PathList parts;
		foreach (Path p in pl.paths) {
			
			if (is_corner_self_intersection (p)) {
				parts = get_parts (p);
				if (parts.paths.size > 1) {
					pl.append (parts);
					remove_self_intersecting_corners (pl);
					return;
				} else {
					
					if (has_self_intersection (p)) { // FIXME: DELETE
						warning ("Path ha self intersection.");
					}
					
					pl.paths.remove (p);
					remove_self_intersecting_corners (pl);
					return;
				}
			}
		}
	}
	
	public static PathList get_stroke_outline (Path path, double thickness) {
		return get_strokes (path, thickness);
	}
	
	public static PathList get_strokes (Path p, double thickness) {
		Path counter = new Path ();
		Path outline = new Path ();
		Path merged = new Path ();
		PathList paths = new PathList ();
			
		if (!p.is_open () && p.is_filled ()) {
			outline = create_stroke (p, thickness);
			outline.close ();
		
			outline.update_region_boundaries ();
			paths.add (outline);
		} else if (!p.is_open () && !p.is_filled ()) {
			outline = create_stroke (p, thickness);
			counter = create_stroke (p, -1 * thickness);
						
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
			paths.add (outline);
			
			counter.update_region_boundaries ();
			paths.add (counter);
		} else if (p.is_open ()) { // FIXME: this can create many parts
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
		Path path;
		
		if (p.points.size >= 2) {
			path = p.copy ();
			//FIXME: DELETE path.remove_points_on_points ();
			stroked = generate_stroke (path, thickness);

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
		
		previous = p.get_first_point ().copy ();
		move_segment (start, previous, thickness);
		
		i = 0;
		foreach (EditPoint ep in p.points) {	
			start = ep.copy ();
			end = ep.get_next ().copy ();
			
			move_segment (start, end, thickness);

			if (start == p.get_last_point ()) {
				end = p.get_first_point ();
			}
			
			if (!p.is_open () || (i != 0 && i != p.points.size - 1)) {
				add_corner (stroked, previous, start, ep.copy (), thickness);
			}
			
			stroked.add_point (start);
			
			if (end.get_left_handle ().length > 0) {
				stroked.add_point (end);
			}

			// open ends around corner
			start.get_left_handle ().convert_to_line (); 
			end.get_right_handle ().convert_to_line ();
			
			start.flags |= EditPoint.STROKE_OFFSET;
			end.flags |= EditPoint.STROKE_OFFSET;
						
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
		
		previous_handle.angle -= PI;
		next_handle.angle -= PI;

		distance = Path.distance_to_point (corner, original);
		ratio = 1.5 * fabs (stroke_width) / distance;
		
		if (distance < 0.1) {
			previous.flags |= EditPoint.NEW_CORNER;
			next.flags |= EditPoint.NEW_CORNER;
		} else {
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

				previous.flags |= EditPoint.NEW_CORNER;
				next.flags |= EditPoint.NEW_CORNER;
			}
		}
	}

	static PathList get_parts (Path path) {
		PathList intersections;
		PathList r;
		
		r = get_parts_self (path);
		intersections = new PathList ();
		
		foreach (Path p in r.paths) {
			intersections.add (p);
		}

		// return split_paths (intersections);
		return intersections;
	}
	
	static PathList split_corners (PathList result) {		
		split_corner (result);
		return result;
	}
	
	static bool split_corner (PathList pl) {
		EditPoint p1, p2;
		EditPoint a1, a2;
		PathList r;
		bool split;
		
		foreach (Path p in pl.paths) {
			if (p.points.size == 0) {
				continue;
			}
								
			for (int index = 1; index < p.points.size + 2; index++) {
				p1 = p.points.get ((index - 1) % p.points.size);
				p2 = p.points.get (index % p.points.size);
				a1 = p.points.get ((index + 3) % p.points.size); // two points ahead
				a2 = p.points.get ((index + 4) % p.points.size);
				
				if ((p1.flags & EditPoint.STROKE_OFFSET) > 0
					|| (p2.flags & EditPoint.STROKE_OFFSET) > 0
					|| (a1.flags & EditPoint.STROKE_OFFSET) > 0
					|| (a2.flags & EditPoint.STROKE_OFFSET) > 0) { // FIXME: safe?
					
					split = split_segment (p, a1, a2, p1, p2, out r);  
										
					if (split) {
						pl.append (r);
						pl.paths.remove (p);
						split_corner (pl);
						return true;
					} else {
						p1 = p.points.get ((index - 1) % p.points.size);
						p2 = p.points.get (index % p.points.size);
						a1 = p.points.get ((index + 2) % p.points.size); // one point ahead
						a2 = p.points.get ((index + 3) % p.points.size);
						
						split = split_segment (p, a1, a2, p1, p2, out r); 
						
						if (split) {
							pl.append (r);
							pl.paths.remove (p);
							split_corner (pl);
							return true;
						} else {

							// FIXME: the special case, merge counter path with outline here
							p1 = p.points.get ((index - 1) % p.points.size);
							p2 = p.points.get (index % p.points.size);
							a1 = p.points.get ((index + 3) % p.points.size); // two points ahead
							a2 = p.points.get ((index + 4) % p.points.size);
				
							if ((p1.flags & EditPoint.STROKE_OFFSET) > 0
								&& (a1.flags & EditPoint.STROKE_OFFSET) > 0) {
								p1.color = new Color (1,0,1,0.7);
								a1.color = new Color (1,0,1,0.7);
								p1.flags = EditPoint.COUNTER_TO_OUTLINE;
								a1.flags = EditPoint.COUNTER_TO_OUTLINE;
								
								p1.counter_to_outline = true;
								a1.counter_to_outline = true;
							}
						}
					}
				}		
			}		
		}

		return false;
	}
	
	static bool split_segment (Path p, EditPoint first, EditPoint next, EditPoint p1, EditPoint p2, out PathList result) {
		double ix, iy;
		bool intersection;
		int i;
		
		result = new PathList ();
		intersection = segments_intersects (first, next, p1, p2, out ix, out iy, true);
		
		if (intersection) {			
			add_intersection (p, first, next, ix, iy);
			add_intersection (p, p1, p2, ix, iy);

			i = mark_intersection_as_deleted (p);
			return_val_if_fail (i == 2, false);
			
			result.append (get_remaining_points (p.copy ()));
		} 
		
		return intersection;	
	}
		
	static bool split_path (Path path1, Path path2, PathList result) {
		PathList pl1, pl2;
		Path a1, a2, b1, b2;
		Path m1, m2;
		int i;
		
		if (path1 == path2) {
			return false;
		}
		
		if (add_intersection_points (path1, path2, 2)) {
			i = mark_intersection_as_deleted (path1);
			return_if_fail (i == 2);

			i = mark_intersection_as_deleted (path2);
			return_if_fail (i == 2);
			
			pl1 = get_remaining_points (path1.copy ());
			pl2 = get_remaining_points (path2.copy ());
			
			return_if_fail (pl1.paths.size == 2);
			return_if_fail (pl2.paths.size == 2);
			
			a1 = pl1.paths.get (0);
			a2 = pl1.paths.get (1);
			b1 = pl2.paths.get (0);
			b2 = pl2.paths.get (1);
			
			m1 = PenTool.merge_open_paths (a1, b2);
			m2 = PenTool.merge_open_paths (b1, a2);
			
			result.add (m1);
			result.add (m2);
			
			return true;
		}
		
		return false;	
	}
	
	static PathList split_paths (PathList pl) {
		PathList n = new PathList ();
		
		n.append (pl);
		
		foreach (Path p1 in pl.paths) {
			foreach (Path p2 in pl.paths) {
				if (p1 != p2) {
					if (split_path (p1, p2, n)) {
						n.paths.remove (p1);
						n.paths.remove (p2);
						return split_paths (n);
					}
				}
			}	
		}
		
		return n;		
	}
		
	static PathList get_parts_self (Path path, PathList? paths = null) {
		PathList pl;
		PathList r;

		r = paths == null ? new PathList () : (!) paths;
		pl = split (path);

		foreach (Path part in pl.paths) {
			if (!has_self_intersection (part)) {
				r.add (part);
			} else {
				get_parts_self (part, r);
			}
		}
		
		if (r.paths.size == 0) {
			warning ("No parts in path");
		}
				
		return r;
	}

	static bool has_intersection_points (Path path) {
		foreach (EditPoint p in path.points) {
			if ((p.flags & EditPoint.INTERSECTION) > 0) {
				return true;
			} 
		}
		return false;
	}
	
	/** Split one path at intersection points in two parts. */
	static PathList split (Path path) {
		PathList pl;
		int i;

		if (!has_intersection_points (path)) {
			add_self_intersection_points (path);
		} else {
			warning ("points already created.");
		}
		
		i = mark_intersection_as_deleted (path);
		
		if (!(i == 0 || i == 2)) {
			warning (@"Split should only create two parts, $i points will be deleted.");
		}
		
		pl = get_remaining_points (path.copy ());
		
		return pl;
	}

	static PathList process_deleted_control_points (Path path) {
		PathList paths, nl, pl, rl;
		
		paths = new PathList ();
		rl = new PathList ();
		pl = new PathList ();
		nl = new PathList ();
		
		if (!path.has_deleted_point ()) {
			return pl;
		}
		
		pl.add (path);
		
		foreach (Path p in pl.paths) {
			nl = p.process_deleted_points ();
			
			if (nl.paths.size > 0) {
				rl.append (nl);
				rl.paths.remove (p);
			}
		}
		
		foreach (Path p in rl.paths) {
			pl = process_deleted_control_points (p);
			
			if (pl.paths.size > 0) {
				paths.append (pl);
			} else {
				paths.add (p);
			}
		}
		
		return paths;
	}

	static PathList get_remaining_points (Path old_path) {
		PathList pl;

		old_path.close ();
		pl = process_deleted_control_points (old_path);
			
		if (pl.paths.size == 0) {
			pl.add (old_path);
		}
		
		foreach (Path pn in pl.paths) {
			pn.close ();
		}
		
		return pl;
	}
	
	static bool has_self_intersection (Path path) {
		bool intersection = false;

		path.all_segments ((ep1, ep2) => {
			double ix, iy;
			EditPoint p1, p2;
			
			if (segment_intersects (path, ep1, ep2, out ix, out iy, out p1, out p2)) {
				intersection = true;
				return false;
			}
			
			return true;
		});
		
		return intersection;
	}
	
	static bool add_self_intersection_points (Path path, bool only_offsets = false) {
		bool intersection = false;
		
		path.all_segments ((ep1, ep2) => {
			double ix, iy;
			EditPoint p1, p2;
			
			if (segment_intersects (path, ep1, ep2, out ix, out iy, out p1, out p2, true, only_offsets)) {
				add_intersection (path, ep1, ep2, ix, iy);
				add_intersection (path, p1, p2, ix, iy); 
				
				intersection = true;
				return false;
			}
						
			return true;
		});
		
		if (intersection) {
			// FIXME: path.create_list ();
		}
		
		return intersection;
	}
	
	static void add_intersection (Path path, EditPoint prev, EditPoint next, double px, double py, Color? c = null) {
		Gee.ArrayList<EditPoint> n = new Gee.ArrayList<EditPoint> ();
		EditPoint ep1 = new EditPoint ();
		EditPoint ep2 = new EditPoint ();
		EditPoint ep3 = new EditPoint ();
		
		if (next == path.get_first_point ()) { // FIXME: double check
			ep1.prev = null;
		} else {
			ep1.prev = prev;
		}
		
		ep1.prev = prev;
		ep1.next = ep2;
		ep1.flags |= EditPoint.NEW_CORNER;
		ep1.type = PointType.CUBIC;
		ep1.x = px;
		ep1.y = py;
		ep1.color = c;
		n.add (ep1);

		ep2.prev = ep1;
		ep2.next = ep3;
		ep2.flags |= EditPoint.INTERSECTION;
		ep2.type = PointType.QUADRATIC;
		ep2.x = px;
		ep2.y = py;
		ep2.color = c;
		n.add (ep2);

		ep3.prev = ep2;
		ep3.next = next;
		ep3.flags |= EditPoint.NEW_CORNER;
		ep3.type = PointType.CUBIC;
		ep3.x = px;
		ep3.y = py;
		ep3.color = c;
		n.add (ep3);
						
		foreach (EditPoint np in n) {
			np = path.add_point_after (np, np.prev);
			path.create_list ();
		}
		
		path.recalculate_linear_handles ();
	}

	static bool segments_intersects (EditPoint p1, EditPoint p2, EditPoint ep, EditPoint next,
		out double ix, out double iy,
		bool skip_points_on_points = false) {
		double cross_x, cross_y;
		
		ix = 0;
		iy = 0;

		Path.find_intersection_point (ep, next, p1, p2, out cross_x, out cross_y);
		
		if (Glyph.CANVAS_MIN < cross_x < Glyph.CANVAS_MAX
			&& Glyph.CANVAS_MIN < cross_y < Glyph.CANVAS_MAX) {
			// iterate to find intersection.

			if (skip_points_on_points ||
				!((ep.x == cross_x && ep.y == cross_y)
				|| (next.x == cross_x && next.y == cross_y)
				|| (p1.x == cross_x && p1.y == cross_y) 
				|| (p2.x == cross_x && p2.y == cross_y))) {
									
				if (is_line (ep.x, ep.y, cross_x, cross_y, next.x, next.y)
					&& is_line (p1.x, p1.y, cross_x, cross_y, p2.x, p2.y)) {
				
					ix = cross_x;
					iy = cross_y;
					
					return true;
				}
			} 
		}
				
		return false;
	}
	
	static bool segment_intersects (Path path, EditPoint ep, EditPoint next,
		out double ix, out double iy,
		out EditPoint ia, out EditPoint ib,
		bool skip_points_on_points = false,
		bool only_offsets = false) {
			
		EditPoint p1, p2;
		bool intersection;
		
		ix = 0;
		iy = 0;
				
		ia = new EditPoint ();
		ib = new EditPoint ();
		
		if (path.points.size == 0) {
			return false;
		}
		
		p1 = path.points.get (path.points.size - 1);
		for (int i = 0; i < path.points.size; i++) {
			p2 = path.points.get (i);
						
			bool is_offset = ((p1.flags & EditPoint.STROKE_OFFSET) > 0)
				&& ((p2.flags & EditPoint.STROKE_OFFSET) > 0)
				&& ((ep.flags & EditPoint.STROKE_OFFSET) > 0)
				&& ((next.flags & EditPoint.STROKE_OFFSET) > 0);
			
			if (!only_offsets || is_offset) {
				intersection = segments_intersects (p1, p2, ep, next, out ix, out iy, 
					skip_points_on_points);
					
				if (intersection) {
					ia = p1;
					ib = p2;
					return true;
				}
			}
			
			p1 = p2;
		}
		
		return false;
	}
	
	/** @return true if p2 is on the line p1 to p3 */
	static bool is_line (double x1, double y1, double x2, double y2, double x3, double y3) {
		double ds = Path.distance (x1, x3, y1, y3);
		double d1 = Path.distance (x1, x2, y1, y2);
		double d2 = Path.distance (x2, x3, y2, y3);
		double p = d1 / ds;
		double x = fabs ((x3 - x1) * p - (x2 - x1));
		double y = fabs ((y3 - y1) * p - (y2 - y1));
		double d = fabs (ds - (d1 + d2));
		
		// FIXME: delete print (@"$(fmin (x1, x3)) < $x2 && $x2 < $(fmax (x1, x3))\n");
		// FIXME: delete print (@"$(fmin (y1, y3)) < $y2 && $y2 < $(fmax (y1, y3))\n");
		
		return ds > 0.01 && d1 > 0.01 && d2 > 0.01 
			&& d < 0.01 && x < 0.01 && y < 0.01
			&& fmin (x1, x3) <= x2 && x2 <= fmax (x1, x3) 
			&& fmin (y1, y3) <= y2 && y2 <= fmax (y1, y3);
	}
	
	static Path get_outline (Path path) {
		PathList pl = get_parts (path);
		Path outline = new Path ();
		int inside;
		int min_inside = int.MAX;
		int points = 0;		
		int i = 0;
		
		foreach (Path p in pl.paths) {
			inside = Path.counters (pl, p);
				
			if (inside < min_inside) {
				outline = p;
				min_inside = inside;
			}
			
			i++;
		}
		
		if (min_inside == 0) {
			foreach (Path p in pl.paths) {
				if (p.points.size > points) {
					outline = p;
					points = p.points.size;
				}
			}
		}
		
		return outline;
	}
	
	static void remove_points_in_stroke (PathList pl) {
		PathList result;
		PathList r;
		PathList parts;
		
		foreach (Path p in pl.paths) {
			if (remove_points_in_stroke_for_path (p, pl, out r)) {
				pl.append (r);
				remove_points_in_stroke (pl);
				return;
			}
		}
	}

	static bool remove_points_in_stroke_for_path (Path p, PathList pl, out PathList result) {
		bool remove = false;
		EditPoint start_ep;
		EditPoint start_next;
		EditPoint start_prev;
		EditPoint end_ep = new EditPoint ();
		EditPoint end_next;
		EditPoint end_prev;		
		Path path2;
		EditPoint found = new EditPoint ();
		
		result = new PathList ();
		
		for (int i = 1; i < p.points.size + 1; i++) {
			start_prev = p.points.get ((i - 1) % p.points.size);
			start_ep = p.points.get (i % p.points.size);
			start_next = p.points.get ((i + 1) % p.points.size);
		
			if ((start_ep.flags & EditPoint.COUNTER_TO_OUTLINE) > 0) {
				for (int j = i; j < p.points.size + i; j++) {
					end_prev = p.points.get ((j - 1) % p.points.size);
					end_ep = p.points.get (j % p.points.size);
					end_next = p.points.get ((j + 1) % p.points.size);
					
					// FIXME: if (!is_inside_of_path
					
					if ((end_ep.flags & EditPoint.COUNTER_TO_OUTLINE) > 0) {
						start_ep.flags = EditPoint.NONE;
						end_ep.flags = EditPoint.NONE;
					
						//start_ep.color = new Color (0,0,1,1);
						//end_ep.color = new Color (0,0,1,1);
					
						if (merge_segments (pl, p, start_prev, start_ep, end_ep, end_next, out result)) {
							return true;
						}
					}
				}
			}			

			start_ep.flags = EditPoint.NONE;
			end_ep.flags = EditPoint.NONE;
		}		
		
		return false;
	}

	static bool merge_segments (PathList pl,
		Path path1, EditPoint start1, EditPoint stop1,
		EditPoint start2, EditPoint stop2,
		out PathList result) {
			
		result = new PathList ();
		
		PathList r1;
		PathList r2;
		
		foreach (Path path2 in pl.paths) {
			if (path2 != path1) {
				reset_intersections (path1);
				reset_intersections (path2);

				if (add_merge_intersection_point (path1, path2, start1, stop1)) {
					if (add_merge_intersection_point (path1, path2, start2, stop2)) {
						
						r1 = get_remaining_points (path1.copy ());
						r2 = get_remaining_points (path2.copy ());
						
						if (r1.paths.size != 2) {
							warning (@"Expecting two paths in r1 found $(r1.paths.size)\n");
							reset_intersections (path1);
							reset_intersections (path2);
							return true;
						}
						
						if (r2.paths.size != 2) {
							warning (@"Expecting two paths in r2 found $(r2.paths.size)\n");
							reset_intersections (path1);
							reset_intersections (path2);
							return true;
						}
						
						pl.paths.remove (path1);
						pl.paths.remove (path2);
						
						// FIXME: find criteria
						
						start1.color = new Color (1,0,0,1);
						stop1.color = new Color (1,0,0,1);
						start2.color = new Color (1,0,0,1);
						stop2.color = new Color (1,0,0,1);
						
						double d1 = Path.point_distance (r1.paths.get (0).get_first_point (), 
							r2.paths.get (0).get_first_point ());
							
						double d2 = Path.point_distance (r1.paths.get (0).get_first_point (), 
							r2.paths.get (1).get_first_point ());
						
						Path m1, m2;
						
						if (d1 > d2) {
							m1 = PenTool.merge_open_paths (r1.paths.get (0), r2.paths.get (0));
							m2 = PenTool.merge_open_paths (r1.paths.get (1), r2.paths.get (1));
						} else {
							m1 = PenTool.merge_open_paths (r1.paths.get (1), r2.paths.get (0));
							m2 = PenTool.merge_open_paths (r1.paths.get (0), r2.paths.get (1));
						}

						result.add (m1);
						result.add (m2);
												
						return true;
					} else {
						reset_intersections (path1);
						reset_intersections (path2);
					}
				} else {
					reset_intersections (path1);
					reset_intersections (path2);
				}
			}
		}
		
		return false;
	}

	static void reset_intersections (Path p) {
		foreach (EditPoint ep in p.points) {
			ep.flags &= uint.MAX ^ EditPoint.INTERSECTION;
			ep.deleted = false;
		}
		p.remove_points_on_points ();
	}

	static bool has_counter_to_outline (Path p) {
		foreach (EditPoint ep in p.points) {
			if ((ep.flags & EditPoint.COUNTER_TO_OUTLINE) > 0) {
				return true;
			}	
		}
		
		return false;
	}

	static bool add_merge_intersection_point (Path path1, Path path2, EditPoint first, EditPoint next) {
		double ix, iy;
		bool intersection;

		intersection = false;
		ix = 0;
		iy = 0;
		path2.all_segments ((p1, p2) => {
			int i;
			
			intersection = segments_intersects (first, next, p1, p2, out ix, out iy);
			
			if (intersection) {			
				add_intersection (path1, first, next, ix, iy);
				add_intersection (path2, p1, p2, ix, iy);

				i = mark_intersection_as_deleted (path1);
				i = mark_intersection_as_deleted (path2);
			} 
			
			return !intersection;
		});
		
		return intersection;
	}
		
	static bool is_inside_of_path (PointSelection ps, PathList pl, out Path outline) {
		outline = new Path ();
		foreach (Path p in pl.paths) {
			if (p != ps.path) {
				if (SvgParser.is_inside (ps.point, p)) {
					outline = p;
					return true;
				}
			}
		}
		
		return false;
	}
	
	static PathList merge (PathList pl) {
		remove_points_in_stroke (pl);
		
		PathList r = pl;
		foreach (Path p in pl.paths) {
			if (stroke_selected) { // FIXME: DELETE
				((!) BirdFont.get_current_font ().get_glyph ("a")).add_path (p);
			}
		}

		PathList result = new PathList ();
		PathList m;
		
		foreach (Path p1 in r.paths) {
			foreach (Path p2 in r.paths) {
				if (p1 != p2) {
					if (p1.is_clockwise ()) { // FIXME
						m = merge_path (p1, p2);
						if (m.paths.size > 1) {
							result.append (m);
						}
					}
				}
			}
			result.add (p1);	
		}
		
		return result;
	}
	
	static PathList merge_path (Path path1, Path path2) {
		EditPoint ep1, next, p1, p2, start_point;
		Path path, other;
		PathList pl1, pl2, r;
		bool intersects;
		int s = 0;
		int i;
		double ix, iy;
		
		foreach (EditPoint e in path1.points) {
			if (SvgParser.is_inside (e, path2)) {
				break;
			}
			s++;
		}
		
		r = new PathList ();
		path = path1;
		other = path2;
		i = s;
		path.points.get (i % path.points.size).color = new Color (0,1,0,1);
		while (i < path.points.size + s) {
			ep1 = path.points.get (i % path.points.size);
			next = path.points.get ((i + 1) % path.points.size);
			
			intersects = segment_intersects (other, ep1, next, out ix, out iy,
				out p1, out p2, true);
				
			if (intersects) {
				add_intersection (path, ep1, next, ix, iy);
				add_intersection (other, p1, p2, ix, iy);
				
				pl1 = get_remaining_points (path.copy ());
				pl2 = get_remaining_points (other.copy ());
			
				return_val_if_fail (0 < pl1.paths.size < 3, r);
				return_val_if_fail (0 < pl2.paths.size < 3, r);
				
				r.paths.remove (path);
				r.paths.remove (other);
				
				path = pl2.paths.get (pl2.paths.size - 1);
				other = pl1.paths.get (pl1.paths.size - 1);
				
				other.reverse ();
				
				r.append (pl1);
				r.append (pl2);
				
				i = 0;
			}
			
			i++;
		}
		
		return r;
	}
	
	public static int counters_in_point_in_path (Path p, EditPoint ep) {
		int inside_count = 0;
		bool inside;
		
		if (p.points.size > 1) {
			inside = true;
			
			if (!SvgParser.is_inside (ep, p)) {
				inside = false;
			}

			if (inside) {
				inside_count++; 
			}
		}
		
		return inside_count;
	}
	
	static int mark_intersection_as_deleted (Path path) {
		int i = 0;
		
		foreach (EditPoint p in path.points) {

			if ((p.flags & EditPoint.INTERSECTION) > 0) {
				p.deleted = true;
				i++;
			} 
		}
		
		return i;
	}
	
	/** @return true if the two paths can be merged. */
	static bool merge_path_delete (Path path1, Path path2, out Path merged) {
		PathList pl1, pl2;
		Path p1, p2;
		int i;
		
		merged = new Path ();
		
		if (path1 == path2) {
			return false;
		}
		
		if (add_intersection_points (path1, path2)) {
			i = mark_intersection_as_deleted (path1);
			return_if_fail (i == 1);

			i = mark_intersection_as_deleted (path2);
			return_if_fail (i == 1);
			
			pl1 = get_remaining_points (path1.copy ());
			pl2 = get_remaining_points (path2.copy ());
			
			return_if_fail (pl1.paths.size == 1);
			return_if_fail (pl2.paths.size == 1);
			
			p1 = pl1.paths.get (0);
			p2 = pl2.paths.get (0);
			
			merged = PenTool.merge_open_paths (p1, p2);
			
			return true;
		}
		
		return false;
	}

	/** @param n number of interrsections to find per path. */
	static bool add_intersection_points (Path path1, Path path2, int n = 1) {
		bool intersection = false;
		int found = 0;
		
		path1.all_segments ((ep1, ep2) => {
			double ix, iy;
			EditPoint p1, p2;
			bool i;
			
			i = segment_intersects (path2, ep1, ep2, out ix, out iy,
				out p1, out p2, true);
				
			if (i) {
				add_intersection (path1, ep1, ep2, ix, iy);
				add_intersection (path2, p1, p2, ix, iy);
				intersection = true;
				found++;
				return found < n;
			}
			
			return true;
		});
		
		return intersection;
	}

}

}
