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

public enum LineCap {
	BUTT,
	SQUARE,
	ROUND
}

public class StrokeTool : GLib.Object {
	
	public static double stroke_width = 0;
	public static bool add_stroke = false;
	
	public static bool show_stroke_tools = false;
	public static bool convert_stroke = false;
	
	public static LineCap line_cap = LineCap.BUTT;
	
	StrokeTask task;

	public StrokeTool () {
		task = new StrokeTask.none ();
	}
	
	public StrokeTool.with_task (StrokeTask cancelable_task) {
		task = cancelable_task;
	}

	/** Create strokes for the selected outlines. */
	public void stroke_selected_paths () {
		Glyph g = MainWindow.get_current_glyph ();
		PathList paths = new PathList ();
		
		convert_stroke = true;	
		g.store_undo_state ();
		
		foreach (Path p in g.active_paths) {
			if (p.stroke > 0) {
				paths.append (p.get_completed_stroke ());
			}
		}

		if (paths.paths.size > 0) {
			foreach (Path p in g.active_paths) {
				g.layers.remove_path (p);
			}
			
			g.active_paths.clear ();

			foreach (Path np in paths.paths) {
				g.add_path (np);
				g.active_paths.add (np);
			}
			
			PenTool.update_orientation ();
			
			GlyphCanvas.redraw ();
		}
		
		PenTool.update_orientation ();
		convert_stroke = false;
	}
	
	public PathList get_stroke_fast (Path path, double thickness) {
		PathList o;
		Path stroke;
		StrokeTool s = new StrokeTool ();
		
		stroke = path.copy ();
		stroke.remove_points_on_points (0.1);
		o = s.create_stroke (stroke, thickness);
				
		return o;
	}
	
	public PathList get_stroke (Path path, double thickness) {
		PathList o, m;
		Path stroke;
		
		if (task.is_cancelled ()) {
			return new PathList ();
		}
		
		stroke = path.copy ();
		stroke.remove_points_on_points (0.1);
		o = create_stroke (stroke, thickness);
		o = get_all_parts (o);
		o = remove_intersection_paths (o);
		o = merge (o);
				
		m = new PathList ();
		foreach (Path p in o.paths) {
			m.add (simplify_stroke (p));
		}
				
		return m;
	}

	void reset_flags (PathList o) {
		foreach (Path p in o.paths) {
			foreach (EditPoint ep in p.points) {
				ep.flags &= ~(EditPoint.INTERSECTION 
						| EditPoint.COPIED 
						| EditPoint.NEW_CORNER 
						| EditPoint.SELF_INTERSECTION);
			}
			p.update_region_boundaries ();
		}
	}

	public void merge_selected_paths () {
		Glyph g = MainWindow.get_current_glyph ();
		PathList o = new PathList ();
		PathList r;
		PathList new_paths = new PathList ();
		bool error = false;
		
		g.store_undo_state ();

		foreach (Path p in g.active_paths) {
			if (p.stroke == 0) {
				o.add (p);
			} else {
				o.append (p.get_completed_stroke ());
			}
		}
						
		foreach (Path p in o.paths) {
			p.close ();
			remove_single_point_intersections (p);
		}
		
		o = remove_overlap (o, out error);
		
		if (error) {
			warning ("merge_selected_paths failed.");
			return;
		}
	
		reset_flags (o);
		new_paths.append (o);
		
		for (int merge = 0; merge < 2; merge++) { 
			for (int i = 0; i < o.paths.size; i++) {
				for (int j = 0; j < o.paths.size; j++) {
					Path p1, p2;

					if (task.is_cancelled ()) {
						return;
					}
				
					p1 = o.paths.get (i);
					p2 = o.paths.get (j);
					
					if (merge == 0) {
						if (p1.is_clockwise () == p2.is_clockwise ()) {
							continue;
						}
					}

					if (merge == 1) {
						if (p1.is_clockwise () != p2.is_clockwise ()) {
							continue;
						}						
					}
										
					if (i == j) {
						continue;
					} 
				
					r = merge_selected (p1, p2, false, out error);
					
					if (error) {
						warning ("Can't merge selected paths.");
						return;
					}

					remove_merged_curve_parts (r);
					
					if (r.paths.size > 0) {
						reset_flags (r);
						new_paths.append (r);

						new_paths.remove (p1);
						new_paths.remove (p2);
						
						o.remove (p1);
						o.remove (p2);
					
						o.append (r);
											
						i = 0;
						j = 0;
					}
				}
			}
		}

		if (task.is_cancelled ()) {
			return;
		}
				
		foreach (Path p in g.active_paths) {
			g.delete_path (p);
		}
		
		g.clear_active_paths ();
	
		remove_merged_curve_parts (new_paths);
	
		foreach (Path p in new_paths.paths) {
			g.add_path (p);
			g.add_active_path (null, p);
		}
		
		PenTool.update_orientation ();
		GlyphCanvas.redraw ();
	}

	void remove_single_point_intersections (Path p) {
		PointSelection ps;

		p.remove_points_on_points ();
				
		for (int i = 0; i < p.points.size; i++) {
			EditPoint ep = p.points.get (i);
			EditPoint next = p.points.get ((i + 1) % p.points.size);
			if (fabs (ep.get_right_handle ().angle - ep.get_left_handle ().angle) % (2 * PI) < 0.01) {
				if (ep.get_right_handle ().length > 0 && ep.get_left_handle ().length > 0) {
					ps = new PointSelection (ep, p);
					PenTool.remove_point_simplify (ps);
				}
			} else if (Path.distance_to_point (ep, next) < 0.01) {
				ps = new PointSelection (ep, p);
				PenTool.remove_point_simplify (ps);
			}
		}
	}
	
	PathList remove_overlap (PathList pl, out bool error) {
		PathList r = new PathList ();
		
		error = false;
		
		foreach (Path p in pl.paths) {
			PathList m = merge_selected (p, new Path (), true, out error);
			
			if (error) {
				warning ("Can't remove overlap.");
				return pl;
			}
			
			if (m.paths.size > 0) {
				r.append (m);
			} else {
				r.add (p);
			}
		}
		
		return r;
	}

	void remove_merged_curve_parts (PathList r) {
		Gee.ArrayList<Path> remove = new Gee.ArrayList<Path> ();
		PathList flat = new PathList ();
		
		foreach (Path p in r.paths) {
			p.update_region_boundaries ();
			flat.add (p.flatten ());
		}
			
		foreach (Path p in r.paths) {
			PathList pl = get_insides (flat, p);
			
			int counters = 0;
			int clockwise = 0;
	
			foreach (Path i in pl.paths) {
				if (i.is_clockwise ()) {
					clockwise++;
				} else {
					counters++;
				}
			}
			
			if (p.is_clockwise ()) {
				if (clockwise - 1 > counters) {
					remove.add (p);
					break;
				}
			} else {
				if (clockwise < counters - 1) {
					remove.add (p);
					break;
				}
			}
		}

		foreach (Path p in remove) {
			r.paths.remove (p);
			remove_merged_curve_parts (r);
			return;
		}
	}
	
