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

using Math;
using Cairo;

namespace Supplement {

public class PenTool : Tool {

	private static const double CONTACT_SURFACE = 50;

	public static bool move_selected = false;
	public static bool begin_new_point_on_path = false;
	public static bool move_point_on_path = false;

	public static bool edit_active_corner = false;
	
	public static List<EditPoint> selected_points = new List<EditPoint> (); 

	public static EditPointHandle active_handle = new EditPointHandle.empty ();
	public static EditPointHandle selected_handle = new EditPointHandle.empty ();
	
	public static EditPoint? active_edit_point = new EditPoint ();

	/** Move handle vertical or horizontal. */
	public static bool tie_x_or_y_coordinates = false;

	private static bool move_selected_handle = false;

	private static double last_point_x = 0;
	private static double last_point_y = 0;

	public static double precision = 1;
	private static ImageSurface? tie_icon = null;
	
	
	/** Move curve handle instead of control point. */
	private bool last_selected_is_handle = false;
	
	public PenTool (string name) {
		base (name, _("Right click to add new points, left click to move points") + " " + _("and double click to add new point on path."), ',', CTRL);
		
		tie_icon = Icons.get_icon ("tie_is_active.png");
		
		select_action.connect ((self) => {
		});

		deselect_action.connect ((self) => {
			Glyph glyph = MainWindow.get_current_glyph ();
			
			CutTool.force_direction ();
			glyph.close_path ();
			
			move_point_on_path = false;
			begin_new_point_on_path = false;
		});
		
		press_action.connect ((self, b, x, y) => {
			last_point_x = x;
			last_point_y = y;

			press (b, x, y, false);
		});
		
		double_click_action.connect ((self, b, x, y) => {
			last_point_x = x;
			last_point_y = y;

			press (b, x, y, true);
		});

		release_action.connect ((self, b, ix, iy) => {
			double x = ix;
			double y = iy;
			
			move (x, y);
			join_paths (x, y);

			active_handle = new EditPointHandle.empty ();

			move_selected = false;
			move_selected_handle = false;
			edit_active_corner = false;
		});

		move_action.connect ((self, x, y) => {
			move (x, y);
		});
		
		key_press_action.connect ((self, keyval) => {
			Glyph g = MainWindow.get_current_glyph ();
			
			if (keyval == Key.DEL) {
				foreach (EditPoint p in selected_points) {
					g.delete_edit_point (p);
				}
				
				g.update_view ();
			}
			
			if (is_arrow_key (keyval)) {
				if (KeyBindings.modifier != CTRL) {
					move_selected_points (keyval);
				} else {
					move_select_next_point (keyval);
				}
			}
					
		});
		
		key_release_action.connect ((self, keyval) => {
		});
		
		draw_action.connect ((tool, cairo_context, glyph) => {
			draw_on_canvas (cairo_context, glyph);
		});
	}
	
	public void set_precision (double p) {
		precision = p;
		MainWindow.get_toolbox ().precision.set_value_round (p, false, false);
	}
	
