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

using Cairo;
using Gtk;
using Gdk;
using Math;

namespace Supplement {

class Glyph : FontDisplay {

	public const double SCALE = 1.0;

	// Background image
	GlyphBackgroundImage? background_image = null;
	bool background_image_visible = true;
	
	// Glyph zoom level
	public double view_zoom = 0.01;
	public double view_offset_x = 0;
	public double view_offset_y = 0;
	List<ZoomView> zoom_list = new List<ZoomView> ();
	int zoom_list_index = 0;
	
	// Paths
	public List<Path> path_list;	// outline // FIXME: make private
	public Path? active_path = null;
	Path? union_path = null; 		// add this to active path
	bool move_edit_point = false;
	double last_move_offset_x = 0;
	double last_move_offset_y = 0;

	// Control points
	public EditPoint? active_point = null;
	public EditPoint? selected_point = null;
	public EditPoint? new_point_on_path = null;
	public EditPoint? flipping_point_on_path = null;
	public EditPoint? last_added_edit_point = null;
		
	// The point where edit event begun 
	double pointer_begin_x = 0;
	double pointer_begin_y = 0;
		
	// Zoom area
	double zoom_x1 = 0;
	double zoom_y1 = 0;
	double zoom_x2 = 0;
	double zoom_y2 = 0;
	bool zoom_area_is_visible = false;
	
	bool move_view = false;
	public double move_offset_x = 0;
	public double move_offset_y = 0;

	public signal void queue_draw_area (int x, int y, int w, int h);
	
	public Allocation allocation;
	
	public string name;

	public double left_limit;
	public double right_limit;
	
	// x-height l-bearing etc.
	public List<Line> vertical_help_lines = new List<Line> ();
	public List<Line> horizontal_help_lines = new List<Line> ();
	List<Line> all_lines = new List<Line> (); 	// vertical, horzontal and grid lines
	bool show_help_lines = true;           			// grey lines
	bool xheight_lines_visible = false;   		 	// blue lines
	bool margin_boundries_visible = false; 			// red lines
	
	public unichar unichar_code = 0;
	
	bool editable = true;
	
	private static List <Glyph> undo_list = new List <Glyph> ();

	public Glyph (string name, unichar unichar_code = 0) {
		this.name = name;
		this.unichar_code = unichar_code;
		
		path_list.append (new Path ());
		
		add_help_lines ();

		left_limit = -28 * SCALE;
		right_limit = 28 * SCALE;
		
		// TODO: call redraw direcly
		queue_draw_area.connect ((x, y, w, h) => {
			redraw_area (x, y, w, h);
		});
	}

	public Glyph.no_lines (string name, unichar unichar_code = 0) {
		this.name = name;
		this.unichar_code = unichar_code;

		path_list.append (new Path ());
	}

	public void boundries (out double x1, out double y1, out double x2, out double y2) {
		if (path_list.length () == 0) {
			x1 = 0;
			y1 = 0;
			x2 = 0;
			y2 = 0;
			return;
		}

		x1 = double.MAX;
		y1 = double.MAX;
		x2 = double.MIN;
		y2 = double.MIN;
				
		foreach (Path p in path_list) {
			if (p.xmin < x1) x1 = p.xmin;
			if (p.xmax > x2) x2 = p.xmax;
			if (p.ymin < y1) y1 = p.ymin;
			if (p.ymax > y2) y2 = p.ymax;
		}
	}

	/** @return centrum pixel for x coordinates. */
	public static double xc () {
		return MainWindow.get_current_glyph ().allocation.width / 2.0;
	}

	/** @return centrum pixel for y coordinates. */
	public static double yc () {
		return MainWindow.get_current_glyph ().allocation.height / 2.0;
	}

	/** @return 1/view_zoom */
	public static double ivz () {
		return 1 / MainWindow.get_current_glyph ().view_zoom;
	}


	public void resized (Allocation o, Allocation n) {
		double a, b, c, d;
		
		if (view_zoom > 1) {	
			a = vertical_help_lines.first ().data.get_coordinate ();
			c = horizontal_help_lines.first ().data.get_coordinate ();
			
			this.allocation = n;
			
			b = vertical_help_lines.first ().data.get_coordinate ();
			d = horizontal_help_lines.first ().data.get_coordinate ();
		
			view_offset_x -= a - b;
			view_offset_y -= c - d;
		}
	}

	public void set_background_image (GlyphBackgroundImage bg) {
		double default_img_offset_x, default_img_offset_y;
		
		default_img_offset_x = -get_width () / 2;
		default_img_offset_y = get_height () / 4;

		default_img_offset_x = 0;
		default_img_offset_y = 0;
		
		bg.set_img_offset (default_img_offset_x, default_img_offset_y);
		
		background_image = bg;
		
		Supplement.get_current_font ().touch ();
	}
	
	public GlyphBackgroundImage? get_background_image () {
		return (!) background_image;
	}
		
	public override void scroll_wheel_up (Gdk.EventScroll e) {
		if (KeyBindings.has_ctrl ()) {
			zoom_in_at_point (e.x, e.y);
		} else if (KeyBindings.has_alt ()) { 
			view_offset_x -= 10 / view_zoom;
		} else {
			view_offset_y -= 10 / view_zoom;
		}
		
		queue_draw_area (0, 0, allocation.width, allocation.height);
	}
	
