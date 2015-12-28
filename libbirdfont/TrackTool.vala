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

/** A tool that lets the user draw fonts with the mouse 
  * instead of adding bezér points one by one.
  */
public class TrackTool : Tool {
	
	bool draw_freehand = false;

	/** Number of points to take the average from in order to create a smooth shape. */
	int added_points = 0;
	
	/** The time in milliseconds when a point was added to the path.
	 * after a few milliseconds will this tool add a sharp corner instead of  
	 * a smooth curve if the user does not move the pointer.
	 */
	double last_update = 0;

	/** The position of mouse pointer. at lat update. */
	int last_x = 0;
	int last_y = 0;

	/** The position of the mouse pointer when this tool is checking if
	 * the pointer has moved.
	 */
	int last_timer_x = 0;
	int last_timer_y = 0;
	int update_cycles = 0;

	/** Join the stroke with the path at the end point in this coordinate. */
	int join_x = -1;
	int join_y = -1;
	bool join_paths = false;

	/** Adjust the number of samples per point by this factor. */
	double samples_per_point = 1;
	bool drawing = false;

	public TrackTool (string name) {
		base (name, t_("Freehand drawing"));
		
		select_action.connect (() => {
			convert_points_to_line ();
			draw_freehand = false;
		});

		deselect_action.connect (() => {
			convert_points_to_line ();
			draw_freehand = false;
		});
				
		press_action.connect ((self, button, x, y) => {
			Glyph glyph = MainWindow.get_current_glyph ();
			Path p;
			PointSelection? ps;
			PointSelection end_point;

			if (button == 3) {
				glyph.clear_active_paths ();
			}
						
			if (button == 2) {
				glyph.close_path ();
			}
			
			if (button == 1) {
				if (draw_freehand) {
					warning ("Already drawing.");
					return;
				}
				
				return_if_fail (!drawing);
				
				draw_freehand = true;
				
				last_x = x;
				last_y = y;
				
				glyph.store_undo_state ();
				
				if (join_paths) {
					ps = get_path_with_end_point (x, y);
					if (unlikely (ps == null)) {
						warning ("No end point.");
						return;
					}
					end_point = (!) ps;
					if (end_point.is_first ()) {
						end_point.path.reverse ();
					}
					glyph.set_active_path (end_point.path);
					add_corner (x, y);
				} else {
					p = new Path ();
					glyph.add_path (p);
					glyph.open_path ();
					
					PenTool.add_new_edit_point (x, y);
				}

				glyph.update_view ();				
				added_points = 0;
				last_update = get_current_time ();
				start_update_timer ();
				drawing = true;
				
				foreach (Object path in glyph.active_paths) {
					if (path is FastPath) {
						// cache merged stroke parts
						((FastPath) path).get_path ().create_full_stroke ();
					}
				}
			}
		});
		
		double_click_action.connect ((self, b, x, y) => {
		});

		release_action.connect ((self, button, x, y) => {
			Path p;
			Glyph g = MainWindow.get_current_glyph ();
			EditPoint previous;

			if (button == 1) {
				if (!draw_freehand) {
					warning ("Not drawing.");
					return;
				}
				
				convert_points_to_line ();
				
				g = MainWindow.get_current_glyph ();
				
				if (g.active_paths.size > 0) { // set type for last point
					Object o = g.active_paths.get (g.active_paths.size - 1);
					p = ((FastPath) o).get_path ();
									
					if (p.points.size > 1) {
						previous = p.points.get (p.points.size - 1);
						previous.type = DrawingTools.point_type;
						previous.set_tie_handle (false);

						previous = p.points.get (0);
						previous.type = DrawingTools.point_type;
						previous.set_tie_handle (false);
					}
				}

				if (button == 1 && draw_freehand) {
					return_if_fail (drawing);
					add_endpoint_and_merge (x, y);
				}
							
				foreach (Object path in g.active_paths) {
					if (path is FastPath) {
						convert_hidden_points (((FastPath) path).get_path ());
					}
				}
				
				g.clear_active_paths ();
				
				set_tie ();
				PenTool.force_direction (); 
				PenTool.reset_stroke ();
				BirdFont.get_current_font ().touch ();
				drawing = false;
			}
		});

		move_action.connect ((self, x, y) => {
			PointSelection? open_path = get_path_with_end_point (x, y);
			PointSelection p;
			bool join;
			
			join = (open_path != null);
			
			if (join != join_paths) {
				MainWindow.get_current_glyph ().update_view ();
				PenTool.reset_stroke ();
			}
			
			join_paths = join;
			
			if (open_path != null) {
				p = (!) open_path;
				join_x = Glyph.reverse_path_coordinate_x (p.point.x);
				join_y = Glyph.reverse_path_coordinate_y (p.point.y);
			}
			
			if (draw_freehand) {
				record_new_position (x, y);
				convert_on_timeout ();
				last_x = x;
				last_y = y;
				PenTool.reset_stroke ();
			}
		});
		
		draw_action.connect ((tool, cairo_context, glyph) => {
			if (join_paths) {
				PenTool.draw_join_icon (cairo_context, join_x, join_y);
			}
		});
		
		key_press_action.connect ((self, keyval) => {
		});
	}
	
