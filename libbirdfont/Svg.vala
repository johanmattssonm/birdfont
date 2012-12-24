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

namespace Supplement {

class Svg {

	/** Export to svg glyph data. */
	public static string to_svg_glyph (Glyph g, double scale = 1) {	
		StringBuilder svg = new StringBuilder ();

		foreach (Path pl in g.path_list) {
			write_path_as_glyph (pl, svg, g, scale);
		}
		
		return svg.str;
	}

	/** Export to svg-font data. */
	public static string to_svg_path (Path pl, Glyph g, double scale = 1) {	
		StringBuilder svg = new StringBuilder ();
		pl.create_list ();
		write_path (pl, svg, g, false, scale);
		return svg.str;
	}

	private static void write_path_as_glyph (Path pl, StringBuilder svg, Glyph g, double scale = 1) {
		write_path (pl, svg, g, true, scale);
	}

	private static void write_path (Path pl, StringBuilder svg, Glyph g, bool do_glyph, double scale = 1) {
		int i = 0;
		EditPoint? n = null;
		EditPoint m;
		
		if (pl.points.length () <= 2) {
			return;
		}
		
		pl.create_list ();
			
		foreach (var e in pl.points) {
			if (i == 0) {
				add_abs_start (e, svg, g, do_glyph, scale);
				i++;
				n = e;
				continue;
			}
			
			m = (!) n;

			add_abs_next (m, e, svg, g, do_glyph, scale);
			
			n = e;
			i++;
		}

		m = pl.points.first ().data;	
		add_abs_next ((!) n, m, svg, g, do_glyph, scale);
		close_path (svg);
	}

	private static void add_abs_next (EditPoint start, EditPoint end, StringBuilder svg, Glyph g, bool do_glyph, double scale = 1) {
		if (start.right_handle.type == PointType.LINE && end.left_handle.type == PointType.LINE) {
			add_abs_line_to (end, start, svg, g, do_glyph, scale);
		} else if (end.get_left_handle ().type == PointType.NONE) {
			add_quadratic_abs_path (end, start, svg, g, do_glyph, scale);
		} else {
			add_cubic_abs_path (end, start, svg, g, do_glyph, scale);
		}
	}

	private static void add_abs_start (EditPoint ep, StringBuilder svg, Glyph g, bool to_glyph, double scale = 1) {		
		double left = g.left_limit;
		double baseline = Supplement.get_current_font ().base_line;
		double height = Supplement.get_current_font ().get_height ();
		
		svg.append_printf ("M");

		if (!to_glyph) {
			svg.append_printf ("%s ",  round ((ep.x - left) * scale));
			svg.append_printf ("%s ",  round ((-ep.y - baseline + height) * scale));
		} else {
			svg.append_printf ("%s ",  round ((ep.x - left) * scale));
			svg.append_printf ("%s ",  round ((ep.y + baseline) * scale));
		}
	}
		
	private static void close_path (StringBuilder svg) {
		svg.append ("z");
	}	
	
	private static void add_abs_line_to (EditPoint start, EditPoint stop, StringBuilder svg, Glyph g, bool to_glyph, double scale = 1) {
		double baseline = Supplement.get_current_font ().base_line;
		double left = g.left_limit;
		
		double xa, ya, xb, yb;
		
		Path.get_line_points (start, stop, out xa, out ya, out xb, out yb);

		double height = Supplement.get_current_font ().get_height (); // no probably not

		double center_x = Glyph.xc ();
		double center_y = Glyph.yc ();
		
		svg.append ("L");
	
		if (!to_glyph) {
			svg.append_printf ("%s ", round ((xb - center_x - left) * scale));
			svg.append_printf ("%s ", round ((yb - center_y - baseline + height) * scale));	
		} else {
			svg.append_printf ("%s ", round ((xb - center_x - left) * scale));
			svg.append_printf ("%s ", round ((-yb + center_y + baseline) * scale));
		}
	}
	
	private static void add_quadratic_abs_path (EditPoint start, EditPoint end, StringBuilder svg, Glyph g,  bool to_glyph, double scale = 1) {
		double left = g.left_limit;
		double baseline = Supplement.get_current_font ().base_line;
		double height = Supplement.get_current_font ().get_height (); // no probably not
		
		double xa, ya, xb, yb, xc, yc, xd, yd;
		
		Path.get_bezier_points (start, end, out xa, out ya, out xb, out yb, out xc, out yc, out xd, out yd);

		double center_x = Glyph.xc ();
		double center_y = Glyph.yc ();
		
		// cubic path
		if (!to_glyph) {
			svg.append_printf ("Q");

			svg.append_printf ("%s ", round ((xb - center_x - left) * scale));
			svg.append_printf ("%s ", round ((yb - center_y - baseline + height) * scale));
			
			svg.append_printf ("%s ", round ((xc - center_x - left) * scale));
			svg.append_printf ("%s ", round ((yc - center_y - baseline + height) * scale));

		} else {		
			svg.append_printf ("Q");

			svg.append_printf ("%s ", round ((xb - center_x - left) * scale));
			svg.append_printf ("%s ", round ((-yb + center_y + baseline) * scale));
			
			svg.append_printf ("%s ", round ((xc - center_x - left) * scale));
			svg.append_printf ("%s ", round ((-yc + center_y + baseline) * scale));	
		}
	}
			
