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
using Math;

namespace BirdFont {

class GridTool : Tool {
	
	static List <Line> horizontal;
	static List <Line> vertical;
	
	static bool visible = false;
	
	public static double size_x;
	public static double size_y;
	
	public static List <SpinButton> sizes;
	
	public GridTool (string n) {
		base (n, _("Show grid"), 'g', NONE);
		
		horizontal = new List <Line> ();
		vertical = new List <Line> ();
		
		sizes = new List <SpinButton> ();
		
		size_x = 2;
		size_y = 2;
	
		update_lines ();
			
		select_action.connect((self) => {
			visible = !visible;
			update_lines ();
			MainWindow.get_glyph_canvas ().redraw ();
			
			self.set_selected (visible);
			
			Toolbox tb = MainWindow.get_toolbox ();
			Tool t = tb.get_tool ("help_lines");
			
			if (visible && !t.is_selected ()) {
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
		size_x = w;
		size_y = w;
		
		update_lines ();
	}
	
	private static void update_lines () {
		Glyph g = MainWindow.get_current_glyph ();
		double step = size_y;
		double i;
		int max_lines = 400;
		int n;
		Line t, l, u;

		Line baseline = g.get_line ("baseline");
		Line bottom_margin = g.get_line ("bottom margin");
		Line top_margin = g.get_line ("top margin");
		
		Line left = g.get_line ("left");
		Line right = g.get_line ("right");

		while (vertical.length () > 0) {
			vertical.delete_link (vertical.first ());
		}
		
		while (horizontal.length () > 0) {
			horizontal.delete_link (horizontal.first ());
		}
	
		n = 0;
		for (i = left.get_pos () - 7 * step; i <= right.get_pos () + 7 * step; i += step) {	
			l = new Line ("grid", i, Line.VERTICAL);
			l.set_moveable (false);
			l.set_color (0.2, 0.6, 0.2, 0.2);
			horizontal.append (l);
			
			if (++n >= max_lines) {
				break;
			}
		}
		
		n = 0;
		for (i = baseline.get_pos () - step; i >= top_margin.get_pos () - 7 * step; i -= step) {
			t = new Line ("grid", i, Line.HORIZONTAL);
			t.set_moveable (false);
			t.set_color (0.2, 0.6, 0.2, 0.2);
			vertical.append (t);	

			if (++n >= max_lines) {
				break;
			}

		}
		
		for (i = baseline.get_pos (); i <= bottom_margin.get_pos () + 7 * step; i += step) {
			u = new Line ("grid", i, Line.HORIZONTAL);
			u.set_moveable (false);
			u.set_color (0.2, 0.6, 0.2, 0.2);
			vertical.append (u);	

			if (++n >= max_lines) {
				break;
			}

		}	
	}
		
	/** Sets x and y the point closest on grid. */
	public static void tie (ref double x, ref double y) {
		tie_point (ref x, ref y, false);
	}

	public static void tie_coordinate (ref double x, ref double y) {
		tie_point (ref x, ref y, true);
	}
		
	private static void tie_point (ref double x, ref double y, bool coordinate)
		requires (horizontal.length () > 0 && vertical.length () > 0)
	{
		double d, m;
		
		Glyph g = MainWindow.get_current_glyph ();
		
		Line xmin = horizontal.first ().data;
		Line ymin = vertical.first ().data;

		Line xpos;
		Line ypos;
		
		if (!coordinate) {
			xpos = new Line ("", 0, Line.VERTICAL);
			ypos = new Line ("", 0, Line.HORIZONTAL);

			xpos.set_move (true);
			ypos.set_move (true);
			
			xpos.move_line_to (x, y, g.allocation);
			ypos.move_line_to (x, y, g.allocation);
		} else {
			xpos = new Line ("", x, Line.VERTICAL);
			ypos = new Line ("", -y, Line.HORIZONTAL);
		}

		m = double.MAX;

		foreach (Line line in vertical) {
			d = Math.fabs (line.get_pos () - ypos.get_pos ());
			
			if (d <= m) {
				m = d;
				ymin = line;
			}
			
		}

		m = double.MAX;
		foreach (Line line in horizontal) {
			d = Math.fabs (line.get_pos () - xpos.get_pos ());
			
			if (d <= m) {
				m = d;
				xmin = line;
			}
			
		}
		
		if (!coordinate) {
			x = Glyph.reverse_path_coordinate_x (xmin.get_pos ());
			y = Glyph.reverse_path_coordinate_y (ymin.get_pos ());
		} else {
			x = xmin.get_pos ();
			y = -ymin.get_pos ();
		}
	}

	public static void set_visible (bool v) {
		visible = v;
	}
	
	public static bool is_visible () {
		return visible;
	}
	
	public static unowned List<Line> get_horizontal_lines () {
		return horizontal;
	}
	
	public static unowned List<Line> get_vertical_lines () {
		return vertical;
	}

}

}