	public override void scroll_wheel_down (Gdk.EventScroll e) {
		if (KeyBindings.has_ctrl ()) {
			zoom_out_at_point (e.x, e.y);
		} else	if (KeyBindings.has_alt ()) { 
			view_offset_x += 10 / view_zoom;
		} else {
			view_offset_y += 10 / view_zoom;
		}
		
		queue_draw_area (0, 0, allocation.width, allocation.height);
	}
	
	public void add_path (Path p) {
		path_list.append (p);
	}
	
	public override void selected_canvas () {
		add_help_lines ();
		KeyBindings.singleton.set_require_modifier (false);
	}
	
	private void remove_lines () {
		while (vertical_help_lines.length () != 0) {
			vertical_help_lines.remove_link (vertical_help_lines.first ());
		}

		while (horizontal_help_lines.length () != 0) {
			horizontal_help_lines.remove_link (horizontal_help_lines.first ());
		}		
	}
	
	public void add_help_lines () {
		
		remove_lines ();

		double bgt = Supplement.get_current_font ().top_limit;
		Line top_margin_line = new Line ("top margin", bgt, false);
		top_margin_line.set_color (0.7, 0, 0, 0.5);
		top_margin_line.position_updated.connect ((pos) => {
			Supplement.get_current_font ().top_limit = pos;
		});
						
		double thp = Supplement.get_current_font ().top_position;
		Line top_line = new Line ("top", thp, false);
		top_line.position_updated.connect ((pos) => {
				Font f = Supplement.get_current_font ();
				f.top_position = pos;
			});
		
		double xhp = Supplement.get_current_font ().xheight_position;
		Line xheight_line = new Line ("x-height", xhp, false);
		xheight_line.set_color (33 / 255.0, 68 / 255.0, 120 / 255.0, 166 / 255.0);
		xheight_line.position_updated.connect ((pos) => {				
				Font f = Supplement.get_current_font ();
				f.xheight_position = pos;
			});

		double xbl = Supplement.get_current_font ().base_line;
		Line base_line = new Line ("baseline", xbl, false);
		base_line.position_updated.connect ((pos) => {
				Font f = Supplement.get_current_font ();
				f.base_line = pos;
			});

		
		double bp = Supplement.get_current_font ().bottom_position;
		Line bottom_line = new Line ("bottom", bp, false);
		bottom_line.set_color (33 / 255.0, 68 / 255.0, 120 / 255.0, 166 / 255.0);
		bottom_line.position_updated.connect ((pos) => {
				Supplement.get_current_font ().bottom_position = pos;
			});

		double bgb = Supplement.get_current_font ().bottom_limit;
		Line bottom_margin_line = new Line ("bottom margin", bgb, false);
		bottom_margin_line.set_color (0.7, 0, 0, 0.5);
		bottom_margin_line.position_updated.connect ((pos) => {
			Supplement.get_current_font ().bottom_limit = pos;
		});
							
		Line left_line = new Line ("left", left_limit, true);
		left_line.position_updated.connect ((pos) => {
				left_limit = pos;
			});
		
		Line right_line = new Line ("right", right_limit, true);
		right_line.position_updated.connect ((pos) => {
				right_limit = pos;
			});
		
		// lists of help lines are sorted and lines are added only if 
		// they are important for a particular glyph.
		
		// left to right
		add_line (left_line);
		add_line (right_line);

		bool glyph_has_top = has_top_line ();

		// top to bottom
		add_line (top_margin_line);
		top_margin_line.set_visible (margin_boundries_visible);
		
		add_line (top_line);
		top_line.set_visible (glyph_has_top || xheight_lines_visible);
		
		add_line (xheight_line);
		xheight_line.set_visible (!glyph_has_top || xheight_lines_visible);
		
		add_line (base_line);
		
		add_line (bottom_line);
		bottom_line.set_visible (CharDatabase.has_descender (unichar_code) || xheight_lines_visible);
		
		add_line (bottom_margin_line);
		bottom_margin_line.set_visible (margin_boundries_visible);
	}
	
	bool has_top_line () {
		return !unichar_code.islower () || CharDatabase.has_ascender (unichar_code);
	}
	
	/** Show both x-height and top lines. */
	public bool get_xheight_lines_visible () {
		return xheight_lines_visible;
	}

	/** Show both x-height and top lines. */
	public void set_xheight_lines_visible (bool x) {
		xheight_lines_visible = x;
		add_help_lines ();
	}
		
	public void set_margin_lines_visible (bool m) {
		margin_boundries_visible = m;
		add_help_lines ();
	}
	
	public bool get_margin_lines_visible () {
		return margin_boundries_visible;
	}
	
	public void remove_empty_paths () {
		foreach (var p in path_list) {
			if (p.points.length () == 0) {
				path_list.remove_all (p);
			}
		}
	}
	
	public string get_svg_data () {
		return Svg.to_svg_glyph (this, 1 / SCALE);
	}
	