	private static void add_cubic_abs_path (EditPoint start, EditPoint end, StringBuilder svg, Glyph g,  bool to_glyph, double scale = 1) {
		double left = g.left_limit;
		double baseline = Supplement.get_current_font ().base_line;
		double height = Supplement.get_current_font ().get_height (); // no probably not
		
		double xa, ya, xb, yb, xc, yc, xd, yd;
		
		Path.get_bezier_points (start, end, out xa, out ya, out xb, out yb, out xc, out yc, out xd, out yd);

		double center_x = Glyph.xc ();
		double center_y = Glyph.yc ();
		
		// cubic path
		if (!to_glyph) {
			svg.append_printf ("C");

			svg.append_printf ("%s ", round ((xb - center_x - left) * scale));
			svg.append_printf ("%s ", round ((yb - center_y - baseline + height) * scale));
			
			svg.append_printf ("%s ", round ((xc - center_x - left) * scale));
			svg.append_printf ("%s ", round ((yc - center_y - baseline + height) * scale));
			
			svg.append_printf ("%s ", round ((xd - center_x - left) * scale));
			svg.append_printf ("%s ", round ((yd - center_y - baseline + height) * scale));	

		} else {		
			svg.append_printf ("C");

			svg.append_printf ("%s ", round ((xb - center_x - left) * scale));
			svg.append_printf ("%s ", round ((-yb + center_y + baseline) * scale));
			
			svg.append_printf ("%s ", round ((xc - center_x - left) * scale));
			svg.append_printf ("%s ", round ((-yc + center_y + baseline) * scale));	
			
			svg.append_printf ("%s ", round ((xd - center_x - left) * scale));
			svg.append_printf ("%s ", round ((-yd + center_y + baseline) * scale));	
		}
	}
	
	/** Draw path from svg font data. */
	public static void draw_svg_path (Context cr, string svg, double x, double y, double scale = 1) {
		double x1, x2, x3;
		double y1, y2, y3;

		string[] d = svg.split (" ");
		
		x /= scale;
		y /= scale;

		if (d.length == 0) {
			return;
		}
		
		cr.save ();

		cr.set_line_width (1);
		cr.set_source_rgba (0, 0, 0, 1);
		
		if (svg == "") {
			return;
		}
		
		for (int i = 0; i < d.length; i++) {
			
			// trim off leading white space	
			while (d[i].index_of (" ") == 0) { 
				d[i] = d[i].substring (1);
			}
			
			if (d[i].index_of ("L") == 0) {
				x1 = double.parse (d[i].substring (1)) + x;
				y1 = -double.parse (d[i+1]) + y;
				
				x1 *= scale;
				y1 *= scale;
				
				cr.line_to (x1, y1);
				continue;
			}

			if (d[i].index_of ("Q") == 0) {
				x1 = double.parse (d[i].substring (1)) + x;
				y1 = -double.parse (d[i+1]) + y;

				x2 = double.parse (d[i+2]) + x;
				y2 = -double.parse (d[i+3]) + y;

				x1 *= scale;
				y1 *= scale;

				x2 *= scale;
				y2 *= scale;
																
				cr.curve_to (x1, y1, x2, y2, x2, y2);
				continue;
			}
			
			if (d[i].index_of ("C") == 0) {
				x1 = double.parse (d[i].substring (1)) + x;
				y1 = -double.parse (d[i+1]) + y;

				x2 = double.parse (d[i+2]) + x;
				y2 = -double.parse (d[i+3]) + y;

				x3 = double.parse (d[i+4]) + x;
				y3 = -double.parse (d[i+5]) + y;

				x1 *= scale;
				y1 *= scale;

				x2 *= scale;
				y2 *= scale;
				
				x3 *= scale;
				y3 *= scale;
																
				cr.curve_to (x1, y1, x2, y2, x3, y3);
				continue;
			}

			if (d[i].index_of ("M") == 0) {
				x1 = double.parse (d[i].substring (1)) + x;
				y1 = -double.parse (d[i+1]) + y;
				
				x1 *= scale;
				y1 *= scale;
				
				cr.move_to (x1, y1);
				continue;
			}
								
			if (d[i].index_of ("zM") == 0) {
				cr.close_path ();
				
				x1 = double.parse (d[i].substring (2)) + x;
				y1 = -double.parse (d[i+1]) + y;
				
				x1 *= scale;
				y1 *= scale;
				
				cr.move_to (x1, y1);
				continue;
			}

			if (d[i].index_of ("z") == 0) {
				cr.close_path ();
				continue;
			}
		
		}
		
		cr.fill ();
		cr.restore ();
	}

}

internal static string round (double p) {
	string v = p.to_string ();
	char[] c = new char [501];
	
	v = p.format (c, "%3.15f");
	
	if (v.index_of ("e") != -1) {	
		return "0.0";
	}
	
	return v;
}
	
}
