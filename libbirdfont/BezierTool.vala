/*
    Copyright (C) 2015 Johan Mattsson

    This library is free software; you can redistribute it and/or modify 
    it under the terms of the GNU Lesser General Public License as 
    published by the Free Software Foundation; either version 3 of the 
    License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful, but 
    WITHOUT ANY WARRANTY; without even the implied warranty of 
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
    Lesser General Public License for more details.
*/

using Math;
using Cairo;

namespace BirdFont {

/** Create Beziér curves. */
public class BezierTool : Tool {
	
	public const uint NONE = 0;
	public const uint MOVE_POINT = 1;
	public const uint MOVE_HANDLES = 2;
	public const uint MOVE_LAST_HANDLE = 3;
	public const uint MOVE_FIRST_HANDLE = 4;
	
	uint state = NONE;
	bool move_right_handle = true;
	int previous_point = 0;
	
	Path current_path = new Path ();
	EditPoint current_point = new EditPoint ();

	int last_x = 0;
	int last_y = 0;

	double last_release_time = 0;
	
	public BezierTool (string name) {
		base (name, t_ ("Create Beziér curves"));

		select_action.connect ((self) => {
			state = NONE;
			MainWindow.set_cursor (NativeWindow.VISIBLE);
		});

		deselect_action.connect ((self) => {
			state = NONE;
			MainWindow.set_cursor (NativeWindow.VISIBLE);
		});
		
		press_action.connect ((self, b, x, y) => {
			press (b, x, y);
		});

		double_click_action.connect ((self, b, x, y) => {
		});

		release_action.connect ((self, b, x, y) => {
			release (b, x, y);
		});

		move_action.connect ((self, x, y) => {
			move (x, y);
		});
		
		key_press_action.connect ((self, keyval) => {
		});
		
		key_release_action.connect ((self, keyval) => {
		});
		
		draw_action.connect ((tool, cairo_context, glyph) => {
			if (PenTool.can_join (current_point)) {
				PenTool.draw_join_icon (cairo_context, last_x, last_y);
			}
		});
	}
	
	public void press (int b, int x, int y) {
		Glyph g = MainWindow.get_current_glyph ();
		double px, py;
		Path? p;
		Path path;

		if (b == 2) {
			if (g.is_open ()) {
				g.close_path ();
			} else {
				g.open_path ();
			}
			
			MainWindow.set_cursor (NativeWindow.VISIBLE);
			state = NONE;

			return;
		}
		
		PenTool.update_orientation ();
		
		MainWindow.set_cursor (NativeWindow.HIDDEN);
		g.open_path ();
		
		px = Glyph.path_coordinate_x (x);
		py = Glyph.path_coordinate_y (y);		

		if (state == NONE) {
			g.open_path ();
			current_path = new Path ();
			current_path.reopen ();
			current_path.hide_end_handle = true;
			current_point = current_path.add (px, py);
			current_point.get_left_handle ().convert_to_line ();
			current_point.recalculate_linear_handles ();
			g.add_path (current_path);
			GlyphCanvas.redraw ();
			state = MOVE_POINT;
		} else if (state == MOVE_POINT) {
			if (PenTool.can_join (current_point)) {
				p = PenTool.join_paths (current_point);
				
				return_if_fail (p != null);
				path = (!) p;
				
				if (current_path.points.size == 1) {
					return_if_fail (path.is_open ());
					current_path = path;
					current_point = path.get_last_point ();
					state = MOVE_POINT;
				} else {
					g.open_path ();
					current_path = path;
					current_point = path.get_first_point ();
					state = MOVE_LAST_HANDLE;	
				}
			} else {
				state = MOVE_HANDLES;
			}
		}
	}

	public void release (int b, int x, int y) {
		double px, py;
		Glyph g;
		
		// ignore double clicks
		if ((GLib.get_real_time () - last_release_time) / 1000000.0 < 0.2) {
			last_release_time = GLib.get_real_time ();
			return;
		}
		last_release_time = GLib.get_real_time ();
			
		px = Glyph.path_coordinate_x (x);
		py = Glyph.path_coordinate_y (y);
		
		if (state == MOVE_HANDLES) {
			current_point = current_path.add (px, py);
			current_path.hide_end_handle = true;
			current_point.get_left_handle ().convert_to_line ();
			current_point.recalculate_linear_handles ();
			GlyphCanvas.redraw ();
			state = MOVE_POINT;
		} else if (state == MOVE_LAST_HANDLE) {
			current_path.update_region_boundaries ();
			g = MainWindow.get_current_glyph ();
			g.close_path ();
			MainWindow.set_cursor (NativeWindow.VISIBLE);
			
			if (Path.is_counter (g.get_paths (), current_path)) {
				current_path.force_direction (Direction.COUNTER_CLOCKWISE);
			} else {
				current_path.force_direction (Direction.CLOCKWISE);
			}
			
			state = NONE;
		}
	}
	
	public void move (int x, int y) {
		double px, py;
		
		last_x = x;
		last_y = y;
		
		px = Glyph.path_coordinate_x (x);
		py = Glyph.path_coordinate_y (y);	
		
		if (state == MOVE_POINT) {
			current_point.x = px;
			current_point.y = py;
			current_path.hide_end_handle = true;
			current_point.recalculate_linear_handles ();
			GlyphCanvas.redraw ();
		} else if (state == MOVE_HANDLES || state == MOVE_LAST_HANDLE) {
			current_path.hide_end_handle = false;
			current_point.set_reflective_handles (true);
			current_point.convert_to_curve ();
			current_point.get_right_handle ().move_to_coordinate (px, py);
			GlyphCanvas.redraw ();
		}
		
		if (current_path.points.size > 0) {
			current_path.get_first_point ().set_reflective_handles (false);
			current_path.get_last_point ().set_reflective_handles (false);
		}
	}
	
	public void switch_to_line_mode () {
		int s = current_path.points.size;
		if (s > 2) {
			current_path.points.get (s - 2).get_right_handle ().convert_to_line ();
			current_point.get_left_handle ().convert_to_line ();
		}
	}
	
	public void stop_drawing () {
		if (state == MOVE_POINT && current_path.points.size > 0) {
			current_path.delete_last_point ();
		}
		
		state = NONE;
	}
	
}

}
