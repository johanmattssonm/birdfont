/*
	Copyright (C) 2012 Johan Mattsson

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

public class GridTool : Tool {
	
	static Gee.ArrayList<Line> horizontal;
	static Gee.ArrayList<Line> vertical;
	
	static bool grid_visible = false;
	public static bool ttf_units = false;
	
	public static double size_x;
	public static double size_y;
	
	public static Gee.ArrayList<SpinButton> sizes;
	
	/** Lock grid and guides. */
	public static bool lock_grid = false;
	
	public GridTool (string n) {
		string units;
		base (n, t_("Show grid"));
		
		units = Preferences.get ("ttf_units");
		if (units == "true") {
			ttf_units = true;
		}
		
		horizontal = new Gee.ArrayList <Line> ();
		vertical = new Gee.ArrayList <Line> ();
		
		sizes = new Gee.ArrayList <SpinButton> ();
		
		size_x = 2;
		size_y = 2;
	
		update_lines ();
			
		select_action.connect((self) => {
			grid_visible = !grid_visible;
			update_lines ();
			GlyphCanvas.redraw ();
			
			self.set_selected (grid_visible);
			
			Toolbox tb = MainWindow.get_toolbox ();
			Tool t = tb.get_tool ("help_lines");
			
			if (grid_visible && !t.is_selected ()) {
				MainWindow.get_toolbox ().select_tool (t);
			}
		});
		
		press_action.connect((self, b, x, y) => {
		});

		release_action.connect((self, b, x, y) => {
		});
		
		move_action.connect ((self, x, y)	 => {
		});
		
		draw_action.connect ((self, cairo_context, glyph) => {
		});
			
	}
	
	public static void set_grid_width (double w) {
		double t = 0;
		
		if (ttf_units) {
			ttf_grid_coordinate (ref w, ref t);	
		}
		
		size_x = w;
		size_y = w;
		
		update_lines ();
	}

	public static void ttf_grid_coordinate (ref double x, ref double y) {
		x = GlyfData.tie_to_ttf_grid_x (MainWindow.get_current_glyph (), x);
		y = GlyfData.tie_to_ttf_grid_y (BirdFont.get_current_font (), y);
	}
		
	public static void update_lines () {
		Glyph g = MainWindow.get_current_glyph ();
		double step = size_y;
		Color color = Theme.get_color ("Grid");
		double i;
		int max_lines = 600;
		int n;
		Line t, l, u;


		Line baseline = g.get_line ("baseline");
		Line bottom_margin = g.get_line ("bottom margin");
		Line top_margin = g.get_line ("top margin");
		
		Line left = g.get_line ("left");
		Line right = g.get_line ("right");

		vertical.clear ();
		horizontal.clear ();
	
		n = 0;
		for (i = left.get_pos () - 7 * step; i <= right.get_pos () + 7 * step; i += step) {	
			l = new Line ("grid", "", i, Line.VERTICAL);
			l.set_moveable (false);
			l.set_color (color.r, color.g, color.b, color.a);
			vertical.add (l);
			
			if (++n >= max_lines) {
				break;
			}
		}
		
		n = 0;
		for (i = baseline.get_pos () - step; i >= bottom_margin.get_pos () - 7 * step; i -= step) {
			t = new Line ("grid", "", i, Line.HORIZONTAL);
			t.set_moveable (false);
			t.set_color (color.r, color.g, color.b, color.a);
			horizontal.insert (0, t);	

			if (++n >= max_lines) {
				break;
			}

		}
		
		for (i = baseline.get_pos (); i <= top_margin.get_pos () + 7 * step; i += step) {
			u = new Line ("grid", "", i, Line.HORIZONTAL);
			u.set_moveable (false);
			u.set_color (color.r, color.g, color.b, color.a);
			horizontal.add (u);	

			if (++n >= max_lines) {
				break;
			}

		}	
	}

	public static void tie_coordinate (ref double x, ref double y) {
		tie_point (ref x, ref y, true);
	}

	public static void tie_point (ref double x, ref double y, bool coordinate) {
		x = tie_point_x (x, coordinate);
		y = tie_point_y (y, coordinate);
	}

	public static double tie_point_x (double x, bool coordinate)
		requires (vertical.size >= 2)
	{
		double d, m;
		Line xmin = vertical.get (0);
		Line xpos;
		Line startx = vertical.get (0);
		Line stopx = vertical.get (vertical.size - 1);

		// outside of the grid
		if (!coordinate) {
			if (!(startx.pos < Glyph.path_coordinate_x (x) < stopx.pos)) {
				return x;
			}
		} else {
			if (!(startx.pos < x < stopx.pos)) {
				return x;
			}
		}
			
		if (!coordinate) {
			xpos = new Line ("", "", 0, Line.VERTICAL);
			xpos.pos = Glyph.path_coordinate_x (x);
		} else {
			xpos = new Line ("", "", x, Line.VERTICAL);
		}

		m = double.MAX;
		foreach (Line line in vertical) {
			d = Math.fabs (line.get_pos () - xpos.get_pos ());
			
			if (d <= m) {
				m = d;
				xmin = line;
			}
			
		}
		
		if (!coordinate) {
			x = Glyph.reverse_path_coordinate_x (xmin.get_pos ());
		} else {
			x = xmin.get_pos ();
		}
		
		return x;
	}

	public static double tie_point_y (double y, bool coordinate)
		requires (horizontal.size >= 2)
	{
		double d, m;
		Line ymin = horizontal.get (0);
		Line ypos;
		Line starty = horizontal.get (0);
		Line stopy = horizontal.get (horizontal.size - 1);
		
		// outside of the grid
		if (!coordinate) {
			if (!(starty.pos < Glyph.path_coordinate_y (y) < stopy.pos)) {
				return y;
			}
		} else {
			if (!(starty.pos < y < stopy.pos)) {
				return y;
			}
		}
		
		if (!coordinate) {
			ypos = new Line ("", "", 0, Line.HORIZONTAL);
			ypos.pos = Glyph.path_coordinate_y (y);
		} else {
			ypos = new Line ("", "", y, Line.HORIZONTAL);
		}

		m = double.MAX;
		foreach (Line line in horizontal) {
			d = Math.fabs (line.get_pos () - ypos.get_pos ());
			
			if (d <= m) {
				m = d;
				ymin = line;
			}
			
		}
		
		if (!coordinate) {
			y = Glyph.reverse_path_coordinate_y (ymin.get_pos ());
		} else {
			y = ymin.get_pos ();
		}
		
		return y;
	}
	
	public static bool has_ttf_grid () {
		return ttf_units;
	}
	
	public static bool is_visible () {
		return grid_visible;
	}
	
	public static Gee.ArrayList<Line> get_horizontal_lines () {
		return horizontal;
	}
	
	public static Gee.ArrayList<Line> get_vertical_lines () {
		return vertical;
	}

}

}

