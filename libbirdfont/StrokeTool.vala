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
	
	public static double stroke_width = 0;
	public static bool add_stroke = false;
	
	public static bool show_stroke_tools = false;
	public static bool stroke_selected = false;
	
	public StrokeTool (string tooltip) {
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
	public static void stroke_selected_paths () {
		Glyph g = MainWindow.get_current_glyph ();
		PathList paths = new PathList ();

		stroke_selected = true; // FIXME: delete
			
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
			paths.append (n);
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
			
			PenTool.update_orientation ();
			
			GlyphCanvas.redraw ();
		}
		
		stroke_selected = false; // FIXME: delete 
	}
	
	public static PathList get_stroke (Path path, double thickness) {
		PathList n;
		Path stroke = path.copy ();
		
		if (!stroke.is_clockwise ()) {
			stroke.force_direction (Direction.CLOCKWISE);
		}
		
		stroke.remove_points_on_points (0.3);

		flatten (stroke, thickness);
		n = get_stroke_outline (stroke, thickness);
		
		foreach (Path p in n.paths) {
			if (stroke_selected) {// FIXME: DELETE
				((!) BirdFont.get_current_font ().get_glyph ("c")).add_path (p);
			}
		}
		
		foreach (Path p in n.paths) {
			p.remove_points_on_points (0.3);
		}
		
		// o = split_corners (n);
		// o = get_all_parts (n);
		
		// Changing orientation causes a problem with self intersecting corners
		// but it solves the problem where the original path is self intersection.
		// According to the fill rule should intersection be counter paths but 
		// it is better to try to merge paths with filled intersections.
		//
		// TODO: Implement merging with other fill rules.
		
		// this works for glyphs like 8 but not for other intersections
		/*
		foreach (Path p in o.paths) {
			if (has_points_outside (o, p)) {
				p.force_direction (Direction.CLOCKWISE);
			} else {
				p.force_direction (Direction.COUNTER_CLOCKWISE);
			}
		}*/
		
		n = merge (n);
	
		// FIXME: this needs to be solved.
		// remove_self_intersecting_corners (n);

		n = remove_remaining_corners (n);
		
		return n;
	}
	
	static PathList remove_remaining_corners (PathList pl) {
		PathList r = new PathList ();
		
		foreach (Path p in pl.paths) {
			if (!has_remove_parts (p)) {
				r.add (p);
			} else {
				if (stroke_selected) { // FIXME: DELETE
					((!) BirdFont.get_current_font ().get_glyph ("k")).add_path (p);
				}
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
				
				if (fabs (l.angle - r.angle) < 0.005 
					&& l.length > 0.001
					&& r.length > 0.001) {
					
					if ((ep.flags & EditPoint.REMOVE_PART) > 0) {
						if (p.points.size > 5) {
							return false;
						}
					}
					
					if ((ep.flags & EditPoint.NEW_CORNER) > 0) {
						if (p.points.size > 5) {
							return false;
						}
					}
					
					ep.color = Color.red ();
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
					ep.color = Color.red ();
				}
				
				if (Path.distance_to_point (ep.get_prev (), ep.get_next ()) < 1) {
					ep.deleted = true;
					ep.color = Color.red ();
					p.remove_deleted_points ();
					return is_corner_self_intersection (p) || is_counter_to_outline (p);
				}
			}
			
			i = corner && p.points.size == 4;

			if ((ep.flags & EditPoint.COUNTER_TO_OUTLINE) > 0) {
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
					pl.paths.remove (p);
					pl.append (parts);
					remove_self_intersecting_corners (pl);
					return;
				} else {
						
					if (stroke_selected) { // FIXME: DELETE
						((!) BirdFont.get_current_font ().get_glyph ("l")).add_path (p);
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
			
			if (stroke_selected) {// FIXME: DELETE
				((!) BirdFont.get_current_font ().get_glyph ("b")).add_path (outline.copy ());
				((!) BirdFont.get_current_font ().get_glyph ("b")).add_path (counter.copy ());
			}
			
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
		EditPoint last_counter, first;
		
		merged = stroke.copy ();
		counter.reverse ();
		
		last_counter = new EditPoint ();
		first = new EditPoint ();
		
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

		if (path.is_open ()) {
			first = merged.get_first_point ();
			last_counter = merged.get_last_point ();

			first.get_left_handle ().convert_to_line ();
			first.recalculate_linear_handles ();

			last_counter.get_right_handle ().convert_to_line ();
			last_counter.recalculate_linear_handles ();
		}

		return merged;
	}
	
	static Path create_stroke (Path p, double thickness) {
		Path stroked;
		Path path;
		
		if (p.points.size >= 2) {
			path = p.copy ();
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
		EditPoint next;
		EditPoint ep;
		
		EditPoint original_start;
		EditPoint original_end;
		EditPoint original_next;
		
		int i;
		bool bump, previous_bump;
		double small_part = 0.5 * fabs (thickness);
		
		previous = p.get_first_point ().copy ();
		move_segment (start, previous, thickness);
		
		i = 0;
		previous_bump = false;
		for (int j = 0; j < p.points.size; j++) {
			original_start = p.points.get (j % p.points.size);
			original_end = p.points.get ((j + 1) % p.points.size).copy ();
			original_next = p.points.get ((j + 2) % p.points.size).copy ();
			
			ep = original_start.copy ();
			start = original_start.copy ();
			end = original_end.copy ();
			next = original_next.copy ();
			
			move_segment (start, end, thickness);

			bump = Path.distance_to_point (previous, start) < small_part;

			if (start == p.get_last_point ()) {
				end = p.get_first_point ();
			}

			start.flags |= EditPoint.STROKE_OFFSET;
			end.flags |= EditPoint.STROKE_OFFSET;

			bool flat = (Path.distance_to_point (previous, start) < 0.05 * thickness);

			if (!flat && !p.is_open () || (i != 0 && i != p.points.size - 1)) {
				if (!ep.tie_handles) {
					add_corner (stroked, previous, start, ep.copy (), thickness);
				} else {
					warning ("Tied handles.");
				}
			}
			
			if (start.is_valid () && end.is_valid ()) {
				stroked.add_point (start);	
				stroked.add_point (end);
			} else {
				warning ("Bad point in stroke.");
			}
			
			adjust_handles (start, end, next, original_start, original_end, original_next);
			
			// open ends around corner
			start.get_left_handle ().convert_to_line (); 
			end.get_right_handle ().convert_to_line ();
			
			previous = end;
			previous_bump = bump;
			
			i++;
		}

		stroked.recalculate_linear_handles ();
			
		return stroked;
	}

	static void adjust_handles (EditPoint stroke_start, EditPoint stroke_end, EditPoint stroke_next,
		EditPoint start, EditPoint end, EditPoint next) {
		double px, py;
		double dp = Path.distance_to_point (stroke_start, stroke_end);
		double dn = Path.distance_to_point (stroke_end, stroke_next);
		double op = Path.distance_to_point (start, end);
		double on = Path.distance_to_point (end, next);
		double rp = dp / op;  
		double rn = on / dn;
		EditPointHandle r = stroke_start.get_right_handle ();
		EditPointHandle l = stroke_end.get_left_handle ();
		
		if (!r.is_line ()) {
			if (r.type == PointType.CUBIC) {
				r.length *= rp;
			} else {
				Path.find_intersection_handle (r, l, out px, out py);
				
				if (EditPoint.is_valid_position (px, py)) {
					l.move_to_coordinate (px, py); 
					r.move_to_coordinate (px, py); 
				} else {
					warning ("Invalid position.");
				}				
			}

			if (l.type == PointType.CUBIC) {
				l.length *= rn; 
			} 
		}
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
		double adjusted_stroke = stroke_width * 0.999999;
		
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
		ratio = 1.5 * fabs (adjusted_stroke) / distance;
		
		if (ratio < 0) {
			return;
		}
		
		if (!corner.is_valid ()) {
			warning ("Invalid corner.");
			return;
		}
		
		if (Path.distance_to_point (previous, next) < fabs (0.2 * stroke_width)) {
			return;
		}
				
		if (distance < stroke_width) {
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

				if (!cutoff1.is_valid () || cutoff2.is_valid ()) {
					cutoff1 = stroked.add_point (cutoff1);
					cutoff2 = stroked.add_point (cutoff2);
				}
				
				cutoff1.recalculate_linear_handles ();
				cutoff2.recalculate_linear_handles ();
				
				if (distance > 4 * stroke_width) {
					previous.flags = EditPoint.NONE;
					next.flags = EditPoint.NONE;
				} else {
					previous.flags |= EditPoint.NEW_CORNER;
					next.flags |= EditPoint.NEW_CORNER;
				}
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

		return intersections;
	}
	
	public static bool is_counter_to_outline (Path p) {
		EditPoint p1, p2;
		EditPoint a1, a2;
		
		if (p.points.size == 0) {
			return false;
		} 
		
		for (int index = 1; index < p.points.size + 2; index++) {
			p1 = p.points.get ((index - 1) % p.points.size);
			p2 = p.points.get (index % p.points.size);
			a1 = p.points.get ((index + 3) % p.points.size); // two points ahead
			a2 = p.points.get ((index + 4) % p.points.size);			

			if ((p2.flags & EditPoint.STROKE_OFFSET) > 0
				&& (a1.flags & EditPoint.STROKE_OFFSET) > 0) {
				return true;	
			}
		}
		
		return false;
	}
	
	static bool split_corner (PathList pl) {
		EditPoint p1, p2;
		EditPoint a1, a2;
		PathList result;
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
					|| (a2.flags & EditPoint.STROKE_OFFSET) > 0) {
					
					split = split_segment (p, a1, a2, p1, p2, out result);  
										
					if (split) {
						pl.append (result);
						pl.paths.remove (p);
						split_corner (pl);
						return true;
					} else {
						p1 = p.points.get ((index - 1) % p.points.size);
						p2 = p.points.get (index % p.points.size);
						a1 = p.points.get ((index + 2) % p.points.size); // one point ahead
						a2 = p.points.get ((index + 3) % p.points.size);
						
						split = split_segment (p, a1, a2, p1, p2, out result); 
						
						if (split) {
							pl.append (result);
							pl.paths.remove (p);
							split_corner (pl);
							return true;
						} else {
							p1 = p.points.get ((index - 1) % p.points.size);
							p2 = p.points.get (index % p.points.size);
							a1 = p.points.get ((index + 3) % p.points.size); // two points ahead
							a2 = p.points.get ((index + 4) % p.points.size);
				
							if ((p1.flags & EditPoint.STROKE_OFFSET) > 0
								&& (a1.flags & EditPoint.STROKE_OFFSET) > 0) {
								p1.flags = EditPoint.COUNTER_TO_OUTLINE;
								a1.flags = EditPoint.COUNTER_TO_OUTLINE;
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
		Path new_path;
		PathList pl;
		int i;

		if (!has_intersection_points (path)) {
			add_self_intersection_points (path);
		} else {
			warning ("points already created.");
		}

		foreach (EditPoint p in path.points) {
			if (insides (p, path) == 1) {
				path.set_new_start (p);
				path.close ();
				break;
			}
		}

		i = mark_intersection_as_deleted (path);
		
		if (!(i == 0 || i == 2)) {
			warning (@"Split should only create two parts, $i points will be deleted.");
		}
		
		new_path = path.copy ();
		pl = get_remaining_points (new_path);
		
		return pl;
	}

	static PathList process_deleted_control_points (Path path) {
		PathList paths, nl, pl, rl, result;
		
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
		
		result = new PathList ();
		foreach (Path p in rl.paths) {
			pl = process_deleted_control_points (p);
			
			if (pl.paths.size > 0) {
				result.append (pl);
			} else {
				result.add (p);
			}
		}
		
		for (int i = 1; i < result.paths.size; i++) {
			result.paths.get (i).reverse ();
		}
		
		paths.append (result);
		
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
		
		return intersection;
	}
	
	static EditPoint add_intersection (Path path, EditPoint prev, EditPoint next, double px, double py, Color? c = null) {
		Gee.ArrayList<EditPoint> n = new Gee.ArrayList<EditPoint> ();
		EditPoint ep1 = new EditPoint ();
		EditPoint ep2 = new EditPoint ();
		EditPoint ep3 = new EditPoint ();
		
		if (next == path.get_first_point ()) {
			ep1.prev = null;
		} else {
			ep1.prev = prev;
		}
		
		ep1.prev = prev;
		ep1.next = ep2;
		ep1.flags |= EditPoint.NEW_CORNER;
		ep1.type = prev.type;
		ep1.x = px;
		ep1.y = py;
		ep1.color = c;
		n.add (ep1);

		ep2.prev = ep1;
		ep2.next = ep3;
		ep2.flags |= EditPoint.INTERSECTION;
		ep2.type = prev.type;
		ep2.x = px;
		ep2.y = py;
		ep2.color = c;
		n.add (ep2);

		ep3.prev = ep2;
		ep3.next = next;
		ep3.flags |= EditPoint.NEW_CORNER;
		ep3.type = prev.type;
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
	
	/** @return true if p2 is on the line p1 to p3 */
	static bool is_line (double x1, double y1, double x2, double y2, double x3, double y3, double tolerance = 0.01) {
		return fmin (x1, x3) <= x2 && x2 <= fmax (x1, x3) 
			&& fmin (y1, y3) <= y2 && y2 <= fmax (y1, y3)
			&& is_flat (x1, y1, x2, y2, x3, y3, tolerance);
	}
	
	public static bool is_flat (double x1, double y1, double x2, double y2, double x3, double y3, double tolerance = 0.01) {
		double ds = Path.distance (x1, x3, y1, y3);
		double d1 = Path.distance (x1, x2, y1, y2);
		double d2 = Path.distance (x2, x3, y2, y3);
		double p = d1 / ds;
		double x = fabs ((x3 - x1) * p - (x2 - x1));
		double y = fabs ((y3 - y1) * p - (y2 - y1));
		double d = fabs (ds - (d1 + d2));
		
		return ds > 0.01 && d1 > 0.01 && d2 > 0.01
			&& d < tolerance && x < tolerance && y < tolerance;	
	}
	
	// indside becomes outside in some paths
	static void remove_points_in_stroke (PathList pl) {
		PathList r;
		
		foreach (Path p in pl.paths) {
			if (remove_points_in_stroke_for_path (p, pl, out r)) {
				pl.append (r);
				remove_points_in_stroke (pl);
				return;
			}
		}
	}

	static bool remove_points_in_stroke_for_path (Path p, PathList pl, out PathList result) {
		EditPoint start_ep;
		EditPoint start_next;
		EditPoint start_prev;
		EditPoint end_ep = new EditPoint ();
		EditPoint end_next;
		EditPoint end_prev;		
		
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
				if (is_inside (ps.point, p)) {
					outline = p;
					return true;
				}
			}
		}
		
		return false;
	}
				
	static PathList get_all_parts (PathList pl) {
		PathList m;
		bool intersects = false;
		PathList r = new PathList ();
		
		foreach (Path p in pl.paths) {
			if (has_self_intersection (p)) {				
				m = get_parts (p);
				r.append (m);
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
			if (stroke_selected) {// FIXME: DELETE
				((!) BirdFont.get_current_font ().get_glyph ("d")).add_path (p);
			}
		}
		
		bool error = false;
		PathList m;
		PathList r = pl;
		Path p1, p2;
		
		r = get_all_parts (r);

		foreach (Path p in r.paths) {
			if (stroke_selected) { // FIXME: DELETE
				((!) BirdFont.get_current_font ().get_glyph ("e")).add_path (p);
			}
		}
		
		while (paths_has_intersection (r, out p1, out p2)) {	
			if (merge_path (p1, p2, out m, out error)) {
				r.paths.remove (p1);
				r.paths.remove (p2);
				
				foreach (Path np in m.paths) {
					np.remove_points_on_points ();
					r.add (np);
				}
				
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
			p.close ();
			p.recalculate_linear_handles ();
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
		int c;
		
		foreach (Path p in r.paths) {
			c = counters (r, p); // FIXME: this needs improvements
			
			if (c % 2 == 0) {
				
				if (c == 0) {
					p.force_direction (Direction.CLOCKWISE);
				} else if (!p.is_clockwise ()) {
					remove.add (p);
				}
				
				if (stroke_selected)
					((!) BirdFont.get_current_font ().get_glyph ("m")).add_path (p);
					
			} else {
				if (stroke_selected)
					((!) BirdFont.get_current_font ().get_glyph ("n")).add_path (p);
					
				if (p.is_clockwise ()) {
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

	// When one point is on the outside is the path not a counter path.
	// Path.counters works the other way around.
	public static int counters (PathList pl, Path path) {
		int inside_count = 0;
		bool inside;
		
		foreach (Path p in pl.paths) {
			inside = false;
			
			if (p.points.size > 1
				&& p != path 
				&& path.boundaries_intersecting (p)
				&& !has_remove_parts (p)) {
				
				// FIXME: all points can be corners in counter paths
				foreach (EditPoint ep in path.points) {
					if (is_inside (ep, p)) {
						inside = true;
					}
				}

				if (inside) {
					inside_count++; 
				}
			}
		}
		
		return inside_count;
	}

	public static bool is_inside (EditPoint point, Path path) {
		EditPoint prev;
		bool inside = false;
		
		if (path.points.size <= 1) {
			return false;
		}
		
		if (!(path.xmin <= point.x <= path.xmax)) {
			return false;
		}
		
		if (!(path.ymin <= point.y <= path.ymax)) {
			return false;
		}
				
		prev = path.points.get (path.points.size - 1);
		
 		foreach (EditPoint p in path.points) {
			if (p.x == point.x && p.y == point.y) {
				point.color = Color.green ();
				// inside = !inside;
				return false; // FIXME: double check
			} else if  ((p.y > point.y) != (prev.y > point.y) 
 				&& point.x < (prev.x - p.x) * (point.y - p.y) / (prev.y - p.y) + p.x) {
 				inside = !inside;
 			}
 			
 			prev = p;
		}
		
		return inside;
	}
	
	public static int insides (EditPoint point, Path path) {
		EditPoint prev;
		int inside = 0;
		
		if (path.points.size <= 1) {
			return 0;
		}
				
		prev = path.get_last_point ();

		foreach (EditPoint start in path.points) {
			if (start.x == point.x && point.y == start.y) {
				inside++;
			} else if ((start.y > point.y) != (prev.y > point.y)
				&& point.x < (prev.x - start.x) * (point.y - start.y) / (prev.y - start.y) + start.x) {
				inside++;
			}
			
			prev = start;
		}
		
		return inside;
	}
	
	static bool merge_path (Path path1, Path path2, out PathList merged_paths, out bool error) {
		IntersectionList intersections;
		EditPoint ep1, next, p1, p2, pp1, pp2;
		Path path, other, merged;
		PathList r, other_paths, result;
		bool intersects;
		int s, i;
		double ix, iy, iix, iiy;
		bool merge = false;
		EditPoint intersection_point, other_intersection_point;
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
			if (!is_inside (e, original_path2)
				&& insides (e, original_path1) == 1) { // FIXME: later as well
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
				if (!is_inside (e, original_path2)) {
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
		
		path1_direction = is_clockwise (original_path1);
		path2_direction = is_clockwise (original_path1);
		
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
						if (!is_inside (ep1, original_path1)) {
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
					if (is_clockwise (original_path2)) {
						ps = new PointSelection (ep1, merged);
						if (is_inside_of_path (ps, result, out outline)) {
							ep1.deleted = true;
							ep1.color = Color.red ();
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

			foreach (Path np in result.paths) {
				Path p = np.copy ();
				bool has_direction = true;
				
				p.remove_points_on_points ();
				
				if (has_direction) {
					p.close ();
					reset_intersections (p);
					merged_paths.append (get_parts (p));
					p.update_region_boundaries ();
					p.recalculate_linear_handles ();
				}
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
	
	public static int counters_in_point_in_path (Path p, EditPoint ep) {
		int inside_count = 0;
		bool inside;
		
		if (p.points.size > 1) {
			inside = true;
			
			if (!is_inside (ep, p)) {
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

	public static bool has_points_outside (PathList pl, Path p) {
		if (pl.paths.size != 2) {
			warning ("Stroke should only create two parts.");
			return false;
		}
		
		foreach (Path path in pl.paths) {
			if (path != p) {
				foreach (EditPoint ep in p.points) {
					if (!is_inside (ep, path)) {
						return true;
					}
				}
			}
		}
		
		return false;
	}

	static bool is_clockwise (Path p) {
		double sum = 0;
		
		return_val_if_fail (p.points.size >= 3, true);
		
		foreach (EditPoint e in p.points) {
			if ((e.flags & EditPoint.NEW_CORNER) == 0 && (e.flags & EditPoint.REMOVE_PART) == 0) {
				sum += e.get_direction ();
			}
		}
		
		return sum > 0;
	}	
	
	static void flatten (Path path, double stroke_width) {
		EditPoint start, end, new_point;
		double px, py;
		int size, i, added_points;
		double step = 0.5;
		bool open = path.is_open ();
		bool flat;
		
		path.add_hidden_double_points ();
		
		size = open ? path.points.size - 1 : path.points.size;

		i = 0;
		added_points = 0;
		while (i < size) {
			start = path.points.get (i);
			end = path.points.get ((i + 1) % path.points.size);
			
			Path.get_point_for_step (start, end, step, out px, out py);
			
			if (start.type == PointType.HIDDEN) {
				start.tie_handles = false;
				start.deleted = true;
			}

			if (end.type == PointType.HIDDEN) {
				start.tie_handles = false;
				end.tie_handles = false;
				end.deleted = true;
			}
			
			flat = is_flat (start.x, start.y, px, py, end.x, end.y, 0.05 * stroke_width) 
				&& ((px - start.x) > 0) == ((start.get_right_handle ().x - start.x) > 0)
				&& ((py - start.y) > 0) == ((start.get_right_handle ().y - start.y) > 0);
			
			if (unlikely (added_points > 20)) {
				warning ("More than four points added in stroke.");
				added_points = 0;
				i++;
			} else if (!flat
					&& Path.distance (start.x, px, start.y, py) > 0.1 * stroke_width
					&& Path.distance (end.x, px, end.y, py) > 0.1 * stroke_width) {
				new_point = new EditPoint (px, py);

				new_point.prev = start;
				new_point.next = end;
				path.insert_new_point_on_path (new_point, step);
				added_points++;
				size++;
			} else {
				added_points = 0;
				i++;
			}
		}
		
		path.remove_deleted_points ();	
		path.remove_points_on_points ();
	}
}

}