	public void move (double x, double y) {
		Glyph glyph = MainWindow.get_current_glyph ();
		double coordinate_x, coordinate_y;
		
		control_point_event (x, y);
		curve_active_corner_event (x, y);
		set_default_handle_positions ();

		// show new point on path
		if (glyph.new_point_on_path != null) {
			move_current_point_on_path (x, y);
		}
		
		// move curve handles
		if (move_selected_handle) {
			if (GridTool.is_visible ()) {
				coordinate_x = Glyph.path_coordinate_x (x);
				coordinate_y = Glyph.path_coordinate_y (y);
				GridTool.tie_coordinate (ref coordinate_x, ref coordinate_y);
				selected_handle.set_point_type (PointType.CURVE);
				selected_handle.move_to_coordinate (coordinate_x, coordinate_y);
			} else {
				selected_handle.set_point_type (PointType.CURVE);
				selected_handle.move_delta ((x - last_point_x) * precision, (y - last_point_y) * precision);
			}
			
			selected_handle.parent.recalculate_linear_handles ();
			
			// Fixa: redraw line only
			glyph.redraw_area (0, 0, glyph.allocation.width, glyph.allocation.height);
						
			last_point_x = x;
			last_point_y = y;
			
			last_selected_is_handle = true;
			
			return;
		}
		
		// move edit point
		if (move_selected) {
			foreach (EditPoint p in selected_points) {
				if (GridTool.is_visible ()) {
					coordinate_x = Glyph.path_coordinate_x (x);
					coordinate_y = Glyph.path_coordinate_y (y);
					GridTool.tie_coordinate (ref coordinate_x, ref coordinate_y);
					glyph.move_selected_edit_point_coordinates (p, coordinate_x, coordinate_y);
				} else {
					glyph.move_selected_edit_point_delta (p, (x - last_point_x) * precision, (y - last_point_y) * precision);
				}
				
				if (tie_x_or_y_coordinates) {
					GridTool.tie_to_prev (p, x, y);
				}
				
				p.recalculate_linear_handles ();
			}
		
			last_selected_is_handle = false;
		}
		
		last_point_x = x;
		last_point_y = y;
		
	}
	
	public void press (int button, int x, int y, bool double_click) {
		Glyph? g = MainWindow.get_current_glyph ();
		Glyph glyph = (!) g;
		
		return_if_fail (g != null);

		if (button == 2) {
			if (glyph.is_open ()) {
				CutTool.force_direction ();
				glyph.close_path ();
			} else {
				glyph.open_path ();
			}
			
			return;
		}

		if (double_click) {
			glyph.insert_new_point_on_path (x, y);
			return;
		}

		if (is_new_point_from_path_selected ()) {
			new_point_on_path_at (x, y);
			return;	
		}

		// add new point on path 
		if (is_new_point_from_path_selected ()) {
			move_selected = true;
			move_point_on_path = true;
			glyph.new_point_on_path = null;
			return;
		}
		
		// add new point
		if (button == 3) {
			remove_all_selected_points ();
			new_point_action (x, y);
			glyph.store_undo_state ();
			return;
		}
				
		control_point_event (x, y);
		curve_corner_event (x, y);
		
		if (!move_selected_handle) {
			select_active_point (x, y);
		}

		glyph.store_undo_state ();
	}
	
	public void select_active_point (double x, double y) {
		Glyph? g = MainWindow.get_current_glyph ();
		Glyph glyph = (!) g;
		
		if (KeyBindings.modifier != SHIFT) {
			if (active_edit_point != null) {
				((!)active_edit_point).set_active (false);
			}

			remove_all_selected_points ();
		}
		
		move_selected = true;
		move_point_on_path = true;

		if (active_edit_point != null) {
			((!)active_edit_point).set_selected (true);
		}

		if (!is_over_handle (x, y)) {
			edit_active_corner = true;
			set_default_handle_positions ();
			
			if (active_edit_point != null) {
				add_selected_point ((!) active_edit_point);
			}
		}
		
		// continue adding points from the selected one
		foreach (Path p in glyph.active_paths) {
			if (p.is_open () && p.points.length () > 0 && active_edit_point == p.points.first ().data) {
				p.reverse ();
			}
		}
	}
	