	public PathList merge_selected (Path path1, Path path2,
		bool self_intersection, out bool error) {
			
		PathList flat = new PathList ();
		PathList o = new PathList ();
		PathList pl = new PathList ();
		PathList r = new PathList ();
		
		pl.add (path1);
		pl.add (path2);
		
		error = false;
		
		if (!self_intersection) {
			if (!path1.boundaries_intersecting (path2)) {
				return r;
			}
		}
		
		foreach (Path p in pl.paths) {
			if (p.stroke == 0) {
				o.add (p);
				flat.add (p.copy ().flatten (50));
			}
		}
		
		flat = merge (flat);	

		foreach (Path pp in o.paths) {
			pp.remove_points_on_points (0.1);
		}
		
		bool has_split_point = false;
		foreach (Path p in flat.paths) {
			foreach (EditPoint ep in p.points) {
				if ((ep.flags & EditPoint.SPLIT_POINT) > 0) {
					foreach (Path pp in o.paths) {
						EditPoint lep = new EditPoint ();
						
						if (pp.points.size > 1) {
							pp.get_closest_point_on_path (lep, ep.x, ep.y, null, null);
							
							if (Path.distance_to_point (ep, lep) < 0.1) {								
								EditPoint lep2 = new EditPoint ();
								pp.get_closest_point_on_path (lep2, ep.x, ep.y, lep.prev, lep.next);
								
								if (lep.prev != null) {
									lep.get_left_handle ().type = lep.get_prev ().get_right_handle ().type;
								} else {
									lep.get_left_handle ().type = pp.get_last_point ().get_right_handle ().type;
								}

								if (lep.next != null) {
									lep.get_right_handle ().type = lep.get_next ().get_left_handle ().type;
								} else {
									lep.get_left_handle ().type = pp.get_first_point ().get_right_handle ().type;
								}

								if (lep2.prev != null) {
									lep2.get_left_handle ().type = lep2.get_prev ().get_right_handle ().type;
								} else {
									lep2.get_left_handle ().type = pp.get_first_point ().get_right_handle ().type;
								}

								if (lep2.next != null) {
									lep2.get_right_handle ().type = lep2.get_next ().get_left_handle ().type;
								} else {
									lep2.get_left_handle ().type = pp.get_last_point ().get_right_handle ().type;
								}
								
								// self intersection				
								if (Path.distance_to_point (ep, lep2) < 0.1
									&& Path.distance_to_point (ep, lep) < 0.1) {
									
									if (Path.distance_to_point (lep, (!) lep.prev) < 0.001) {
										continue;
									}

									if (Path.distance_to_point (lep, (!) lep.next) < 0.001) {
										continue;
									}
									
									add_double_point_at_intersection (pp, lep, ep);
									add_double_point_at_intersection (pp, lep2, ep);
																
									pp.insert_new_point_on_path (lep);
									pp.insert_new_point_on_path (lep2);

									lep.flags |= EditPoint.SELF_INTERSECTION;
									lep2.flags |= EditPoint.SELF_INTERSECTION;
									
									lep.tie_handles = false;
									lep.reflective_point = false;
									lep2.tie_handles = false;
									lep2.reflective_point = false;
								} else {
									if (lep.prev != null && Path.distance_to_point (lep, (!) lep.prev) < 0.00000001) {
										lep.get_prev ().flags |= EditPoint.INTERSECTION;
										lep.get_prev ().tie_handles = false;
										lep.get_prev ().reflective_point = false;
										continue;
									}

									if (lep.next != null && Path.distance_to_point (lep, (!) lep.next) < 0.00000001) {
										lep.get_next ().flags |= EditPoint.INTERSECTION;
										lep.get_next ().tie_handles = false;
										lep.get_next ().reflective_point = false;
										continue;
									}
									
									add_double_point_at_intersection (pp, lep, ep);
									pp.insert_new_point_on_path (lep);
									lep.flags |= EditPoint.INTERSECTION;
									lep.tie_handles = false;
									lep.reflective_point = false;
								}
								
								has_split_point = true;
							}
						}
					}
				}
			}
		}
						
		if (!has_split_point) {
			return r;
		}

		// remove double intersection points 
		EditPoint prev = new EditPoint ();
		foreach (Path pp in o.paths) {
			foreach (EditPoint ep in pp.points) {
				if (((prev.flags & EditPoint.SELF_INTERSECTION) > 0 || (prev.flags & EditPoint.INTERSECTION) > 0)
					&& ((ep.flags & EditPoint.SELF_INTERSECTION) > 0 || (ep.flags & EditPoint.INTERSECTION) > 0)
					&& fabs (ep.x - prev.x) < 0.2
					&& fabs (ep.y - prev.y) < 0.2) {
					prev.deleted = true;
				}
				
				prev = ep;
			}
		}
		
		foreach (Path pp in o.paths) {
			pp.remove_deleted_points ();
		}

		foreach (Path p in o.paths) {
			foreach (EditPoint ep in p.points) {
				ep.flags &= ~EditPoint.COPIED;
			}
		}
		
		return_val_if_fail (o.paths.size == 2, r);

		Path p1, p2;
		
		p1 = o.paths.get (0);
		p2 = o.paths.get (1);
		PathList parts = new PathList ();
		
		if (self_intersection) {
			// remove overlap
			PathList self_parts;
			
			self_parts = remove_self_intersections (p1, out error);
			
			if (error) {
				warning ("remove_self_intersections failed");
				return new PathList ();
			}
			
			parts.append (self_parts);
		} else {
			// merge two path
			PathList merged_paths = merge_paths_with_curves (p1, p2);
			
			if (merged_paths.paths.size > 0) {
				parts.append (merged_paths);
			} else {
				parts.add (p1);
				parts.add (p2);
			}
		}
		
		foreach (Path p in parts.paths) {
			reset_intersections (p);
		}
		
		reset_intersections (path1);
		reset_intersections (path2);

		return parts;
	}
	
	/** Add hidden double points to make sure that the path does not
	 * change when new points are added to a 2x2 path.
	 */
	void add_double_point_at_intersection (Path pp, EditPoint lep, EditPoint ep) {
		EditPoint prev;
		EditPoint next;
		EditPoint hidden;
		double px, py;
		
		if (lep.get_right_handle ().type == PointType.DOUBLE_CURVE
			|| lep.get_right_handle ().type == PointType.LINE_DOUBLE_CURVE) {
				
			return_if_fail (lep.prev != null);
			return_if_fail (lep.next != null);
			
			prev = lep.get_prev ();
			next = lep.get_next ();
			hidden = new EditPoint (0, 0, PointType.QUADRATIC);
			
			px = (next.get_left_handle ().x + prev.get_right_handle ().x) / 2.0;
			py = (next.get_left_handle ().y + prev.get_right_handle ().y) / 2.0;
			hidden.independent_x = px;
			hidden.independent_y = py;
			
			hidden.get_right_handle ().x = next.get_left_handle ().x;
			hidden.get_right_handle ().y = next.get_left_handle ().y;
			hidden.get_left_handle ().x = prev.get_right_handle ().x;
			hidden.get_left_handle ().y = prev.get_right_handle ().y;
			
			pp.add_point_after (hidden, prev);

			hidden.get_right_handle ().type = PointType.QUADRATIC;
			hidden.get_left_handle ().type = PointType.QUADRATIC;

			prev.get_right_handle ().type = PointType.QUADRATIC;
			next.get_left_handle ().type = PointType.QUADRATIC;
			prev.type = PointType.QUADRATIC;
			next.type = PointType.QUADRATIC;
						
			pp.get_closest_point_on_path (lep, ep.x, ep.y, null, null);
		}
	}
	