	public int get_height () 
		requires (vertical_help_lines.length () >= 2)
	{
		unowned List<Line> a = horizontal_help_lines.first ();
		unowned List<Line> b = horizontal_help_lines.last ();
		
		return (int) Math.fabs (a.data.pos / SCALE - b.data.pos / SCALE); 
	}
	
	public int get_width () {
		return (int) Math.fabs (right_limit / SCALE - left_limit / SCALE);
	}

	public unichar get_unichar () {
		return unichar_code;
	}

	public bool get_show_help_lines () {
		return show_help_lines;
	}
	
	public void redraw_help_lines () {
		queue_draw_area (0, 0, allocation.width, allocation.height);
	}
	
	public void set_show_help_lines (bool hl) {
		show_help_lines = hl;
	}
	
	private void add_line (Line line) {
		if (line.is_vertical ()) {
			vertical_help_lines.append (line);
			line.list_item = vertical_help_lines.last ();
		} else {
			horizontal_help_lines.append (line);
			line.list_item = horizontal_help_lines.last ();
		}

		sort_help_lines ();
		
		line.queue_draw_area.connect ((x, y, w, h) => {
			this.queue_draw_area (x, y, w, h);
		});
	}
	
	public void sort_help_lines () {
		vertical_help_lines.sort ((a, b) => {
			return (int) (a.get_pos () - b.get_pos ());
		});
		
		horizontal_help_lines.sort ((a, b) => {
			return (int) (a.get_pos () - b.get_pos ());
		});
	}
	
	public override string get_name () {
		return name;
	}
			
	private void help_line_event (EventMotion e) {
		double mx = e.x;
		double my = e.y;
		
		if (GridTool.is_visible ()) {
			GridTool.tie (ref mx, ref my);
		}
		
		foreach (Line line in get_all_help_lines ()) {
			line.event_move_to (mx, my, e.x, e.y, allocation);
		}
	}

	public override void key_press (EventKey e) {	
		if (e.keyval == Key.DEL) {
			if (active_path != null) {
				Path p = (!) active_path;
				close_path ();
				path_list.remove (p);
				redraw_area (0, 0, allocation.width, allocation.height);
			}
			
			if (selected_point != null) {
				delete_edit_point ((!) selected_point);
			}
			
		}
	}
	
	/** Delete edit point from path. */
	public void delete_edit_point (EditPoint ep) {
		
		foreach (Path p in path_list) {
			foreach (EditPoint e in p.points) {
				if (likely (e == ep)) {
										
					p.set_new_start (e);

					if (p.is_open ()) {
						p.close ();
						p.points.remove (e);
						p.reopen ();
					} else {
						p.reopen ();
					}
					
					redraw_area (0, 0, allocation.width, allocation.height);
					return;
				}
			}
		}
		
		warning ("This point does not exist.");
	}
	
	public override void motion_notify (EventMotion e) {
		Tool t;
		
		if (KeyBindings.has_ctrl ()) {
			move_view_offset  (e.x, e.y);
			return;
		}
		
		t = MainWindow.get_toolbox ().get_current_tool ();
		t.move_action (t, (int) e.x, (int) e.y);
		
		help_line_event (e);	
	}
	
	public override void button_release (EventButton event) {
		bool line_moving = false;
		
		if (KeyBindings.has_ctrl ()) {
			move_view = false;
			return;
		}
		
		foreach (Line line in get_all_help_lines ()) {
			if (!line.set_move (false)) {
				line_moving = true;
			}
		}

		if (!line_moving) {
			Tool t = MainWindow.get_toolbox ().get_current_tool ();
			t.release_action (t, (int) event.button, (int) event.x, (int) event.y);
		}
		
		move_edit_point = false;
		update_view ();
	}

	private unowned List<Line> get_all_help_lines () {
		while (all_lines.length () > 0) all_lines.delete_link (all_lines.first ());
		
		all_lines.concat (vertical_help_lines.copy ());
		all_lines.concat (horizontal_help_lines.copy ());
		
		if (GridTool.is_visible ()) {
			all_lines.concat (GridTool.get_vertical_lines ().copy ());
			all_lines.concat (GridTool.get_horizontal_lines ().copy ());
		}
		
		return all_lines;
	}
		
	public void update_view () {
		MainWindow.get_glyph_canvas ().redraw ();
	}
	
	public override void leave_notify (EventCrossing e) {
	}
	
	public override void button_press (EventButton e) {				
		pointer_begin_x = e.x;
		pointer_begin_y = e.y;
		
		foreach (Line line in get_all_help_lines ()) {
			if (line.button_press (e, allocation)) {
				return;
			}
		}
				
		if (KeyBindings.has_ctrl ()) {
			move_view = true;
			move_offset_x = view_offset_x;
			move_offset_y = view_offset_y;
		} else {
			Tool t = MainWindow.get_toolbox ().get_current_tool ();
			t.press_action (t, (int) e.button, (int) e.x, (int) e.y);
		}
		
		MainWindow.hide_cursor ();
	}

	/** Insert new edit point for current path on the appropriate zoom
	 * level.
	 */
	public EditPoint add_new_edit_point (int x, int y) {
		insert_edit_point (x, y);
		move_edit_point = true;
		last_added_edit_point = ((!) active_path).get_last_point ();
		return (!) last_added_edit_point;
	}