	private static void join_paths (double x, double y) {
		Glyph glyph = MainWindow.get_current_glyph ();
		EditPoint ep_last, ep_first;
		Path? m = null;
		Path merge;
		
		if (glyph.path_list.length () < 2) {
			return;
		}
		
		// find the path to merge
		foreach (Path path in glyph.path_list) {
			
			if (path.points.length () < 2) {
				continue;
			}
			
			ep_last = path.points.last ().data;
			ep_first = path.points.first ().data;	
			
			if (active_edit_point == ep_last || active_edit_point == ep_first) {
				m = path;
			}			
		}
		
		if (m == null) {
			return;
		}
		
		merge = (!) m;
		
		foreach (Path path in glyph.path_list) {

			// don't join path with it self
			if (path == merge) {
				continue;
			}

			// we need both start and end points
			if (path.points.length () < 2) {
				continue;
			}

			ep_last = path.points.last ().data;
			ep_first = path.points.first ().data;	
						
			if (path.is_open ()) {
				if (is_close_to_point (ep_last, x, y)) {
					
					if (merge.is_clockwise ()) merge.reverse ();
					if (!path.is_clockwise ()) path.reverse ();
					
					glyph.store_undo_state ();
					merge.reverse ();
					path.append_path (merge);
					glyph.delete_path (merge);
					return;
				}
							
				if (is_close_to_point (ep_first, x, y)) {
					glyph.store_undo_state ();
					path.append_path (merge);
					glyph.delete_path (merge);
					return;
				}
			}
		}
	}
	
	private static bool is_close_to_point (EditPoint ep, double x, double y) {
		double px, py, distance;
		
		px = Glyph.reverse_path_coordinate_x (ep.x);
		py = Glyph.reverse_path_coordinate_y (ep.y);		

		distance = sqrt (fabs (pow (px - x, 2)) + fabs (pow (py - y, 2)));
				
		return (distance < 8);
	}

	/** Show the user that curves will be tied on release. */
	public void draw_on_canvas (Context cr, Glyph glyph) {
		ImageSurface img;
		double x, y;
		
		return_if_fail (tie_icon != null);
		
		img = (!) tie_icon;	
			
		cr.save ();
		get_tie_position (out x, out y);
		cr.set_source_surface (img, x - img.get_width () / 2, y - img.get_height () / 2);
		cr.paint ();
		cr.restore ();		
	}
	
	/** Obtain the position where to ends meet. */
	void get_tie_position (out double x, out double y) {
		Glyph glyph;
		EditPoint active;
		double px, py;

		x = -100;
		y = -100;
				
		if (active_edit_point == null) {
			return;
		}
		
		if (!is_endpoint ((!) active_edit_point)) {
			return;
		}
		
		glyph = MainWindow.get_current_glyph ();
		active = (!) active_edit_point;
		
		px = Glyph.reverse_path_coordinate_x (active.x);
		py = Glyph.reverse_path_coordinate_y (active.y);

		foreach (Path path in glyph.path_list) {
			foreach (EditPoint ep in path.points) {
			
				if (ep == active || !is_endpoint (ep)) {
					continue;
				}

				if (is_close_to_point (ep, px, py)) {
					x = Glyph.reverse_path_coordinate_x (ep.x);
					y = Glyph.reverse_path_coordinate_y (ep.y);
					return;
				}
			}
		}
	}
	
	public bool is_endpoint (EditPoint ep) {
		EditPoint start;
		EditPoint end;
		Glyph glyph = MainWindow.get_current_glyph ();
		
		foreach (Path path in glyph.path_list) {
			if (path.points.length () < 2) {
				continue;
			}
			
			start = path.points.first ().data;
			end = path.points.last ().data;
			
			if (ep == start || ep == end) {
				return true;
			}		
		}
		
		return false;
	}
	
	public void move_current_point_on_path (double x, double y) {
		Glyph g = MainWindow.get_current_glyph ();

		EditPoint e;
		
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

		g.redraw_area (0, 0, g.allocation.width, g.allocation.height);
	}

	EditPoint? get_closest_point (double ex, double ey, out Path? path) {
		double x = Glyph.path_coordinate_x (ex);
		double y = Glyph.path_coordinate_y (ey);
		double d = double.MAX;
		double nd;
		EditPoint? ep = null;
		Glyph g = MainWindow.get_current_glyph ();
		
		path = null;
		
		foreach (Path current_path in g.path_list) {
			foreach (EditPoint e in current_path.points) {
				nd = e.get_distance (x, y);
				
				if (nd < d) {
					d = nd;
					ep = e;
					path = current_path;
				}
			}	
		}
		
		return ep;
	}

