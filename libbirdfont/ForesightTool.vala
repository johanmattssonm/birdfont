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
	public const uint MOVE_FIRST_HANDLE = 3;
	
	uint state = NONE;
	bool move_right_handle = true;
	int previous_point = 0;
	
	Path current_path = new Path ();

	public ForesightTool (string name) {
		base (name, t_ ("Create Beziér curves"));

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
			
			if (previous_point > 0) {
				previous_point = 0;
				state = MOVE_POINT;
			} else {	
				if (state == NONE) {
					state = MOVE_POINT;
					add_new_point (x, y);
					
					p.last_point_x = Glyph.path_coordinate_x (x);
					p.last_point_y = Glyph.path_coordinate_y (y);
					
					move_action (this, x, y);
					
					state = MOVE_FIRST_HANDLE;
				} else if (state == MOVE_POINT) {			
					state = MOVE_HANDLES;
					
					if (p.has_join_icon ()) {
						print ("JOIN\n");
					
						if (unlikely (PenTool.active_path.points.size == 0)) {
							warning ("No point to join.");
							return;
						}

						ps = new PointSelection (PenTool.active_path.points.get (PenTool.active_path.points.size - 1), PenTool.active_path);
						ps.point.set_tie_handle (false);
						ps.point.convert_to_curve ();
						
						ps = new PointSelection (PenTool.active_path.points.get (0), PenTool.active_path);
						ps.point.set_tie_handle (false);
						ps.point.convert_to_curve ();
						
						first_point = PenTool.active_path.points.get (0);
						clockwise = PenTool.active_path.is_clockwise ();
						
						p.move_selected = false;
						p.release_action (p, 2, x, y);
						
						p.move_selected = false;
						p.press_action (p, 2, x, y);

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
			}
		});
		
		double_click_action.connect ((self, b, x, y) => {
			Tool p = PointTool.pen ();
			
			if (!BirdFont.android) {
				p.double_click_action (p, b, x, y);
			}
		});

		release_action.connect ((self, b, x, y) => {
			PenTool p = (PenTool) PointTool.pen ();
			PointSelection last;

			if (state == MOVE_HANDLES || state == MOVE_FIRST_HANDLE) {
				if (state == MOVE_FIRST_HANDLE) {
					last = add_new_point (x + 100, y);
					last.point.x = Glyph.path_coordinate_x (x);
					last.point.y = Glyph.path_coordinate_y (y);
				} else {
					last = add_new_point (x, y);
				}
				
				state = MOVE_POINT;
			} else if (state == MOVE_LAST_HANDLE) {
				previous_point = 0;
				
				if (unlikely (PenTool.selected_points.size == 0)) {
					warning ("No point in move last handle.");
					return;
				}
				
				last = PenTool.selected_points.get (PenTool.selected_points.size - 1);
				
				p.release_action (p, 2, x, y);
				
				PenTool.selected_points.add (last);
				PenTool.active_path.highlight_last_segment = false;
				
				last.path.direction_is_set = false;
				PenTool.force_direction ();
				
				print ("LAST.");
				
				state = NONE;
			} else if (state == MOVE_POINT) {
			} else {
				warning (@"Unknown state $state.");
			}
			
			current_path.hide_end_handle = true;
		});

		move_action.connect ((self, x, y) => {
			Tool p =  PointTool.pen ();
			PointSelection last;
			bool lh;
			EditPointHandle h;
			
			PenTool.active_path = current_path;
			PenTool.active_path.hide_end_handle = (state == MOVE_POINT);
			
			if (state == MOVE_HANDLES || state == MOVE_LAST_HANDLE) {				
				if (previous_point > 0) {
					return_if_fail (PenTool.active_path.points.size >= previous_point + 1);
					last = new PointSelection (PenTool.active_path.points.get (PenTool.active_path.points.size - (previous_point + 1)), PenTool.active_path);				
				} else {
					if (unlikely (PenTool.selected_points.size == 0)) {
						warning ("No point to move in state %u", state);
						return;
					}
					last = PenTool.selected_points.get (PenTool.selected_points.size - 1);
				}
				
				PenTool.move_selected_handle = true;
				PenTool.move_selected = false;
				
				lh = (state == MOVE_LAST_HANDLE);
				
				if (!move_right_handle) {
					lh = !lh;
				}
				
				if (previous_point > 0) {
					lh = false;
				}
				
				h = (lh) ? last.point.get_left_handle () : last.point.get_right_handle ();
				PenTool.selected_handle = h;
				PenTool.active_handle = h;
				
				if (previous_point == 0) {
					last.point.set_reflective_handles (true);
				} 
				
				if (previous_point > 0) {
					PenTool.retain_angle = last.point.tie_handles;
				}
				
				if (h.is_line ()) {
					last.point.convert_to_curve ();
					last.point.get_right_handle ().length = 0.01;
					last.point.get_left_handle ().length = 0.01;
				}
				
				p.move_action (p, x, y);
				last.point.set_reflective_handles (false);
				
				PenTool.selected_handle = h;
				PenTool.active_handle = h;
				
				PenTool.move_selected_handle = false;
				last.path.highlight_last_segment = true;
				
				if (previous_point == 0) {
					last.point.set_tie_handle (true);
					p.move_action (p, x, y);
				}
				
				PenTool.retain_angle = false;
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
			unichar c = ((unichar) keyval).tolower ();
			EditPoint ep;
			
			switch (c) {
				case 's':
					switch_to_line_mode ();
					break;
				case 'r':
					move_right_handle = !move_right_handle;
					state = MOVE_HANDLES;
					break;			
				case 'p':
					previous_point++;
					state = MOVE_HANDLES;
					break;
				case 'w':	
					if (previous_point != 0) {
						return_if_fail (current_path.points.size >= (previous_point + 1));
						ep = current_path.points.get (current_path.points.size - (previous_point + 1));
					} else {
						return_if_fail (current_path.points.size >= 1);
						ep = current_path.points.get (current_path.points.size - 1);
					}
					
					ep.set_tie_handle (!ep.tie_handles);
					
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
	
	PointSelection add_new_point (int x, int y) {
		PointSelection last;
		double handle_x, handle_y;
		
		PenTool p = (PenTool) PointTool.pen ();

		if (PenTool.active_path.points.size == 0) {
			last = p.new_point_action (x, y);
		} else {
			if (PenTool.selected_points.size == 0) {
				warning ("No selected points.");
				return new PointSelection.empty ();
			}
			
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
			
			PenTool.move_selected = true;
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
		
		current_path = last.path;
		
		return last;
	}
}

}
