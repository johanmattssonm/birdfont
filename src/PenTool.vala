/*
    Copyright (C) 2012 Johan Mattsson

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

namespace Supplement {

class PenTool : Tool {

	public static bool move_selected = false;
	public static bool begin_new_point_on_path = false;
	public static bool move_point_on_path = false;

	public static bool edit_active_corner = false;
	public static EditPoint active_corner = new EditPoint ();
	public static EditPoint selected_corner = new EditPoint ();

	public static EditPointHandle active_handle = new EditPointHandle.empty ();
	public static EditPointHandle selected_handle = new EditPointHandle.empty ();
	
	public static EditPoint? active_edit_point = new EditPoint ();
	public static EditPoint selected_edit_point = new EditPoint ();
	
	/** Move handle vertical or horizontal. */
	public static bool tie_x_or_y_coordinates = false;

	private static bool move_selected_handle = false;

	public PenTool (string name) {
		base (name, "Edit path", 'p', CTRL);
						
		select_action.connect((self) => {
		});

		deselect_action.connect ((self) => {
			Glyph glyph = MainWindow.get_current_glyph ();
			
			CutTool.force_direction ();
			glyph.close_path ();
			
			move_point_on_path = false; 		// Fixa: this might be better as toggle buttons
			begin_new_point_on_path = false;
		});
		
		press_action.connect((self, b, x, y) => {
			press (b, x, y);
		});

		release_action.connect((self, b, ix, iy) => {
			double x = ix;
			double y = iy;
			Glyph g = MainWindow.get_current_glyph ();
			
			if (move_selected && GridTool.is_visible ()) {
				GridTool.tie (ref x, ref y);
				g.move_selected_edit_point (x, y);
			}

			move_selected = false;
			move_selected_handle = false;
			edit_active_corner = false;
			
			selected_handle = new EditPointHandle.empty ();
			active_handle = new EditPointHandle.empty ();			
		});

		move_action.connect((self, x, y) => {
			move (x, y);
		});
	}
		
	public void move (double x, double y) {
		Glyph glyph = MainWindow.get_current_glyph ();
		
		control_point_event (x, y);
		
		if (move_selected) {
			glyph.move_selected_edit_point (x, y);
			
			if (tie_x_or_y_coordinates) {
				return_if_fail (glyph.selected_point != null);
				
				EditPoint ep = (!) glyph.selected_point;
				GridTool.tie_to_prev (ep, x, y);
			}
			
		}
		
		if (begin_new_point_on_path) {
			move_current_point_on_path (x, y);
		}
		
		if (is_corner_selected ()) {
			if (active_corner != selected_corner) {
				active_corner.set_active_handle (false);
			}
			
			if (!move_selected_handle && !is_over_handle (x, y) && active_edit_point != null) { 
				active_corner = (!) active_edit_point;
				active_corner.set_active_handle (true);
			}
			
			if (move_selected_handle) {
				if (GridTool.is_visible ()) {
					GridTool.tie (ref x, ref y);
				}
				
				selected_handle.parent.set_point_type (PointType.CURVE);
				selected_handle.move_to (x, y);
				
				selected_handle.parent.get_prev ().data.set_point_type (PointType.CURVE);
				
				// Fixa: redraw line only
				glyph.redraw_area (0, 0, glyph.allocation.width, glyph.allocation.height);				
			}
		}
		
	}

	public void move_current_point_on_path (double x, double y) {
			Glyph g = MainWindow.get_current_glyph ();

			if (g.new_point_on_path == null) {
				return;
			}
			
			if (GridTool.is_visible ()) {
				GridTool.tie (ref x, ref y);
			}
			
			return_if_fail (g.active_path != null);
			return_if_fail (g.new_point_on_path != null);
			
			EditPoint ep = (!) g.new_point_on_path;
			Path p = (!) g.active_path;
			
			double rax, ray;
			double pax, pay;

			pax = x * Glyph.ivz () + g.view_offset_x - Glyph.xc ();
			pay = y * Glyph.ivz () + g.view_offset_y - Glyph.yc ();

			pay *= -1;

			p.get_closest_point_on_path (ep, pax, pay);
			
			rax = (pax + g.view_offset_x - Glyph.xc ()) / Glyph.ivz ();
			ray = (pax + g.view_offset_x - Glyph.xc ()) / Glyph.ivz ();
			
			g.redraw_area (rax - 5, ray - 5, 10, 10);
	}

	public void set_new_point_on_path (Path ap, int x, int y) {
		Glyph g = MainWindow.get_current_glyph ();
		
		return_if_fail (ap.is_editable ());
		
		g.active_path = ap;

		if (g.new_point_on_path == null) {
			g.new_point_on_path = new EditPoint (0, 0, PointType.FLOATING);
		}
		
		move_current_point_on_path (x, y);
	}
		
	public static void set_active_edit_point (EditPoint? e) {
		Glyph g = MainWindow.get_current_glyph ();
		foreach (var p in g.path_list) {
			foreach (var ep in p.points) {
				ep.set_active (false);
			}
		}
		
		active_edit_point = e;
		
		if (e != null) {
			((!)e).set_active (true);
		}

		g.queue_draw_area (0, 0, g.allocation.width, g.allocation.height);
	}

	public void control_point_event (double event_x, double event_y) {
		Glyph g = MainWindow.get_current_glyph ();
		
		double x = event_x * Glyph.ivz () + g.view_offset_x - Glyph.xc ();
		double y = event_y * Glyph.ivz () + g.view_offset_y - Glyph.yc ();

		double m = double.MAX;
		double d = 0;
		
		y *= -1;

		set_active_edit_point (null);
		
		foreach (Path current_path in g.path_list) {
			if (!current_path.is_editable ()) {
				continue;
			}

			foreach (EditPoint e in current_path.points) {
				d = Math.sqrt (Math.fabs (Math.pow (e.x - x, 2) + Math.pow (e.y - y, 2)));
								
				if (d < m && d * g.view_zoom < 14) {
					m = d;
					set_active_edit_point (e);
				}
			}

		}
		
	}
	
	public static bool is_move_point_selected () {
		Tool t = MainWindow.get_toolbox ().get_tool ("move_point");
		return t.is_selected ();
	}

	public static bool is_new_point_on_path_selected () {
		Tool t = MainWindow.get_toolbox ().get_tool ("new_point_on_path");
		return t.is_selected ();
	}

	public static bool is_new_point () {
		Tool t = MainWindow.get_toolbox ().get_tool ("new_point");
		return t.is_selected ();
	}

	public static bool is_corner_selected () {
		Tool t = MainWindow.get_toolbox ().get_tool ("corner");
		return t.is_selected ();
	}
	
	public static bool is_erase_selected () {
		Tool t = MainWindow.get_toolbox ().get_tool ("erase_tool");
		return t.is_selected ();
	}
	
	public void new_point_action (int x, int y) {
		Glyph glyph;
		glyph = MainWindow.get_current_glyph ();
		glyph.open_path ();
		glyph.add_new_edit_point (x, y);
		move_selected = true;
	}

	public void press (int button, int x, int y) {
		Path cp;
		Glyph? g = MainWindow.get_current_glyph ();
		Glyph glyph = (!) g;
			
		return_if_fail (g != null);
		
		glyph.open_path ();
		
		control_point_event (x, y);
		
		// select or deselect a path
		if (button == 3) {
			if (glyph.has_active_path ()) {
				CutTool.force_direction ();
				glyph.close_path ();
			} else {
				glyph.open_path ();
				open_closest_path (x, y);
			}
		}
	
		if (!new_point_on_path_at (x, y)) {
			return;
		}
		
		if (!is_move_point_selected ()) {		
			move_selected = false;
			move_point_on_path = false;
		}
			
		if (is_move_point_selected () && active_edit_point != null) {
			glyph.store_undo_state ();
			
			if (glyph.has_active_path ()) {
				cp = (!) glyph.active_path;
				foreach (var e in cp.points) {
					e.set_active (false);
				}
			}
			
			move_selected = true;
			move_point_on_path = true;
			
			glyph.selected_point = active_edit_point;
		} 
		
		if (is_new_point () && button == 1) {
			glyph.store_undo_state ();
			new_point_action (x, y);
		}
		
		if (is_corner_selected ()) {
			if (!is_over_handle (x, y)) {
				selected_corner.set_active_handle (false);
				edit_active_corner = true;
				set_default_handle_positions ();
				
				if (active_edit_point != null) {
					selected_corner = (!) active_edit_point;
				}
			}
			
			curve_corner_event (x, y);
		}
		
		if (is_erase_selected () && active_edit_point != null) {
			glyph.store_undo_state ();
			glyph.delete_edit_point ((!) active_edit_point);
		}
		
	}

	void set_default_handle_positions () {
		Glyph g = MainWindow.get_current_glyph ();
		foreach (var p in g.path_list) {
			if (p.is_editable ()) {
				p.create_list ();
				set_default_handle_positions_on_path (p);
			}
		}
	}

	void set_default_handle_positions_on_path (Path path) {
		EditPointHandle h;
		EditPoint n;
		double nx, ny;
		
		// set handle pointing at next point to create a line to next point
		// as default handle position for LINE points.
		
		foreach (EditPoint e in path.points) {
			if (e.type == PointType.LINE) {
				n = e.get_next ().data;
				h = e.get_right_handle ();
				
				nx = e.x + ((n.x - e.x) / 3);
				ny = e.y + ((n.y - e.y) / 3);
				
				h.move_to_coordinate (nx, ny);
			}
		}
		
		foreach (EditPoint e in path.points) {
			if (e.type == PointType.LINE) {
				n = e.get_prev ().data;
				h = e.get_left_handle ();
				
				nx = e.x + ((n.x - e.x) / 3);
				ny = e.y + ((n.y - e.y) / 3);
				
				h.move_to_coordinate (nx, ny);
			}
		}
	}

	void open_closest_path (double x, double y) {
		Path? p;
		Glyph g = MainWindow.get_current_glyph ();

		if (g.path_list.length () == 0) return;
		
		p = g.get_closeset_path (x, y);
		
		if (p != null) {
			((!)p).set_editable (true);
			g.open_path ();
		}
	}

	bool new_point_on_path_at (int x, int y) {
		EditPoint ep;
		Glyph glyph = MainWindow.get_current_glyph ();
		
		if (is_new_point_on_path_selected ()) {
			
			if (glyph.new_point_on_path != null) {
				ep = (!)glyph.new_point_on_path; 
				
				begin_new_point_on_path = false;
				
				// Fixa: även en ny punkt på objektet
				
				glyph.add_new_edit_point (glyph.reverse_path_coordinate_x (ep.x), glyph.reverse_path_coordinate_x (ep.y));
				glyph.new_point_on_path = null;
				
				MainWindow.get_toolbox ().select_tool_by_name ("new_point");

				return false;
			}
			
			start_from_new_point_on_path (x, y);
			begin_new_point_on_path = true;
			
			return false;
		} else {
			begin_new_point_on_path = false;
		}
		
		if (glyph.active_point != null) {
			move_selected = true;
			return false;
		}
		
		return true;
	}

	void start_from_new_point_on_path (double x, double y) {		
		Glyph g = MainWindow.get_current_glyph ();
		Path? p = null;
		Path pn;
		
		p = g.get_closeset_path (x, y);

		pn = (!)p;

		if (pn.points.length () >= 2) {
			pn.set_editable (true);
			set_new_point_on_path (pn, 0, 0);
			g.open_path ();
		}
		
		begin_new_point_on_path = false;
	}
	
	public void begin_from_new_point_on_path () {
		begin_new_point_on_path = true;
	}

	private bool is_over_handle (double x, double y) {
		return selected_corner.get_left_handle ().get_point ().is_close (x, y) 
		|| selected_corner.get_right_handle ().get_point ().is_close (x, y);
	}

	private void curve_corner_event (double x, double y) {
		EditPointHandle eh;
		
		open_closest_path (x, y);
		
		eh = selected_corner.get_left_handle ();
		
		if (eh.get_point ().is_close (x, y)) {
			selected_handle = eh;
			move_selected_handle = true;
		}

		eh = selected_corner.get_right_handle ();
		
		if (eh.get_point ().is_close (x, y)) {
			selected_handle = eh;
			move_selected_handle = true;
		}
				
	}
	
	/** Draw a test glyph. */
	public override bool test () {
		test_select_action ();
		
		test_open_next_glyph ();
		
		// paint
		test_click_action (1, 30, 30); 
		test_click_action (1, 60, 30);
		test_click_action (1, 60, 60);
		test_click_action (1, 30, 60);
		
		// close
		test_click_action (3, 0, 0);

		// reopen
		test_click_action (3, 35, 35);
		
		// move around
		test_move_action (100, 200);
		test_move_action (20, 300);
		test_move_action (0, 0);
		
		// add to path
		test_move_action (70, 50);
		
		test_click_action (1, 70, 50);
		test_click_action (1, 70, 50);
		test_click_action (1, 70, 100);
		test_click_action (1, 50, 100); 
		test_click_action (1, 50, 50);
		
		// close
		test_click_action (3, 0, 0);
		
		// merge it
		
		this.yield ();
		
		return true;
	}

	public void test_active_edit_point () {
		Glyph g;
		EditPoint epa, epb;
		
		// paint
		test_select_action ();
		test_open_next_glyph ();

		g = MainWindow.get_current_glyph ();

		test_click_action (1, 130, 130); 
		epa = g.get_last_edit_point ();
		
		test_click_action (1, 160, 130);
		test_click_action (1, 160, 160);
		epb = g.get_last_edit_point ();
		
		test_click_action (1, 130, 160);
		
		// validate active point
		test_move_action (130, 130);
		warn_if_fail (active_edit_point == epa);
		
		test_move_action (161, 161); // close but not on
		warn_if_fail (active_edit_point == epb);
		
		warn_if_fail (epa != epb);
		
		// TODO: Test move handle here.
	}

	/** Test path coordinates and reverse path coordinates. */
	public void test_coordinates () {
		int x, y, xc, yc;
		double px, py;
		string n;
		
		Glyph g = MainWindow.get_current_glyph ();
		
		xc = (int) (g.allocation.width / 2.0);
		yc = (int) (g.allocation.height / 2.0);

		g.default_zoom ();
		
		x = 10;
		y = 15;
		
		px = g.path_coordinate_x (x);
		py = g.path_coordinate_y (y);

		test_reverse_coordinate (x, y, px, py, "ten fifteen");
		test_click_action (1, x, y);
	
		// offset no zoom
		n = "Offset no zoom";
		g.reset_zoom ();
		
		
		px = g.path_coordinate_x (x);
		py = g.path_coordinate_y (y);
		
		test_coordinate (px, py, x, y, n);
		test_reverse_coordinate (x, y, px, py, n);
		test_click_action (1, x, y);
				
		// zoom + offset
		n = "View zoom";
		g.default_zoom ();
		
		x = xc + 10;
		y = yc - 10;
		
		px = g.path_coordinate_x (x);
		py = g.path_coordinate_y (y);
		
		test_click_action (1, x, y);

		test_coordinate (px * g.view_zoom, py - yc * g.view_zoom, 10, 10, n);
		test_reverse_coordinate (x, y, px, py, n);
		
		// close path
		test_click_action (3, x, y);
	}
	
	private void test_coordinate (double x, double y, double px, double py, string n) {
		if (!(px - 0.5 <= x <= px + 0.5|| py - 0.5 <= y <= py + 0.5)) {
			warning (@"Expecting (x == px || y == py) got ($x == $px || $y == $py) in \"$n\"\n");
		}
	}
	
	private void test_reverse_coordinate (int x, int y, double px, double py, string n) {
		Glyph g = MainWindow.get_current_glyph ();
		if (x != g.reverse_path_coordinate_x (px) || g.reverse_path_coordinate_y (py) != y) {
			warning (@"Reverse coordinates does not match current point for test case \"$n\".\n $x != $(g.reverse_path_coordinate_x (px)) || $(g.reverse_path_coordinate_y (py)) != $y (x != g.reverse_path_coordinate_x (px) || g.reverse_path_coordinate_y (py) != y)");
		}
	}


}

}