	public double get_distance_to_closest_edit_point (double event_x, double event_y) {
		Path? p;
		EditPoint e;
		EditPoint? ep = get_closest_point (event_x, event_y, out p);

		double x = Glyph.path_coordinate_x (event_x);
		double y = Glyph.path_coordinate_y (event_y);
		
		if (ep == null) {
			return double.MAX;
		}
		
		e = (!) ep;
		
		return e.get_distance (x, y);
	}

	public void control_point_event (double event_x, double event_y) {
		Path? p;
		EditPoint? ep = get_closest_point (event_x, event_y, out p);
		Glyph g = MainWindow.get_current_glyph ();
		double x = Glyph.path_coordinate_x (event_x);
		double y = Glyph.path_coordinate_y (event_y);
		double distance;
		EditPoint e;
		
		set_active_edit_point (null);
		
		if (ep == null) {
			return;	
		}
		
		e = (!) ep;
		distance = e.get_distance (x, y) * g.view_zoom;

		if (distance < CONTACT_SURFACE) {
			set_active_edit_point (ep);
		}
	}

	public static bool is_new_point_from_path_selected () {
		if (!Supplement.experimental) {
			return false;
		}
		
		Tool t = MainWindow.get_toolbox ().get_tool ("new_point_on_path");
		return t.is_selected ();
	}
	
