/*
    Copyright (C) 2012 2013 2014 2015 Johan Mattsson

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
using Gee;

namespace BirdFont {

public class Glyph : FontDisplay {
	// Background image
	BackgroundImage? background_image = null;
	bool background_image_visible = true;
	
	// Glyph zoom level
	public double view_zoom = 0.1;
	
	public double view_offset_x = 0;
	public double view_offset_y = 0;
	Gee.ArrayList<ZoomView> zoom_list = new Gee.ArrayList<ZoomView> ();
	int zoom_list_index = 0;
	
	// Paths
	public Gee.ArrayList<Path> path_list = new Gee.ArrayList<Path> ();	
	public Gee.ArrayList<Path> active_paths = new Gee.ArrayList<Path> ();

	// The point where edit event begun 
	double pointer_begin_x = 0;
	double pointer_begin_y = 0;

	// Tap last tap event position in pixels
	int last_tap0_y = 0;
	int last_tap0_x = 0;
	int last_tap1_y = 0;
	int last_tap1_x = 0;
	double zoom_distance = 0;
	bool change_view; 

	bool ignore_input = false;
	
	// Current pointer position
	public double motion_x = 0;
	public double motion_y = 0;
		
	// Zoom area
	double zoom_x1 = 0;
	double zoom_y1 = 0;
	double zoom_x2 = 0;
	double zoom_y2 = 0;
	bool zoom_area_is_visible = false;
	
	bool view_is_moving = false;
	public double move_offset_x = 0;
	public double move_offset_y = 0;
	bool move_canvas = false;

	public WidgetAllocation allocation = new WidgetAllocation ();

	public unichar unichar_code = 0; // FIXME: name and unichar should be moved to to glyph collection 
	public string name;

	public double left_limit;
	public double right_limit;
	
	// x-height, lsb, etc.
	public Gee.ArrayList<Line> vertical_help_lines = new Gee.ArrayList<Line> ();
	public Gee.ArrayList<Line> horizontal_help_lines = new Gee.ArrayList<Line> ();
	bool show_help_lines = true;
	bool xheight_lines_visible = false;
	bool margin_boundaries_visible = false;
	string new_guide_name = "";
	
	Gee.ArrayList<Glyph> undo_list = new Gee.ArrayList<Glyph> ();
	Gee.ArrayList<Glyph> redo_list = new Gee.ArrayList<Glyph> ();

	string glyph_sequence = "";
	bool open = true;
	
	public static Glyph? background_glyph = null;
	
	bool empty = false;
	
	/** Id in the version list. */
	public int version_id = 1;
	
	/** Cache quadratic form on export. */
	GlyfData? ttf_data = null;
	
	Line left_line;
	Line right_line;
	
	/** Cache for Cairo rendering */
	HashMap<string, Surface> glyph_cache = new HashMap<string, Surface> ();

	public Glyph (string name, unichar unichar_code = 0) {
		this.name = name;
		this.unichar_code = unichar_code;

		path_list.add (new Path ());
		
		add_help_lines ();
		
		left_limit = -28;
		right_limit = 28;
	}
	
	public Glyph.no_lines (string name, unichar unichar_code = 0) {
		this.name = name;
		this.unichar_code = unichar_code;

		path_list.add (new Path ());
	}

	public GlyfData get_ttf_data () {
		if (ttf_data == null) {
			ttf_data =  new GlyfData (this);
		}
		
		return (!) ttf_data;
	}
	
	public PathList get_quadratic_paths () {
		PointConverter pc;
		PathList pl;

		pl = new PathList ();
		foreach (Path p in path_list) {
			pc = new PointConverter (p);
			pl.add (pc.get_quadratic_path ());
		}

		return pl;
	}

	public override void close () {
		undo_list.clear ();
		redo_list.clear ();
	}
	
	public void set_empty_ttf (bool e) {
		empty = e;
	}

	public bool is_empty_ttf () {
		return empty;
	}

	public void clear_active_paths () {
		active_paths.clear ();
	}
	
	public void add_active_path (Path? p) {
		Path path;
		if (p != null) {
			path = (!) p;
			
			if (Toolbox.get_move_tool ().is_selected ()) {
				Toolbox.set_object_stroke (path.stroke);
			}
			
			if (!active_paths.contains (path)) {
				active_paths.add (path);
			}
		}
	}
	
	public void delete_background () {
		store_undo_state ();
		background_image = null;
		GlyphCanvas.redraw ();
	}
	
	public Path? get_active_path () {
		return_val_if_fail (active_paths.size > 0, null);
		return active_paths.get (active_paths.size - 1);
	}
	
	public bool boundaries (out double x1, out double y1, out double x2, out double y2) {
		if (path_list.size == 0) {
			x1 = 0;
			y1 = 0;
			x2 = 0;
			y2 = 0;
			return false;
		}

		x1 = double.MAX;
		x2 = double.MIN;
		y1 = double.MAX;
		y2 = double.MIN;
	
		foreach (Path p in path_list) {
			p.update_region_boundaries ();
					
			if (p.points.size > 0) {
				if (p.xmin < x1) {
					x1 = p.xmin;
				}
				
				if (p.xmax > x2) {
					x2 = p.xmax;
				}
				
				if (p.ymin < y1) {
					y1 = p.ymin;
				}
				
				if (p.ymax > y2) {
					y2 = p.ymax;
				}
			}
		}
		
		return x1 != double.MAX;
	}
	
	public void selection_boundaries (out double x, out double y, out double w, out double h) {
		double px, py, px2, py2;
		
		px = 10000;
		py = 10000;
		px2 = -10000;
		py2 = -10000;
				
		foreach (Path p in active_paths) {
			if (p.xmin < px) {
				px = p.xmin;
			} 

			if (p.ymin < py) {
				py = p.ymin;
			}

			if (p.xmax > px2) {
				px2 = p.xmax;
			}
			
			if (p.ymax > py2) {
				py2 = p.ymax;
			}
		}
		
		if (px2 == -10000 || px == 10000) {
			warning (@"No box for selected paths. ($(active_paths.size))");
			px = 0;
			py = 0;
			px2 = 0;
			py2 = 0;
		}

		x = px;
		y = py2;		
		w = px2 - px;
		h = py2 - py;
	}
	
	/** @return centrum pixel for x coordinates. */
	public static double xc () {
		double c = MainWindow.get_current_glyph ().allocation.width / 2.0;
		return c;	
	}

	/** @return centrum pixel for y coordinates. */
	public static double yc () {
		double c = MainWindow.get_current_glyph ().allocation.height / 2.0;
		return c;
	}

	/** @return 1/view_zoom */
	public static double ivz () {
		return 1 / MainWindow.get_current_glyph ().view_zoom;
	}

	public void resized (WidgetAllocation alloc) {
		double a, b, c, d;

		a = Glyph.path_coordinate_x (0);
		b = Glyph.path_coordinate_y (0);
		
		this.allocation = alloc;

		c = Glyph.path_coordinate_x (0);
		d = Glyph.path_coordinate_y (0);

		view_offset_x -= c - a;
		view_offset_y -= b - d;
	}

	public void set_background_image (BackgroundImage? b) {
		BackgroundImage bg;
		
		if (b == null) {
			background_image = null;
		} else {		
			bg = (!) b;
			background_image = bg;
		}
		
		BirdFont.get_current_font ().touch ();
	}
	
	public BackgroundImage? get_background_image () {
		return background_image;
	}
		
	public override void scroll_wheel_up (double x, double y) {
		if (KeyBindings.has_alt ()) {
			zoom_in_at_point (x, y);
		} else if (KeyBindings.has_ctrl ()) { 
			view_offset_x -= 10 / view_zoom;
		} else {
			view_offset_y -= 10 / view_zoom;
		}
		
		redraw_area (0, 0, allocation.width, allocation.height);
	}
	
	public override void scroll_wheel_down (double x, double y) {
		if (KeyBindings.has_alt ()) {
			zoom_out_at_point (x, y);
		} else	if (KeyBindings.has_ctrl ()) { 
			view_offset_x += 10 / view_zoom;
		} else {
			view_offset_y += 10 / view_zoom;
		}
		
		redraw_area (0, 0, allocation.width, allocation.height);
	}
	
	public void add_path (Path p) {
		path_list.add (p);
	}
	
	public override void selected_canvas () {
		TimeoutSource input_delay;
		
		ttf_data = null; // recreate quatradic path on export
		
		ignore_input = true; // make sure that tripple clicks in overview are ignored

		input_delay = new TimeoutSource (250);
		input_delay.set_callback(() => {
			ignore_input = false;
			return false;
		});
		input_delay.attach (null);
		
		add_help_lines ();
		KeyBindings.set_require_modifier (false);
		glyph_sequence = Preferences.get ("glyph_sequence");
		
		GridTool.update_lines ();
		
		if (!is_null (MainWindow.native_window)) {
			MainWindow.native_window.set_scrollbar_size (0);
		}
		
		update_zoom_bar ();
	}
	
	void update_zoom_bar () {
		if (!is_null (Toolbox.drawing_tools)
			&& !is_null (Toolbox.drawing_tools.zoom_bar)) {
			Toolbox.drawing_tools.zoom_bar.set_zoom ((view_zoom - 1) / 20);
		}
	}
	
	public void remove_lines () {
		vertical_help_lines.clear ();
		horizontal_help_lines.clear ();	
	}
	
	public void add_help_lines () {
		remove_lines ();
		
		return_if_fail (!is_null (BirdFont.get_current_font ()));
		
		double bgt = BirdFont.get_current_font ().top_limit;
		Line top_margin_line = new Line ("top margin", bgt, false);
		top_margin_line.set_color_theme ("Guide 2");
		top_margin_line.position_updated.connect ((pos) => {
			BirdFont.get_current_font ().top_limit = pos;
		});
						
		double thp = BirdFont.get_current_font ().top_position;
		Line top_line = new Line ("top", thp, false);
		top_line.position_updated.connect ((pos) => {
				Font f = BirdFont.get_current_font ();
				f.top_position = pos;
			});
		
		double xhp = BirdFont.get_current_font ().xheight_position;
		Line xheight_line = new Line ("x-height", xhp, false);
		xheight_line.set_color_theme ("Guide 3");
		xheight_line.dashed = true;
		xheight_line.position_updated.connect ((pos) => {				
				Font f = BirdFont.get_current_font ();
				f.xheight_position = pos;
			});

		double xbl = BirdFont.get_current_font ().base_line;
		Line base_line = new Line ("baseline", xbl, false);
		base_line.position_updated.connect ((pos) => {
				Font f = BirdFont.get_current_font ();
				f.base_line = pos;
			});
		
		double bp = BirdFont.get_current_font ().bottom_position;
		Line bottom_line = new Line ("bottom", bp, false);
		bottom_line.position_updated.connect ((pos) => {
				BirdFont.get_current_font ().bottom_position = pos;
			});

		double bgb = BirdFont.get_current_font ().bottom_limit;
		Line bottom_margin_line = new Line ("bottom margin", bgb, false);
		bottom_margin_line.set_color_theme ("Guide 2");
		bottom_margin_line.position_updated.connect ((pos) => {
			BirdFont.get_current_font ().bottom_limit = pos;
		});
					
		left_line = new Line ("left", left_limit, true);
		left_line.position_updated.connect ((pos) => {
			left_limit = pos;
			update_other_spacing_classes ();
			
			left_line.set_metrics (get_left_side_bearing ());
		});
		left_line.position_updated (left_limit);
		
		right_line = new Line ("right", right_limit, true);
		right_line.position_updated.connect ((pos) => {
			right_limit = pos;
			update_other_spacing_classes ();
			
			right_line.set_metrics (get_right_side_bearing ());
		});
		right_line.position_updated (right_limit);
		
		// lists of lines are sorted and lines are added only if 
		// they are relevant for a particular glyph.
		
		// left to right
		add_line (left_line);
		add_line (right_line);

		bool glyph_has_top = has_top_line ();

		// top to bottom
		add_line (top_margin_line);
		top_margin_line.set_visible (margin_boundaries_visible);
		
		add_line (top_line);
		top_line.set_visible (glyph_has_top || xheight_lines_visible);
		
		add_line (xheight_line);
		xheight_line.set_visible (!glyph_has_top || xheight_lines_visible);
		
		add_line (base_line);
		
		add_line (bottom_line);
		bottom_line.set_visible (CharDatabase.has_descender (unichar_code) || xheight_lines_visible);
		
		add_line (bottom_margin_line);
		bottom_margin_line.set_visible (margin_boundaries_visible);
		
		foreach (Line guide in BirdFont.get_current_font ().custom_guides) {
			add_line (guide);
		}
	}

	public double get_left_side_bearing () {
		double x1, y1, x2, y2;
		
		if (boundaries (out x1, out y1, out x2, out y2)) {
			return x1 - left_limit;
		} else {
			return right_limit - left_limit;
		}
	}

	public double get_right_side_bearing () {
		double x1, y1, x2, y2;
		
		if (boundaries (out x1, out y1, out x2, out y2)) {
			if (get_name () == "g") {
				print (@"G: $right_limit - $x2    left_limit - x2\n");
			}
			return right_limit - x2;
		} else {
			return right_limit - left_limit;
		}
	}
	
	bool has_top_line () {
		return !unichar_code.islower () || CharDatabase.has_ascender (unichar_code);
	}

	public bool get_show_help_lines () {
		return show_help_lines;
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
		margin_boundaries_visible = m;
		add_help_lines ();
	}
	
	public bool get_margin_lines_visible () {
		return margin_boundaries_visible;
	}
	
	public void remove_empty_paths () {
		foreach (Path p in path_list) {
			if (p.points.size < 2) {
				delete_path (p);
				remove_empty_paths ();
				return;
			}
		}
	}
	
	public void delete_path (Path p) requires (path_list.size > 0) {
		path_list.remove (p);
	}
	
	public string get_svg_data () {
		return Svg.to_svg_glyph (this);
	}
	
	public int get_height () {
		Font f = BirdFont.get_current_font ();
		return (int) Math.fabs (f.top_limit - f.bottom_limit); 
	}
	
	public double get_width () {
		return Math.fabs (right_limit - left_limit);
	}

	public unichar get_unichar () {
		return unichar_code;
	}

	public string get_unichar_string () {
		string? s = (!)get_unichar ().to_string ();
		
		if (unlikely (s == null)) {
			warning ("Invalid character.");
			return "".dup ();
		}
		
		return (!) s;
	}
	
	public void redraw_help_lines () {
		redraw_area (0, 0, allocation.width, allocation.height);
	}
	
	public void set_show_help_lines (bool hl) {
		show_help_lines = hl;
	}
	
	private void add_line (Line line) {
		if (line.is_vertical ()) {
			vertical_help_lines.add (line);
		} else {
			horizontal_help_lines.add (line);
		}

		sort_help_lines ();
		
		line.queue_draw_area.connect ((x, y, w, h) => {
			this.redraw_area (x, y, w, h);
		});
	}
	
	public void sort_help_lines () {
		vertical_help_lines.sort ((a, b) => {
			Line first, next;
			first = (Line) a;
			next = (Line) b;
			return (int) (first.get_pos () - next.get_pos ());
		});
		
		horizontal_help_lines.sort ((a, b) => {
			Line first, next;
			first = (Line) a;
			next = (Line) b;
			return (int) (first.get_pos () - next.get_pos ());
		});
	}
	
	public override string get_name () {
		return name;
	}

	public override string get_label () {
		return name;
	}
				
	private void help_line_event (int x, int y) {
		bool m = false;
		
		foreach (Line line in vertical_help_lines) {
			if (!m && line.event_move_to (x, y, allocation)) {
				m = true;
			}
		}

		foreach (Line line in horizontal_help_lines) {
			if (!m && line.event_move_to (x, y, allocation)) {
				m = true;
			}
		}
	}

	public override void key_release (uint keyval) {	
		Tool t;
		t = MainWindow.get_toolbox ().get_current_tool ();
		t.key_release_action (t, keyval);

		if (keyval == (uint)' ') {
			move_canvas = false;
		}
	}

	public override void key_press (uint keyval) {	
		Tool t = MainWindow.get_toolbox ().get_current_tool ();
		t.key_press_action (t, keyval);
		
		if (keyval == (uint)' ') {
			move_canvas = true;
		}

		switch (keyval) {
			case Key.NUM_PLUS:
				zoom_in ();
				break;
			case Key.NUM_MINUS:
				zoom_out ();
				break;
		}
	}

	/** Delete edit point from path.
	 * @return false if no points was deleted 
	 */
	public bool process_deleted () {
		Gee.ArrayList<Path> deleted_paths = new Gee.ArrayList<Path> ();
		foreach (Path p in path_list) {
			if (p.points.size > 0) {
				if (process_deleted_points_in_path (p)) {
					return true;
				}
			} else {
				deleted_paths.add (p);
			}
		}
		
		foreach (Path p in deleted_paths) {
			delete_path (p);
		}
		
		return false;
	}
	
	private bool process_deleted_points_in_path (Path p) {
		PathList remaining_points;
		remaining_points = p.process_deleted_points ();
		foreach (Path path in remaining_points.paths) {
			add_path (path);
			path.reopen ();
			path.create_list ();
			
			add_active_path (path);
		}
		
		if (remaining_points.paths.size > 0) {
			delete_path (p);
			return true;
		}
		
		return false;
	}
	
	public override void motion_notify (double x, double y) {
		Tool t = MainWindow.get_toolbox ().get_current_tool ();
		
		if (view_is_moving) {
			move_view_offset  (x, y);
			return;
		}
		
		help_line_event ((int) x, (int) y);
		t.move_action (t, (int) x, (int) y);

		motion_x = x * ivz () - xc () + view_offset_x;
		motion_y = yc () - y * ivz () - view_offset_y;
	}
	
	public override void button_release (int button, double ex, double ey) {
		bool line_moving = false;
		view_is_moving = false;
		
		foreach (Line line in get_all_help_lines ()) {
			if (!line.set_move (false)) {
				line_moving = true;
			}
		}

		if (!line_moving) {
			Tool t = MainWindow.get_toolbox ().get_current_tool ();
			t.release_action (t, (int) button, (int) ex, (int) ey);
		}
		
		update_view ();
	}

	private Gee.ArrayList<Line> get_all_help_lines () {
		Gee.ArrayList<Line> all_lines = new Gee.ArrayList<Line> ();
		
		foreach (Line l in vertical_help_lines) {
			all_lines.add (l);
		}

		foreach (Line l in horizontal_help_lines) {
			all_lines.add (l);
		}
				
		if (GridTool.is_visible ()) {
			foreach (Line l in GridTool.get_vertical_lines ()) {
				all_lines.add (l);
			}
			
			foreach (Line l in GridTool.get_horizontal_lines ()) {
				all_lines.add (l);
			}
		}
		
		return all_lines;
	}
		
	public void update_view () {
		GlyphCanvas.redraw ();
	}
	
	public override void double_click (uint button, double ex, double ey) {	
		Tool t = MainWindow.get_toolbox ().get_current_tool ();
		t.double_click_action (t, (int) button, (int) ex, (int) ey);
	}
	
	public override void button_press (uint button, double ex, double ey) {				
		bool moving_lines = false;
			
		pointer_begin_x = ex;
		pointer_begin_y = ey;
		
		foreach (Line line in horizontal_help_lines) {
			if (!moving_lines && line.is_visible () && line.button_press (button)) {
				moving_lines = true;
			}
		}

		foreach (Line line in vertical_help_lines) {
			if (!moving_lines && line.is_visible () && line.button_press (button)) {
				moving_lines = true;
			}
		}
				
		if (moving_lines) {
			return;
		}
			
		if (move_canvas || DrawingTools.move_canvas.is_selected ()) {
			view_is_moving = true;
			move_offset_x = view_offset_x;
			move_offset_y = view_offset_y;
		} else {
			Tool t = MainWindow.get_toolbox ().get_current_tool ();
			t.press_action (t, (int) button, (int) ex, (int) ey);
		}
	}

	/** Add new points to this path. */
	public void set_active_path (Path p) {
		path_list.remove (p);
		path_list.add (p);
		p.reopen ();
	}

	/** Insert new edit point for current path on the appropriate zoom
	 * level.
	 */
	public PointSelection add_new_edit_point (int x, int y) {
		return insert_edit_point (x, y);
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

		if (Path.distance (x, x + w, y, y + h) < 7) {
			zoom_in ();
		} else {
			view_offset_x += x / view_zoom;
			view_offset_y += y / view_zoom;
			
			if (unlikely (allocation.width == 0 || allocation.height == 0)) {
				return;
			}
			
			view_zoom_x = allocation.width * view_zoom / w;
			view_zoom_y = allocation.height * view_zoom / h;
					
			// TODO: there is a max zoom level
			
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
		
		update_zoom_bar ();
	}
	
	public void show_zoom_area (int sx, int sy, int nx, int ny) {
		double x, y, w, h;
				
		set_zoom_area (sx, sy, nx, ny);
		
		zoom_area_is_visible = true;
		
		x = Math.fmin (zoom_x1, zoom_x2) - 50;
		y = Math.fmin (zoom_y1, zoom_y2) - 50;

		w = Math.fabs (zoom_x1 - zoom_x2) + 100;
		h = Math.fabs (zoom_y1 - zoom_y2) + 100;
				
		redraw_area ((int)x, (int)y, (int)w, (int)h);
	}

	public void set_zoom_area (int sx, int sy, int nx, int ny) {
		zoom_x1 = sx;
		zoom_y1 = sy;
		zoom_x2 = nx;
		zoom_y2 = ny;
	}

	public static void validate_zoom () {
		Glyph g = MainWindow.get_current_glyph ();
		if (unlikely (g.view_zoom == 0)) {
			warning ("Zoom is zero.");
			g.reset_zoom ();
			
			if (g.view_zoom == 0) {
				g.view_zoom = 1;
				g.view_offset_x = 0;
				g.view_offset_y = 0;
			}
		}	
	}

	public static double path_coordinate_x (double x) {
		Glyph g = MainWindow.get_current_glyph ();
		validate_zoom ();
		return x * ivz () - xc () + g.view_offset_x;
	}

	public static int reverse_path_coordinate_x (double x) {
		Glyph g = MainWindow.get_current_glyph ();
		validate_zoom ();
		return (int) Math.rint ((x - g.view_offset_x + xc ()) * g.view_zoom);
	}

	public static double precise_reverse_path_coordinate_x (double x) {
		Glyph g = MainWindow.get_current_glyph ();
		validate_zoom ();
		return (x - g.view_offset_x + xc ()) * g.view_zoom;
	}
	
	public static double path_coordinate_y (double y) {
		Glyph g = MainWindow.get_current_glyph ();
		validate_zoom ();
		return yc () - y * ivz () - g.view_offset_y;
	}

	public static int reverse_path_coordinate_y (double y) {
		Glyph g = MainWindow.get_current_glyph ();
		validate_zoom ();
		y =  Math.rint ((y + g.view_offset_y - yc ()) * g.view_zoom);	
		return (int) (-y);
	}

	public static double precise_reverse_path_coordinate_y (double y) {
		Glyph g = MainWindow.get_current_glyph ();
		validate_zoom ();
		y = (y + g.view_offset_y - yc ()) * g.view_zoom;	
		return -y;
	}
	
	public bool select_path (double x, double y) {
		Path? p = null;
		bool found = false;
		
		foreach (Path pt in path_list) {
			if (pt.is_over (x, y)) {
				p = pt;
				found = true;
			}
		}
		
		if (!KeyBindings.has_shift ()) {
			clear_active_paths ();
		}
		
		add_active_path (p);
		
		return found;
	}
	
	public bool is_over_selected_path (double x, double y) {
		foreach (Path pt in active_paths) {
			if (pt.is_over (x, y)) {
				return true;
			}
		}
		return false;		
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

		redraw_area ((int)xtb - 10, (int)yta - 10, (int)(xtb - xta) + 10, (int) (yta - ytb) + 10);
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
			if (p.points.size == 0) continue;
			
			p.get_closest_point_on_path (ep, xt, yt);
			d = Math.pow (ep.x - xt, 2) + Math.pow (ep.y - yt, 2);
			
			if (d < min_distance) {
				min_distance = d;
				min_point = p;
			}

		}
		
		// a path without any editpoints
		if (path_list.size > 0) {
			return path_list.get (0);
		}

		if (unlikely (min_distance == double.MAX)) {
			warning (@"No path found in path_list. Length: $(path_list.size)");
		}
		
		return min_point;
	}
	
	private PointSelection insert_edit_point (double x, double y) {
		double xt, yt;
		Path np;
		EditPoint inserted;
		
		if (path_list.size == 0) {
			np = new Path ();
			path_list.add (np);
		}
			
		xt = path_coordinate_x (x);
		yt = path_coordinate_y (y);
	
		return_val_if_fail (path_list.size > 0, new PointSelection.empty ());

		if (path_list.get (path_list.size - 1).is_open ()) {
			np = path_list.get (path_list.size - 1);
			np.add (xt, yt);
		} else {
			np = new Path ();
			path_list.add (np);
			np.add (xt, yt);
			
			if (DrawingTools.pen_tool.is_selected ()) {
				np.set_stroke (PenTool.path_stroke_width);
			}
		}

		clear_active_paths ();
		add_active_path (np);
		
		inserted = np.points.get (np.points.size - 1);
		
		return new PointSelection (inserted, np);
	}
	
	public void move_selected_edit_point_coordinates (EditPoint selected_point, double xt, double yt) {	
		double x, y;
				
		BirdFont.get_current_font ().touch ();

		x = reverse_path_coordinate_x (xt);
		y = reverse_path_coordinate_y (yt);
		
		// redraw control point
		redraw_area ((int)(x - 4*view_zoom), (int)(y - 4*view_zoom), (int)(x + 3*view_zoom), (int)(y + 3*view_zoom));
		
		// update position of selected point
		selected_point.set_position (xt, yt);
		
		if (view_zoom >= 2) {
			redraw_area (0, 0, allocation.width, allocation.height);
		} else {
			redraw_last_stroke (x, y);
		}	
	}

	public void move_selected_edit_point (EditPoint selected_point, double x, double y) {		
		double xt = path_coordinate_x (x);
		double yt = path_coordinate_y (y);
		move_selected_edit_point_coordinates (selected_point, xt, yt);
	}
	
	public void redraw_segment (EditPoint a, EditPoint b) {
		double margin = 10;
		double x = Math.fmin (reverse_path_coordinate_x (a.x), reverse_path_coordinate_x (b.x)) - margin;
		double y = Math.fmin (reverse_path_coordinate_y (a.y), reverse_path_coordinate_y(b.y)) - margin;
		double w = Math.fabs (reverse_path_coordinate_x (a.x) - reverse_path_coordinate_x(b.x)) + 2 * margin;
		double h = Math.fabs (reverse_path_coordinate_y (a.y) - reverse_path_coordinate_y (b.y)) + 2 * margin;
				
		redraw_area ((int)x, (int)y, (int)w, (int)h);
	}
	
	private void redraw_last_stroke (double x, double y) {
		// redraw line, if we have more than one new point on path
		double px = 0;
		double py = 0;
		int tw = 0;
		int th = 0;

		double xc = (allocation.width / 2.0);

		if (active_paths.size == 0) {
			return;
		}
		
		foreach (Path path in active_paths) {
			EditPoint p;
			EditPoint pl = path.get_last_point ();
			
			if (pl.prev != null) {
				p = pl.get_prev ();
				
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
		}
		
		redraw_area ((int)px - 20, (int)py - 20, tw + 120, th + 120); 		
	}
	
	public Path? get_last_path () 
		ensures (result != null)
	{
		return_val_if_fail (path_list.size > 0, null);
		return path_list.get (path_list.size - 1);
	}
	
	public bool has_active_path () {
		return active_paths.size > 0;
	}
	
	public bool is_open () {
		return open;
	}
	
	/** Close all editable paths and return false if no path have been closed. */
	public bool close_path () {
		bool r = false;

		foreach (var p in path_list) {
			if (p.is_editable ()) {
				r = true;
				p.set_editable (false);
			}
			
			if (p.is_open ()) {
				p.convert_path_ending_to_line ();
			}
		}
		
		redraw_area (0, 0, allocation.width, allocation.height);
		open = false;
		return r;
	}

	public void open_path () {
		clear_active_paths ();
		
		foreach (Path p in path_list) {
			p.set_editable (true);
			p.recalculate_linear_handles ();
		}
		
		open = true;
		redraw_area (0, 0, allocation.width, allocation.height);
	}
	
	public void redraw_path_region (Path p) {
		int x, y, w, h;
			
		p.update_region_boundaries ();
		
		x = reverse_path_coordinate_x (p.xmin);
		y = reverse_path_coordinate_x (p.xmin);
		w = reverse_path_coordinate_x (p.xmax) - x;
		h = reverse_path_coordinate_x (p.ymax) - y; // FIXME: redraw path
					
		redraw_area (x, y, w, h);		
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
		update_zoom_bar ();
	}
	
	public override void zoom_out () {
		double w = allocation.width;
		int n = (int) (10 * ((w - 10) / allocation.width));
		set_zoom_area (-n, -n, allocation.width + n, allocation.height + n);
		set_zoom_from_area ();
		update_view ();
		update_zoom_bar ();
	}
	
	public override void zoom_max () {
		default_zoom ();
		update_zoom_bar ();
	}
	
	public override void zoom_min () {
		double ax =  1000;
		double ay =  1000;
		double bx = -1000;
		double by = -1000;
		
		int iax, iay, ibx, iby;
		
		reset_zoom ();

		foreach (var p in path_list) {
			p.update_region_boundaries ();
			
			if (p.points.size > 2) {
				if (p.xmin < ax) ax = p.xmin;
				if (p.ymin < ay) ay = p.ymin;			
				if (p.xmax > bx) bx = p.xmax;
				if (p.ymax > by) by = p.ymax;
			}
		}
	
		if (ax == 1000) return; // empty page
		
		iax = (int) ((ax + view_offset_x + allocation.width / 2.0) * view_zoom);
		iay = (int) ((-ay + view_offset_y + allocation.height / 2.0) * view_zoom);
		ibx = (int) ((bx + view_offset_x + allocation.width / 2.0) * view_zoom);
		iby = (int) ((-by + view_offset_y + allocation.height / 2.0) * view_zoom);

		show_zoom_area (iax, iay, ibx, iby); // set this later on button release
		set_zoom_from_area ();
		zoom_out (); // add some margin
		
		redraw_area (0, 0, allocation.width, allocation.height);
		update_zoom_bar ();
	}

	public override void store_current_view () {
		ZoomView n;
		
		if (zoom_list_index + 1 < zoom_list.size) {
			n = zoom_list.get (zoom_list_index);
			while (n != zoom_list.get (zoom_list.size - 1)) {
				zoom_list.remove_at (zoom_list.size - 1);
			}
		}
		
		zoom_list.add (new ZoomView (view_offset_x, view_offset_y, view_zoom, allocation));
		zoom_list_index = (int) zoom_list.size - 1;
		
		if (zoom_list.size > 50) {
			zoom_list.remove_at (0);
		}
	}
	
	public override void restore_last_view () {
		if (zoom_list.size == 0 || zoom_list_index - 1 < 0 || zoom_list.size == 0) {
			return;
		}
		
		zoom_list_index--;
			
		ZoomView z = zoom_list.get (zoom_list_index);
			
		view_offset_x = z.x;
		view_offset_y = z.y;
		view_zoom = z.zoom;
		allocation = z.allocation;
		
		update_zoom_bar ();
	}

	public override void next_view () {
		ZoomView z;
		
		if (zoom_list.size == 0 || zoom_list_index + 1 >= zoom_list.size) {
			return;
		}
		
		zoom_list_index++;
		
		z = zoom_list.get (zoom_list_index);
			
		view_offset_x = z.x;
		view_offset_y = z.y;
		view_zoom = z.zoom;
		allocation = z.allocation;
		
		update_zoom_bar ();		
	}
	
	public override void reset_zoom () {
		view_offset_x = 0;
		view_offset_y = 0;
		
		set_zoom (1);
		
		store_current_view ();
		update_zoom_bar ();
	}
	
	/** Get x-height or top line. */
	public Line get_upper_line () {
		if (has_top_line () || xheight_lines_visible) {
			return get_line ("top");
		}
		
		return get_line ("x-height");
	}

	/** Get base line. */
	public Line get_lower_line () {
		return get_line ("baseline");
	}
		
	/** Set default zoom. See default_zoom. */
	public void set_default_zoom () {
		int bottom = 0;
		int top = 0;
		int left = 0;
		int right = 0;
	
		return_if_fail (vertical_help_lines.size != 0);
		return_if_fail (horizontal_help_lines.size != 0);

		reset_zoom ();
		
		bottom = get_lower_line ().get_position_pixel ();
		top = get_upper_line ().get_position_pixel ();

		left = vertical_help_lines.get (vertical_help_lines.size - 1).get_position_pixel ();
		right = vertical_help_lines.get (0).get_position_pixel ();
		
		set_zoom_area (left + 10, top - 10, right - 10, bottom + 10);
		set_zoom_from_area ();
	}
	
	/** Set default zoom and redraw canvas. */
	public void default_zoom () {
		set_default_zoom ();
		update_view ();
	}
	
	public bool is_empty () {
		foreach (Path p in path_list) {
			if (p.points.size > 0) {
				return false;
			}
		}
		
		return true;
	}
	
	public void set_zoom (double z)
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
	
	private void draw_coordinate (Context cr) {
		Theme.color (cr, "Foreground 3");
		cr.set_font_size (12);
		cr.move_to (0, 10);
		cr.show_text (@"($motion_x, $motion_y)");
		cr.stroke ();		
	}
	
	/** Draw filled paths. */
	public void draw_paths (Context cr) {
		PathList stroke;
		
		cr.save ();
		cr.new_path ();
		foreach (Path p in path_list) {
			if (p.stroke > 0) {
				stroke = StrokeTool.get_stroke (p, p.stroke);
				draw_path_list (stroke, cr, Color.black ());
			} else {
				p.draw_path (cr, this, Color.black ());
			}
		}
		cr.fill ();
		cr.restore ();
	}
	
	public void draw_path (Context cr) {
		if (is_open () && Path.fill_open_path) {
			cr.save ();
			cr.new_path ();
			foreach (Path p in path_list) {
				if (p.stroke > 0) {
					draw_path_list (StrokeTool.get_stroke (p, p.stroke), cr, get_path_fill_color ());
				}

				p.draw_path (cr, this, get_path_fill_color ());
			}
			cr.fill ();
			cr.restore ();
		}
						
		if (is_open ()) {
			cr.save ();
			cr.new_path ();
			foreach (Path p in path_list) {
				if (p.stroke > 0) {			
					draw_outline_for_paths (StrokeTool.get_stroke (p, p.stroke), cr);
				}

				p.draw_outline (cr);
				p.draw_edit_points (cr);	
			}
			cr.restore ();
		}

		if (!is_open ()) {
			// This was good for testing but it is way too slow:
			// Svg.draw_svg_path (cr, get_svg_data (), Glyph.xc () + left, Glyph.yc () - baseline);
			
			cr.save ();
			cr.new_path ();
			foreach (Path p in path_list) {
				if (p.stroke == 0) {
					p.draw_path (cr, this, Color.black ());
				} else {
					draw_path_list (StrokeTool.get_stroke (p, p.stroke), cr, Color.black ());
				}
			}
			cr.close_path ();
			cr.fill ();
			cr.restore ();
			
			foreach (Path p in active_paths) {
				cr.save ();
				cr.new_path ();
				if (p.stroke == 0) {
					p.draw_path (cr, this);
				} else {
					draw_path_list (StrokeTool.get_stroke (p, p.stroke), cr);
				}
				cr.close_path ();
				cr.fill ();
				cr.restore ();
			}
		}
	}
	
	private Color get_path_fill_color () {
		return Theme.get_color ("Fill Color");
	}
	
	private void draw_outline_for_paths (PathList pl, Context cr) {
		foreach (Path p in pl.paths) {			
			p.draw_outline (cr);
		}
	} 
	
	private void draw_path_list (PathList pl, Context cr, Color? c = null) {
		foreach (Path p in pl.paths) {
			p.draw_path (cr, this, c);
		}
	}
		
	private void draw_zoom_area(Context cr) {
		cr.save ();
		cr.set_line_width (2.0);
		Theme.color (cr, "Foreground 4");
		cr.rectangle (Math.fmin (zoom_x1, zoom_x2), Math.fmin (zoom_y1, zoom_y2), Math.fabs (zoom_x1 - zoom_x2), Math.fabs (zoom_y1 - zoom_y2));
		cr.stroke ();
		cr.restore ();
	}

	private void draw_background_color (Context cr, double opacity) {
		if (opacity > 0) {
			cr.save ();
			cr.rectangle (0, 0, allocation.width, allocation.height);
			Theme.color (cr, "Background 1");
			cr.fill ();
			cr.restore ();
		}
	}
	
	private void draw_help_lines (Context cr) {
		foreach (Line line in get_all_help_lines ()) {
			cr.save ();
			line.draw (cr, allocation);
			cr.restore ();
		}
	}
	
	public void set_allocation (WidgetAllocation a) {
		allocation = a;
	}
	
	public override void draw (WidgetAllocation allocation, Context cr) {
		Tool tool;
			
		this.allocation = allocation;

		ImageSurface ps = new ImageSurface (Format.ARGB32, allocation.width, allocation.height);
		Context cmp = new Context (ps);

		cr.save ();
		draw_background_color (cr, 1);
		cr.restore ();
		
		if (background_image != null && background_image_visible) {
			((!)background_image).draw (cr, allocation, view_offset_x, view_offset_y, view_zoom);
		}

		if (unlikely (Preferences.draw_boundaries)) {
			foreach (Path p in path_list) {
				p.draw_boundaries (cr);
			}
		}
		
		draw_background_glyph (allocation, cr);
		juxtapose (allocation, cr);

		if (BirdFont.show_coordinates) {
			draw_coordinate (cmp);
		}

		if (show_help_lines) {
			cmp.save ();
			draw_help_lines (cmp);
			cmp.restore ();
		}

		if (zoom_area_is_visible) {
			cmp.save ();
			draw_zoom_area (cmp);
			cmp.restore ();
		}

		if (!is_empty ()) {
			cmp.save ();
			cmp.scale (view_zoom, view_zoom);
			cmp.translate (-view_offset_x, -view_offset_y);
			draw_path (cmp);
			cmp.restore ();
		}

		cmp.save (); 
		tool = MainWindow.get_toolbox ().get_current_tool ();
		tool.draw_action (tool, cmp, this);
		cmp.restore ();
				
		cr.save ();
		cr.set_source_surface (ps, 0, 0);
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
	
	public void zoom_tap (double distance) {
		int w = (int) (distance);
		if (distance != 0) {
			show_zoom_area (-w , -w, allocation.width + w, allocation.height + w);
			set_zoom_from_area ();
		}
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
		view_offset_x = move_offset_x + (pointer_begin_x - x) * (1/view_zoom);
		view_offset_y = move_offset_y + (pointer_begin_y - y) * (1/view_zoom);
		redraw_area (0, 0, allocation.width, allocation.height);
	}

	public void store_undo_state (bool clear_redo = false) {
		Glyph g = copy ();
		undo_list.add (g);
		
		if (clear_redo) {
			redo_list.clear ();
		}
	}

	public void store_redo_state () {
		Glyph g = copy ();
		redo_list.add (g);	
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
		
		foreach (Path p in active_paths) {
			g.active_paths.add (p);
		}

		if (background_image != null) {
			g.background_image = ((!) background_image).copy ();
		}

		g.empty = empty;
		g.open = open;
		
		return g;
	}

	public void reload () {
		Font f = BirdFont.get_current_font ();
		
		if (f.has_glyph (name)) {
			set_glyph_data ((!) f.get_glyph (name));
		}
	}

	public override void undo () {
		Glyph g;
		Tool tool;
		
		if (undo_list.size == 0) {
			return;
		}
		
		tool = MainWindow.get_toolbox ().get_current_tool ();
		tool.before_undo ();
		
		g = undo_list.get (undo_list.size - 1);	
		
		store_redo_state ();
		set_glyph_data (g);
		
		undo_list.remove_at (undo_list.size - 1);

		PenTool.update_selected_points ();
		
		clear_active_paths ();
		
		tool.after_undo ();
	}

	public override void redo () {
		Glyph g;
		
		if (redo_list.size == 0) {
			return;
		}
		
		g = redo_list.get (redo_list.size - 1);	
		
		store_undo_state (false);
		set_glyph_data (g);
		
		redo_list.remove_at (redo_list.size - 1);

		PenTool.update_selected_points ();
		
		clear_active_paths ();
	}
	
	void set_glyph_data (Glyph g) {
		path_list.clear ();
		
		foreach (Path p in g.path_list) {
			add_path (p);
			p.update_region_boundaries ();
		}

		remove_lines ();
		foreach (Line line in g.get_all_help_lines ()) {
			add_line (line.copy ());
		}

		add_help_lines ();
		
		if (g.background_image != null) {
			background_image = ((!) g.background_image).copy ();
		}
		
		clear_active_paths ();
		foreach (Path p in g.active_paths) {
			add_active_path (p);
		}

		redraw_area (0, 0, allocation.width, allocation.height);		
	}

	/** Split curve in two parts and add a new point in between.
	 * @return the new point
	 */
	public void insert_new_point_on_path (double x, double y) {
		double min, distance;
		Path? p = null;
		Path path;
		EditPoint? np = null;
		EditPoint lep;
		
		double xt;
		double yt;

		xt = x * ivz () - xc () + view_offset_x;
		yt = yc () - y * ivz () - view_offset_y;
		
		min = double.MAX;
		
		foreach (Path pp in path_list) {
			lep = new EditPoint ();
			pp.get_closest_point_on_path (lep, xt, yt);
			distance = Math.sqrt (Math.pow (Math.fabs (xt - lep.x), 2) + Math.pow (Math.fabs (yt - lep.y), 2));
			
			if (distance < min) {
				min = distance;
				p = pp;
				np = lep;
			}
		}

		if (p == null) {
			return;
		}
		
		path = (!) p;

		lep = new EditPoint ();
		path.get_closest_point_on_path (lep, xt, yt);
		path.insert_new_point_on_path (lep);
	}
	
	static bool in_range (double offset_x, double coordinate_x1, double coordinate_x2) {
		return coordinate_x1 <= offset_x <= coordinate_x2;
	}
	
	public void juxtapose (WidgetAllocation allocation, Context cr) {
		string glyph_sequence = Preferences.get ("glyph_sequence");
		unichar c;
		Font font = BirdFont.get_current_font ();
		Glyph glyph = MainWindow.get_current_glyph ();
		Glyph juxtaposed;
		StringBuilder current = new StringBuilder ();
		int pos;
		string name;
		double x, kern;
		double left, baseline;
		string last_name;
		
		double box_x1, box_x2, box_y1, box_y2;
		double marker_x, marker_y;
		
		KerningClasses classes = font.get_kerning_classes ();
		
		x = 0;
		
		box_x1 = path_coordinate_x (0);
		box_y1 = path_coordinate_y (0);
		box_x2 = path_coordinate_x (allocation.width);
		box_y2 = path_coordinate_y (allocation.height);
		
		current.append_unichar (glyph.unichar_code);
		pos = glyph_sequence.index_of (current.str);
		
		baseline = font.base_line;;
		left = glyph.get_line ("left").pos;

		x = glyph.get_width ();
		last_name = glyph.name;
		for (int i = pos + 1; i < glyph_sequence.char_count (); i++) {
			c = glyph_sequence.get_char (i);
			name = font.get_name_for_character (c);			
			juxtaposed = (font.has_glyph (name)) ? (!) font.get_glyph (name) : font.get_space ().get_current ();
			
			if (font.has_glyph (last_name) && font.has_glyph (name)) {
				kern = classes.get_kerning (last_name, name);
			} else {
				kern = 0;
			}
			
			if (!juxtaposed.is_empty ()
				&& (in_range (left + x + kern, box_x1, box_x2) // the letter is visible
				|| in_range (left + x + kern + juxtaposed.get_width (), box_x1, box_x2))) {

				marker_x = Glyph.xc () + left + x + kern - glyph.view_offset_x;
				marker_y = Glyph.yc () - baseline - glyph.view_offset_y;
				
				cr.save ();
				cr.scale (glyph.view_zoom, glyph.view_zoom);
				Theme.color (cr, "Foreground 1");

				Svg.draw_svg_path (cr, juxtaposed.get_svg_data (), marker_x, marker_y);
				cr.restore ();
			}
			
			x += juxtaposed.get_width () + kern;

			last_name = name;
		}

		x = 0;
		last_name = glyph.name;
		for (int i = pos - 1; i >= 0; i--) {
			c = glyph_sequence.get_char (i);
			name = font.get_name_for_character (c);			
			juxtaposed = (font.has_glyph (name)) ? (!) font.get_glyph (name) : font.get_space ().get_current ();
			
			if (font.has_glyph (last_name) && font.has_glyph (name)) {
				kern = classes.get_kerning (name, last_name);
			} else {
				kern = 0;
			}
			
			x -= juxtaposed.get_width ();
			x -= kern;
			
			marker_x = Glyph.xc () + left + x;
			marker_y = Glyph.yc () - baseline;
			if (!juxtaposed.is_empty () 
				&&(in_range (left + x, box_x1, box_x2)
				|| in_range (left + x + juxtaposed.get_width (), box_x1, box_x2))) {
				cr.save ();
				cr.scale (glyph.view_zoom, glyph.view_zoom);
				cr.translate (-glyph.view_offset_x, -glyph.view_offset_y);
				Theme.color (cr, "Foreground 1");
				Svg.draw_svg_path (cr, juxtaposed.get_svg_data (), marker_x, marker_y);
				cr.restore ();
			}
			
			last_name = name;
		}
	}
	
	/** @return left side bearing */
	public double get_lsb () {
		return get_line ("left").pos;
	}

	/** @return bottom line */
	public double get_baseline () {
		Font font = BirdFont.get_current_font ();
		return font.base_line;
	}
	
	void draw_background_glyph (WidgetAllocation allocation, Context cr) {
		double left, baseline, current_left;
		Glyph g;
		Font font = BirdFont.get_current_font ();
		
		current_left = get_line ("left").pos;
		
		if (background_glyph != null) {
			g = (!) background_glyph;
			baseline = font.base_line;
			left = g.get_line ("left").pos;
			cr.save ();
			cr.scale (view_zoom, view_zoom);
			cr.translate (-view_offset_x, -view_offset_y);
			Theme.color (cr, "Background Glyph");
			
			Svg.draw_svg_path (cr, g.get_svg_data (), 
				Glyph.xc () + left - (left - current_left) , 
				Glyph.yc () - baseline);
			cr.restore ();
		}
		
	}
	
	public string get_hex () {
		return Font.to_hex_code (unichar_code);
	}
	
	public override void move_view (double x, double y) {
		view_offset_x += x / view_zoom; 
		view_offset_y += y / view_zoom;
		GlyphCanvas.redraw ();
	}

	/** Scroll or zoom from tap events. */
	public void change_view_event (int finger, int x, int y) {
		double dx, dy;
		double last_distance, new_distance;

		dx = 0;
		dy = 0;

		new_distance = 0;
		
		if (last_tap0_y == -1 || last_tap0_x == -1 || last_tap1_y == -1 || last_tap1_x == -1) {
			return;
		}
		
		if (finger == 0) {
			dx = last_tap0_x - x;
			dy = last_tap0_y - y;
			new_distance = Path.distance (last_tap1_x, x, last_tap1_y, y);
		}
		
		if (finger == 1) {
			dx = last_tap1_x - x;
			dy = last_tap1_y - y;
			new_distance = Path.distance (last_tap0_x, x, last_tap0_y, y);
		}
		
		last_distance = Path.distance (last_tap0_x, last_tap1_x, last_tap0_y, last_tap1_y);

		if (zoom_distance != 0) {
			zoom_tap (zoom_distance - new_distance);	
		}	
				
		if (finger == 1) {
			warning (@"dx $dx dy $dy last_tap1_x $last_tap1_x  last_tap1_y $last_tap1_y   x $x  y $y");
			move_view (dx, dy); 
		} 

		zoom_distance = new_distance;
	}

	public override void tap_down (int finger, int x, int y) {
		TimeoutSource delay;
		
		if (finger == 0) {
			delay = new TimeoutSource (400); // wait for second finger
			delay.set_callback(() => {
				if (!change_view && !ignore_input) {
					button_press (1, x, y);
				}
				return false;
			});
			delay.attach (null);
			
			last_tap0_x = x;
			last_tap0_y = y;
		}
		
		if (finger == 1) {
			change_view = true;
			last_tap1_x = x;
			last_tap1_y = y;
		}
	}
	
	public override void tap_up (int finger, int x, int y) {
		if (finger == 0) {
			button_release (1, x, y);
			
			last_tap0_x = -1;
			last_tap0_y = -1;
		}
		
		if (finger == 1) {
			last_tap1_x = -1;
			last_tap1_y = -1;
			
			change_view = false;
			zoom_distance = 0;
		}
	}
		
	public override void tap_move (int finger, int x, int y) {
		if (!change_view) {
			motion_notify (x, y);
		} else {
			change_view_event (finger, x, y);
		}
						
		if (finger == 0) {
			last_tap0_x = x;
			last_tap0_y = y;
		}
		
		if (finger == 1) {
			last_tap1_x = x;
			last_tap1_y = y;
		}
	}
	
	public void update_spacing_class () {
		Font font = BirdFont.get_current_font ();
		GlyphCollection? g;
		GlyphCollection gc;
		Glyph glyph;
		
		foreach (string l in font.get_spacing ()
				.get_all_connections ((!) unichar_code.to_string ())) {
			if (l != (!) unichar_code.to_string ()) {
				g = font.get_glyph_collection (l);
				if (g != null) {
					gc = (!) g;
					glyph = gc.get_current ();
					left_limit = glyph.left_limit;
					right_limit = glyph.right_limit;
					break;
				}
			}
		}
		
		add_help_lines ();
	}

	public void update_other_spacing_classes () {
		Font font = BirdFont.get_current_font ();
		GlyphCollection? g;
		GlyphCollection gc;
		Glyph glyph;
		
		foreach (string l in font.get_spacing ()
				.get_all_connections ((!) unichar_code.to_string ())) {
			if (l != (!) unichar_code.to_string ()) {
				g = font.get_glyph_collection (l);
				if (g != null) {
					gc = (!) g;
					glyph = gc.get_current ();
					glyph.left_limit = left_limit;
					glyph.right_limit = right_limit;
					// FIXME: DELETE glyph.add_help_lines ();
				}
			}
		}	
	}

	public void set_cache (string key, Surface cache) {
		glyph_cache.set (key, cache);
	}

	public bool has_cache (string key) {
		return glyph_cache.has_key (key);
	}

	public Surface get_cache (string key) {
		if (unlikely (!has_cache (key))) {
			warning ("No cache for glyph.");
			return new ImageSurface (Cairo.Format.ARGB32, 1, 1);
		}
		
		return glyph_cache.get (key);
	}
	
	public void add_custom_guide () {
		TextListener listener;
		
		listener = new TextListener (t_("Guide"), "", t_("Add"));
		
		listener.signal_text_input.connect ((text) => {
			new_guide_name = text;
		});
		
		listener.signal_submit.connect (() => {
			Line guide;
			double position;
			
			position = path_coordinate_y (allocation.height / 2.0);
			guide = new Line (new_guide_name, position);
			horizontal_help_lines.add (guide);
			
			BirdFont.get_current_font ().custom_guides.add (guide);
			
			TabContent.hide_text_input ();
			GlyphCanvas.redraw ();
		});
		
		TabContent.show_text_input (listener);
	}
}

}