	void convert_hidden_points (Path p) {
		foreach (EditPoint e in p.points) {
			if (e.type == PointType.HIDDEN) {
				e.type = DrawingTools.point_type;
				e.get_right_handle ().type = DrawingTools.point_type;
				e.get_left_handle ().type = DrawingTools.point_type;
			}
		}
	}
	
	// FIXME: double check
	void set_tie () {
		Glyph glyph = MainWindow.get_current_glyph ();
		var paths = glyph.get_visible_paths ();
		Path p = paths.get (paths.size - 1);
		
		foreach (EditPoint ep in p.points) {
			if (ep.get_right_handle ().is_line () || ep.get_left_handle ().is_line ()) {
				ep.set_tie_handle (false);
			}

			if (!ep.get_right_handle ().is_line () || !ep.get_left_handle ().is_line ()) {
				ep.convert_to_curve ();
			}
		}
	}
	
	public void set_samples_per_point (double s) {
		samples_per_point = s;
	}

	void add_endpoint_and_merge (int x, int y) {
		Glyph glyph;
		Path p;
		PointSelection? open_path = get_path_with_end_point (x, y);
		PointSelection joined_path;
		
		glyph = MainWindow.get_current_glyph ();
		var paths = glyph.get_visible_paths ();
		
		if (paths.size == 0) {
			warning ("No path.");
			return;
		}
		
		// FIXME: double check this
		p = paths.get (paths.size - 1);
		draw_freehand = false;
		
		convert_points_to_line ();

		if (join_paths && open_path != null) {
			joined_path = (!) open_path;
			 
			if (joined_path.path == p) {
				delete_last_points_at (x, y);
				glyph.close_path ();
				p.close ();
			} else {
				p = merge_paths (p, joined_path);
				if (!p.is_open ()) {
					glyph.close_path ();
				}
			}
			
			glyph.clear_active_paths ();
		} else {
			add_corner (x, y);
		}

		if (p.points.size == 0) {
			warning ("No point.");
			return;
		}

		p.create_list ();
		
		if (DrawingTools.get_selected_point_type () == PointType.QUADRATIC) {
			foreach (EditPoint e in p.points) {
				if (e.tie_handles) {
					e.convert_to_curve ();
					e.process_tied_handle ();							
				}
			}
		}

		if (PenTool.is_counter_path (p)) {
			p.force_direction (Direction.COUNTER_CLOCKWISE);
		} else {
			p.force_direction (Direction.CLOCKWISE);
		}
				
		glyph.update_view ();
	}