	PathList remove_self_intersections (Path original, out bool error) {
		Path merged = new Path ();
		IntersectionList intersections = new IntersectionList ();
		EditPoint ep1, ep2, found;
		double d;
		double min_d;
		Path current;
		bool found_intersection;
		PathList parts;
		int i = 0;
		Path path = original.copy ();

		error = false;

		path.remove_points_on_points ();
		parts = new PathList ();

		if (path.points.size <= 1) {
			return parts;
		}

		// reset copied points
		foreach (EditPoint n in path.points) {
			n.flags &= ~EditPoint.COPIED;
		}
				
		// build list of intersection points
		for (i = 0; i < path.points.size; i++) {
			ep1 = path.points.get (i);

			if ((ep1.flags & EditPoint.SELF_INTERSECTION) > 0
				&& (ep1.flags & EditPoint.COPIED) == 0) {
				ep1.flags |= EditPoint.COPIED;
				
				found = new EditPoint ();
				min_d = double.MAX;
				found_intersection = false;
				
				for (int j = 0; j < path.points.size; j++) {
					ep2 = path.points.get (j);
					d = Path.distance_to_point (ep1, ep2);
					if ((ep2.flags & EditPoint.COPIED) == 0
						&& (ep2.flags & EditPoint.SELF_INTERSECTION) > 0) {
						if (d < min_d) {
							min_d = d;
							found_intersection = true;
							found = ep2;
						}
					}
				}

				if (!found_intersection) {
					warning (@"No self intersection:\n$(ep1)");
					return parts;
				}

				ep1.tie_handles = false;
				ep1.reflective_point = false;
				found.tie_handles = false;
				found.reflective_point = false;
				
				found.flags |= EditPoint.COPIED;
				Intersection intersection = new Intersection (ep1, path, found, path);
				intersection.self_intersection = true;
				intersections.points.add (intersection);
			}
		}
		
		// reset copy flag
		foreach (EditPoint n in path.points) {
			n.flags &= ~EditPoint.COPIED;
		}
		
		if (intersections.points.size == 0) {
			warning ("No intersection points.");				
			error = true;
			return parts;
		}
		
		current = path;
		current.reverse ();
		
		while (true) {
			EditPoint modified;
			i = 0;
			Intersection new_start = new Intersection.empty ();
			ep1 = current.points.get (i);
			current = path;
			
			modified = ep1.copy ();
			
			for (i = 0; i < current.points.size; i++) {
				ep1 = current.points.get (i);
				modified = ep1.copy ();
				if ((ep1.flags & EditPoint.COPIED) == 0
					&& (ep1.flags & EditPoint.SELF_INTERSECTION) == 0) {
					break;
				}
			}	
			
			if (i >= current.points.size || (ep1.flags & EditPoint.COPIED) > 0) {
				// all points have been copied
				break;
			}
			
			while (true) {
				
				if ((ep1.flags & EditPoint.SELF_INTERSECTION) > 0) {
					bool other;
					EditPointHandle handle;
					
					handle = ep1.get_left_handle ();
					new_start = intersections.get_point (ep1, out other);
					
					i = index_of (current, other ? new_start.point : new_start.other_point);
					
					if (!(0 <= i < current.points.size)) {
						warning (@"Index out of bounds. ($i)");
						return parts;
					}
					
					ep1 = current.points.get (i);
					modified = ep1.copy ();
					modified.left_handle.move_to_coordinate (handle.x, handle.y);
				} 
				
				if ((ep1.flags & EditPoint.COPIED) > 0) {
					merged.close ();

					merged.close ();
					merged.create_list ();
					parts.add (merged);
						
					foreach (EditPoint n in merged.points) {
						n.flags &= ~EditPoint.SELF_INTERSECTION;
					}
					
					merged.reverse ();
					
					merged = new Path ();
					
					break;
				}
				
				// adjust the other handle
				if ((ep1.flags & EditPoint.INTERSECTION) > 0) {
					ep1.left_handle.convert_to_curve ();
					ep1.right_handle.convert_to_curve ();
					ep1.tie_handles = false;
					ep1.reflective_point = false;
				}
				
				// add point to path
				ep1.flags |= EditPoint.COPIED;
				merged.add_point (modified.copy ());
				
				i++;
				ep1 = current.points.get (i % current.points.size);
				modified = ep1.copy ();
			}
			
			ep1.flags |= EditPoint.COPIED;
			
		}
		
		return parts;
	}
	
	PathList merge_paths_with_curves (Path path1, Path path2) {
		PathList r = new PathList ();
		IntersectionList intersections = new IntersectionList ();
		EditPoint ep1, ep2, found;
		double d;
		double min_d;
		Path current;
		bool found_intersection;
		Path flat1, flat2;
		
		if (path1.points.size <= 1 || path2.points.size <= 1) {
			return r;
		}

		flat1 = path1.flatten ();
		flat2 = path2.flatten ();

		// reset copied points
		foreach (EditPoint n in path2.points) {
			n.flags &= ~EditPoint.COPIED;
		}
						
		// build list of intersection points
		for (int i = 0; i < path1.points.size; i++) {
			ep1 = path1.points.get (i);
			
			if ((ep1.flags & EditPoint.INTERSECTION) > 0) {
				found = new EditPoint ();
				min_d = double.MAX;
				found_intersection = false;
				for (int j = 0; j < path2.points.size; j++) {
					ep2 = path2.points.get (j);
					d = Path.distance_to_point (ep1, ep2);
					if ((ep2.flags & EditPoint.COPIED) == 0
						&& (ep2.flags & EditPoint.INTERSECTION) > 0) {
						if (d < min_d && d < 0.1) {
							min_d = d;
							found_intersection = true;
							found = ep2;
						}
					}
				}

				if (!found_intersection) {
					warning (@"No intersection for:\n $(ep1)");
					continue;
				}
				
				found.flags |= EditPoint.COPIED;
				
				ep1.tie_handles = false;
				ep1.reflective_point = false;
				found.tie_handles = false;
				found.reflective_point = false;
				Intersection intersection = new Intersection (ep1, path1, found, path2);
				intersections.points.add (intersection);
			}
		}
		
		// reset copy flag
		foreach (EditPoint n in path1.points) {
			n.flags &= ~EditPoint.COPIED;
		}
		
		foreach (EditPoint n in path2.points) {
			n.flags &= ~EditPoint.COPIED;
		}
		
		if (intersections.points.size == 0) {
			warning ("No intersection points.");
			return r;
		}
		
		Path new_path = new Path ();
		current = path1;
		while (true) {
			// find a beginning of a new part
			bool find_parts = false;
			Intersection new_start = new Intersection.empty ();
			foreach (Intersection inter in intersections.points) {
				if (!inter.done && !find_parts) {
					find_parts = true;
					new_start = inter;
					current = new_start.path;
				}
			}

			if (new_path.points.size > 0) {
				new_path.close ();
				new_path.recalculate_linear_handles ();
				new_path.update_region_boundaries ();
				r.add (new_path);
			}
						
			if (!find_parts) { // no more parts
				break;
			}
			
			if ((new_start.get_point (current).flags & EditPoint.COPIED) > 0) {
				current = new_start.get_other_path (current);
			} 
			
			int i = index_of (current, new_start.get_point (current));
			
			if (i < 0) {
				warning ("i < 0");
				return r;
			}

			EditPoint previous = new EditPoint ();
			new_path = new Path ();
			ep1 = current.points.get (i);
			current = new_start.get_other_path (current); // swap at first iteration
			bool first = true;
			while (true) {
				if ((ep1.flags & EditPoint.INTERSECTION) > 0) {
					bool other;
					
					previous = ep1;
					
					if (likely (intersections.has_point (ep1))) {
						new_start = intersections.get_point (ep1, out other);
						current = new_start.get_other_path (current);
						i = index_of (current, new_start.get_point (current));
						
						if (!(0 <= i < current.points.size)) {
							warning (@"Index out of bounds. ($i)");
							return r;
						}
						
						ep1 = current.points.get (i);
						ep2 = current.points.get ((i + 1) % current.points.size); 
					
						double px, py;
						
						Path.get_point_for_step (ep1, ep2, 0.5, out px, out py);
						bool inside = (current == path1 && flat2.is_over_coordinate (px, py))
							|| (current == path2 && flat1.is_over_coordinate (px, py));
						
						bool other_inside = (current != path1 && flat2.is_over_coordinate (px, py))
							|| (current != path2 && flat1.is_over_coordinate (px, py));
											
						if (inside && !other_inside) {
							current = new_start.get_other_path (current);
							i = index_of (current, new_start.get_point (current));

							if (!(0 <= i < current.points.size)) {
								warning (@"Index out of bounds. ($i >= $(current.points.size)) ");
								return r;
							}
							
							new_start.done = true;
							ep1 = current.points.get (i);
						} 
						
						inside = (current == path1 && flat2.is_over_coordinate (px, py))
							|| (current == path2 && flat1.is_over_coordinate (px, py));
		
						if (first) {
							Path c = new_start.get_other_path (current);
							if (c.points.size >= 1) {
								previous = c.get_first_point ();
							}
							
							first = false;
						}
					}
				}
				
				if ((ep1.flags & EditPoint.COPIED) > 0) {
					new_path.close ();
					
					if (new_path.points.size >= 1) {
						EditPoint first_point = new_path.get_first_point ();
						EditPointHandle h;
						if ((ep1.flags & EditPoint.INTERSECTION) > 0) {
							first_point.left_handle.move_to_coordinate (previous.left_handle.x, previous.left_handle.y);
							
							if (first_point.next != null) {
								h = first_point.get_next ().get_left_handle ();
								h.process_connected_handle ();
							}
						}
					}
					
					break;
				}

				// adjust the other handle
				if ((ep1.flags & EditPoint.INTERSECTION) > 0) {
					ep1.left_handle.convert_to_curve ();
					ep1.right_handle.convert_to_curve ();
				}
				
				// add point to path
				ep1.flags |= EditPoint.COPIED;
				new_path.add_point (ep1.copy ());

				if ((ep1.flags & EditPoint.INTERSECTION) > 0) { 
					new_path.get_last_point ().left_handle.move_to_coordinate (previous.left_handle.x, previous.left_handle.y);
				}

				i++;
				ep1 = current.points.get (i % current.points.size);
			}
			
			ep1.flags |= EditPoint.COPIED;
			
			if (!new_start.done) {
				new_start.done = (new_start.get_other_point (current).flags & EditPoint.COPIED) > 0;
			}
		}
		
		return r;
	}
	
