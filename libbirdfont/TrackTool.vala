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

/** A tool that lets the user draw fonts with the mouse 
  * instead of adding bezér points one by one.
  */
public class TrackTool : Tool {
	bool draw_free_hand = false;

	int added_points = 0;
	double last_update = 0;

	int last_x = 0;
	int last_y = 0;

	int last_timer_x = 0;
	int last_timer_y = 0;
	int update_cycles = 0;

	int join_x = -1;
	int join_y = -1;
	bool join_paths = false;

	double stroke_width = 0; 

	public TrackTool (string name) {
		string sw;
		
		base (name, t_("Draw paths on free hand"));
		
		sw = Preferences.get ("free_hand_stroke_width");
		if (sw != "") {
			stroke_width = SpinButton.convert_to_double (sw);
		}
		
		select_action.connect((self) => {
			Toolbox.set_object_stroke (stroke_width);
		});
		
		press_action.connect ((self, b, x, y) => {
			Glyph glyph = MainWindow.get_current_glyph ();
			Path p;
			PointSelection? ps;
			PointSelection end_point;
			
			if (b == 1) {
				draw_free_hand = true;
				
				last_x = x;
				last_y = y;
				
				glyph.store_undo_state ();
				
				if (join_paths) {
					ps = get_path_with_end_point (x, y);
					return_if_fail (ps != null);
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
					PenTool.add_new_edit_point (x, y).point;
					record_new_position (x, y);
					p.set_stroke (stroke_width);
				}

				glyph.update_view ();				
				added_points = 0;
				last_update = get_current_time ();
				start_update_timer ();
			}
		});
		
		double_click_action.connect ((self, b, x, y) => {
		});

		release_action.connect ((self, button, x, y) => {
			if (button == 1) {
				add_endpoint_and_merge (x, y);
			}
		});

		move_action.connect ((self, x, y) => {
			PointSelection? open_path = get_path_with_end_point (x, y);
			PointSelection p;
			bool join;
			
			join = (open_path != null);
			
			if (join != join_paths) {
				MainWindow.get_current_glyph ().update_view ();

			}
			
			join_paths = join;
			
			if (open_path != null) {
				p = (!) open_path;
				join_x = Glyph.reverse_path_coordinate_x (p.point.x);
				join_y = Glyph.reverse_path_coordinate_y (p.point.y);
			}
			
			if (draw_free_hand) {
				record_new_position (x, y);
				convert_on_timeout ();
				last_x = x;
				last_y = y;
			}
		});
		
		draw_action.connect ((tool, cairo_context, glyph) => {
			if (join_paths) {
				PenTool.draw_join_icon (cairo_context, join_x, join_y);
			}
		});
	}

	public void set_stroke_width (double width) {
		string w = SpinButton.convert_to_string (width);
		Preferences.set ("free_hand_stroke_width", w);
		stroke_width = width;
	}

	void add_endpoint_and_merge (int x, int y) {
			Glyph glyph;
			Path p;
			PointSelection? open_path = get_path_with_end_point (x, y);
			PointSelection joined_path;
			glyph = MainWindow.get_current_glyph ();
			
			if (glyph.path_list.length () == 0) {
				warning ("No path.");
				return;
			}
			
			p = glyph.path_list.last ().data;
			draw_free_hand = false;
			
			convert_points_to_line ();

			if (join_paths && open_path != null) {
				joined_path = (!) open_path;
				 
				if (joined_path.path == p) {
					p.close (); 
				} else {
					merge_paths (p, joined_path);
				}
			} else {
				add_corner (x, y);
			}

			
			if (p.points.length () == 0) {
				warning ("No point.");
				return;
			}
			
			p.points.first ().data.set_tie_handle (false);
			p.points.last ().data.set_tie_handle (false);
			
			p.create_list ();
			
			if (glyph.path_list.length () < 2) {
				warning ("Points have been deleted");
				return;
			}

			if (DrawingTools.get_selected_point_type () == PointType.QUADRATIC) {
				foreach (EditPoint e in p.points) {
						e.set_tie_handle (true);
						e.process_tied_handle ();							
				}
			}
					
			glyph.update_view ();
	}