	private static Path merge_paths (Path a, PointSelection b) {
		Glyph g;
		Path merged = a.copy ();

		if (a.points.size < 2) {
			warning ("Less than two points in path.");
			return merged;
		}

		if (b.path.points.size < 2) {
			warning ("Less than two points in path.");
			return merged;
		}
				
		if (!b.is_first ()) {
			b.path.close ();
			b.path.reverse ();
			b.path.reopen ();
		}
		
		merged.append_path (b.path);
		
		g = MainWindow.get_current_glyph ();
		
		g.add_path (merged);
		
		a.delete_last_point ();
		
		update_corner_handle (a.get_last_point (), b.path.get_first_point ());
		
		g.delete_path (a);
		g.delete_path (b.path);
		
		merged.create_list ();
		merged.update_region_boundaries ();
		merged.recalculate_linear_handles ();
		merged.reopen ();
		
		return merged;
	}

	public static void update_corner_handle (EditPoint end, EditPoint new_start) {
		EditPointHandle h1, h2;
		
		h1 = end.get_right_handle ();
		h2 = new_start.get_left_handle ();
		
		h1.convert_to_line ();
		h2.convert_to_line ();
	}

	PointSelection? get_path_with_end_point (int x, int y) {
		Glyph glyph = MainWindow.get_current_glyph ();
		EditPoint e;
		EditPoint current_end = new EditPoint ();

		// exclude the end point on the path we are adding points to
		if (draw_freehand) {
			current_end = get_active_path ().get_last_point ();
		}

		foreach (Path p in glyph.get_visible_paths ()) {
			if (p.is_open () && p.points.size > 2) {
				e = p.points.get (0);
				if (PenTool.is_close_to_point (e, x, y)) {
					return new PointSelection (e, p);
				}

				e = p.points.get (p.points.size - 1);
				if (current_end != e && PenTool.is_close_to_point (e, x, y)) {
					return new PointSelection (e, p);				
				}
			}
		}
		
		return null;
	}
	
	void record_new_position (int x, int y) {
		Glyph glyph;
		Path p;
		EditPoint new_point;
		double px, py;
	
		glyph = MainWindow.get_current_glyph ();
		
		if (glyph.active_paths.size == 0) {
			warning ("No path.");
			return;
		}
		
		Object o = glyph.active_paths.get (glyph.active_paths.size - 1);
		
		if (unlikely (!(o is FastPath))) {
			warning ("Object is not a path");
			return;
		}
		
		p = ((FastPath) o).get_path ();
		p.reopen ();
		px = Glyph.path_coordinate_x (x);
		py = Glyph.path_coordinate_y (y);
		new_point = p.add (px, py);
		added_points++;

		PenTool.convert_point_to_line (new_point, false);
		new_point.set_point_type (PointType.HIDDEN);		
		p.recalculate_linear_handles_for_point (new_point);
		
		if (p.points.size > 1) {
			glyph.redraw_segment (new_point, new_point.get_prev ());
		}
		
		glyph.update_view ();
		
		last_x = x;
		last_y = y;
	}
	
	void start_update_timer () {
		TimeoutSource timer = new TimeoutSource (100);

		timer.set_callback (() => {
			if (draw_freehand) {
				record_new_position (last_x, last_y);
				convert_on_timeout ();
			}
					
			return draw_freehand;
		});

		timer.attach (null);
	}

	/** @returns true while the mounse pointer is moving. */
	bool is_moving (int x, int y) {
		return Path.distance (x, last_x, y, last_y) >= 1;
	}
	
	/** Add a new point if the update period has ended. */
	void convert_on_timeout () {
		if (!is_moving (last_timer_x, last_timer_y)) {
			update_cycles++;
		} else {
			last_timer_x = last_x;
			last_timer_y = last_y;
			update_cycles = 0;
		}
		
		if (update_cycles > 4) { // cycles of 100 ms
			convert_points_to_line ();
			last_update  = get_current_time ();
			add_corner (last_x, last_y);
			added_points = 0;
			update_cycles = 0;
		}
			
		if (added_points > 25 / samples_per_point) {
			last_update  = get_current_time ();
			convert_points_to_line ();
		}
	}
	