	public EditPoint get_last_edit_point () {
		return_val_if_fail (last_added_edit_point != null, new EditPoint ());
		return (!) last_added_edit_point;
	}

	/** Move view port centrum to this coordinate. */
	public void set_center (double x, double y) {
		x -= allocation.width / 2.0;
		y -= allocation.height / 2.0;
		
		view_offset_x += x / view_zoom;
		view_offset_y += y / view_zoom;		
	}

	public void set_zoom_from_area () {
		double x = Math.fmin (zoom_x1, zoom_x2);
		double y = Math.fmin (zoom_y1, zoom_y2);

		double w = Math.fabs (zoom_x1 - zoom_x2);
		double h = Math.fabs (zoom_y1 - zoom_y2);
		
		double view_zoom_x, view_zoom_y;
		double ivz, off;

		view_offset_x += x / view_zoom;
		view_offset_y += y / view_zoom;
			
		view_zoom_x = allocation.width * view_zoom / w;
		view_zoom_y = allocation.height * view_zoom / h;
				
		// TODO: there is a max zoom level: probably ivz > 0.1
		
		if (view_zoom_x * allocation.width < view_zoom_y * allocation.height) {
			view_zoom = view_zoom_x;
			ivz = 1 / view_zoom;

			off = (view_zoom / view_zoom_y) * allocation.height / view_zoom;	
			off = allocation.height/view_zoom - off;
			off /= 2;
			
			view_offset_y -= off;

		} else {
			view_zoom = view_zoom_y;
			ivz = 1 / view_zoom;

			off = (view_zoom / view_zoom_x) * allocation.width / view_zoom;	
			off = allocation.width / view_zoom - off;
			off /= 2;			

			view_offset_x -= off;
		}
		
		zoom_area_is_visible = false;
		store_current_view ();
	}
	
	public void show_zoom_area (int sx, int sy, int nx, int ny) {
		double x, y, w, h;
				
		set_zoom_area (sx, sy, nx, ny);
		
		zoom_area_is_visible = true;
		
		x = Math.fmin (zoom_x1, zoom_x2) - 50;
		y = Math.fmin (zoom_y1, zoom_y2) - 50;

		w = Math.fabs (zoom_x1 - zoom_x2) + 100;
		h = Math.fabs (zoom_y1 - zoom_y2) + 100;
				
		queue_draw_area ((int)x, (int)y, (int)w, (int)h);
	}

	public void set_zoom_area (int sx, int sy, int nx, int ny) {
		zoom_x1 = sx;
		zoom_y1 = sy;
		zoom_x2 = nx;
		zoom_y2 = ny;
	}

	public static double path_coordinate_x (double x) {
		Glyph g = MainWindow.get_current_glyph ();
		double xc = Glyph.yc ();
		
		return_if_fail (xc != 0);
		
		x *= 1 / g.view_zoom;
		return (x - xc + g.view_offset_x);
	}

	public static int reverse_path_coordinate_x (double x) {
		Glyph g = MainWindow.get_current_glyph ();
		double xc = Glyph.xc ();
		
		return_if_fail (xc != 0);
		
		x *= g.view_zoom;
		return (int) (x + xc + g.view_offset_x);
	}

	public static double path_coordinate_y (double y) {
		Glyph? t = MainWindow.get_current_glyph ();
		
		return_val_if_fail (t != null, 0);
		
		Glyph g = (!) t;
		double yc = (g.allocation.height / 2.0);

		y *= 1 / g.view_zoom;
		
		return (yc - y) - g.view_offset_y;
	}

	public static int reverse_path_coordinate_y (double y) {
		Glyph g = MainWindow.get_current_glyph ();
		double yc = (g.allocation.height / 2.0);
		y *= g.view_zoom;
		return (int) ((yc - y) + g.view_offset_y);
	}

	public static void reverse (double x, double y, out int rx, out int ry) {
		rx = Glyph.reverse_path_coordinate_x (x);
		ry = Glyph.reverse_path_coordinate_y (y);		
	}	

	public void move_selected_path (double x, double y) {	
		if (active_path == null) {
			return;
		}
				
		move_selected_path_freely (path_coordinate_x (x), path_coordinate_y (y));
	}
	
	public void move_selected_path_freely (double coordinate_x, double coordinate_y) 
		requires (active_path != null)
	{
		double dx = coordinate_x - path_coordinate_x (pointer_begin_x);
		double dy = coordinate_y - path_coordinate_y (pointer_begin_y);

		Path path = (!) active_path;

		path.move (dx - last_move_offset_x, dy - last_move_offset_y);
		
		last_move_offset_x = dx;
		last_move_offset_y = dy;
		
		queue_redraw_path (path);
	}
	
	public void move_path_begin (double x, double y) {
		Supplement.get_current_font ().touch ();
		Path? p = null;
				
		foreach (var pt in path_list) {
			if (pt.is_over (x, y)) {
				p = pt;
			}
		}
		
		active_path = p;
		
		last_move_offset_x = 0;
		last_move_offset_y = 0;

		move_selected_path (x, y);
	}
			
	public void queue_redraw_path (Path path) {
		redraw_path (path.xmin, path.ymin, path.xmax, path.ymax);
	}
	
