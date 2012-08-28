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
	public static Path active_path = new Path ();

	public static EditPointHandle active_handle = new EditPointHandle.empty ();
	public static EditPointHandle selected_handle = new EditPointHandle.empty ();
	
	public static EditPoint? active_edit_point = new EditPoint ();

	/** Move handle vertical or horizontal. */
	public static bool tie_x_or_y_coordinates = false;

	private static bool move_selected_handle = false;

	private static double last_point_x = 0;
	private static double last_point_y = 0;

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
			last_point_x = x;
			last_point_y = y;

			press (b, x, y);
		});
		
		double_click_action.connect((self, b, x, y) => {
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
		EditPoint ep;
		
		control_point_event (x, y);
		curve_active_corner_event (x, y);
		set_default_handle_positions ();
		
		// show new point on path
		if (glyph.new_point_on_path != null) {
			move_current_point_on_path (x, y);
		}
		
		// show curve handles
		active_corner.set_active_handle (false);
		selected_corner.set_active_handle (true);
		if (active_edit_point != null) {
			active_corner = (!) active_edit_point;
			active_corner.set_active_handle (true);
		}

		// move curve handles
		if (move_selected_handle) {
			if (GridTool.is_visible ()) {
				GridTool.tie (ref x, ref y);
				selected_handle.set_point_type (PointType.CURVE);
				selected_handle.move_to (x, y);
			} else {
				selected_handle.set_point_type (PointType.CURVE);
				selected_handle.move_delta (x - last_point_x, y - last_point_y);
			}
			
			selected_handle.parent.recalculate_linear_handles ();
			
			// Fixa: redraw line only
			glyph.redraw_area (0, 0, glyph.allocation.width, glyph.allocation.height);
						
			last_point_x = x;
			last_point_y = y;
			
			return;
		}
		
		// move edit point
		if (move_selected) {
			glyph.move_selected_edit_point_delta (x - last_point_x, y - last_point_y);
			ep = (!) glyph.selected_point;
			
			if (tie_x_or_y_coordinates) {
				return_if_fail (glyph.selected_point != null);
				GridTool.tie_to_prev (ep, x, y);
			}
			
			if (active_corner != selected_corner) {
				active_corner.set_active_handle (false);
			}
			
			if (!is_over_handle (x, y) && active_edit_point != null) { 
				active_corner = (!) active_edit_point;
				active_corner.set_active_handle (true);
			}
			
			ep.recalculate_linear_handles ();
		}
		
		last_point_x = x;
		last_point_y = y;
	}
	
	public void press (int button, int x, int y) {
		Glyph? g = MainWindow.get_current_glyph ();
		Glyph glyph = (!) g;
			
		return_if_fail (g != null);

		// select or deselect a path
		if (button == 3) {
			if (glyph.has_active_path ()) {
				CutTool.force_direction ();
				glyph.close_path ();
			} else {
				glyph.open_path ();
				open_closest_path (x, y);
			}
			
			return;
		}

		// make path transparent and show edit points
		if (!glyph.is_editable ()) {
			glyph.open_path ();
			return;
		}

		if (insert_new_point_on_path_selected ()) {
			glyph.insert_new_point_on_path (x, y);
			return;
		}

		if (is_new_point_on_path_selected ()) {
			new_point_on_path_at (x, y);
			return;	
		}

		// add new point on path 
		if (is_new_point_on_path_selected ()) {
			move_selected = true;
			move_point_on_path = true;
			glyph.selected_point = active_edit_point;
			glyph.new_point_on_path = null;
			return;
		}
		
		// add new point
		if (active_edit_point == null && !is_over_handle (x, y)) {
			new_point_action (x, y);
			glyph.store_undo_state ();
			return;
		}
				
		control_point_event (x, y);
		select_active_point (x, y);
		curve_corner_event (x, y);
		glyph.store_undo_state ();
		
		if (is_erase_selected () && active_edit_point != null) {
			glyph.delete_edit_point ((!) active_edit_point);
		}
	}
	
	public void select_active_point (double x, double y) {
		Glyph? g = MainWindow.get_current_glyph ();
		Glyph glyph = (!) g;
		
		foreach (Path cp in glyph.active_paths) {
			foreach (var e in cp.points) {
				e.set_active (false);
			}
		}
		
		move_selected = true;
		move_point_on_path = true;
		
		glyph.selected_point = active_edit_point;

		if (!is_over_handle (x, y)) {
			selected_corner.set_active_handle (false);
			edit_active_corner = true;
			set_default_handle_positions ();
			
			if (active_edit_point != null) {
				selected_corner = (!) active_edit_point;
			}
		}		
	}
	
	public void move_current_point_on_path (double x, double y) {
		Glyph g = MainWindow.get_current_glyph ();

		EditPoint e;
		EditPoint ep = (!) g.new_point_on_path;
		
		double rax, ray;
		double pax, pay;

		double distance, min;
		
		return_if_fail (g.new_point_on_path != null);
		
		if (GridTool.is_visible ()) {
			GridTool.tie (ref x, ref y);
		}

		min = double.MAX;

		foreach (Path p in g.path_list) {
			if (p.points.length () < 2) {
				continue;
			}
			
			e = new EditPoint ();
			
			pax = x * Glyph.ivz () + g.view_offset_x - Glyph.xc ();
			pay = y * Glyph.ivz () + g.view_offset_y - Glyph.yc ();

			pay *= -1;

			p.get_closest_point_on_path (e, pax, pay);
			
			distance = Math.sqrt (Math.pow (Math.fabs (pax - e.x), 2) + Math.pow (Math.fabs (pay - e.y), 2));
			
			if (distance < min) {
				min = distance;
				
				g.new_point_on_path = e;
				
				rax = (pax + g.view_offset_x - Glyph.xc ()) / Glyph.ivz ();
				ray = (pax + g.view_offset_x - Glyph.xc ()) / Glyph.ivz ();
				
				g.redraw_area (rax - 5, ray - 5, 10, 10);					
			}
		}
	}

	public void set_new_point_on_path (Path ap, int x, int y) {
		Glyph g = MainWindow.get_current_glyph ();
		
		return_if_fail (ap.is_editable ());
		
		g.clear_active_paths ();
		g.add_active_path (ap);

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
			foreach (EditPoint e in current_path.points) {
				d = Math.sqrt (Math.fabs (Math.pow (e.x - x, 2) + Math.pow (e.y - y, 2)));
								
				if (d < m && d * g.view_zoom < 14 && !is_over_handle (x, y)) {
					m = d;
					set_active_edit_point (e);
					g.add_active_path (active_path);
				}
			}

		}
		
	}
	
	public static bool is_move_point_selected () {
		Tool t = MainWindow.get_toolbox ().get_tool ("move_point");
		return t.is_selected ();
	}

	public static bool insert_new_point_on_path_selected () {
		Tool t = MainWindow.get_toolbox ().get_tool ("insert_point_on_path");
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
		
		set_linear_handles_for_last_point ();
		
		move_selected = true;
	}

	void set_linear_handles_for_last_point () {
		Glyph glyph;
		glyph = MainWindow.get_current_glyph ();
		return_if_fail (glyph.active_paths.length () > 0);
		return_if_fail (glyph.active_paths.last ().data.points.length () > 0);
		glyph.active_paths.last ().data.points.last ().data.right_handle.parent.recalculate_linear_handles ();
	}

	public static void set_default_handle_positions () {
		Glyph g = MainWindow.get_current_glyph ();
		foreach (var p in g.path_list) {
			if (p.is_editable ()) {
				p.create_list ();
				set_default_handle_positions_on_path (p);
			}
		}
	}

	static void set_default_handle_positions_on_path (Path path) {
		foreach (EditPoint e in path.points) {
			e.recalculate_linear_handles ();
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
		double dp = selected_corner.get_close_distance (x, y);
		double dl = selected_corner.get_left_handle ().get_point ().get_close_distance (x, y);
		double dr = selected_corner.get_right_handle ().get_point ().get_close_distance (x, y);
		
		return (dl < dp || dr < dp);
	}

	private void curve_active_corner_event (double x, double y) {
		EditPointHandle eh;
		
		active_handle.active = false;
		
		if (!is_over_handle (x, y)) {
			return;
		}		


		eh = selected_corner.get_left_handle ();
		if (eh.get_point ().is_close (x, y)) {
			eh.active = true;
			active_handle = eh;
		}
		
		
		eh = selected_corner.get_right_handle ();
		if (eh.get_point ().is_close (x, y)) {
			eh.active = true;
			active_handle = eh;	
		}
	}

	private void curve_corner_event (double x, double y) {
		EditPointHandle eh;
		
		open_closest_path (x, y);
		
		if (!is_over_handle (x, y)) {
			return;
		}
		
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

		test_click_action (1, 130, 130); // open path
		test_click_action (1, 130, 130); // add point
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
		double px, py, mx, my;
		string n;
		
		Tool.test_open_next_glyph ();
		Glyph g = MainWindow.get_current_glyph ();
		
		xc = (int) (g.allocation.width / 2.0);
		yc = (int) (g.allocation.height / 2.0);

		g.default_zoom ();
		
		x = 10;
		y = 15;
		
		px = g.path_coordinate_x (x);
		py = g.path_coordinate_y (y);

		mx = x * g.ivz () - g.xc () + g.view_offset_x;
		my = g.yc () - y * g.ivz () - g.view_offset_y;
		
		if (mx != px || my != py) {
			warning (@"bad coordinate $mx != $px || $my != $py");
		}
			
		test_reverse_coordinate (x, y, px, py, "ten fifteen");
		test_click_action (1, x, y);
	
		// offset no zoom
		n = "Offset no zoom";
		g.reset_zoom ();
		
		px = g.path_coordinate_x (x);
		py = g.path_coordinate_y (y);
		
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

	private void test_last_is_counter_clockwise (string name) {
		bool d = ((!)MainWindow.get_current_glyph ().get_last_path ()).is_clockwise ();
		
		if (d) {
			critical (@"\nPath $name is clockwise, in test_last_is_counter_clockwise");
		}		
	}
	
	private void test_last_is_clockwise (string name) {
		bool d = ((!)MainWindow.get_current_glyph ().get_last_path ()).is_clockwise ();
		
		if (!d) {
				critical (@"\nPath $name is counter clockwise, in test_last_is_clockwise");
		}

	}
	
	private bool test_reverse_last (string name) 
		requires (MainWindow.get_current_glyph ().get_last_path () != null)
	{
		Glyph g = MainWindow.get_current_glyph ();
		Path p = (!) g.get_last_path ();
		bool direction = p.is_clockwise ();

		p.reverse ();
		
		if (direction == p.is_clockwise ()) {
			critical (@"Direction did not change after reverseing path \"$name\"\n");
			stderr.printf (@"Path length: $(p.points.length ()) \n");
			return false;
		}

		this.yield ();
		return true;
	}
	
	
	class Point {
		
		public int x;
		public int y;
		
		public Point (int x, int y) {
			this.x = x;
			this.y = y;
		}
	}
	
	private Point p (int x, int y) {
		return new Point (x, y);
	}
	
	private void test_triangle (Point a, Point b, Point c, string name = "") {
		Tool pen_tool = MainWindow.get_toolbox ().get_tool ("pen_tool");
		
		this.yield ();
		MainWindow.get_tab_bar ().select_overview ();

		this.yield ();
		MainWindow.get_overview ().open_current_glyph ();
		
		pen_tool.test_select_action ();
		
		pen_tool.test_click_action (1, 0, 0); // open path
		
		pen_tool.test_click_action (1, a.x, a.y);
		pen_tool.test_click_action (1, b.x, b.y);
		pen_tool.test_click_action (1, c.x, c.y);
		pen_tool.test_click_action (3, 0, 0);
		
		test_reverse_last (@"Triangle reverse \"$name\" ($(a.x), $(a.y)), ($(b.x), $(b.y)), ($(c.x), $(c.y)) failed.");
		
		this.yield ();
	}
	
	private void test_various_triangles () {
		test_triangle (p (287, 261), p (155, 81), p (200, 104), "First");
		test_triangle (p (65, 100), p (168, 100), p (196, 177), "Second");
		test_triangle (p (132, 68), p (195, 283), p (195, 222), "Third");
		test_triangle (p (144, 267), p (147, 27), p (296, 267), "Fourth");
	}
	
	public bool test_reverse_path () {
		// open a new glyph
		Tool pen_tool = MainWindow.get_toolbox ().get_tool ("pen_tool");

		this.yield ();
		MainWindow.get_tab_bar ().select_overview ();

		this.yield ();
		MainWindow.get_overview ().open_current_glyph ();
		
		pen_tool.test_select_action ();
		
		// paint
		int x_offset = 10;
		int y_offset = 10;
		
		test_open_next_glyph ();
		test_various_triangles ();
		
		test_open_next_glyph ();
		// draw clockwise and check direction		

		y_offset += 160;
		pen_tool.test_click_action (1, 10 + x_offset, 20 + y_offset);
		pen_tool.test_click_action (1, 17 + x_offset, 17 + y_offset);
		pen_tool.test_click_action (1, 20 + x_offset, 0 + y_offset);
		pen_tool.test_click_action (3, 0, 0);
		test_last_is_clockwise ("Clockwise triangle 1.2");

		// draw paths clockwise / counter clockwise and reverse them
		
		pen_tool.test_click_action (1, 115, 137);
		pen_tool.test_click_action (1, 89, 74);
		pen_tool.test_click_action (1, 188, 232);
		pen_tool.test_click_action (3, 0, 0);
		test_reverse_last ("Triangle 0");

		// draw incomplete paths
		y_offset += 20;
		pen_tool.test_click_action (1, 10 + x_offset, 20 + y_offset);
		pen_tool.test_click_action (3, 0, 0);
		test_reverse_last ("Point");

		y_offset += 20;
		pen_tool.test_click_action (1, 10 + x_offset, 20 + y_offset);
		pen_tool.test_click_action (1, 10 + x_offset, 20 + y_offset);
		pen_tool.test_click_action (3, 0, 0);
		test_reverse_last ("Double point");

		y_offset += 20;
		pen_tool.test_click_action (1, 10 + x_offset, 30 + y_offset);
		pen_tool.test_click_action (1, 10 + x_offset, 20 + y_offset);
		pen_tool.test_click_action (3, 0, 0);
		test_reverse_last ("Vertical line");

		y_offset += 20;
		pen_tool.test_click_action (1, 30 + x_offset, 20 + y_offset);
		pen_tool.test_click_action (1, 10 + x_offset, 20 + y_offset);
		pen_tool.test_click_action (3, 0, 0);
		test_reverse_last ("Horisontal line");

		// triangle 1
		y_offset += 20;
		pen_tool.test_click_action (1, 10 + x_offset, -10 + y_offset);
		pen_tool.test_click_action (1, 20 + x_offset, 20 + y_offset);
		pen_tool.test_click_action (1, 30 + x_offset, 0 + y_offset);
		pen_tool.test_click_action (3, 0, 0);
		test_reverse_last ("Triangle reverse 1");

		// box
		y_offset += 20;
		pen_tool.test_click_action (1, 100 + x_offset, 150 + y_offset);
		pen_tool.test_click_action (1, 150 + x_offset, 150 + y_offset);
		pen_tool.test_click_action (1, 150 + x_offset, 100 + y_offset);
		pen_tool.test_click_action (1, 100 + x_offset, 100 + y_offset); 
		pen_tool.test_click_action (3, 0, 0); // close
		test_reverse_last ("Box 1");
		
		return true;
	}
	
	private Tool select_pen () {
		Tool pen_tool = MainWindow.get_toolbox ().get_tool ("pen_tool");
		pen_tool.test_select_action ();
		return pen_tool;
	}
	
	public bool test_delete_points () {
		PenTool pen;
		Tool delete_tool = MainWindow.get_toolbox ().get_tool ("erase_tool");
		
		test_open_next_glyph ();
				
		pen = (PenTool) select_pen ();
		pen.test_click_action (1, 0, 0); // open path
		
		// draw a line with ten points
		for (int i = 1; i <= 10; i++) {
			pen.test_click_action (1, 20*i, 20);
		}	
	
		// TODO: it would be nice to test if points were created here
		
		// delete points
		delete_tool.test_select_action ();
		for (int i = 1; i <= 10; i++) {
			pen.move (20*i, 20);
			pen.test_click_action (1, 20*i, 20);
		}
		
		return true;
	}
	
	public bool test_reverse_random_triangles () {
		Tool pen;
		
		int ax, bx, cx;
		int ay, by, cy;

		bool r = true;

		test_open_next_glyph ();
		pen = select_pen ();

		for (int i = 0; i < 30; i++) {
			this.yield ();
			
			ax = Random.int_range (0, 300);
			bx = Random.int_range (0, 300);
			cx = Random.int_range (0, 300);

			ay = Random.int_range (0, 300);
			by = Random.int_range (0, 300);
			cy = Random.int_range (0, 300);

			pen.test_click_action (1, ax, ay);
			pen.test_click_action (1, bx, by);
			pen.test_click_action (1, cx, cy);
			pen.test_click_action (3, 0, 0);
		
			r = test_reverse_last (@"Random triangle № $(i + 1) ($ax, $ay), ($bx, $by), ($cx, $cy)");
			if (!r) {
				test_open_next_glyph ();
				pen = select_pen ();

				pen.test_click_action (1, ax, ay);
				pen.test_click_action (1, bx, by);
				pen.test_click_action (1, cx, cy);
		
				return false;
			}
			
			test_open_next_glyph ();
		}
		
		if (r) test_open_next_glyph ();
		
		return true;
	}
}

}
