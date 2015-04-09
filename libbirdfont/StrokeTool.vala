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
		
		g.store_undo_state ();
		
		foreach (Path p in g.active_paths) {
			p.set_stroke (width);
		}
		
		GlyphCanvas.redraw ();
	}

	/** Create strokes for the selected outlines. */
	void stroke_selected_paths () {
		Glyph g = MainWindow.get_current_glyph ();
		PathList paths = new PathList ();
			
		g.store_undo_state ();
		
		foreach (Path p in g.active_paths) {
			if (p.stroke > 0) {
				paths.append (get_stroke (p, p.stroke));
			}
		}

		// FIXME: delete
		bool h = false;
		foreach (Path p in g.active_paths) {
			if (p.stroke == 0) {
				h = true;
			}
		}
		
		if (h) {
			PathList n = new PathList ();
			foreach (Path p in g.active_paths) {
				if (p.stroke == 0) {
					n.add (p);
				}
			}
			n = merge (n);
			paths.append (n); //
		}

		if (paths.paths.size > 0) {
			foreach (Path p in g.active_paths) {
				g.path_list.remove (p);
			}
			
			g.active_paths.clear ();

			foreach (Path np in paths.paths) {
				g.add_path (np);
				g.active_paths.add (np);
			}
					
			GlyphCanvas.redraw ();
		}
	}
	
	public static PathList get_stroke (Path path, double thickness) {
		PathList n;
		PathList o = new PathList ();
		Path original = path.copy ();
		
		original.remove_points_on_points (0.001);
		
		n = get_stroke_outline (original, thickness);
		
		o = split_corners (n);
		remove_self_intersecting_corners (o);
		
		o = merge (o);
		o = remove_remaining_corners (o);
		
		return o;
	}
	
	static PathList remove_remaining_corners (PathList pl) {
		PathList r = new PathList ();
		
		foreach (Path p in pl.paths) {
			if (!has_remove_parts (p)) {
				r.add (p);
			}
		}
		
		return r;
	}
	
	static bool has_remove_parts (Path p) {
		EditPointHandle l, r;
		
		foreach (EditPoint ep in p.points) {
			if ((ep.flags & EditPoint.REMOVE_PART) > 0 || (ep.flags & EditPoint.NEW_CORNER) > 0) {
				l = ep.get_left_handle ();
				r = ep.get_right_handle ();
				
				if (fabs (l.angle - r.angle) < 0.005) { 
					return true;
				} 
			}
		}
		
		return false;
	}
	
	static bool is_corner_self_intersection (Path p) {
		EditPointHandle l, r;
		bool corner, i, remove;
		
		remove = false;
		i = false;
		p.remove_points_on_points ();
		foreach (EditPoint ep in p.points) {
			corner = (ep.flags & EditPoint.NEW_CORNER) > 0;
		
			if (corner || i) {
				l = ep.get_left_handle ();
				r = ep.get_right_handle ();
				
				if (fabs (l.angle - r.angle) < 0.005) { 
					remove = true;
				} 
			}
			
			i = corner && p.points.size == 4;

			if ((ep.flags & EditPoint.COUNTER_TO_OUTLINE) > 0) {
				ep.color = new Color (0,1,0,1); // FIXME: DELETE
				ep.flags |= EditPoint.REMOVE_PART;
				
				return false;
			}
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
	
	static void set_direction (PathList paths, Path direction) {
		foreach (Path path in paths.paths) {
			if (direction.is_clockwise ()) {
				path.force_direction (Direction.CLOCKWISE);
			} else {
				path.force_direction (Direction.COUNTER_CLOCKWISE);
			}
		}
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
							set_direction (r, p);
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
			
			if (segment_intersects (path, ep1, ep2, out ix, out iy, out p1, out p2, true)) {
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
	
	static EditPoint add_intersection (Path path, EditPoint prev, EditPoint next, double px, double py, Color? c = null) {
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
		ep1.type = PointType.LINE_CUBIC;
		ep1.x = px;
		ep1.y = py;
		ep1.color = c;
		n.add (ep1);

		ep2.prev = ep1;
		ep2.next = ep3;
		ep2.flags |= EditPoint.INTERSECTION;
		ep2.type = PointType.LINE_QUADRATIC;
		ep2.x = px;
		ep2.y = py;
		ep2.color = c;
		n.add (ep2);

		ep3.prev = ep2;
		ep3.next = next;
		ep3.flags |= EditPoint.NEW_CORNER;
		ep3.type = PointType.LINE_CUBIC;
		ep3.x = px;
		ep3.y = py;
		ep3.color = c;
		n.add (ep3);
						
		foreach (EditPoint np in n) {
			np = path.add_point_after (np, np.prev);
			path.create_list ();
		}
		
		PenTool.convert_point_to_line (ep1, true);
		PenTool.convert_point_to_line (ep2, true);
		PenTool.convert_point_to_line (ep3, true);
		
		ep1.recalculate_linear_handles ();
		ep2.recalculate_linear_handles ();
		ep3.recalculate_linear_handles ();
		
		return ep2;
	}

	// FIXME: skip_points_on_points, it is the other way around
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
		bool intersection, inter;
		double iix, iiy;
		
		double distance, min_distance;
		
		intersection = false;
		
		ix = 0;
		iy = 0;
				
		iix = 0;
		iiy = 0;

		ia = new EditPoint ();
		ib = new EditPoint ();
		
		if (path.points.size == 0) {
			return false;
		}
		
		min_distance = double.MAX;
		p1 = path.points.get (path.points.size - 1);
		for (int i = 0; i < path.points.size; i++) {
			p2 = path.points.get (i);
						
			bool is_offset = ((p1.flags & EditPoint.STROKE_OFFSET) > 0)
				&& ((p2.flags & EditPoint.STROKE_OFFSET) > 0)
				&& ((ep.flags & EditPoint.STROKE_OFFSET) > 0)
				&& ((next.flags & EditPoint.STROKE_OFFSET) > 0);
			
			if (!only_offsets || is_offset) {
				if (p1 != ep && p2 != next) {
					inter = segments_intersects (p1, p2, ep, next, out iix, out iiy, 
						skip_points_on_points);
						
					if (inter) {
						distance = Path.distance (ep.x, iix, ep.y, iiy);
						if (distance < min_distance) {
							ia = p1;
							ib = p2;
							ix = iix;
							iy = iiy;
							intersection = true;
							min_distance = distance;
						}
					}
				}
			}
			
			p1 = p2;
		}
		
		return intersection;
	}
	
	static bool same (EditPoint a, EditPoint b) {
		return a.x == b.x && a.y == b.y;
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
	
	// indside becomes outside in some paths
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
			ep.flags &= uint.MAX ^ EditPoint.COPIED;
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

	static PathList get_all_parts (PathList pl) {
		bool intersects = false;
		PathList r = new PathList ();
		
		foreach (Path p in pl.paths) { // FIXM: remove
			if (has_self_intersection (p)) {
				r.append (get_parts (p));
				intersects = true;
			} else {
				r.add (p);
			}
		}
	
		foreach (Path p in r.paths) {
			p.close ();
			p.update_region_boundaries ();
		}
	
		if (intersects) {
			return get_all_parts (r);
		}
		
		return r;
	}
	
	static PathList merge (PathList pl) {
		foreach (Path p in pl.paths) {
			if (stroke_selected) { // FIXME: DELETE
				((!) BirdFont.get_current_font ().get_glyph ("d")).add_path (p);
			}
		}
		
		bool error = false;
		PathList m;
		PathList r = pl;
		Path p1, p2;
		
		// FIXME: DELETE remove_points_in_stroke (r);
		
		r = get_all_parts (r);

		foreach (Path p in r.paths) {
			if (stroke_selected) { // FIXME: DELETE
				((!) BirdFont.get_current_font ().get_glyph ("e")).add_path (p);
			}
		}
		
		foreach (Path p in r.paths) {
			if (Path.is_counter (r, p)) {
				p.force_direction (Direction.COUNTER_CLOCKWISE);
			} else {
				p.force_direction (Direction.CLOCKWISE);
			}
		}
		
		while (paths_has_intersection (r, out p1, out p2)) {
			if (merge_path (p1, p2, out m, out error)) {
				r.paths.remove (p1);
				r.paths.remove (p2);
				r.append (m);
				
				if (stroke_selected) { // FIXME: DELETE
					((!) BirdFont.get_current_font ().get_glyph ("f")).add_path (p1);
					((!) BirdFont.get_current_font ().get_glyph ("f")).add_path (p2);
					
					foreach (Path mm in m.paths)
						((!) BirdFont.get_current_font ().get_glyph ("g")).add_path (mm);
				}
				
				r = get_all_parts (r);
			} else {
				warning ("Not merged.");
			}
			
			if (error) {
				warning ("Merge error");
				break;
			}
		}
		
		if (!error) {
			remove_merged_parts (r);
		}
		
		foreach (Path p in r.paths) {
			if (stroke_selected) { // FIXME: DELETE
				((!) BirdFont.get_current_font ().get_glyph ("h")).add_path (p);
			}
		}
		
		return r;
	}

	static void remove_merged_parts (PathList r) {
		Gee.ArrayList<Path> remove = new Gee.ArrayList<Path> ();
		foreach (Path p in r.paths) {
			if (Path.is_counter (r, p)) {
				if (p.is_clockwise ()) {
					remove.add (p);	
				}
			} else {
				if (!p.is_clockwise ()) {
					remove.add (p);
				}
			}
		}

		if (stroke_selected) { // FIXME: DELETE	
			foreach (Path mm in r.paths)
				((!) BirdFont.get_current_font ().get_glyph ("i")).add_path (mm);
		}
						
		foreach (Path p in remove) {
			r.paths.remove (p);
		}
		
		if (stroke_selected) { // FIXME: DELETE	
			foreach (Path mm in r.paths)
				((!) BirdFont.get_current_font ().get_glyph ("j")).add_path (mm);
		}
	}
	
	static bool merge_next (Path p1, PathList pl, out Path path2, out PathList result, out bool error) {
		PathList m;
		
		result = new PathList ();
		path2 = new Path ();
		
		error = false;
		foreach (Path p2 in pl.paths) {
			if (p1 != p2) {
				if (equals (p1, p2)) { // FIXME: DELETE
					warning ("Same path.");
					continue;
				}
				
				if (p1.points.size == 0 || p2.points.size == 0) {
					warning ("No points.");
					continue;
				}
				
				if (merge_path (p1, p2, out m, out error)) {
					foreach (Path np in m.paths) {	
						if (np.points.size == 0) {
							warning (@"No points after merge, $(m.paths.size) paths.");
							
							if (stroke_selected) { // FIXME: DELETE
								((!) BirdFont.get_current_font ().get_glyph ("d")).add_path (p2);
								((!) BirdFont.get_current_font ().get_glyph ("d")).add_path (p1);
							}
							
							error = true;
							return false;
						}
						
						result.add (np);
					}
					
					path2 = p2;
					return true;
				}
			}
		}
		
		return false;
	}
	
	public static bool equals (Path p1, Path p2) {
		EditPoint ep1, ep2;
		
		if (p1.points.size != p2.points.size) {
			return false;
		}
		
		for (int i = 0; i < p1.points.size; i++) {
			ep1 = p1.points.get (i);
			ep2 = p2.points.get (i);
			
			if (ep1.x != ep2.x || ep1.y != ep2.y) {
				return false;
			}
		}
		
		return true;
	}
	
	public class Intersection : GLib.Object {
		public bool done = false;
		public EditPoint point;
		public EditPoint other_point;
		public Path path;
		public Path other_path;
		
		public Intersection (EditPoint point, Path path,
			EditPoint other_point, Path other_path)  {
			
			this.point = point;
			this.path = path;
			this.other_point = other_point;
			this.other_path = other_path;
		}
		
		public Intersection.empty () {
			this.point = new EditPoint ();
			this.path = new Path ();
			this.other_point = new EditPoint ();
			this.other_path = new Path ();
		}

		public Path get_other_path (Path p) {
			if (p == path) {
				return other_path;
			}

			if (p == other_path) {
				return path;
			}

			warning ("Wrong intersection.");
			return new Path ();
		}
		
		public EditPoint get_point (Path p) {
			if (p == path) {
				return point;
			}

			if (p == other_path) {
				return other_point;
			}

			warning ("Wrong intersection.");
			return new EditPoint ();
		}
	}
	
	public class IntersectionList : GLib.Object {
		public Gee.ArrayList<Intersection> points = new Gee.ArrayList<Intersection> ();
		
		public IntersectionList () {
		}

		public Intersection get_point (EditPoint ep, out bool other) {
			other = false;
			foreach (Intersection i in points) {
				if (i.other_point == ep || i.point == ep) {
					other = (i.other_point == ep);
					return i;
				}	
			}
			
			warning ("No intersection found for point.");
			return new Intersection.empty ();
		}
	}
	
	static bool merge_path (Path path1, Path path2, out PathList merged_paths, out bool error) {
		IntersectionList intersections;
		EditPoint ep1, next, p1, p2, pp1, pp2;
		Path path, other, merged;
		PathList pl1, pl2, r, other_paths, result;
		bool intersects;
		int s, i;
		double ix, iy, iix, iiy;
		bool merge = false;
		EditPoint intersection_point, other_intersection_point;
		Intersection intersection;
		bool path1_direction, path2_direction;

		error = false;
		merged_paths = new PathList ();
		intersections = new IntersectionList ();
		
		reset_intersections (path1);
		reset_intersections (path2);
		
		iix = 0;
		iiy = 0;
		
		result = new PathList ();
		
		if (path1.points.size == 0 || path2.points.size == 0) {
			warning ("No points in path.");
			error = true;
			return false;
		}
	
		if (!path1.boundaries_intersecting (path2)) {
			return false;
		}
		
		Path original_path1 = path1.copy ();
		Path original_path2 = path2.copy ();
		
		s = 0;
		foreach (EditPoint e in original_path1.points) {
			if (!SvgParser.is_inside (e, original_path2)) {
				break;
			}
			s++;
		}
		
		if (s >= path1.points.size) {
			Path t;
			t = original_path1;
			original_path1 = original_path2;
			original_path2 = t;
			s = 0;
			foreach (EditPoint e in original_path1.points) {
				if (!SvgParser.is_inside (e, original_path2)) {
					break;
				}
				s++;
			}
		} 
		
		if (s >= original_path1.points.size) {
			warning ("No start point found.");
			error = true;
			return false;
		}
		
		path = original_path1;
		other = original_path2;
		
		other_paths = new PathList ();
		r = new PathList ();
		other_paths.add (path);
		other_paths.add (other);
		intersects = false;
		p1 = new EditPoint ();
		p2 = new EditPoint ();
		pp1 = new EditPoint ();
		pp2 = new EditPoint ();

		ix = 0;
		iy = 0;
		i = s;
		merged = new Path ();
		
		path1_direction = original_path1.is_clockwise ();
		path2_direction = original_path1.is_clockwise ();
		
		while (true) {
			ep1 = path.points.get (i % path.points.size);
			next = path.points.get ((i + 1) % path.points.size);
						
			if ((ep1.flags & EditPoint.COPIED) > 0) {
				if (merge) {
					merged.close ();
					result.add (merged.copy ());
				}
			
				merged = new Path ();
				
				bool find_parts = false;
				Intersection new_start = new Intersection.empty ();
				foreach (Intersection inter in intersections.points) {
					if (!inter.done && !find_parts) {
						find_parts = true;
						new_start = inter;
						break;
					}
				}
				
				if (!find_parts) {
					break; // done, no more parts to merge
				} else {
					// set start point for next part
					path = new_start.other_path;
					
					if (path.points.size == 0) {
						warning ("No points.");
						error = true;
						return false;
					}
					
					i = index_of (path, new_start.get_point (path));
					
					if (i < 0) {
						warning ("Start point not found.");
						error = true;
						return false;
					}
					
					ep1 = path.points.get (i % path.points.size);
					next = path.points.get ((i + 1) % path.points.size);
					
					if ((ep1.flags & EditPoint.INTERSECTION) == 0) {
						warning ("Not starting on an intersection point.");
						error = true;
						return false;
					}
					
					new_start.done = true;
				}
			}
			
			intersects = false;
			
			double dm;
			double d;
			
			if ((ep1.flags & EditPoint.INTERSECTION) > 0) {
				Intersection current_intersection;
				bool continue_on_other_path;
				current_intersection = intersections.get_point (ep1, out continue_on_other_path);
				current_intersection.done = true;
				
				// take the other part of an intersection
				if ((next.flags & EditPoint.COPIED) != 0) {
					bool next_is_intersection = false;
					bool next_continue_on_other_path;
					
					next_is_intersection = ((next.flags & EditPoint.INTERSECTION) > 0);
					
					if (next_is_intersection) {
						Intersection next_intersection = intersections.get_point (next, out next_continue_on_other_path);
						
						ep1.flags |= EditPoint.COPIED;
						merged.add_point (ep1.copy ());					
						
						if (!next_intersection.done) {
							EditPoint new_start_point;
							
							path = next_continue_on_other_path 
								? next_intersection.other_path : next_intersection.path;
								
							new_start_point = next_continue_on_other_path 
								? next_intersection.other_point : next_intersection.point;
							
							i = index_of (path, new_start_point);
							
							if (i < 0) {
								warning ("Point not found in path.\n");
								error = true;
								return false;
							}
							
							ep1 = path.points.get (i % path.points.size);
							next = path.points.get ((i + 1) % path.points.size);
						} else {
							warning ("Part is already created.\n");
							error = true;
							return false;
						}
					}  else {
						ep1.flags |= EditPoint.COPIED;
						merged.add_point (ep1.copy ());	
						
						EditPoint new_start_point;
						
						if ((next.flags & EditPoint.COPIED) > 0) {
							path = current_intersection.get_other_path (path);
							new_start_point = current_intersection.get_point (path);
							i = index_of (path, new_start_point);
							
							if (i < 0) {
								warning ("Point not found in path.");
								error = true;
								return false;
							}
							
							ep1 = path.points.get (i % path.points.size);
							next = path.points.get ((i + 1) % path.points.size);
							
							if ((next.flags & EditPoint.INTERSECTION) > 0) {
								warning ("Wrong type.");
								error = true;
								return false;
							}
							
							if ((next.flags & EditPoint.COPIED) > 0) {
								merged.add_point (ep1.copy ());
								continue;
							}
						} else {
							ep1.flags |= EditPoint.COPIED;
							merged.add_point (ep1.copy ());								
						} 					
					}
				} else {
					ep1.flags |= EditPoint.COPIED;
					
					if (path1_direction == path2_direction) {
						if (!SvgParser.is_inside (ep1, original_path1)) {
							merged.add_point (ep1.copy ());
						}
					} else {
						merged.add_point (ep1.copy ());
					}
				}
				
				current_intersection.done = true;
			} else {
				// find new intersection
				dm = double.MAX;
				foreach (Path o in other_paths.paths) {
					bool inter = segment_intersects (o, ep1, next, out iix, out iiy,
						out pp1, out pp2);
					d = Path.distance (ep1.x, iix, ep1.y, iiy);
					if (d < dm && inter) {
						other = o;
						dm = d;
						intersects = true;
						p1 = pp1;
						p2 = pp2;
						ix = iix;
						iy = iiy;
					}
					
					if (d < 0.0001) {
						intersects = false;
					}
				}
			
				if (intersects) {
					merged.add_point (ep1.copy ());
					ep1.flags |= EditPoint.COPIED;

					intersection_point = add_intersection (path, ep1, next, ix, iy);
					other_intersection_point = add_intersection (other, p1, p2, ix, iy);
					
					bool g = false;
					foreach (Intersection old_intersection in intersections.points) {
						if (old_intersection.point  == intersection_point
							|| old_intersection.other_point == other_intersection_point) {
							old_intersection.done = true;
							g = true;
						}
					}
					
					if (!g) {
						Intersection ip = new Intersection (intersection_point, path, other_intersection_point, other);
						intersections.points.add (ip);
					}
				
					merged.add_point (intersection_point.copy ());
					intersection_point.flags |= EditPoint.COPIED;
					
					i = index_of (other, other_intersection_point);
					
					if (i < 0) {
						warning (@"Point not found ($i).");
						break;
					}
					
					path = other;
					merge = true;
				} else {
					ep1.flags |= EditPoint.COPIED;
					merged.add_point (ep1.copy ());
					
					PointSelection ps;
					Path outline;
					
					// remove points inside of path
					if (original_path2.is_clockwise ()) {
						ps = new PointSelection (ep1, merged);
						if (is_inside_of_path (ps, result, out outline)) {
							ep1.deleted = true;
						}
					}
				}
			}
			
			i++;
		}
		
		if (merge) {			
			original_path1.remove_points_on_points ();
			original_path2.remove_points_on_points ();
			original_path1.remove_deleted_points ();
			original_path2.remove_deleted_points ();
			
			// FIXME: delete
			foreach (EditPoint ep in original_path1.points) {
				if ((ep.flags & EditPoint.COPIED) == 0) {
					warning (@"Points left in original_path1 ($(original_path1.points.size) ).\n");
				}
			}

			foreach (EditPoint ep in original_path2.points) {
				if ((ep.flags & EditPoint.COPIED) == 0) {
					warning (@"Points left original_path2 ($(original_path2.points.size)).\n");
					ep.color = new Color (0,1,0,1);
					
					if (stroke_selected) { // FIXME: DELETE
						((!) BirdFont.get_current_font ().get_glyph ("h")).add_path (original_path2);
					}
				}
			}
					
			int counter;
			foreach (Path np in result.paths) {
				Path p = np.copy ();
				p.remove_points_on_points ();
				counter = Path.counters (result, p);
				if (counter == 0) {
					merged.force_direction (Direction.CLOCKWISE);
				} else {
					if (original_path1.is_clockwise () != original_path2.is_clockwise ()) {
						merged.force_direction (Direction.COUNTER_CLOCKWISE);
					} else {
						merged.force_direction (Direction.CLOCKWISE);
					}
				}
				
				p.close ();
				reset_intersections (p);
				merged_paths.append (get_parts (p));
				p.update_region_boundaries ();
				p.recalculate_linear_handles ();
			}
		}

		return merge && !error;
	}
	
	static int index_of (Path p, EditPoint ep) {
		int i = 0;
		foreach (EditPoint e in p.points) {
			if (e == ep) {
				return i;
			}
			i++;
		}
		
		return -1;
	}
	
	static Path get_next_part (PathList pl, EditPoint ep) {
		double d, m;
		Path r;
		
		r = new Path ();
		m = double.MAX;
		foreach (Path p in pl.paths) {
			d = Path.distance_to_point (p.get_last_point (), ep);
			if (d < m) {
				m = d;
				r = p;
			}
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

	/** @param n number of interrsections to find per path. */
	static bool has_intersection (Path path1, Path path2) {
		bool intersection = false;
		
		if (!path1.boundaries_intersecting (path2)) {
			return false;
		}
		
		path1.all_segments ((ep1, ep2) => {
			double ix, iy;
			EditPoint p1, p2;
			bool i;
			
			i = segment_intersects (path2, ep1, ep2, out ix, out iy,
				out p1, out p2, true);
				
			if (i) {
				intersection = true;
			}
			
			return !intersection;
		});
		
		return intersection;
	}
	
	static bool paths_has_intersection (PathList r, out Path path1, out Path path2) {
		int i, j;
		path1 = new Path ();
		path2 = new Path ();
		
		i = 0;
		foreach (Path p1 in r.paths) {
			
			j = 0;
			foreach (Path p2 in r.paths) {
				if (p1 != p2) {
					if (has_intersection (p1, p2)) {
						path1 = p1;
						path2 = p2;
						return true;
					}
				}
				j++;
			}
			i++;
		}
		return false;
	}
}

}
