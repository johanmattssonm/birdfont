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

using Math;
using Cairo;

namespace BirdFont {

/** Create Beziér curves and preview the path. */
public class ForesightTool : Tool {
	
	public const uint NONE = 0;
	
	public const uint MOVE_POINT = 1;
	public const uint MOVE_HANDLES = 2;
	public const uint MOVE_LAST_HANDLE = 3;
	
	uint state = NONE;
	bool move_right_handle = true;

	public ForesightTool (string name) {
		base (name, t_ ("Create Beziér curves"), '.', CTRL);

		select_action.connect ((self) => {
			state = NONE;
		});

		deselect_action.connect ((self) => {
			state = NONE;
		});
		
		press_action.connect ((self, b, x, y) => {
			PenTool p = (PenTool) PointTool.pen ();
			PointSelection ps;
			EditPoint first_point;
			bool clockwise;
			
			if (state == NONE) {
				p.press_action (p, 3, x, y);
				p.release_action (p, 3, x, y);
				
				add_new_point (x, y);
				
				state = MOVE_HANDLES;
			}
			
			if (state == MOVE_POINT) {			
				state = MOVE_HANDLES;
					
				if (p.has_join_icon ()) {
					return_if_fail (PenTool.active_path.points.size != 0);
					ps = new PointSelection (PenTool.active_path.points.get (PenTool.active_path.points.size - 1), PenTool.active_path);
					ps.point.set_tie_handle (false);
					ps.point.convert_to_curve ();
					
					ps = new PointSelection (PenTool.active_path.points.get (0), PenTool.active_path);
					ps.point.set_tie_handle (false);
					ps.point.convert_to_curve ();
					
					first_point = PenTool.active_path.points.get (0);
					clockwise = PenTool.active_path.is_clockwise ();
				
					p.release_action (p, 3, x, y);
					p.press_action (p, 3, x, y);

					if (ps.path.has_point (first_point)) {
						ps.path.reverse ();
					}
					
					if (clockwise && PenTool.active_path.is_clockwise ()) {
						ps = new PointSelection (PenTool.active_path.points.get (0), PenTool.active_path);
					} else {
						ps = new PointSelection (PenTool.active_path.points.get (PenTool.active_path.points.size - 1), PenTool.active_path);
					}
					
					PenTool.selected_points.clear ();
					PenTool.selected_points.add (ps);
					PenTool.selected_point = ps.point; 
					
					state = MOVE_LAST_HANDLE;
				}
			}
		});
		
		double_click_action.connect ((self, b, x, y) => {
			Tool p = PointTool.pen ();
			
			if (!BirdFont.android) {
				p.double_click_action (p, b, x, y);
			}
		});

		release_action.connect ((self, b, x, y) => {
			Tool p = PointTool.pen ();
			PointSelection last;
			
			if (state == MOVE_HANDLES) {
				state = MOVE_POINT;
				add_new_point (x, y);
			} else if (state == MOVE_LAST_HANDLE) {
				state = NONE;
				return_if_fail (PenTool.selected_points.size != 0);
				last = PenTool.selected_points.get (PenTool.selected_points.size - 1);
				p.release_action (p, 3, x, y);
				PenTool.selected_points.add (last);
				PenTool.active_path.highlight_last_segment = false;
				
				last.path.direction_is_set = false;
				PenTool.force_direction ();
			} else {
				warning (@"Unknown state $state.");
			}
		});

		move_action.connect ((self, x, y) => {
			Tool p =  PointTool.pen ();
			PointSelection last;
			bool rh;
			
			PenTool.active_path.hide_end_handle = (state == MOVE_POINT);

			if (state == MOVE_HANDLES || state == MOVE_LAST_HANDLE) {
				return_if_fail (PenTool.selected_points.size != 0);
				last = PenTool.selected_points.get (PenTool.selected_points.size - 1);
				
				PenTool.move_selected_handle = true;
				
				rh = (state == MOVE_LAST_HANDLE);
				
				if (!move_right_handle) {
					rh = !rh;
				}
				
				PenTool.selected_handle = (rh) 
					? last.point.get_left_handle () : last.point.get_right_handle ();
				
				last.point.set_reflective_handles (true);
				last.point.convert_to_curve ();
				p.move_action (p, x, y);
				last.point.set_reflective_handles (false);
				PenTool.move_selected_handle = false;
				last.path.highlight_last_segment = true;
				
				last.point.set_tie_handle (true);
				
				p.move_action (p, x, y);
			} else {
				if (DrawingTools.get_selected_point_type () != PointType.QUADRATIC) {
					p.move_action (p, x, y);
				} else {
					PenTool.move_point_independent_of_handle = true;
					p.move_action (p, x, y);
					PenTool.move_point_independent_of_handle = false;
				}
			}
			
		});
		
		key_press_action.connect ((self, keyval) => {
			Tool p = PointTool.pen ();
			
			switch (keyval) {
				case 's':
					switch_to_line_mode ();
					break;
				case 'l':
					move_right_handle = true;
					break;
				case 'r':
					move_right_handle = false;
					break;				
			}
						
			p.key_press_action (p, keyval);
		});
		
		key_release_action.connect ((self, keyval) => {
			Tool p = PointTool.pen ();
			p.key_release_action (p, keyval);
		});
		
		draw_action.connect ((tool, cairo_context, glyph) => {
			Tool p = PointTool.pen ();
			p.draw_action (p, cairo_context, glyph);
		});
	}
	
	void switch_to_line_mode () {
		EditPoint ep;
		EditPoint last;
		
		if (PenTool.active_path.points.size > 2) {
			ep = PenTool.active_path.points.get (PenTool.active_path.points.size - 2);
			ep.get_right_handle ().convert_to_line ();
			ep.set_tie_handle (false);
			
			last = PenTool.active_path.points.get (PenTool.active_path.points.size - 1);
			last.convert_to_line ();
		}
	}
	
	void add_new_point (int x, int y) {
		PointSelection last;
		double handle_x, handle_y;
		
		PenTool p = (PenTool) PointTool.pen ();

		if (PenTool.active_path.points.size == 0) {
			last = p.new_point_action (x, y);
		} else {
			return_if_fail (PenTool.selected_points.size != 0);
			last = PenTool.selected_points.get (PenTool.selected_points.size - 1);
			
			PenTool.selected_points.clear ();
			PenTool.selected_handle = new EditPointHandle.empty ();

			p.release_action (p, 3, x, y);
			
			if (DrawingTools.get_selected_point_type () != PointType.QUADRATIC) {
				last = p.new_point_action (x, y);
			} else {
				last.point.get_right_handle ().length *= 0.999999;
				handle_x = last.point.get_right_handle ().x;
				handle_y = last.point.get_right_handle ().y;
				
				last = p.new_point_action (x, y);
				
				last.point.get_left_handle ().x = handle_x;
				last.point.get_left_handle ().y = handle_y;
			}
			
			p.press_action (p, 3, x, y);
			p.move_action (p, x, y);
		}
		
		PenTool.selected_points.clear ();
		PenTool.selected_points.add (last);	
		PenTool.selected_point = last.point; 
		PenTool.active_edit_point = null;
		PenTool.show_selection_box = false;
		
		PenTool.move_selected_handle = false;
		PenTool.move_selected = true;

		PenTool.active_path.hide_end_handle = (state == MOVE_POINT);
	}
}

}
