/*
    Copyright (C) 2012, 2013 Johan Mattsson

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

public class PenTool : Tool {

	private static const double CONTACT_SURFACE = 20;

	public static bool move_selected = false;
	public static bool begin_new_point_on_path = false;
	public static bool move_point_on_path = false;

	public static bool edit_active_corner = false;
	
	public static List<EditPoint> selected_points = new List<EditPoint> (); 

	public static EditPointHandle active_handle = new EditPointHandle.empty ();
	public static EditPointHandle selected_handle = new EditPointHandle.empty ();
	
	public static EditPoint? active_edit_point = new EditPoint ();
	public static EditPoint selected_point = new EditPoint ();

	private static bool move_selected_handle = false;

	private static double last_point_x = 0;
	private static double last_point_y = 0;

	public static double precision = 1;
	private static ImageSurface? tie_icon = null;
	
	/** First move action must move the current point in to the grid. */
	bool first_move_action = false;
	
	/** Move curve handle instead of control point. */
	private bool last_selected_is_handle = false;

	static List<Path> clockwise = new List<Path> ();
	static List<Path> counter_clockwise = new List<Path> ();
			
	public PenTool (string name) {
		string click_to_add_points;
		
		if (BirdFont.mac) {
			click_to_add_points = _("Right click or use left command key and click to add new points");
		} else {
			click_to_add_points = _("Right click to add new points, left click to move points");
		}		
		
		base (name, click_to_add_points + " " + _("and double click to add new point on path."), ',', CTRL);
		
		tie_icon = Icons.get_icon ("tie_is_active.png");
		
		select_action.connect ((self) => {
		});

		deselect_action.connect ((self) => {
			Glyph glyph = MainWindow.get_current_glyph ();
			
			force_direction ();
			glyph.close_path ();
			
			move_point_on_path = false;
			begin_new_point_on_path = false;
		});
		
		press_action.connect ((self, b, x, y) => {
			// retain path direction
			Glyph glyph = MainWindow.get_current_glyph ();
			clockwise = new List<Path> ();
			counter_clockwise = new List<Path> ();

			foreach (Path p in glyph.path_list) {
				if (p.is_clockwise ()) {
					clockwise.append (p);
				} else {
					counter_clockwise.append (p);
				}
			}
			
			first_move_action = true;
			
			last_point_x = x;
			last_point_y = y;

			press (b, x, y, false);
			
			if (GridTool.is_visible ()) {
				tie_pixels (ref x, ref y);
			}
			
			last_point_x = x;
			last_point_y = y;
		});
		
		double_click_action.connect ((self, b, x, y) => {
			last_point_x = x;
			last_point_y = y;

			press (b, x, y, true);
		});

		release_action.connect ((self, b, ix, iy) => {
			double x = ix;
			double y = iy;
			
			join_paths (x, y);

			active_handle = new EditPointHandle.empty ();

			move_selected = false;
			move_selected_handle = false;
			edit_active_corner = false;
			
			// update path direction if it has changed
			foreach (Path p in clockwise) {
				if (!p.is_open () && !p.is_clockwise ()) {
					p.reverse ();
					update_selection ();
				}
			}

			foreach (Path p in counter_clockwise) {
				if (!p.is_open () &&  p.is_clockwise ()) {
					p.reverse ();
					update_selection ();
				}
			}
		});

		move_action.connect ((self, x, y) => {
			move (x, y);
		});
		
		key_press_action.connect ((self, keyval) => {
			if (keyval == Key.DEL) {
				delete_selected_points ();
			}
			
			if (is_arrow_key (keyval)) {
				if (KeyBindings.modifier != CTRL) {
					move_selected_points (keyval);
					active_edit_point = selected_point;
				} else {
					move_select_next_point (keyval);
				}
			}	
		});
		
		key_release_action.connect ((self, keyval) => {
			double x, y;
			if (is_arrow_key (keyval)) {
				if (KeyBindings.modifier != CTRL) {
					x = Glyph.reverse_path_coordinate_x (selected_point.x);
					y = Glyph.reverse_path_coordinate_y (selected_point.y);
					join_paths (x, y);
				}
			}	
		});
		
		draw_action.connect ((tool, cairo_context, glyph) => {
			draw_on_canvas (cairo_context, glyph);
		});
	}

	public static void delete_selected_points () {
		Glyph g = MainWindow.get_current_glyph ();

		foreach (EditPoint p in selected_points) {
			p.deleted = true;
		}
		
		process_deleted ();

		foreach (var p in g.path_list) {
			if (p.has_deleted_point ()) {
				process_deleted ();
			}
		}
								
		g.update_view ();

		while (selected_points.length () > 0) {
			selected_points.remove_link (selected_points.first ());
		}
		
		selected_handle.selected = false;
		
		active_handle = new EditPointHandle.empty ();
		selected_handle = new EditPointHandle.empty ();
	
		active_edit_point = null;
		selected_point = new EditPoint ();
	}
	
	/** Retain selected points even if path is copied after running reverse. */
	public static void update_selection () {
		Glyph g = MainWindow.get_current_glyph ();
		
		while (selected_points.length () > 0) {
			selected_points.remove_link (selected_points.first ());
		}
		//remove_all_selected_points ();
		foreach (Path p in g.path_list) {
			foreach (EditPoint e in p.points) {
				if (e.is_selected ()) {
					selected_points.append (e);
				}
			}
		}
	}
	
	static void process_deleted () {
		Glyph g = MainWindow.get_current_glyph ();
		while (g.process_deleted ());
	}
	
	public static void close_all_paths () {
		Glyph g = MainWindow.get_current_glyph ();
		foreach (Path p in g.path_list) {
			p.close ();
		}
		g.close_path ();
		g.redraw_area (0, 0, g.allocation.width, g.allocation.height);
	}
	
	public void set_precision (double p) {
		precision = p;
		DrawingTools.precision.set_value_round (p, false, false);
	}
	
	public void move (double x, double y) {
		Glyph glyph = MainWindow.get_current_glyph ();
		double coordinate_x, coordinate_y;
		double px = 0;
		double py = 0;
		
		control_point_event (x, y);
		curve_active_corner_event (x, y);
		set_default_handle_positions ();
		
		// show new point on path
		if (glyph.new_point_on_path != null) {
			move_current_point_on_path (x, y);
		}
		
		// move control point handles
		if (move_selected_handle) {
			set_type_for_moving_handle ();

			if (GridTool.is_visible ()) {
				coordinate_x = Glyph.path_coordinate_x (x);
				coordinate_y = Glyph.path_coordinate_y (y);
				GridTool.tie_coordinate (ref coordinate_x, ref coordinate_y);
				px = Glyph.reverse_path_coordinate_x (coordinate_x);
				py = Glyph.reverse_path_coordinate_y (coordinate_y);
				selected_handle.move_delta ((px - last_point_x), (py - last_point_y));
			} else {
				selected_handle.move_delta ((x - last_point_x) * precision, (y - last_point_y) * precision);
			}
			
			selected_handle.parent.recalculate_linear_handles ();
			
			// Fixa: redraw line only
			glyph.redraw_area (0, 0, glyph.allocation.width, glyph.allocation.height);
			
			if (GridTool.is_visible ()) {
				last_point_x = Glyph.precise_reverse_path_coordinate_x (selected_handle.x ());
				last_point_y = Glyph.precise_reverse_path_coordinate_y (selected_handle.y ());
			} else {
				last_point_x = x;
				last_point_y = y;				
			}
			
			return;
		}

		// move edit point
		if (move_selected) {
			foreach (EditPoint p in selected_points) {
				if (GridTool.is_visible ()) {
					coordinate_x = Glyph.path_coordinate_x (x);
					coordinate_y = Glyph.path_coordinate_y (y);
					GridTool.tie_coordinate (ref coordinate_x, ref coordinate_y);
					px = Glyph.precise_reverse_path_coordinate_x (coordinate_x);
					py = Glyph.precise_reverse_path_coordinate_y (coordinate_y);
					glyph.move_selected_edit_point_delta (p, (px - last_point_x), (py - last_point_y));
				} else {
					glyph.move_selected_edit_point_delta (p, (x - last_point_x) * precision, (y - last_point_y) * precision);
				}
				
				p.recalculate_linear_handles ();
			}
		}
		
		if (GridTool.is_visible ()) {
			last_point_x = Glyph.precise_reverse_path_coordinate_x (selected_point.x);
			last_point_y = Glyph.precise_reverse_path_coordinate_y (selected_point.y);
		} else {
			last_point_x = x;
			last_point_y = y;			
		}
	}
	
	private static void tie_pixels (ref int x, ref int y) {
		double coordinate_x, coordinate_y;
		coordinate_x = Glyph.path_coordinate_x (x);
		coordinate_y = Glyph.path_coordinate_y (y);
		GridTool.tie_coordinate (ref coordinate_x, ref coordinate_y);
		x = Glyph.reverse_path_coordinate_x (coordinate_x);
		y = Glyph.reverse_path_coordinate_y (coordinate_y);
	}
	
	public void press (int button, int x, int y, bool double_click) {
		Glyph? g = MainWindow.get_current_glyph ();
		Glyph glyph = (!) g;
		
		return_if_fail (g != null);

		if (button == 2) {
			if (glyph.is_open ()) {
				force_direction ();
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
		if (button == 3 || (KeyBindings.modifier & LOGO) > 0) {
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
	
	void set_type_for_moving_handle () {
		if (selected_handle.type == PointType.LINE_CUBIC) {
			selected_handle.set_point_type (PointType.CUBIC);
		}

		if (selected_handle.type == PointType.LINE_QUADRATIC) {
			selected_handle.set_point_type (PointType.QUADRATIC);
		}

		if (selected_handle.type == PointType.LINE_DOUBLE_CURVE) {
			selected_handle.set_point_type (PointType.DOUBLE_CURVE);
		}
	}
	
	/** Set fill property to transparend for counter paths. */ 
	public static void force_direction () {
		Glyph g = MainWindow.get_current_glyph ();
		
		// don't retain direction
		while (clockwise.length () > 0) {
			clockwise.remove_link (clockwise.first ());
		}
		
		while (counter_clockwise.length () > 0) {
			counter_clockwise.remove_link (counter_clockwise.first ());
		}

		foreach (Path p in g.active_paths) {
			if (p.is_open () && !p.has_direction ()) {
				if (is_counter_path (p)) {
					p.force_direction (Direction.COUNTER_CLOCKWISE);
				} else {
					p.force_direction (Direction.CLOCKWISE);
				}				
			}
		}
	}

	public static bool is_counter_path (Path path) {
		Glyph g = MainWindow.get_current_glyph ();
		PathList pl = new PathList ();
		
		foreach (Path p in g.path_list) {
			pl.paths.append (p);
		}
		
		return Path.is_clasped (pl, path);
	}
		
	bool is_new_point_from_path_selected () {
		return false;
	}
	
	public void remove_from_selected (EditPoint ep) 
		requires (selected_points.length () > 0) {
		for (unowned List<EditPoint> e = selected_points.first (); !is_null (e.next); e = e.next) {
			if (ep.equals (e.data)) {
				ep.set_selected (false);
				selected_points.remove_link (e);
				return;
			}
		}
	}
	
	public void select_active_point (double x, double y) {
		Glyph? g = MainWindow.get_current_glyph ();
		Glyph glyph = (!) g;
		bool reverse;
		
		control_point_event (x, y);

		// continue adding points from the other end
		reverse = false;
		foreach (Path p in glyph.active_paths) {
			if (p.is_open () && p.points.length () > 1 && active_edit_point == p.points.first ().data) {
				p.reverse ();
				update_selection ();
				reverse = true;
				control_point_event (x, y);
			}
		}
				
		if (active_edit_point == null) {
			if (KeyBindings.modifier != SHIFT) {
				remove_all_selected_points ();
				return;
			}
		}
		
		move_selected = true;
		move_point_on_path = true;
		
		if (active_edit_point != null) {
			if (KeyBindings.modifier == SHIFT) {
				if (((!)active_edit_point).is_selected ()) {
					((!)active_edit_point).set_selected (false);
					remove_from_selected ((!)active_edit_point);
					selected_point = new EditPoint ();
					last_selected_is_handle = false;
				} else {
					((!)active_edit_point).set_selected (true);
					selected_point = (!)active_edit_point;
					add_selected_point (selected_point);
					last_selected_is_handle = false;
				}
			} else {
				selected_point = (!)active_edit_point;
				
				if (!((!)active_edit_point).is_selected ()) {
					remove_all_selected_points ();
					((!)active_edit_point).set_selected (true);
					selected_point = (!)active_edit_point;
					add_selected_point (selected_point);
					last_selected_is_handle = false;
				}
			}
		}
		
		if (reverse) {
			while (clockwise.length () > 0) {
				clockwise.remove_link (clockwise.first ());
			}

			while (counter_clockwise.length () > 0) {
				counter_clockwise.remove_link (counter_clockwise.first ());
			}
		}
	}
	
	private static Path? find_path_to_join () {
		Path? m = null;
		Glyph glyph = MainWindow.get_current_glyph ();
		EditPoint ep_last, ep_first;

		foreach (Path path in glyph.path_list) {
			if (path.points.length () == 0) {
				continue;
			}

			ep_last = path.points.last ().data;
			ep_first = path.points.first ().data;	
			
			if (active_edit_point == ep_last) {
				m = path;
				break;
			}
			
			if (active_edit_point == ep_first) {
				m = path;
				break;				
			}
		}
		
		return m;	
	}
	
	private static void join_paths (double x, double y) {
		Glyph glyph = MainWindow.get_current_glyph ();
		Path? p;
		Path path;
		bool direction_changed = false;
		Path union;
		
		if (glyph.path_list.length () < 1) {
			return;
		}

		p = find_path_to_join ();
		if (p == null) {
			return;
		}
		path = (!) p;
		
		if (!path.is_open ()) {
			return;
		}
		
		if (active_edit_point == path.points.first ().data) {
			path.reverse ();
			update_selection ();
			path.recalculate_linear_handles ();
			direction_changed = true;
			active_edit_point = path.points.last ().data;
		}
		
		// join path with it self
		if (path.points.first ().data != active_edit_point
			&& is_endpoint ((!) active_edit_point)
			&& is_close_to_point (path.points.first ().data, x, y)) {
				
			// TODO: set point type
			path.points.first ().data.left_handle.move_to_coordinate (
				path.points.last ().data.left_handle.x (),
				path.points.last ().data.left_handle.y ());
				
			path.points.first ().data.left_handle.type = 
				path.points.last ().data.left_handle.type;

			path.points.first ().data.recalculate_linear_handles ();
			path.points.last ().data.recalculate_linear_handles ();
			
			// force the connected handle to move
			path.points.first ().data.set_position (
				path.points.first ().data.x, path.points.first ().data.y);
		
			path.points.remove_link (path.points.last ());
			
			path.close ();
			
			force_direction ();

			if (direction_changed) {
				path.reverse ();
				update_selection ();
			}
			
			remove_all_selected_points ();
			return;
		}
		
		union = new Path ();
		foreach (EditPoint ep in path.points) {
			union.add_point (ep.copy ());
		}
				
		foreach (Path merge in glyph.path_list) {
			// don't join path with it self here
			if (path == merge) {
				continue;
			}

			// we need both start and end points
			if (merge.points.length () < 1 || path.points.length () < 1) {
				continue;
			}
			
			if (is_close_to_point (merge.points.last ().data, x, y)) {
				merge.reverse ();
				update_selection ();
				direction_changed = !direction_changed;
			}

			return_if_fail (merge.points.length () > 0);

			if (is_close_to_point (merge.points.first ().data, x, y)) {
				merge.points.first ().data.set_tie_handle (false);
				merge.points.first ().data.set_reflective_handles (false);
				
				merge.points.last ().data.set_tie_handle (false);
				merge.points.last ().data.set_reflective_handles (false);
								
				path.points.last ().data.set_tie_handle (false);
				path.points.last ().data.set_reflective_handles (false);

				path.points.first ().data.set_tie_handle (false);
				path.points.first ().data.set_reflective_handles (false);
				
				union.append_path (merge.copy ());
				glyph.add_path (union);
				
				glyph.delete_path (path);
				glyph.delete_path (merge);
				
				union.reopen ();
				union.create_list ();
				
				force_direction ();
				
				if (direction_changed) {
					path.reverse ();
					update_selection ();
				}
				
				return;
			}
		}

		if (direction_changed) {
			path.reverse ();
			update_selection ();
		}
	}
	
	/** Merge paths if ends are close. */
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
		
		return_if_fail (!is_null (glyph));
		
		px = Glyph.reverse_path_coordinate_x (active.x);
		py = Glyph.reverse_path_coordinate_y (active.y);

		foreach (Path path in glyph.path_list) {
			
			if (!path.is_open ()) {
				continue;
			}
			
			if (path.points.length () == 0) {
				continue;
			}
			
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
	
	public static bool is_endpoint (EditPoint ep) {
		EditPoint start;
		EditPoint end;
		Glyph glyph = MainWindow.get_current_glyph ();
		
		foreach (Path path in glyph.path_list) {
			if (path.points.length () < 1) {
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
			
			if (first_move_action && GridTool.is_visible () && move_selected) {
				double coordinate_x = e.x;
				double coordinate_y = e.y;
				GridTool.tie_coordinate (ref coordinate_x, ref coordinate_y);
				int px = Glyph.reverse_path_coordinate_x (coordinate_x);
				int py = Glyph.reverse_path_coordinate_y (coordinate_y);
				
				last_point_x += Glyph.reverse_path_coordinate_x (e.x) - px;
				last_point_y += Glyph.reverse_path_coordinate_y (e.y) - py;
				
				first_move_action = false;
			}
		}
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
		selected_point = new_point;
		add_selected_point (selected_point);
		
		move_selected = true;
		
		set_point_type (new_point);
		set_default_handle_positions ();
	}

	void set_point_type (EditPoint p) {
		if (p.prev != null && p.get_prev ().data.right_handle.type == PointType.QUADRATIC) {
			p.left_handle.type = PointType.QUADRATIC;
			p.right_handle.type = PointType.LINE_QUADRATIC;
			p.type = PointType.QUADRATIC;
		} else if (DrawingTools.get_selected_point_type () == PointType.QUADRATIC) {
			p.left_handle.type = PointType.LINE_QUADRATIC;
			p.right_handle.type = PointType.LINE_QUADRATIC;
			p.type = PointType.LINE_QUADRATIC;
		} else if (DrawingTools.get_selected_point_type () == PointType.DOUBLE_CURVE) {
			p.left_handle.type = PointType.LINE_DOUBLE_CURVE;
			p.right_handle.type = PointType.LINE_DOUBLE_CURVE;
			p.type = PointType.DOUBLE_CURVE;
		} else {
			p.left_handle.type = PointType.LINE_CUBIC;
			p.right_handle.type = PointType.LINE_CUBIC;
			p.type = PointType.CUBIC;				
		}
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
		last_selected_is_handle = true;
		selected_handle.selected = false;
		selected_handle = get_closest_handle (event_x, event_y);
		selected_handle.selected = true;
	}

	public static void add_selected_point (EditPoint p) {
		foreach (EditPoint ep in selected_points) {
			if (p == ep) {
				return;
			}
		}
		
		selected_points.append (p);
	}
	
	public static void remove_all_selected_points () {
		Glyph g = MainWindow.get_current_glyph ();
		
		selected_point.set_selected (false);
		selected_point.set_active (false);
		selected_point = new EditPoint ();
			
		while (selected_points.length () > 0) {
			EditPoint ep = selected_points.first ().data;
			ep.set_active (false);
			ep.set_selected (false);
			selected_points.remove_link (selected_points.first ());
		}
		
		foreach (Path p in g.path_list) {
			foreach (EditPoint e in p.points) {
				e.set_active (false);
				e.set_selected (false);
			}
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
		
		return_val_if_fail (e.next != null, new EditPoint ());
		return_val_if_fail (e.prev != null, new EditPoint ());
			
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
			set_type_for_moving_handle ();
			active_handle.active = false;
			active_handle = new EditPointHandle.empty ();
			
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
	
	public static void convert_point_to_line (EditPoint ep, bool both) {
		ep.set_tie_handle (false);
		ep.set_reflective_handles (false);
		
		if (ep.next == null) {
			warning ("Next is null.");
		}

		if (ep.prev == null) {
			warning ("Prev is null.");
		}
		
		if (ep.type == PointType.CUBIC || ep.type == PointType.LINE_CUBIC) {
			ep.type = PointType.LINE_CUBIC;
			
			if (both) {
				ep.get_left_handle ().type = PointType.LINE_CUBIC;
				ep.get_right_handle ().type = PointType.LINE_CUBIC;
			}
			
			if (ep.next != null && ep.get_next ().data.is_selected ()) {
				ep.get_right_handle ().type = PointType.LINE_CUBIC;
			}

			if (ep.prev != null && ep.get_prev ().data.is_selected ()) {
				ep.get_left_handle ().type = PointType.LINE_CUBIC;
			}
						
		}

		if (ep.type == PointType.DOUBLE_CURVE| ep.type == PointType.LINE_DOUBLE_CURVE) {
			ep.type = PointType.LINE_DOUBLE_CURVE;
			if (both) {
				ep.get_left_handle ().type = PointType.LINE_DOUBLE_CURVE;
				ep.get_right_handle ().type = PointType.LINE_DOUBLE_CURVE;
			}

			if (ep.next != null && ep.get_next ().data.is_selected ()) {
				ep.get_right_handle ().type = PointType.LINE_DOUBLE_CURVE;
			}

			if (ep.prev != null && ep.get_prev ().data.is_selected ()) {
				ep.get_left_handle ().type = PointType.LINE_DOUBLE_CURVE;
			}
		}

		if (ep.type == PointType.QUADRATIC || ep.type == PointType.LINE_QUADRATIC) {
			ep.type = PointType.LINE_QUADRATIC;
			
			if (both) {
				ep.get_left_handle ().type = PointType.LINE_QUADRATIC;
				ep.get_right_handle ().type = PointType.LINE_QUADRATIC;
				
				if (ep.next != null) {
					ep.get_next ().data.get_left_handle ().type = PointType.LINE_QUADRATIC;		
				}
				
				if (ep.prev != null) {
					ep.get_prev ().data.get_right_handle ().type = PointType.LINE_QUADRATIC;		
				}
			}
			
			if (ep.next != null && ep.get_next ().data.is_selected ()) {
				ep.get_right_handle ().type = PointType.LINE_QUADRATIC;
				ep.get_next ().data.get_left_handle ().type = PointType.LINE_QUADRATIC;
			}

			if (ep.prev != null && ep.get_prev ().data.is_selected ()) {
				ep.get_left_handle ().type = PointType.LINE_QUADRATIC;
				ep.get_prev ().data.get_right_handle ().type = PointType.LINE_QUADRATIC;
			}		
			
		}
						
		ep.recalculate_linear_handles ();
	}
	
	public static void convert_segment_to_line () {
		if (selected_points.length () == 0) {
			return;
		}
		
		if (selected_points.length () == 1) {
			convert_point_to_line (selected_points.first ().data, true);
		} else {
			foreach (EditPoint p in selected_points) {
				convert_point_to_line (p, false);
			}
		}
	}
	
	public static bool is_line (PointType t) {
		return t == PointType.LINE_QUADRATIC 
			|| t == PointType.LINE_DOUBLE_CURVE
			|| t == PointType.LINE_CUBIC;
	}

	public static PointType to_line (PointType t) {
		switch (DrawingTools.point_type) {
			case PointType.QUADRATIC:
				return PointType.LINE_QUADRATIC;
			case PointType.DOUBLE_CURVE:
				return PointType.LINE_DOUBLE_CURVE;
			case PointType.CUBIC:
				return PointType.LINE_CUBIC;
			default:
				break;
		}
		return t;
	}

	public static PointType to_curve (PointType t) {
		switch (DrawingTools.point_type) {
			case PointType.LINE_QUADRATIC:
				return PointType.QUADRATIC;
			case PointType.LINE_DOUBLE_CURVE:
				return PointType.DOUBLE_CURVE;
			case PointType.LINE_CUBIC:
				return PointType.CUBIC;
			default:
				break;
		}
		return t;
	}
	
	public static void set_converted_handle_length (EditPointHandle e) {
		if (e.type == PointType.QUADRATIC  && DrawingTools.point_type == PointType.DOUBLE_CURVE) {
			e.length *= 2;
			e.length /= 4;
		}

		if (e.type == PointType.QUADRATIC  && DrawingTools.point_type == PointType.CUBIC) {
			e.length *= 2;
			e.length /= 3;
		}

		if (e.type == PointType.DOUBLE_CURVE  && DrawingTools.point_type == PointType.QUADRATIC) {
			e.length *= 4;
			e.length /= 2;			
		}

		if (e.type == PointType.DOUBLE_CURVE  && DrawingTools.point_type == PointType.CUBIC) {
			e.length *= 4;
			e.length /= 3;		
		}

		if (e.type == PointType.CUBIC  && DrawingTools.point_type == PointType.QUADRATIC) {
			e.length *= 3;
			e.length /= 2;		
		}

		if (e.type == PointType.CUBIC  && DrawingTools.point_type == PointType.DOUBLE_CURVE) {
			e.length *= 3;
			e.length /= 4;			
		}		
	}
	
	public static void convert_point_types () {
		Glyph glyph = MainWindow.get_current_glyph ();
		glyph.store_undo_state ();
		EditPoint selected = new EditPoint ();
		bool reset_selected = false;
		
		if (selected_points.length () == 1) {
			selected = selected_points.first ().data;
			if (selected.next != null) {
				selected_points.append (selected.get_next ().data);
				selected.get_next ().data.set_selected (true);
			}
			
			if (selected.prev != null) {
				selected_points.append (selected.get_prev ().data);
				selected.get_next ().data.set_selected (true);
			}
			
			reset_selected = true;
		}
		
		foreach (EditPoint e in selected_points) {
			
			// convert segments not control points
			if (e.next == null || !e.get_next ().data.is_selected ()) {
				continue;
			}

			set_converted_handle_length (e.get_right_handle ());
			set_converted_handle_length (e.get_next ().data.get_left_handle ());
														
			if (!is_line (e.type)) {
				e.type = DrawingTools.point_type;
			} else {
				e.type = to_line (DrawingTools.point_type);
			}
			
			if (!is_line (e.get_right_handle ().type)) {
				e.get_right_handle ().type = DrawingTools.point_type;
			} else {
				e.get_right_handle ().type = to_line (DrawingTools.point_type);
			}

			if (!is_line (e.type)) {
				e.get_next ().data.get_left_handle ().type = DrawingTools.point_type;
			} else {
				e.get_next ().data.get_left_handle ().type = to_line (DrawingTools.point_type);
			}
				
			// process connected handle
			e.set_position (e.x, e.y);
			e.recalculate_linear_handles ();
		}
		
		if (reset_selected) {
			remove_all_selected_points ();
			selected_points.append (selected);
			selected.set_selected (true);
		}
	}
}

}