	private void redraw_path (double xmin, double ymin, double xmax, double ymax) {
		int yc = (int)(allocation.height / 2.0);

		double yta = yc - ymin - view_offset_y;
		double ytb = yc - ymax - view_offset_y;

		double xta = -view_offset_x - xmin;
		double xtb = -view_offset_x - xmax;

		queue_draw_area ((int)xtb - 10, (int)yta - 10, (int)(xtb - xta) + 10, (int) (yta - ytb) + 10);
	}

	public Path get_closeset_path (double x, double y) {
		double d;
		EditPoint ep = new EditPoint ();
		
		Path min_point = new Path ();
		double min_distance = double.MAX;

		double xt = path_coordinate_x (x);
		double yt = path_coordinate_y (y);

		foreach (Path p in path_list) {
			if (p.is_over (xt, yt)) {
				return p;
			}
		}

		foreach (Path p in path_list) {
			if (p.points.length () == 0) continue;
			
			p.get_closest_point_on_path (ep, xt, yt);
			d = Math.pow (ep.x - xt, 2) + Math.pow (ep.y - yt, 2);
			
			if (d < min_distance) {
				min_distance = d;
				min_point = p;
			}

		}

		if (unlikely (min_distance == double.MAX)) {
			warning (@"No path found in path_list. Length: $(path_list.length ())");
			
			if (path_list.length () > 0) {
				stderr.printf (@"p.points.length () $(path_list.first ().data.points.length ()) \n");
			}
		}
		
		return min_point;
	}
	
	public Path? get_active_path () {
		return active_path;
	}
	
	private void insert_edit_point (double x, double y) {
		unowned List<Path> paths;
		double xt, yt;
		bool added;
		Path np;
		
		if (active_path == null) {
			np = new Path ();
			active_path = np;
			path_list.append (np);
		}
		
		paths = path_list;
		
		xt = path_coordinate_x (x);
		yt = path_coordinate_y (y);
		
		added = false;

		if (new_point_on_path != null) {
			return_if_fail (active_path != null);

			Path p = new Path ();
			EditPoint e = (!) new_point_on_path;

			return_if_fail (e.prev != null);
			
			union_path = p;
			p.add_point (e);
			e.type = PointType.CURVE;
			
			paths.append (p);
			active_path = p;
			flipping_point_on_path = new_point_on_path;
			new_point_on_path = null;
			added = true;
			return;
		}
		
		if (!added && union_path != null) {
			Path p = (!) union_path;
			if (p.is_open ()) {
					p.add (xt, yt);
					active_path = p;
					added = true;
			}
		}
		
		if (!added) {
			foreach (Path p in paths) {
				if (p.is_open ()) {
					p.add (xt, yt);
					active_path = p;
					added = true;
					break;
				}
			}
		}

		if (!added) {
			foreach (Path p in paths) {
				if (p.is_over (xt, yt)) {
					p.add (xt, yt);
					active_path = p;
					added = true;
					queue_draw_area (0, 0, allocation.width, allocation.height);
					break;
				}
			}
		}
		
		if (!added) {
			if (paths.length () > 0 && paths.last ().data.is_open ()) {
				paths.last().data.add (xt, yt);
			}
			
			foreach (var p in path_list) {
				p.close ();
			}
			
			np = new Path ();
			paths.append (np);
			np.add (xt, yt);
			
			active_path = np;
		}
	
		return_if_fail (active_path != null);
	
		selected_point = ((!) active_path).get_last_point ();
	
		move_selected_edit_point (x, y);
	}
	
	public void move_selected_edit_point (double x, double y) {		
		double xc, yc, xt, yt;
		double ivz = 1 / view_zoom;
		EditPoint p;
		
		Supplement.get_current_font ().touch ();

		xc = (allocation.width / 2.0);
		yc = (allocation.height / 2.0);
				
		x *= ivz;
		y *= ivz;
	
		xt = x - xc + view_offset_x;
		yt = yc - y - view_offset_y;
		
		// redraw control point
		queue_draw_area ((int)(x - 4*view_zoom), (int)(y - 4*view_zoom), (int)(x + 3*view_zoom), (int)(y + 3*view_zoom));
		
		// update position of selected point
		((!) selected_point).set_position (xt, yt);
		
		if (view_zoom >= 2) {
			queue_draw_area (0, 0, allocation.width, allocation.height);
		} else {
			redraw_last_stroke (x, y);
		}
		
		if (flipping_point_on_path != null) {
			p = (!) flipping_point_on_path;
			p.recalculate_handles (x, y);
			queue_draw_area (0, 0, allocation.width, allocation.height);
		}		
	}
	
	private void redraw_last_stroke (double x, double y) {
		// redraw line, if we have more than one new point on path
		double px;
		double py;
		int tw;
		int th;

		double xc = (allocation.width / 2.0);

		if (active_path == null) {
			return;
		}
		
		EditPoint? pt = ((!) active_path).get_second_last_point ();
		if (pt != null) {
			EditPoint p = (!) pt;
			
			px = p.x + xc;
			py = p.y - xc;
							
			tw = (px > x) ? (int) (px - x) : (int) (x - px);
			th = (py > y) ? (int) (py - y) : (int) (y - py);
			
			if (px > x) px -= tw + 60;
			if (py > y) py -= th + 60;
			
		} else {
			px = x - 60;
			py = y - 60;
			tw = 0;
			th = 0;
		}

		queue_draw_area ((int)px - 20, (int)py - 20, tw + 120, th + 120); 		
	}
	
