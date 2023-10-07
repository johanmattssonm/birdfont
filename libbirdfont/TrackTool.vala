/*
	Copyright (C) 2014 2015 2016 Johan Mattsson

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

				if (is_null(glyph.active_paths)) {
					warning("No active paths in free hand tool.");
					return;				
				}
				
				foreach (Path path in glyph.active_paths) {
					path.create_full_stroke (); // cache merged stroke parts
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
				
				return_if_fail (!is_null (g.active_paths));
				
				if (!is_null (g.active_paths) && g.active_paths.size > 0) { // set type for last point
					p = g.active_paths.get (g.active_paths.size - 1);

					return_if_fail (!is_null (p.points));
					
					if (!is_null (p.points) && p.points.size > 1) {
						previous = p.points.get (p.points.size - 1);
						previous.type = PointType.CUBIC;
						previous.set_tie_handle (false);

						previous = p.points.get (0);
						previous.type = PointType.CUBIC;
						previous.set_tie_handle (false);
					}
				}

				if (button == 1 && draw_freehand) {
					return_if_fail (drawing);
					add_endpoint_and_merge (x, y);
				}
				
				var paths_in_layer = g.layers.get_all_paths (); 

				if (is_null (paths_in_layer) || is_null (paths_in_layer)) {
					warning ("No layers in glyph.");		
				} else {
					foreach (Path path in paths_in_layer.paths) {
						convert_hidden_points (path);
						path.update_region_boundaries ();
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
				e.get_right_handle ().type = PointType.CUBIC;
				e.get_left_handle ().type = PointType.CUBIC;
			}
		}
	}
	
	// FIXME: double check
	void set_tie () {
		Glyph glyph = MainWindow.get_current_glyph ();
		var paths = glyph.get_visible_paths ();
		
		return_if_fail (!is_null (paths));
		return_if_fail (paths.size > 0);
		
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

		EditPoint last_point = p.get_last_point ();
		EditPointHandle handle = last_point.get_right_handle ();
		handle.convert_to_line ();
		p.recalculate_linear_handles ();

		PenTool.convert_point_type (p.get_last_point (), PointType.CUBIC);
		PenTool.convert_point_type (p.get_first_point (), PointType.CUBIC);

		p.create_list ();

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
		
		p = glyph.active_paths.get (glyph.active_paths.size - 1);
		p.reopen ();

		EditPoint last_point = new EditPoint ();
		
		if (p.points.size > 0) {
			last_point = p.get_last_point ();
		}
		
		px = Glyph.path_coordinate_x (x);
		py = Glyph.path_coordinate_y (y);
		
		new_point = new EditPoint (px, py, PointType.CUBIC);
		p.add_point (new_point);
		added_points++;

		PenTool.convert_point_to_line (new_point, false);
		new_point.set_point_type (PointType.HIDDEN);
		p.recalculate_linear_handles_for_point (new_point);

		last_point.get_right_handle ().length = 0.000001;		
		
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
		
		if (update_cycles > 0.7 * 10) { // delay in time
			convert_points_to_line ();
			last_update = get_current_time ();
			add_corner (last_x, last_y);
			added_points = 0;
			update_cycles = 0;
		}
			
		if (added_points > 80 / samples_per_point) {
			last_update = get_current_time ();
			convert_points_to_line ();
		}
	}
	
	/** Add a sharp corner instead of a smooth curve. */
	void add_corner (double px, double py) {
		EditPoint p;
		p = new EditPoint (px, py, PointType.CUBIC);
		p.set_tie_handle (false);
		p.get_left_handle ().convert_to_line ();
		p.get_right_handle ().convert_to_line ();
		get_active_path ().recalculate_linear_handles_for_point (p);
		last_update = get_current_time ();
		MainWindow.get_current_glyph ().update_view ();
	}

	Path get_active_path () {
		Glyph glyph = MainWindow.get_current_glyph ();
		
		if (glyph.active_paths.size == 0) {
			warning ("No path.");
			return new Path ();
		}
			
		return glyph.active_paths.get (glyph.active_paths.size - 1);		
	}
	
	/** Delete all points close to the pixel at x,y. */
	void delete_last_points_at (double px, double py) {
		Path p;
					
		p = get_active_path ();

		if (unlikely (p.points.size == 0)) {
			warning ("Missing point.");
			return;
		}

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
		double sum_x, sum_y;
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
		
		int start = p.points.size - 1 - added_points;
		int stop = p.points.size - 1;
		
		EditPoint end = p.points.get (stop);
		
		Path segment = StrokeTool.fit_bezier_path (p, start, stop, 5.0 / samples_per_point);
		
		for (int i = 0; i < added_points; i++) {
			p.delete_last_point ();
		}		
		
		p.append_path (segment);
		p.remove_points_on_points ();
		
		add_corner (end.x, end.y);
		
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