	public static void merge_paths (Path a, PointSelection b) {
		Glyph g;
		Path merged = a.copy ();

		if (a.points.length () < 2) {
			warning ("Less than two points in path.");
			return;
		}

		if (b.path.points.length () < 2) {
			warning ("Less than two points in path.");
			return;
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
		
		merged.delete_last_point ();
		
		if (PenTool.is_counter_path (merged)) {
			merged.force_direction (Direction.COUNTER_CLOCKWISE);
		} else {
			merged.force_direction (Direction.CLOCKWISE);
		}
	}

	static void update_corner_handle (EditPoint end, EditPoint new_start) {
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
		if (draw_free_hand) {
			current_end = get_active_path ().get_last_point ();
		}

		foreach (Path p in glyph.path_list) {
			if (p.is_open () && p.points.length () > 2) {
				e = p.points.first ().data;
				if (PenTool.is_close_to_point (e, x, y)) {
					return new PointSelection (e, p);
				}

				e = p.points.last ().data;
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
		
		if (glyph.path_list.length () == 0) {
			warning ("No path.");
			return;
		}
		
		p = glyph.path_list.last ().data;
		p.reopen ();
		px = Glyph.path_coordinate_x (x);
		py = Glyph.path_coordinate_y (y);
		new_point = p.add (px, py);
		added_points++;

		PenTool.convert_point_to_line (new_point, false);
		
		if (p.points.length () > 1) {
			glyph.redraw_segment (new_point, new_point.get_prev ().data);
		}
		
		glyph.update_view ();
		
		last_x = x;
		last_y = y;
	}
	
	void start_update_timer () {
		TimeoutSource timer = new TimeoutSource (100);

		timer.set_callback (() => {
			
			if (draw_free_hand) {
				record_new_position (last_x, last_y);
				convert_on_timeout ();
			}
			
			return draw_free_hand;
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
		
		if (update_cycles > 5) { // cycles of 100 ms
			convert_points_to_line ();
			last_update  = get_current_time ();
			add_corner (last_x, last_y);
			added_points = 0;
			update_cycles = 0;
		}
			
		if (added_points > 40) {
			last_update  = get_current_time ();
			convert_points_to_line ();
		}
	}
	
	void add_corner (int px, int py) {
		PointSelection p;
		delete_last_points_at (px, py);
		p = PenTool.add_new_edit_point (px, py);
		p.point.set_tie_handle (false);
		p.point.get_left_handle ().convert_to_line ();
		p.point.get_right_handle ().convert_to_line ();
		p.point.recalculate_linear_handles ();
		last_update = get_current_time ();
		MainWindow.get_current_glyph ().update_view ();
	}

	Path get_active_path () {
		Glyph glyph = MainWindow.get_current_glyph ();
		
		if (glyph.path_list.length () == 0) {
			warning ("No path.");
			return new Path ();
		}
			
		return glyph.path_list.last ().data;		
	}
	
	void delete_last_points_at (int x, int y) {
		double px, py;
		Path p;
					
		p = get_active_path ();

		if (unlikely (p.points.length () == 0)) {
			warning ("Missing point.");
			return;
		}

		px = Glyph.path_coordinate_x (x);
		py = Glyph.path_coordinate_y (y);

		while (p.points.length () > 0 && is_close (p.points.last ().data, px, py)) {
			p.delete_last_point ();
		}
	}
	
	/** @return true if the new point point is closer than a few pixels EditPoint. */
	bool is_close (EditPoint p, double x, double y) {
		Glyph glyph = MainWindow.get_current_glyph ();
		return glyph.view_zoom * Path.distance (p.x, x, p.y, y) < 5;
	}
	
	/** @return the last removed point. */
	EditPoint convert_points_to_line () {
		EditPoint ep, last_point;
		double sum_x, sum_y, sum_angle, nx, ny;
		int px, py;
		EditPoint average;
		Path p;
		Glyph glyph;
		
		if (added_points == 0) {
			warning ("No points to add.");
			return new EditPoint ();
		}
		
		glyph = MainWindow.get_current_glyph ();
		
		if (glyph.path_list.length () == 0) {
			warning ("No path.");
			return new EditPoint ();
		}
			
		p = glyph.path_list.last ().data;

		if (unlikely (p.points.length () < added_points)) {
			warning ("Missing point.");
			return new EditPoint ();
		}

		sum_x = 0;
		sum_y = 0;
		sum_angle = 0;
		
		List<EditPoint> points = new List<EditPoint> ();
		
		last_point = p.points.last ().data;
		
		for (int i = 0; i < added_points; i++) {
			ep = p.delete_last_point ();
			sum_x += ep.x;
			sum_y += ep.y;			
			points.append (ep);
		}
		
		nx = sum_x / added_points;
		ny = sum_y / added_points;

		px = Glyph.reverse_path_coordinate_x (nx);
		py = Glyph.reverse_path_coordinate_y (ny);
		average = PenTool.add_new_edit_point (px, py).point;
		average.set_tie_handle (true);
		
		if (unlikely (p.points.length () == 0)) {
			warning ("No points.");
			return new EditPoint ();
		}
		
		if (average.prev != null && average.get_prev ().data.tie_handles) {
			PenTool.convert_point_to_line (average.get_prev ().data, true);
			average.get_prev ().data.process_tied_handle ();
		}

		added_points = 0;
		last_update = get_current_time ();
		glyph.update_view ();
		
		return last_point;
	}
	
	/** @return current time in milli seconds. */
	static double get_current_time () {
		return GLib.get_real_time () / 1000.0;
	}
}

}