	public Path? get_last_path () 
		ensures (result != null)
	{
		return_if_fail (path_list.length () > 0);
		return path_list.last ().data;
	}
	
	public bool has_active_path () {
		return (active_path != null);
	}
	
	/** Close all editable paths and return false if no path have boon closed. 
	 * Paths without area (points and lines) will be deleted.
	 */
	public bool close_path () {
		bool r = false;
		
		foreach (var p in path_list) {
			if (p.is_editable ()) {
				r = true;
				p.close ();
				redraw_path_region (p);
			}
		}
		
		editable = false;
		
		active_path = null;
		union_path = null; 
		new_point_on_path = null;
		flipping_point_on_path = null;
		selected_point = null;
		
		delete_invisible_paths ();
		
		return r;
	}

	public void open_path () {
		editable = true;
		
		foreach (var p in path_list) {
			p.set_editable (true);
			redraw_path_region (p);
		}
	}
	
	public void redraw_path_region (Path p) {
		int x, y, w, h;
			
		p.update_region_boundries ();
		
		x = reverse_path_coordinate_x (p.xmin);
		y = reverse_path_coordinate_x (p.xmin);
		w = reverse_path_coordinate_x (p.xmax) - x;
		h = reverse_path_coordinate_x (p.ymax) - y; // FIXME: redraw path
					
		queue_draw_area (x, y, w, h);		
	}

	/** Delete all paths without area. */
	private void delete_invisible_paths () {
		foreach (var p in path_list) {
			
			if (p.points.length () < 2) {
				path_list.remove (p);
				continue;
			}
			
			if (p.points.length () == 2) {
				if (p.points.first ().data.type == PointType.LINE && p.points.last ().data.type == PointType.LINE) {
					path_list.remove (p);
					continue;
				}
			}
			
		}
	}

	/** lsb */
	public double get_left_marker () {
		foreach (var line in vertical_help_lines) {
			if (line.get_label () == "left") {
				return line.get_coordinate ();
			}
		}
		
		warn_if_reached ();
		
		return 0;
	}	

	/** rsb */
	public double get_right_marker () {
		foreach (var line in vertical_help_lines) {
			if (line.get_label () == "right") {
				return line.get_coordinate ();
			}
		}
		
		warn_if_reached ();
		
		return 0;
	}

	public Line get_line (string name) {		
		foreach (Line line in vertical_help_lines) {
			if (likely (line.get_label () == name)) {
				return line;
			}
		}
		
		foreach (Line line in horizontal_help_lines) {
			if (likely (line.get_label () == name)) {
				return line;
			}
		}
		
		warning (@"No line with label $name found");
		return new Line ("Err");
	}
	
	public override void zoom_in () {
		set_zoom_area (10, 10, allocation.width - 10, allocation.height - 10);
		set_zoom_from_area ();
		update_view ();
	}
	
	public override void zoom_out () {
		double w = allocation.width;
		int n = (int) (10 * ((w - 10) / allocation.width));
		set_zoom_area (-n, -n, allocation.width + n, allocation.height + n);
		set_zoom_from_area ();
		update_view ();
	}
	
	public override void zoom_max () {
		default_zoom ();
	}
	
	public override void zoom_min () {
		double ax =  1000;
		double ay =  1000;
		double bx = -1000;
		double by = -1000;
		
		int iax, iay, ibx, iby;
		
		reset_zoom ();

		foreach (var p in path_list) {
			p.update_region_boundries ();
			
			if (p.points.length () > 2) {
				if (p.xmin < ax) ax = p.xmin;
				if (p.ymin < ay) ay = p.ymin;			
				if (p.xmax > bx) bx = p.xmax;
				if (p.ymax > by) by = p.ymax;
			}
		}
	
		if (ax == 1000) return; // empty page
		
		// Fixa: Skrota eller ordna upp reverse och path_coordinate
		reverse (ax, ay, out iax, out iay);
		reverse (bx, by, out ibx, out iby);
	
		show_zoom_area (iax - 5, iay - 5, ibx + 5, iby + 5); // set this later on button release
		set_zoom_from_area ();
		
		queue_draw_area (0, 0, allocation.width, allocation.height);
		
	}

	public override void store_current_view () {
		if (zoom_list_index + 1 < zoom_list.length ()) {
			unowned List<ZoomView> n = zoom_list.nth (zoom_list_index);
			while (n != zoom_list.last ()) zoom_list.delete_link (zoom_list.last ());
		}
		
		zoom_list.append (new ZoomView (view_offset_x, view_offset_y, view_zoom, allocation));
		zoom_list_index = (int) zoom_list.length () - 1;
		if (zoom_list.length () > 50) zoom_list.delete_link (zoom_list.first ());
	}
	
	public override void restore_last_view () 
		requires (zoom_list.length () > 0)
	{		
		if (zoom_list_index - 1 < 0 || zoom_list.length () == 0)
			return;
		
		zoom_list_index--;
			
		ZoomView z = zoom_list.nth (zoom_list_index).data;
			
		view_offset_x = z.x;
		view_offset_y = z.y;
		view_zoom = z.zoom;
		allocation = z.allocation;
	}