	Path simplify_stroke (Path p) {
		Path simplified = new Path ();
		Path segment, added_segment;
		EditPoint ep, ep_start, last, first, segment_last;
		int start, stop;
		int j;
		EditPointHandle last_handle;

		last_handle = new EditPointHandle.empty ();
		
		segment_last = new EditPoint ();
		last = new EditPoint ();
		
		p.remove_points_on_points ();
		
		foreach (EditPoint e in p.points) {
			PenTool.convert_point_type (e, PointType.CUBIC);
		}
		
		bool has_curve_start = true;
		foreach (EditPoint e in p.points) {
			e.flags &= ~EditPoint.NEW_CORNER;
			
			if ((e.flags & EditPoint.CURVE) == 0) {
				p.set_new_start (e);
				has_curve_start = false;
				break;
			}
		}
		
		if (has_curve_start) {
			warning ("Curve start");
		}
		
		for (int i = 0; i < p.points.size; i++) {
			ep = p.points.get (i);
			
			if ((ep.flags & EditPoint.CURVE) > 0) {
				start = i;
				for (j = start + 1; j < p.points.size; j++) {
					ep = p.points.get (j);
					if ((ep.flags & EditPoint.CURVE) == 0) {
						break;
					}
				}
	
				if (task.is_cancelled ()) {
					return new Path ();
				}

				
				stop = j;
				start -= 1;
				
				if (start < 0) {
					warning ("start < 0");
					start = 0;
				}

				if (stop >= p.points.size) {
					warning ("stop >= p.points.size");
					stop = p.points.size - 1;
				}
				
				ep_start = p.points.get (start);
				ep = p.points.get (stop);
				
				double l = Path.distance_to_point (ep_start, ep);
				segment = fit_bezier_path (p, start, stop, 0.00001 * l * l);

				added_segment = segment.copy ();	
				
				if (simplified.points.size > 0) {
					last = simplified.get_last_point ();
				}	
				
				if (added_segment.points.size > 0) {
					segment_last = added_segment.get_last_point ();
					first = added_segment.get_first_point ();
					segment_last.right_handle = ep_start.get_right_handle ().copy ();
					
					if (simplified.points.size > 1) {
						last = simplified.delete_last_point ();
					}
					
					first.set_tie_handle (false);
					last.set_tie_handle (false);
					
					last.get_right_handle ().x = first.get_right_handle ().x;
					last.get_right_handle ().y = first.get_right_handle ().y;
					
					first.get_left_handle ().convert_to_curve ();
					first.get_left_handle ().x = last.get_left_handle ().x;
					first.get_left_handle ().y = last.get_left_handle ().y;
	
					last = added_segment.get_last_point ();
					last.right_handle = ep.get_right_handle ().copy ();
					added_segment.recalculate_linear_handles_for_point (last);
						
					simplified.append_path (added_segment);

					segment_last.right_handle = ep.get_right_handle ().copy ();
					
					if (added_segment.points.size > 0) {
						if (ep_start.get_right_handle ().is_line ()) {
							first = added_segment.get_first_point ();
							simplified.recalculate_linear_handles_for_point (first);
						}
					}
					
					last_handle = last.get_left_handle ();
				} else {
					warning ("No points in segment.");
				}
									
				i = stop;
			} else {
				simplified.add_point (ep.copy ());
			}
		}
		
		simplified.recalculate_linear_handles ();
		simplified.close ();
		remove_single_point_intersections (simplified);
		
		return simplified;
	}
	
	Path fit_bezier_path (Path p, int start, int stop, double error) {
		int index, size;
		Path simplified;
		double[] lines;
		double[] result;
		EditPoint ep;
		
		simplified = new Path ();

		return_val_if_fail (0 <= start < p.points.size, simplified);
		return_val_if_fail (0 <= stop < p.points.size, simplified);

		size = stop - start + 1;
		lines = new double[2 * size];
		
		index = 0;
				
		for (int i = start; i <= stop; i++) {
			ep = p.points.get (i);
			lines[index] = ep.x;
			index++;
			
			lines[index] = ep.y;
			index++;
		}
		
		return_val_if_fail (2 * size == index, new Path ());
		
		Gems.fit_bezier_curve_to_line (lines, error, out result);

		return_val_if_fail (!is_null (result), simplified);
		
		for (int i = 0; i + 7 < result.length; i += 8) {
			simplified.add_cubic_bezier_points (
				result[i], result[i + 1],
				result[i + 2], result[i + 3],
				result[i + 4], result[i + 5],
				result[i + 6], result[i + 7]);
		}
		
		return simplified;
	}
	
	PathList remove_intersection_paths (PathList pl) {
		PathList r = new PathList ();
		
		foreach (Path p in pl.paths) {
			if (p.points.size > 7) {
				r.add (p);
			} else if (!has_new_corner (p)) {
				r.add (p);
			} else if (counters (pl, p) == 0) {
				r.add (p);
			}
		}
		
		return r;
	}

	bool has_new_corner (Path p) {
		foreach (EditPoint ep in p.points) {
			if ((ep.flags & EditPoint.NEW_CORNER) > 0) {
				return true;
			}
		}
		
		return false;
	}

	void add_line_cap (Path path, Path stroke1, Path stroke2, bool last_cap) {
		if (path.line_cap == LineCap.SQUARE) {
			add_square_cap (path, stroke1, stroke2, last_cap);
		} else if (path.line_cap == LineCap.ROUND) {
			add_round_cap (path, stroke1, stroke2, last_cap);
		}
	}
	