	public void new_point_action (int x, int y) {
		Glyph glyph;
		EditPoint new_point;
		glyph = MainWindow.get_current_glyph ();
		glyph.open_path ();
		
		new_point = glyph.add_new_edit_point (x, y);
		new_point.set_selected (true);
		
		if (KeyBindings.modifier != SHIFT) {
			remove_all_selected_points ();
		}
		
		add_selected_point (new_point);
		
		move_selected = true;
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

	bool new_point_on_path_at (int x, int y) {
		EditPoint ep;
		Glyph glyph = MainWindow.get_current_glyph ();
		int px, py;
						
		if (is_new_point_from_path_selected ()) {
			
			if (glyph.new_point_on_path != null) {
				ep = (!)glyph.new_point_on_path; 
				
				begin_new_point_on_path = false;
				
				px = Glyph.reverse_path_coordinate_x (ep.x);
				py = Glyph.reverse_path_coordinate_x (ep.y);
				glyph.add_new_edit_point (px, py);
				glyph.new_point_on_path = null;
				
				Toolbox.select_tool_by_name ("new_point");

				return false;
			}
			
			start_from_new_point_on_path (x, y);
			begin_new_point_on_path = true;
			
			return false;
		} else {
			begin_new_point_on_path = false;
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
	
	private bool is_over_handle (double event_x, double event_y) {
		double x = Glyph.path_coordinate_x (event_x);
		double y = Glyph.path_coordinate_y (event_y);
		Glyph g = MainWindow.get_current_glyph (); 
		double d_point = g.view_zoom * get_distance_to_closest_edit_point (event_x, event_y);
		
		double dl, dr;
	
		foreach (EditPoint selected_corner in selected_points) {
			dl = g.view_zoom * selected_corner.get_left_handle ().get_point ().get_distance (x, y);
			dr = g.view_zoom * selected_corner.get_right_handle ().get_point ().get_distance (x, y);
			
			if (dl < CONTACT_SURFACE && dl < d_point) {
				return true;
			}

			if (dr < CONTACT_SURFACE && dr < d_point) {
				return true;
			}
		}
	
		return false;
	}

	EditPointHandle get_closest_handle (double event_x, double event_y) {
		EditPointHandle left, right;
		double x = Glyph.path_coordinate_x (event_x);
		double y = Glyph.path_coordinate_y (event_y);		
		EditPointHandle eh = new EditPointHandle.empty();

		double d = double.MAX;
		double dn;
				
		foreach (EditPoint selected_corner in selected_points) {
			left = selected_corner.get_left_handle ();
			right = selected_corner.get_right_handle ();

			dn = left.get_point ().get_distance (x, y);
			
			if (dn < d) {
				eh = left;
				d = dn;
			}

			dn = right.get_point ().get_distance (x, y);
			
			if (dn < d) {
				eh = right;
				d = dn;
			}
		}
		
		return eh;
	}

	private void curve_active_corner_event (double event_x, double event_y) {
		EditPointHandle eh;
		
		active_handle.active = false;
		
		if (!is_over_handle (event_x, event_y)) {
			return;
		}		
		
		eh = get_closest_handle (event_x, event_y);
		eh.active = true;
		active_handle = eh;
	}

	private void curve_corner_event (double event_x, double event_y) {
		MainWindow.get_current_glyph ().open_path ();

		if (!is_over_handle (event_x, event_y)) {
			return;
		}

		move_selected_handle = true;
		selected_handle = get_closest_handle (event_x, event_y);
	}

	static void add_selected_point (EditPoint p) {
		foreach (EditPoint ep in selected_points) {
			if (p == ep) {
				return;
			}
		}
		
		selected_points.append (p);
	}
	
	static void remove_all_selected_points () {
		foreach (EditPoint e in selected_points) {
			e.set_active (false);
			e.set_selected (false);
		}
			
		while (selected_points.length () > 0) {
			selected_points.remove_link (selected_points.first ());
		}
	}

	static void move_select_next_point (uint keyval) {
		EditPoint next = new EditPoint ();
		Glyph g = MainWindow.get_current_glyph();
		
		if (selected_points.length () == 0) {
			return;
		}

		switch (keyval) {
			case Key.UP:
				next = get_next_point_up ();
				break;
			case Key.DOWN:
				next = get_next_point_down ();
				break;
			case Key.LEFT:
				next = get_next_point_left ();
				break;
			case Key.RIGHT:
				next = get_next_point_right ();
				break;
			default:
				break;
		}

		set_selected_point (next);		
		g.redraw_area (0, 0, g.allocation.width, g.allocation.height);	
	}

	private static EditPoint get_next_point (double angle) 
		requires (selected_points.length () != 0) {
		EditPoint e = selected_points.last ().data;		
		double right_angle = e.right_handle.angle;
		double left_angle = e.left_handle.angle;
		double min_right, min_left;
		double min;
		
		return_if_fail (e.next != null);
		return_if_fail (e.prev != null);
			
		// angle might be greater than 2 PI or less than 0
		min_right = double.MAX;
		min_left = double.MAX;
		for (double i = -2 * PI; i <= 2 * PI; i += 2 * PI) {
			min = fabs (right_angle - (angle + i));
			if (min < min_right) {
				min_right = min;
			}
			
			min = fabs (left_angle - (angle + i));
			if (min < min_left) {
				min_left = min;
			}
		}
		
		if (min_right < min_left) {
			return e.get_next ().data;
		}
		
		return e.get_prev ().data;
	}
	
	private static EditPoint get_next_point_up () {
		return get_next_point (PI / 2);
	}

	private static EditPoint get_next_point_down () {
		return get_next_point (PI + PI / 2);
	}

	private static EditPoint get_next_point_left () {
		return get_next_point (PI);
	}

	private static EditPoint get_next_point_right () {
		return get_next_point (0);
	}

	private static void set_selected_point (EditPoint ep) {
		remove_all_selected_points ();
		add_selected_point (ep);
		set_active_edit_point (ep);
		edit_active_corner = true;
		ep.set_selected (true);
		set_default_handle_positions ();		
	}

	public static void select_point_up () {	
		move_select_next_point (Key.UP);
	}

	public static void select_point_down () {
		move_select_next_point (Key.DOWN);
	}

	public static void select_point_right () {
		move_select_next_point (Key.RIGHT);
	}

	public static void select_point_left () {
		move_select_next_point (Key.LEFT);
	}

	/**
	 * Move the selected editpoint one pixel with keyboard irrespectivly of 
	 * current zoom.
	 */
	void move_selected_points (uint keyval) {
		Glyph g = MainWindow.get_current_glyph();
		
		if (!last_selected_is_handle) {
			if (keyval == Key.UP) {
				foreach (EditPoint e in selected_points) {
					e.set_position (e.x, e.y + Glyph.ivz ());
					e.recalculate_linear_handles ();
				}
			}
			
			if (keyval == Key.DOWN) {
				foreach (EditPoint e in selected_points) {
					e.set_position (e.x, e.y - Glyph.ivz ());
					e.recalculate_linear_handles ();
				}
			}

			if (keyval == Key.LEFT) {
				foreach (EditPoint e in selected_points) {
					e.set_position (e.x - Glyph.ivz (), e.y);
					e.recalculate_linear_handles ();
				}
			}

			if (keyval == Key.RIGHT) {
				foreach (EditPoint e in selected_points) {
					e.set_position (e.x + Glyph.ivz (), e.y);
					e.recalculate_linear_handles ();
				}
			}
			
		} else {
			if (keyval == Key.UP) {
				selected_handle.move_delta (0, -1);
			}
			
			if (keyval == Key.DOWN) {
				selected_handle.move_delta (0, 1);
			}

			if (keyval == Key.LEFT) {
				selected_handle.move_delta (-1, 0);
			}

			if (keyval == Key.RIGHT) {
				selected_handle.move_delta (1, 0);
			}				
		}
		
		// TODO: redraw only the relevant parts
		g.redraw_area (0, 0, g.allocation.width, g.allocation.height);
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
		
		
		Tool.yield ();
		
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
		
		px = Glyph.path_coordinate_x (x);
		py = Glyph.path_coordinate_y (y);

		mx = x * Glyph.ivz () - Glyph.xc () + g.view_offset_x;
		my = Glyph.yc () - y * Glyph.ivz () - g.view_offset_y;
		
		if (mx != px || my != py) {
			warning (@"bad coordinate $mx != $px || $my != $py");
		}
			
		test_reverse_coordinate (x, y, px, py, "ten fifteen");
		test_click_action (1, x, y);
	
		// offset no zoom
		n = "Offset no zoom";
		g.reset_zoom ();
		
		px = Glyph.path_coordinate_x (x);
		py = Glyph.path_coordinate_y (y);
		
		test_reverse_coordinate (x, y, px, py, n);
		test_click_action (1, x, y);
		
		// close path
		test_click_action (3, x, y);
	}
	
	private void test_reverse_coordinate (int x, int y, double px, double py, string n) {
		if (x != Glyph.reverse_path_coordinate_x (px) || Glyph.reverse_path_coordinate_y (py) != y) {
			warning (@"Reverse coordinates does not match current point for test case \"$n\".\n $x != $(Glyph.reverse_path_coordinate_x (px)) || $(Glyph.reverse_path_coordinate_y (py)) != $y (x != Glyph.reverse_path_coordinate_x (px) || Glyph.reverse_path_coordinate_y (py) != y)");
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

		Tool.yield ();
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
		
		Tool.yield ();
		MainWindow.get_tab_bar ().select_overview ();

		Tool.yield ();
		MainWindow.get_overview ().open_current_glyph ();
		
		pen_tool.test_select_action ();
		
		pen_tool.test_click_action (1, 0, 0); // open path
		
		pen_tool.test_click_action (1, a.x, a.y);
		pen_tool.test_click_action (1, b.x, b.y);
		pen_tool.test_click_action (1, c.x, c.y);
		pen_tool.test_click_action (3, 0, 0);
		
		test_reverse_last (@"Triangle reverse \"$name\" ($(a.x), $(a.y)), ($(b.x), $(b.y)), ($(c.x), $(c.y)) failed.");
		
		Tool.yield ();
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

		Tool.yield ();
		MainWindow.get_tab_bar ().select_overview ();

		Tool.yield ();
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
			Tool.yield ();
			
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