	/** Add a sharp corner instead of a smooth curve. */
	void add_corner (int px, int py) {
		PointSelection p;
		delete_last_points_at (px, py);
		p = PenTool.add_new_edit_point (px, py);
		p.point.set_tie_handle (false);
		p.point.get_left_handle ().convert_to_line ();
		p.point.get_right_handle ().convert_to_line ();
		p.path.recalculate_linear_handles_for_point (p.point);
		last_update = get_current_time ();
		MainWindow.get_current_glyph ().update_view ();
	}

	Path get_active_path () {
		Glyph glyph = MainWindow.get_current_glyph ();
		
		if (glyph.active_paths.size == 0) {
			warning ("No path.");
			return new Path ();
		}
			
		Object o = glyph.active_paths.get (glyph.active_paths.size - 1);
		
		if (likely (o is FastPath)) {
			return ((FastPath) o).get_path ();
		}
		
		warning ("Active object is a path.");
		
		return new Path ();
	}
	
	/** Delete all points close to the pixel at x,y. */
	void delete_last_points_at (int x, int y) {
		double px, py;
		Path p;
					
		p = get_active_path ();

		if (unlikely (p.points.size == 0)) {
			warning ("Missing point.");
			return;
		}

		px = Glyph.path_coordinate_x (x);
		py = Glyph.path_coordinate_y (y);

		while (p.points.size > 0 && is_close (p.points.get (p.points.size - 1), px, py)) {
			p.delete_last_point ();
		}
	}
	
	/** @return true if the new point point is closer than a few pixels from p. */
	bool is_close (EditPoint p, double x, double y) {
		Glyph glyph = MainWindow.get_current_glyph ();
		return glyph.view_zoom * Path.distance (p.x, x, p.y, y) < 5;
	}
	
	/** Take the average of tracked points and create a smooth line.
	 * @return the last removed point.
	 */
	public void convert_points_to_line () {
		EditPoint ep, last_point;
		double sum_x, sum_y, nx, ny;
		int px, py;
		EditPoint average, previous;
		Path p;
		Glyph glyph;
		Gee.ArrayList<EditPoint> points;
		
		points = new Gee.ArrayList<EditPoint> ();
		glyph = MainWindow.get_current_glyph ();
		var paths = glyph.get_visible_paths ();
		
		if (paths.size == 0) {
			warning ("No path.");
			return;
		}
			
		p = paths.get (paths.size - 1);
				
		if (added_points == 0) { // last point
			return;
		}

		if (unlikely (p.points.size < added_points)) {
			warning ("Missing point.");
			return;
		}

		sum_x = 0;
		sum_y = 0;
		
		last_point = p.points.get (p.points.size - 1);
		
		for (int i = 0; i < added_points; i++) {
			ep = p.delete_last_point ();
			sum_x += ep.x;
			sum_y += ep.y;			
			points.add (ep);
		}
		
		nx = sum_x / added_points;
		ny = sum_y / added_points;

		px = Glyph.reverse_path_coordinate_x (nx);
		py = Glyph.reverse_path_coordinate_y (ny);
		average = PenTool.add_new_edit_point (px, py).point;
		average.type = PointType.HIDDEN;
		
		// tie handles for all points except for the end points
		average.set_tie_handle (p.points.size > 1); 
		
		if (unlikely (p.points.size == 0)) {
			warning ("No points.");
			return;
		}
		
		if (average.prev != null && average.get_prev ().tie_handles) {
			if (p.points.size > 2) {
				previous = average.get_prev ();
				previous.type = DrawingTools.point_type;
				PenTool.convert_point_to_line (previous, true);
				p.recalculate_linear_handles_for_point (previous);
				previous.process_tied_handle ();
				previous.set_tie_handle (false);
			}
		}

		added_points = 0;
		last_update = get_current_time ();
		glyph.update_view ();
		p.reset_stroke ();
	}
	
	/** @return current time in milli seconds. */
	public static double get_current_time () {
		return GLib.get_real_time () / 1000.0;
	}
}

}