	public override void next_view () 
		requires (zoom_list.length () > 0)
	{
		if (zoom_list_index + 1 >= zoom_list.length ())
			return;
		
		zoom_list_index++;
		
		ZoomView z = zoom_list.nth (zoom_list_index).data;
			
		view_offset_x = z.x;
		view_offset_y = z.y;
		view_zoom = z.zoom;
		allocation = z.allocation;		
	}
	
	public override void reset_zoom () {
		view_offset_x = 0;
		view_offset_y = 0;
		
		set_zoom (1);
		
		store_current_view ();
	}
	
	/** Get x-height or top line. */
	public Line get_upper_line () 
		requires (horizontal_help_lines.length () > 2)
	{
		
		if (has_top_line () || xheight_lines_visible) {
			return get_line ("top");
		}
		
		return get_line ("x-height");
	}

	/** Get base line. */
	public Line get_lower_line () 
		requires (horizontal_help_lines.length () > 2)
	{
		return horizontal_help_lines.last ().prev.data;
	}
		
	/** Set default zoom. See default_zoom. */
	public void set_default_zoom () {
		int l, t, b, r;
		
		double bottom = 0;
		double top = 0;
		double left = 0;
		double right = 0;
	
		unowned List<Line>? n = horizontal_help_lines;
		unowned List<Line>? v = vertical_help_lines;
		
		if (unlikely (n == null)) {
				warning ("n == null");
				warning (@"Can not set default zoom for $name, help lines are not available.");
		}
		
		return_if_fail (v != null);
		return_if_fail (vertical_help_lines.length () != 0);
		return_if_fail (horizontal_help_lines.length () != 0);

		reset_zoom ();
		
		bottom = -get_lower_line ().get_pos ();
		top = -get_upper_line ().get_pos ();

		left = vertical_help_lines.last ().data.get_pos ();
		right = vertical_help_lines.first ().data.get_pos ();
		
		l = reverse_path_coordinate_x (left);
		t = reverse_path_coordinate_y (top);
		r = reverse_path_coordinate_x (right); 
		b = reverse_path_coordinate_y (bottom);
		
		set_zoom_area (l + 10, t - 10, r - 10, b + 10);
		set_zoom_from_area ();
	}
	
	/** Set default zoom and redraw canvas. */
	public void default_zoom () {
		set_default_zoom ();
		update_view ();
	}
	
	public bool is_empty () {
		bool p = path_list.length () == 0 || path_list.first ().data.points.length () == 0;
		return p && background_image == null;
	}
	
	private void set_zoom (double z)
		requires (z > 0)
	{		
		view_zoom = z;
	}

	public void set_background_visible (bool visibility) {
		background_image_visible = visibility;
	}
	
	public bool get_background_visible () {
		return background_image_visible;
	}
	
	private void plot_outline (Context cr) {
		foreach (unowned Path p in path_list) {
			p.plot (cr, allocation, view_zoom);
		}		
	}
	
	private void draw_path (Context cr) {
		double left, baseline;
		
		// plot_outline (cr);
			
		cr.save ();
		
		baseline = get_line ("baseline").pos;
		left = get_line ("left").pos;
		
		if (!editable) {
			Svg.draw_svg_path (cr, get_svg_data (), Glyph.xc () + left, Glyph.yc () + baseline, SCALE);
		}
		
		foreach (unowned Path p in path_list) {
			p.draw_edit_points (cr, allocation, view_zoom);
		}

		if (new_point_on_path != null) {
			Path.draw_edit_point_center ((!) new_point_on_path, cr);
		}			

		cr.restore ();
	}
	
	private void draw_zoom_area(Context cr) {
		cr.save ();
		cr.set_line_width (2.0);
		cr.set_source_rgba (1, 0, 0, 0.3);
		cr.rectangle (Math.fmin (zoom_x1, zoom_x2), Math.fmin (zoom_y1, zoom_y2), Math.fabs (zoom_x1 - zoom_x2), Math.fabs (zoom_y1 - zoom_y2));
		cr.fill_preserve ();
		cr.restore ();
	}

	private void draw_background_color (Context cr, double opacity) {
		cr.save ();
		cr.rectangle (0, 0, allocation.width, allocation.height);
		cr.set_line_width (0);
		cr.set_source_rgba (1, 1, 1, opacity);
		cr.fill ();
		cr.stroke ();
		cr.restore ();
	}
	
	private void draw_help_lines (Context cr) {
		
		// lines 
		foreach (Line line in get_all_help_lines ()) {
			cr.save ();
			line.draw (cr, allocation);
			cr.restore ();
		}
		
	}
	