	void add_round_cap (Path path, Path stroke1, Path stroke2, bool last_cap) {
		double px, py;
		double step, start_angle, stop_angle;
		double radius;
		EditPoint n, nstart, nend;
		Path cap = new Path ();

		EditPoint start, end;
		EditPointHandle last_handle;
		EditPoint first, last; 
		
		stroke1.remove_points_on_points ();
		stroke2.remove_points_on_points ();
		
		last_handle = path.get_first_point ().get_right_handle ();
		start = stroke1.get_last_point ();
		end = stroke2.get_first_point ();
		
		start_angle = last_handle.angle + PI / 2;
		stop_angle = start_angle + PI;	
					
		nstart = cap.add (start.x, start.y);
		radius = Path.distance_to_point (start, end) / 2;
		step = PI / 5;
		
		for (int j = 0; j < 5; j++) {
			double angle = start_angle + step * j;
			px = radius * cos (angle) + last_handle.parent.x;
			py = radius * sin (angle) + last_handle.parent.y;
			n = cap.add (px, py);
			
			n.type = PointType.LINE_CUBIC;
			n.get_right_handle ().type = PointType.LINE_CUBIC;
			n.get_left_handle ().type = PointType.LINE_CUBIC;
		}
		
		nend = cap.add (end.x, end.y);
				
		for (int i = 0; i < cap.points.size; i++) {
			cap.recalculate_linear_handles_for_point (cap.points.get (i));
		}
		
		int size = cap.points.size;

		for (int i = 1; i < size; i++) {
			n = cap.points.get (i);
			n.convert_to_curve ();
			n.set_tie_handle (true);
			n.process_tied_handle ();
		}

		int f = stroke1.points.size - 1;
		
		for (int i = 2; i < cap.points.size - 1; i++) {
			n = cap.points.get (i).copy ();
			stroke1.add_point (n);
		}

		cap.remove_points_on_points ();
		return_if_fail (0 < f < stroke1.points.size);
		
		first = stroke1.points.get (f);
		
		last = stroke1.get_last_point ();
		last.convert_to_curve ();
		
		last = stroke1.add_point (stroke2.get_first_point ());
		stroke2.delete_first_point ();

		last.convert_to_line ();
		stroke1.recalculate_linear_handles_for_point (last);
		
		last.next = stroke1.add_point (stroke2.get_first_point ()).get_link_item ();
		stroke2.delete_first_point ();
		
		last.get_left_handle ().convert_to_curve ();
		last.get_left_handle ().angle = last.get_right_handle ().angle + PI;
		last.flags = EditPoint.CURVE_KEEP;
								
		double a;
		double l;
		
		return_if_fail (cap.points.size > 1);
		
		a = (first.get_left_handle ().angle + PI) % (2 * PI);
		l = cap.points.get (1).get_right_handle ().length;
		
		first.get_right_handle ().convert_to_curve ();
		first.get_right_handle ().angle = a;
		first.get_right_handle ().length = l;
		
		a = (first.get_left_handle ().angle + PI) % (2 * PI);
		
		last.get_left_handle ().convert_to_curve ();
		last.get_left_handle ().angle = a;
		last.get_left_handle ().length = l;
	}
		
	void add_square_cap (Path path, Path stroke1, Path stroke2, bool last_cap) {
		EditPointHandle last_handle;
		EditPoint start;
		EditPoint end;
		EditPoint n;
		double x, y;
		double stroke_width = path.stroke / 2;

		last_handle = path.get_first_point ().get_right_handle ();
		start = stroke1.get_last_point ();
		end = stroke2.get_first_point ();

		y = sin (last_handle.angle - PI) * stroke_width;
		x = cos (last_handle.angle - PI) * stroke_width;
						
		n = stroke1.add (start.x + x, start.y + y);
		n.type = PointType.CUBIC;
		n.get_right_handle ().type = PointType.CUBIC;
		n.get_left_handle ().type = PointType.CUBIC;
		n.convert_to_line ();
		
		n = stroke1.add (end.x + x, end.y + y);
		n.type = PointType.CUBIC;
		n.get_right_handle ().type = PointType.CUBIC;
		n.get_left_handle ().type = PointType.CUBIC;
		n.convert_to_line ();
	}

	/** Create one stroke from the outline and counter stroke and close the 
	 * open endings.
	 * 
	 * @param path the path to create stroke for
	 * @param stroke for the outline of path
	 * @param stroke for the counter path
	 */
	Path merge_strokes (Path path, Path stroke, Path counter) {
			
		Path merged;
		EditPoint last_counter, first;

		merged = stroke.copy ();
		merged.reverse ();
		
		last_counter = new EditPoint ();
		first = new EditPoint ();
		
		add_line_cap (path, merged, counter, true);		
		path.reverse ();		
		
		add_line_cap (path, counter, merged, true);
		path.reverse ();
			
		merged.append_path (counter);

		merged.close ();
		merged.create_list ();
		merged.recalculate_linear_handles ();
		
		return merged;
	}