	public override void draw (Allocation allocation, Context cr) {
		Tool tool;
		
		this.allocation = allocation;

		ImageSurface ims = new ImageSurface (Format.ARGB32, allocation.width, allocation.height);
		Context cms = new Context (ims);
		
		ImageSurface ps = new ImageSurface (Format.ARGB32, allocation.width, allocation.height);
		Context cmp = new Context (ps);

		cr.save ();
		draw_background_color (cr, 1);
		cr.restore ();

		if (show_help_lines) {
			cmp.save ();
			cmp.scale (view_zoom, view_zoom);
			cmp.translate (-view_offset_x, -view_offset_y);
			draw_help_lines (cmp);
			cmp.restore ();
		}

		if (background_image != null && background_image_visible) {
			cmp.save ();
			((!)background_image).draw (cr, allocation, view_offset_x, view_offset_y, view_zoom);
			cmp.restore ();
		}
						
		cmp.save ();
		cmp.scale (view_zoom, view_zoom);
		cmp.translate (-view_offset_x, -view_offset_y);
		draw_path (cmp);
		cmp.restore ();
		
		cmp.save (); 
		tool = MainWindow.get_toolbox ().get_current_tool ();
		tool.draw_action (tool, cmp, this);
		cmp.restore ();
		
		// detta kanske är en del av verktyget
		if (zoom_area_is_visible) {
			cmp.save ();
			draw_zoom_area (cmp);
			cmp.restore ();
		}
		
		cr.save ();
		cr.set_source_surface (ps, 0, 0);
		cr.paint ();
		cr.restore ();
	}	
	
	private void add_layer (ImageSurface path_image, ImageSurface background_image, Context cr) {
		cr.save ();
		unowned uchar[] pb = background_image.get_data ();
		unowned uchar[] pp = path_image.get_data ();
		int len;

		int bw = background_image.get_width ();
		int bh = background_image.get_height ();

		int pw = path_image.get_width ();
		int ph = path_image.get_height ();
				
		ImageSurface cs = new ImageSurface (Format.ARGB32, pw, ph);
			
		unowned uchar[] img = cs.get_data ();
		
		len = pw * ph * 4;
		int i = 0;
		while (i < len) {
			img[i++] = 0;
		}

		len = pw * ph * 4;
		int pi = 0;
		int bi = 0;
		
		while (true) {
				
			for (int c = 0; c < bw && c < pw; c += 4) {
				switch (pp[c+3]) {
					case 255:
						img[c + pi] = pb[c + bi];
						img[c+1 + pi] = pb[c+1 + bi];
						img[c+2 + pi] = pb[c+2 + bi];
						img[c+3 + pi] = 255;
						break;
					
					default:
						img[c + pi] = pp[c + bi];
						img[c+1 + pi] = pp[c+1 + bi];
						img[c+2 + pi] = pp[c+2 + bi];
						img[c+3 + pi] = 255;
						break;
				}
			}
			
			bi += bw;
			pi += pw;
			
			if (bi >= 4 * bw * bh) {
				break;
			}
			
			if (pi >= 4 * pw * ph) {
				break;
			}
			
		}

		cr.set_source_surface (cs, 0, 0);
	
		cr.paint ();
		cr.restore ();
	}

	private void zoom_in_at_point (double x, double y) {
		int n = -10;
		zoom_at_point (x, y, n);
	}
		
	private void zoom_out_at_point (double x, double y) {
		int n = (int) (10.0 * ((allocation.width - 10.0) / allocation.width));
		zoom_at_point (x, y, n);
	}
	
	/** Zoom in @param n pixels. */
	private void zoom_at_point (double x, double y, int n) {
		double w = allocation.width;
		double h = allocation.height;
		
		double rx = Math.fabs (w / 2 - x) / (w / 2);
		double ry = Math.fabs (h / 2 - y) / (h / 2);
		
		int xd = (x < w / 2) ? (int) (n * rx) : (int) (-n * rx);
		int yd = (y < h / 2) ? (int) (n * ry) : (int) (-n * ry);
			
		show_zoom_area (-n + xd, -n + yd, allocation.width + n + xd, allocation.height + n + yd);
		set_zoom_from_area ();
	}
	
	private void move_view_offset (double x, double y) {
		if (move_view) {
			view_offset_x = move_offset_x + (pointer_begin_x - x) * (1/view_zoom);
			view_offset_y = move_offset_y + (pointer_begin_y - y) * (1/view_zoom);
			redraw_area (0, 0, allocation.width, allocation.height);
		}
	}

	public void store_undo_state () {
		Glyph g = copy ();
		undo_list.append (g);		
	}

	public Glyph copy () {
		Glyph g = new Glyph.no_lines (name, unichar_code);
		
		g.left_limit = left_limit;
		g.right_limit = right_limit;
		
		g.remove_lines ();
		
		foreach (Line line in get_all_help_lines ()) {
			g.add_line (line.copy ());
		}

		foreach (Path p in path_list) {
			g.add_path (p.copy ());
		}
		
		g.active_path = active_path;
				
		return g;
	}

	public override void undo () {
		Glyph g;
		
		if (undo_list.length () == 0) {
			return;
		}
		
		g = undo_list.last ().data;
		
		while (path_list.length () > 0) {
			path_list.remove_link (path_list.last ());
		}
		
		foreach (Path p in g.path_list) {
			add_path (p);
		}

		remove_lines ();
		foreach (Line line in g.get_all_help_lines ()) {
			add_line (line.copy ());
		}
				
		active_path = g.active_path;
		
		undo_list.remove_link (undo_list.last ());
	}
	
}

}