	public static void move_segment (EditPoint stroke_start, EditPoint stroke_stop, double thickness) {
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

	void add_corner (Path stroked, EditPoint previous, EditPoint next,
		EditPoint original, double stroke_width) {
		
		double ratio;
		double distance;
		EditPoint corner;
		double corner_x, corner_y;
		EditPointHandle previous_handle;
		EditPointHandle next_handle;
		EditPoint cutoff1, cutoff2;
		double adjusted_stroke = (stroke_width * 0.999999) / 2.0;
		bool d1, d2;
		
		previous_handle = previous.get_left_handle ();
		next_handle = next.get_right_handle ();
		
		previous_handle.convert_to_line ();
		next_handle.convert_to_line ();
		
		previous_handle.angle += PI;
		next_handle.angle += PI;
		
		Path.find_intersection_handle (previous_handle, next_handle, out corner_x, out corner_y);
		corner = new EditPoint (corner_x, corner_y, PointType.CUBIC);
		corner.convert_to_line ();
		
		previous_handle.angle -= PI;
		next_handle.angle -= PI;

		distance = Path.distance_to_point (corner, original);
		ratio = 1.5 * fabs (adjusted_stroke) / distance;

		double or = original.get_right_handle ().angle;
		double ol = original.get_left_handle ().angle;			

		if (previous.prev == null) { // FIXME: first point 
			warning ("Point before corner.");
			d1 = false;
			d2 = false;
		} else {
			d1 = corner.x - previous.x >= 0 == previous.x - previous.get_prev ().x >= 0;
			d2 = corner.y - previous.y >= 0 == previous.y - previous.get_prev ().y >= 0;		
		}
		
		if (ratio > 1) {
			if (!d1 && !d2) {
				return;
			} else {
				stroked.add_point (corner);
			}
		} else {
		
			cutoff1 = new EditPoint ();
			cutoff1.set_point_type (previous.type);
			cutoff1.convert_to_line ();
			
			cutoff2 = new EditPoint ();
			cutoff2.set_point_type (previous.type);
			cutoff2.convert_to_line ();

			if (fabs (or - ol) < 0.001) {
				cutoff1.x = previous.x + 1.5 * fabs (adjusted_stroke) * -cos (or);
				cutoff1.y = previous.y + 1.5 * fabs (adjusted_stroke) * -sin (or);

				cutoff2.x = next.x + 1.5 * fabs (adjusted_stroke) * -cos (or);
				cutoff2.y = next.y + 1.5 * fabs (adjusted_stroke) * -sin (or);
			} else {
				cutoff1.x = previous.x + (corner.x - previous.x) * ratio;
				cutoff1.y = previous.y + (corner.y - previous.y) * ratio;

				cutoff2.x = next.x + (corner.x - next.x) * ratio;
				cutoff2.y = next.y + (corner.y - next.y) * ratio;
			}
			
			if (!cutoff1.is_valid () || cutoff2.is_valid ()) {
				cutoff1 = stroked.add_point (cutoff1);
				cutoff2 = stroked.add_point (cutoff2);
			}
			
			stroked.recalculate_linear_handles_for_point (cutoff1);
			stroked.recalculate_linear_handles_for_point (cutoff2);

			// self intersection
			if (!d1 && !d2) { 
				cutoff1.deleted = true;
				cutoff2.deleted = true;
				
				stroked.remove_deleted_points ();
				return;
			}
			
			if (distance > 4 * stroke_width) {
				previous.flags = EditPoint.NONE;
				next.flags = EditPoint.NONE;
			} else {
				previous.flags |= EditPoint.NEW_CORNER;
				next.flags |= EditPoint.NEW_CORNER;
			}
		}
	}

	PathList get_parts (Path path) {
		PathList intersections;
		PathList r;
		
		r = get_parts_self (path);
		intersections = new PathList ();
		
		foreach (Path p in r.paths) {
			intersections.add (p);
		}

		return intersections;
	}
	
	bool split_corner (PathList pl) {
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

	bool split_segment (Path p, EditPoint first, EditPoint next, EditPoint p1, EditPoint p2, out PathList result) {
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
			
	PathList get_parts_self (Path path, PathList? paths = null) {
		PathList pl;
		PathList r;
		
		if (task.is_cancelled ()) {
			return new PathList ();
		}

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


	bool has_intersection_points (Path path) {
		foreach (EditPoint p in path.points) {
			if ((p.flags & EditPoint.INTERSECTION) > 0) {
				return true;
			} 
		}
		return false;
	}
	
	/** Split one path at intersection points in two parts. */
	PathList split (Path path) {
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

	PathList process_deleted_control_points (Path path) {
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

	PathList get_remaining_points (Path old_path) {
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
	
	bool has_self_intersection (Path path) {
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
	
	bool add_self_intersection_points (Path path, bool only_offsets = false) {
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
	
	EditPoint add_intersection (Path path, EditPoint prev, EditPoint next, double px, double py, Color? c = null) {
		Gee.ArrayList<EditPoint> n = new Gee.ArrayList<EditPoint> ();
		EditPoint ep1 = new EditPoint ();
		EditPoint ep2 = new EditPoint ();
		EditPoint ep3 = new EditPoint ();
		double d;
		
		if (next == path.get_first_point ()) {
			ep1.prev = null;
		} else {
			ep1.prev = prev;
		}
				
		ep1.prev = prev;
		ep1.next = ep2;
		ep1.flags |= EditPoint.NEW_CORNER | EditPoint.SPLIT_POINT;
		ep1.type = prev.type;
		ep1.x = px;
		ep1.y = py;
		ep1.color = c;
		n.add (ep1);

		ep2.prev = ep1;
		ep2.next = ep3;
		ep2.flags |= EditPoint.INTERSECTION | EditPoint.SPLIT_POINT;
		ep2.type = prev.type;
		ep2.x = px;
		ep2.y = py;
		ep2.color = c;
		n.add (ep2);

		ep3.prev = ep2;
		ep3.next = next;
		ep3.flags |= EditPoint.NEW_CORNER | EditPoint.SPLIT_POINT;
		ep3.type = prev.type;
		ep3.x = px;
		ep3.y = py;
		ep3.color = c;
		n.add (ep3);
		
		next.get_left_handle ().convert_to_line ();			
		
		foreach (EditPoint np in n) {
			np = path.add_point_after (np, np.prev);
			path.create_list ();
		}
		
		PenTool.convert_point_to_line (ep1, true);
		PenTool.convert_point_to_line (ep2, true);
		PenTool.convert_point_to_line (ep3, true);
		
		path.recalculate_linear_handles_for_point (ep1);
		path.recalculate_linear_handles_for_point (ep2);
		path.recalculate_linear_handles_for_point (ep3);
		
		d =  Path.distance_to_point (prev, next);
		prev.get_right_handle ().length *= Path.distance_to_point (prev, ep1) / d;
		next.get_left_handle ().length *= Path.distance_to_point (ep3, next) / d;
		
		path.recalculate_linear_handles_for_point (next);
		
		return ep2;
	}

	bool segments_intersects (EditPoint p1, EditPoint p2, EditPoint ep, EditPoint next,
		out double ix, out double iy,
		bool skip_points_on_points = false) {
		double cross_x, cross_y;
				
		ix = 0;
		iy = 0;

		if (is_line (ep.x, ep.y, p1.x, p1.y, next.x, next.y)) {
			ix = p1.x;
			iy = p1.y;
			return true;
		}
		
		if (is_line (ep.x, ep.y, p2.x, p2.y, next.x, next.y)) {
			ix = p2.x;
			iy = p2.y;
			return true;
		}
		
		if (is_line (p1.x, p1.y, ep.x, ep.y, p2.x, p2.y)) {
			ix = ep.x;
			iy = ep.y;
			return true;
		}
		
		if (is_line (p1.x, p1.y, next.x, next.y, p2.x, p2.y)) {
			ix = next.x;
			iy = next.y;
			return true;
		}
		
		Path.find_intersection_point (ep, next, p1, p2, out cross_x, out cross_y);
		
		if (fmin (ep.x, next.x) - 0.00001 <= cross_x <= fmax (ep.x, next.x) + 0.00001
			&& fmin (ep.y, next.y) - 0.00001 <= cross_y <= fmax (ep.y, next.y) + 0.00001) {
			// iterate to find intersection.				
			if (is_line (ep.x, ep.y, cross_x, cross_y, next.x, next.y)
				&& is_line (p1.x, p1.y, cross_x, cross_y, p2.x, p2.y)) {
			
				ix = cross_x;
				iy = cross_y;
				
				return true;
			}
		}
		
		return false;
	}
	
	bool segment_intersects (Path path, EditPoint ep, EditPoint next,
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
	bool is_line (double x1, double y1, double x2, double y2, double x3, double y3, double tolerance = 0.01) {
		return fmin (x1, x3) - 0.00001 <= x2 && x2 <= fmax (x1, x3) + 0.00001
			&& fmin (y1, y3) - 0.00001 <= y2 && y2 <= fmax (y1, y3) + 0.00001
			&& is_flat (x1, y1, x2, y2, x3, y3, tolerance);
	}
	
	public static bool is_flat (double x1, double y1, double x2, double y2, double x3, double y3, double tolerance = 0.001) {
		double ds = Path.distance (x1, x3, y1, y3);
		double d1 = Path.distance (x1, x2, y1, y2);
		double d2 = Path.distance (x2, x3, y2, y3);
		double p = d1 / ds;
		double x = fabs ((x3 - x1) * p - (x2 - x1)) / ds;
		double y = fabs ((y3 - y1) * p - (y2 - y1)) / ds;
		double d = fabs (ds - (d1 + d2)) / ds;
		
		return ds > 0.001 && d1 > 0.001 && d2 > 0.001
			&& d < tolerance && x < tolerance && y < tolerance;	
	}
	
	// indside becomes outside in some paths
	void remove_points_in_stroke (PathList pl) {
		PathList r;
		
		foreach (Path p in pl.paths) {
			if (remove_points_in_stroke_for_path (p, pl, out r)) {
				pl.append (r);
				remove_points_in_stroke (pl);
				return;
			}
		}
	}

	bool remove_points_in_stroke_for_path (Path p, PathList pl, out PathList result) {
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

	bool merge_segments (PathList pl,
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

	void reset_intersections (Path p) {
		foreach (EditPoint ep in p.points) {
			ep.flags &= ~EditPoint.INTERSECTION;
			ep.flags &= ~EditPoint.COPIED;
			ep.flags &= ~EditPoint.SELF_INTERSECTION;
			ep.deleted = false;
		}
		p.remove_points_on_points ();
	}

	bool add_merge_intersection_point (Path path1, Path path2, EditPoint first, EditPoint next) {
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
	
	bool is_inside_of_path (PointSelection ps, PathList pl, out Path outline) {
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
				
	PathList get_all_parts (PathList pl) {
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

	void remove_single_points (PathList pl) {
		PathList r = new PathList ();
		
		foreach (Path p in pl.paths) {
			p.update_region_boundaries ();
			if (p.points.size < 10 
				|| p.xmax - p.xmin < 0.01
				|| p.ymax - p.ymin < 0.01) {
						
				r.add (p);
			}
		}
		
		foreach (Path p in r.paths) {
			pl.remove (p);
		}
	}

	public PathList merge (PathList pl) {
		bool error = false;
		PathList m;
		PathList r = pl;
		Path p1, p2;

		r = get_all_parts (r);
		remove_single_points (r);
		
		while (paths_has_intersection (r, out p1, out p2)) {
			if (task.is_cancelled ()) {
				return new PathList ();
			}
			
			if (merge_path (p1, p2, out m, out error)) {
				r.paths.remove (p1);
				r.paths.remove (p2);
				
				foreach (Path np in m.paths) {
					np.remove_points_on_points ();
					r.add (np);
				}
		
				if (task.is_cancelled ()) {
					return new PathList ();
				}
		
				r = get_all_parts (r);
				remove_single_points (r);
				
				if (paths_has_intersection (m, out p1, out p2)) {
					warning ("Paths are not merged.");
					error = true;
				}
			} else {
				warning ("Not merged.");
				error = true;
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

		if (task.is_cancelled ()) {
			return new PathList ();
		}
					
		return r;
	}

	void remove_merged_parts (PathList r) {
		Gee.ArrayList<Path> remove = new Gee.ArrayList<Path> ();
		int c;
		
		foreach (Path p in r.paths) {
			p.update_region_boundaries ();
		}
		
		foreach (Path p in r.paths) {
			c = counters (r, p);
			
			if (c % 2 == 0) {
				if (!p.is_clockwise ()) {
					remove.add (p);
				}
			} else {
				if (p.is_clockwise ()) {
					remove.add (p);
				}
			}
		}
						
		foreach (Path p in remove) {
			r.paths.remove (p);
		}
	}

	public PathList get_insides (PathList pl, Path path) {
		bool inside = false;
		PathList insides = new PathList ();
		
		foreach (Path p in pl.paths) {
			if (p.points.size > 1
				&& p != path 
				&& path.boundaries_intersecting (p)) {
				
				inside = true;
				foreach (EditPoint ep in path.points) {
					if (!is_inside (ep, p)) {
						inside = false;
						break;
					}
				}
				
				if (inside) {
					insides.add (p); // add the flat inside to the list
				}
			}
		}
		
		return insides;		
	} 

	public int counters (PathList pl, Path path) {
		int inside_count = 0;
		bool inside;
		
		foreach (Path p in pl.paths) {
			inside = true;
			
			if (p.points.size > 1
				&& p != path 
				&& path.boundaries_intersecting (p)) {
				
				foreach (EditPoint ep in path.points) {
					if (!is_inside (ep, p)) {
						inside = false;
						break;
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
		
		prev = path.points.get (path.points.size - 1);
		
		foreach (EditPoint p in path.points) {
			if ((fabs (p.x - point.x) < 0.1 && fabs (p.y - point.y) < 0.1) 
				|| (fabs (prev.x - point.x) < 0.1 && fabs (prev.y - point.y) < 0.1)) {
				return true;
			} else if  ((p.y > point.y) != (prev.y > point.y) 
				&& point.x < (prev.x - p.x) * (point.y - p.y) / (prev.y - p.y) + p.x) {
				inside = !inside;
			}
			
			prev = p;
		}
		
		return inside;
	}
	
	public int insides (EditPoint point, Path path) {
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
	
	bool merge_path (Path path1, Path path2, out PathList merged_paths, out bool error) {
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

		if (path1.points.size == 0) {
			return false;
		}

		if (path2.points.size == 0) {
			return false;
		}
				
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
				
				if (task.is_cancelled ()) {
					return false;
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
						out pp1, out pp2, false, false);
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
	
	int index_of (Path p, EditPoint ep) {
		int i = 0;
		foreach (EditPoint e in p.points) {
			if (e == ep) {
				return i;
			}
			i++;
		}
		
		return -1;
	}
	
	public int counters_in_point_in_path (Path p, EditPoint ep) {
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
	
	int mark_intersection_as_deleted (Path path) {
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
	bool has_intersection (Path path1, Path path2) {
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
	
	bool paths_has_intersection (PathList r, out Path path1, out Path path2) {
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

	public bool has_points_outside (PathList pl, Path p) {
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

	bool is_clockwise (Path p) {
		double sum = 0;
		EditPoint p1, p2;

		EditPointHandle l, r;
		
		p.recalculate_linear_handles ();
				
		if (p.points.size < 3) {
			return true;
		}
		
		for (int i = 0; i < p.points.size; i++) {
			p1 = p.points.get (i);
			p2 = p.points.get ((i + 1) % p.points.size);
			
			l = p1.get_left_handle ();
			r = p1.get_right_handle ();
			if (!(fabs (l.angle - r.angle) < 0.0001 && l.length > 0.01 && r.length > 0.01)) {
				sum += (p2.x - p1.x) * (p2.y + p1.y);
			}
		}
		
		return sum > 0;
	}	

	public PathList create_stroke (Path original_path, double thickness) {	
		PathList pl;
		EditPoint p1, p2, p3;
		EditPoint previous, previous_inside, start, start_inside;
		
		Path side1, side2;
		
		double x, y, x2, y2, x3, y3;
		int size;
		bool flat, f_next, f_bigger;
		int i;

		double tolerance;
		double step_increment;
		double step_size;
		EditPoint corner1, corner1_inside;
		double step;
		double min_increment;
		
		EditPointHandle l, r;

		Path path = original_path.copy ();
		
		int keep;
		bool on_curve;
		
		pl = new PathList ();
		size = path.is_open () ? path.points.size - 1 : path.points.size;
		
		side1 = new Path ();
		side2 = new Path ();
		
		foreach (EditPoint ph in path.points) {
			if (ph.type == PointType.HIDDEN) {
				ph.type = PointType.CUBIC;
			}
		}
		path.remove_deleted_points ();
		
		if (path.points.size < 2) {
			return pl;
		}

		previous = new EditPoint ();
		previous_inside = new EditPoint ();
		corner1 = new EditPoint ();
		corner1_inside = new EditPoint ();
				
		if (path.is_open ()) {
			p1 = path.points.get (0);
			p2 = path.points.get (1 % path.points.size);
			
			get_segment (thickness, 0, 0.00001, p1, p2, out start);
			get_segment (-thickness, 0, 0.00001, p1, p2, out start_inside);

			previous = start.copy ();
			previous_inside = start_inside.copy ();
			
			previous.flags |= EditPoint.CURVE_KEEP;
			previous_inside.flags |= EditPoint.CURVE_KEEP;
						
			side1.add_point (previous);
			side2.add_point (previous_inside);
		}

		min_increment = 0.02; // 0.013

		for (i = 0; i < size; i++) {
			p1 = path.points.get (i % path.points.size);
			p2 = path.points.get ((i + 1) % path.points.size);
			p3 = path.points.get ((i + 2) % path.points.size);
			
			if (unlikely (task.is_cancelled ())) {
				return new PathList ();
			}

			tolerance = 0.01;
			step_increment = 1.05;
			step_size = 0.039;

			corner1 = new EditPoint ();
			
			if (p1.type == PointType.HIDDEN
				|| p2.type == PointType.HIDDEN) {
				continue;
			}
			
			get_segment (thickness, 0, 0.00001, p1, p2, out start);
			get_segment (-thickness, 0, 0.00001, p1, p2, out start_inside);

			previous = start.copy ();
			previous_inside = start_inside.copy ();
			
			previous.flags |= EditPoint.CURVE | EditPoint.SEGMENT_END;
			previous_inside.flags |= EditPoint.CURVE | EditPoint.SEGMENT_END;

			side1.add_point (previous);
			side2.add_point (previous_inside);	
		
			step = step_size;
			keep = 0;
			step_size = 0.05;
			
			while (step < 1 - 2 * step_size) {
				Path.get_point_for_step (p1, p2, step, out x, out y);
				Path.get_point_for_step (p1, p2, step + step_size, out x2, out y2);
				Path.get_point_for_step (p1, p2, step + 2 * step_size, out x3, out y3);
				
				flat = is_flat (x, y, x2, y2, x3, y3, tolerance); 
				
				Path.get_point_for_step (p1, p2, step, out x, out y);
				Path.get_point_for_step (p1, p2, step + step_size / step_increment, out x2, out y2);
				Path.get_point_for_step (p1, p2, step + 2 * step_size / step_increment, out x3, out y3);
				
				f_next = is_flat (x, y, x2, y2, x3, y3, tolerance);

				Path.get_point_for_step (p1, p2, step, out x, out y);
				Path.get_point_for_step (p1, p2, step + step_size * step_increment, out x2, out y2);
				Path.get_point_for_step (p1, p2, step + 2 * step_size * step_increment, out x3, out y3);
				
				f_bigger = is_flat (x, y, x2, y2, x3, y3, tolerance);
				
				if (!flat && !f_next && step_size > min_increment) {
					step_size /= step_increment;
					continue;
				}
								
				if (flat && f_bigger && step_size < 0.1) {
					step_size *= step_increment;
					continue;
				}
				
				get_segment (thickness, step, step_size, p1, p2, out corner1);
				get_segment (-thickness, step, step_size, p1, p2, out corner1_inside);

				previous.get_right_handle ().length *= step_size;
				corner1.get_left_handle ().length *= step_size;
				previous_inside.get_right_handle ().length *= step_size;
				corner1_inside.get_left_handle ().length *= step_size;

				previous = corner1.copy ();
				previous_inside = corner1_inside.copy ();
				
				if (keep == 0 && step > 0.3) { // keep two points per segment
					on_curve = true;
					keep++;
				} else if (keep == 1 && step > 0.6) {
					on_curve = true;
					keep++;
				} else {
					on_curve = false;
				}
				
				if (!on_curve) {
					previous.flags |= EditPoint.CURVE;
					previous_inside.flags |= EditPoint.CURVE;
				} else {
					previous.flags |= EditPoint.CURVE_KEEP;
					previous_inside.flags |= EditPoint.CURVE_KEEP;
				}

				side1.add_point (previous);
				side2.add_point (previous_inside);
				
				step += step_size;
			}

			previous.get_right_handle ().length *= step_size;
			corner1.get_left_handle ().length *= step_size;
			previous_inside.get_right_handle ().length *= step_size;
			corner1_inside.get_left_handle ().length *= step_size;
			
			get_segment (thickness, 1 - 0.00001, 0.00001, p1, p2, out corner1);
			get_segment (-thickness, 1 - 0.00001, 0.00001, p1, p2, out corner1_inside);
			
			previous = corner1.copy ();
			previous_inside = corner1_inside.copy ();

			previous.get_right_handle ().length *= step_size;
			previous.get_left_handle ().length *= step_size;
			previous_inside.get_right_handle ().length *= step_size;
			previous_inside.get_left_handle ().length *= step_size;

			previous.flags |= EditPoint.CURVE | EditPoint.SEGMENT_END;
			previous_inside.flags |= EditPoint.CURVE | EditPoint.SEGMENT_END;

			side1.add_point (previous);
			side2.add_point (previous_inside);
				
			l = p2.get_left_handle ();
			r = p2.get_right_handle ();
			
			if (fabs ((l.angle + r.angle + PI) % (2 * PI) - PI) > 0.005) {
				if (!path.is_open () || i < size - 1) {
					get_segment (thickness, 0, 0.00001, p2, p3, out start);
					add_corner (side1, previous, start, p2.copy (), thickness);

					get_segment (-thickness, 0, 0.00001, p2, p3, out start);
					add_corner (side2, previous_inside, start, p2.copy (), thickness);
				}
			}
		}
		
		side1.remove_points_on_points ();
		side2.remove_points_on_points ();
	
		convert_to_curve (side1);
		convert_to_curve (side2);
		
		side2.reverse ();		
		pl = merge_stroke_parts (path, side1, side2);
			
		return pl;
	}
	
	void convert_to_curve (Path path) {
		if (path.is_open ()) {
			path.get_first_point ().flags &= ~EditPoint.CURVE;
			path.get_last_point ().flags &= ~EditPoint.CURVE;
		}
		
		path.recalculate_linear_handles ();

		foreach (EditPoint ep in path.points) {
			if ((ep.flags & EditPoint.SEGMENT_END) == 0) {
				if ((ep.flags & EditPoint.CURVE) > 0 || (ep.flags & EditPoint.CURVE_KEEP) > 0) {
					ep.convert_to_curve (); 
				}
			}
		}

		if (task.is_cancelled ()) {
			return;
		}
			
		foreach (EditPoint ep in path.points) {
			if ((ep.flags & EditPoint.SEGMENT_END) == 0) {
				if ((ep.flags & EditPoint.CURVE) > 0 || (ep.flags & EditPoint.CURVE_KEEP) > 0) {
					ep.set_tie_handle (true);
				}
			}
		}

		if (task.is_cancelled ()) {
			return;
		}
			
		foreach (EditPoint ep in path.points) {
			if ((ep.flags & EditPoint.SEGMENT_END) == 0) {
				if ((ep.flags & EditPoint.CURVE) > 0 || (ep.flags & EditPoint.CURVE_KEEP) > 0) {
					ep.process_tied_handle ();
				}
			}
		}			
	}
		
	public void get_segment (double stroke_thickness, double step, double step_size,
		EditPoint p1, EditPoint p2, out EditPoint ep1) {
		
		double thickness = stroke_thickness / 2;
		Path overlay; 
		double x, y, x2, y2, x3, y3;
		EditPoint corner1, corner2, corner3;
		PointType type;
				
		Path.get_point_for_step (p1, p2, step, out x, out y);
		Path.get_point_for_step (p1, p2, step + step_size, out x2, out y2);
		Path.get_point_for_step (p1, p2, step + 2 * step_size, out x3, out y3);
		
		overlay = new Path ();
		
		type = p1.get_right_handle ().type;
		corner1 = new EditPoint (x, y, type);
		corner2 = new EditPoint (x2, y2, type);
		corner3 = new EditPoint (x3, y3, type);
		
		corner2.convert_to_line (); 
		
		overlay.add_point (corner1);
		overlay.add_point (corner2);
		overlay.add_point (corner3);
		
		overlay.close ();
		overlay.recalculate_linear_handles ();
		
		move_segment (corner1, corner2, thickness);

		ep1 = corner2;
	}

	public PathList merge_stroke_parts (Path p, Path side1, Path side2) {
		Path merged = new Path ();
		PathList paths = new PathList ();
			
		if (!p.is_open ()) {
			side1.update_region_boundaries ();
			paths.add (side1);
			side2.update_region_boundaries ();
			paths.add (side2);
			side1.close ();
			side2.close ();
		} else if (p.is_open ()) {
			side2.reverse ();
			merged = merge_strokes (p, side1, side2);
			merged.close ();
			merged.update_region_boundaries ();
			paths.add (merged);
			merged.reverse ();
		} else {
			warning ("Can not create stroke.");
			paths.add (p);
		}

		return paths;
	}
	
	public static Path change_weight_fast (Path path, double weight, bool counter) {
		StrokeTool tool = new StrokeTool ();
		PathList pl;
		
		pl = tool.get_stroke_fast (path, fabs(weight));
		
		return_val_if_fail (pl.paths.size == 2, new Path ());
		
		if (counter == !pl.paths.get (0).is_clockwise ()) {
			return pl.paths.get (0);
		}
		
		return pl.paths.get (1);
	}
	
	public static Path change_weight (Path path, bool counter, double weight) {
		StrokeTool tool = new StrokeTool ();
		Path o = path.copy ();
		Path interpolated = new Path();
		o.force_direction (Direction.CLOCKWISE);
		double default_weight = 5;
		
		PathList pl = tool.get_stroke (o, default_weight);
		Gee.ArrayList<PointSelection> deleted;
		
		deleted = new Gee.ArrayList<PointSelection> (); 

		return_val_if_fail (pl.paths.size > 0, new Path ());
		
		if (weight < 0) {
			counter = !counter;
		}
		
		foreach (Path sp in pl.paths) {
			if (sp.points.size > interpolated.points.size
				&& counter == !sp.is_clockwise ()) {
				interpolated = sp;
			}
		}
		
		return interpolated;
	} 
}

}
