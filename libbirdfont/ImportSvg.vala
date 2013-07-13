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
using Xml;
using Math;

namespace BirdFont {
	
public class ImportSvg {
	public ImportSvg () {
	}
	
	public static void import () {
		string? p;
		string path;
		
		p = MainWindow.file_chooser_open (_("Import"));

		if (p == null) {
			return;
		}
		path = (!) p;
		import_svg (path);
	}
	
	public static void import_svg_data (string xml_data) {
		if (BirdFont.win32) {
			string svg;
			string xml;
			Glyph glyph = MainWindow.get_current_glyph ();
			
			xml = xml_data.replace ("id", "__");
			foreach (string svg_data in xml.split ("d=\"")) {
				svg = svg_data.substring (0, svg_data.index_of ("\""));
				
				if (svg.has_prefix ("M") || svg.has_prefix ("m")) {
					parse_svg_data (svg, glyph);
				}
			}
		} else {
			Xml.Doc* doc;
			Xml.Node* root = null;
			
			Parser.init ();
			
			doc = Parser.parse_doc (xml_data);
			root = doc->get_root_element ();
			return_if_fail (root != null);
			parse_svg_file (root);

			delete doc;
			Parser.cleanup ();
		}
	}
	
	public static void import_svg (string path) {
		// FIXME: libxml2 (2.7.8) refuses to parse svg files created with Adobe Illustrator on 
		// windows. This is a way around it.
		if (BirdFont.win32) {
			try {
				File f = File.new_for_path (path);
				DataInputStream dis = new DataInputStream (f.read ());
				string xml_data;
				string? line;
				StringBuilder sb = new StringBuilder ();

				while ((line = dis.read_line (null)) != null) {
					sb.append ((!) line);
					sb.append ("\n");
				}
				
				xml_data = sb.str;
				import_svg_data (xml_data);
			} catch (GLib.Error e) {
				warning (e.message);
			}
		} else {
			Xml.Doc* doc;
			Xml.Node* root = null;
			
			Parser.init ();
			
			doc = Parser.parse_file (path);
			root = doc->get_root_element ();
					
			if (root == null) {
				warning ("Failed to load SVG file");
				delete doc;
				return;
			}

			parse_svg_file (root);

			delete doc;
			Parser.cleanup ();
		}
	}
	
	private static void parse_svg_file (Xml.Node* root) {
		Xml.Node* node;
		
		node = root;
		
		for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
			if (iter->name == "g") {
				parse_layer (iter);
			}
			
			if (iter->name == "path") {
				parse_path (iter);
			}
		}		
	}
	
	private static void parse_layer (Xml.Node* node) {
		return_if_fail (node != null);
				
		for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
			if (iter->name == "path") {
				parse_path (iter);
			}
			
			if (iter->name == "g") {
				parse_layer (iter);
			}
		}
	}
	
	private static void parse_path (Xml.Node* node) {
		string attr_name = "";
		string attr_content;
		Glyph glyph = MainWindow.get_current_glyph ();
				
		for (Xml.Attr* prop = node->properties; prop != null; prop = prop->next) {
			attr_name = prop->name;
			attr_content = prop->children->content;
			
			if (attr_name == "d") {
				parse_svg_data (attr_content, glyph);
			}
		}
	}
	
	/** Add space as separator to svg data. 
	 * @param d svg data
	 */
	static string add_separators (string d) {
		string data = d;
		
		data = data.replace (",", " ");
		data = data.replace ("m", " m ");
		data = data.replace ("M", " M ");
		data = data.replace ("h", " h ");
		data = data.replace ("H", " H ");
		data = data.replace ("v", " v ");
		data = data.replace ("V", " V ");
		data = data.replace ("l", " l ");
		data = data.replace ("L", " L ");
		data = data.replace ("q", " q ");
		data = data.replace ("Q", " Q ");		
		data = data.replace ("c", " c ");
		data = data.replace ("C", " C ");
		data = data.replace ("t", " t ");
		data = data.replace ("T", " T ");
		data = data.replace ("s", " s ");
		data = data.replace ("S", " S ");
		data = data.replace ("zM", " z M ");
		data = data.replace ("zm", " z m ");
		data = data.replace ("z", " z ");
		data = data.replace ("Z", " Z ");
		data = data.replace ("-", " -");
		data = data.replace ("e -", "e-"); // minus can be either separator or a negative exponent
		data = data.replace ("\t", " ");
		data = data.replace ("\r\n", " ");
		data = data.replace ("\n", " ");
		
		// use only a single space as separator
		while (data.index_of ("  ") > -1) {
			data = data.replace ("  ", " ");
		}
		
		return data;
	}
	
	/** 
	 * Add svg paths to a glyph.
	 * 
	 * @param d svg data
	 * @param glyph add paths to this glyph
	 * @param svg_glyph parse svg glyph (origo in lower left corner)
	 */
	public static void parse_svg_data (string d, Glyph glyph, bool svg_glyph = false, double units = 1) {
		string[] c;
		string[] command;
		int ci = 0;
		double px = 0;
		double py = 0;
		double px2 = 0;
		double py2 = 0;
		double cx = 0;
		double cy = 0;
		double[] p;
		int pi = 0;
		string data;
		Font font;

		if (d.index_of ("z") == -1) { // ignore all open paths
			return;
		}

		font = BirdFont.get_current_font ();
		
		data = add_separators (d);
		c = data.split (" ");
		p = new double[2 * c.length];
		command = new string[2 * c.length];
		
		for (int i = 0; i < 2 * c.length; i++) {
			command[i] = "";
			p[i] = 0;
		}
		
		// parse path
		for (int i = 0; i < c.length; i++) {	
			if (c[i] == "m") {
				while (is_point (c[i + 1])) {
					command[ci++] = "M";

					px += parse_double (c[++i]);
					
					if (svg_glyph) {
						py += parse_double (c[++i]);
					} else {
						py += -parse_double (c[++i]);
					}
					
					p[pi++] = px;
					p[pi++] = py;
				}
			}

			if (c[i] == "M") {
				while (is_point (c[i + 1])) {
					command[ci++] = "M";

					px = parse_double (c[++i]);
					
					if (svg_glyph) {
						py = parse_double (c[++i]);
					} else {
						py = -parse_double (c[++i]);
					}
					
					p[pi++] = px;
					p[pi++] = py;
				}
			}

			if (c[i] == "h") {
				while (is_point (c[i + 1])) {
					command[ci++] = "L";

					px += parse_double (c[++i]);

					p[pi++] = px;
					p[pi++] = py;
				}
			}

			if (c[i] == "H") {
				while (is_point (c[i + 1])) {
					command[ci++] = "L";

					px = parse_double (c[++i]);

					p[pi++] = px;
					p[pi++] = py;
				}
			}

			if (c[i] == "v") {
				while (is_point (c[i + 1])) {
					command[ci++] = "L";
					
					if (svg_glyph) {
						py = py + parse_double (c[++i]);
					} else {
						py = py + -parse_double (c[++i]);
					}
					
					p[pi++] = px;
					p[pi++] = py;
				}				
			}

			if (c[i] == "V") {
				while (is_point (c[i + 1])) {
					command[ci++] = "L";
					
					if (svg_glyph) {
						py = parse_double (c[++i]);
					} else {
						py = -parse_double (c[++i]);
					}
					
					p[pi++] = px;
					p[pi++] = py;
				}
			}
						
			if (c[i] == "l") {
				while (is_point (c[i + 1])) {
					command[ci++] = "L";
					
					cx = px + parse_double (c[++i]);
					
					if (svg_glyph) {
						cy = py + parse_double (c[++i]);
					} else {
						cy = py + -parse_double (c[++i]);
					}
					
					p[pi++] = cx;
					p[pi++] = cy;
					
					px = cx;
					py = cy;
				}
			}
			
			if (c[i] == "L") {
				while (is_point (c[i + 1])) {
					command[ci++] = "L";
					
					cx = parse_double (c[++i]);
					
					if (svg_glyph) {
						cy = parse_double (c[++i]);
					} else {
						cy = -parse_double (c[++i]);
					}
					
					p[pi++] = cx;
					p[pi++] = cy;
					
					px = cx;
					py = cy;					
				}	
			}
						
			if (c[i] == "c") {
				while (is_point (c[i + 1])) {
					command[ci++] = "C";
					
					cx = px + parse_double (c[++i]);
					
					if (svg_glyph) {
						cy = py + parse_double (c[++i]);
					} else {
						cy = py + -parse_double (c[++i]);
					}
					
					p[pi++] = cx;
					p[pi++] = cy;
					
					cx = px + parse_double (c[++i]);
					
					if (svg_glyph) {
						cy = py + parse_double (c[++i]);
					} else {
						cy = py + -parse_double (c[++i]);
					}
					
					px2 = cx;
					py2 = cy;
					
					p[pi++] = px2;
					p[pi++] = py2;
					
					cx = px + parse_double (c[++i]);
					
					if (svg_glyph) {
						cy = py + parse_double (c[++i]);
					} else {
						cy = py + -parse_double (c[++i]);
					}
					
					p[pi++] = cx;
					p[pi++] = cy;
					
					px = cx;
					py = cy;
				}
			}
			
			if (c[i] == "C") {

				while (is_point (c[i + 1])) {
					command[ci++] = "C";
					
					cx = parse_double (c[++i]);
					
					if (svg_glyph) {
						cy = parse_double (c[++i]);
					} else {
						cy = -parse_double (c[++i]);
					}
									
					p[pi++] = cx;
					p[pi++] = cy;
					
					cx = parse_double (c[++i]);
					
					if (svg_glyph) {
						cy = parse_double (c[++i]);
					} else {
						cy = -parse_double (c[++i]);
					}
					
					px2 = cx;
					py2 = cy;
					
					p[pi++] = cx;
					p[pi++] = cy;
					
					cx = parse_double (c[++i]);
					
					if (svg_glyph) {
						cy = parse_double (c[++i]);
					} else {
						cy = -parse_double (c[++i]);
					}
					
					p[pi++] = cx;
					p[pi++] = cy;
					
					px = cx;
					py = cy;					
				}	
			}

			// quadratic
			if (c[i] == "q") {
				while (is_point (c[i + 1])) {
					command[ci++] = "Q";
					
					cx = px + parse_double (c[++i]);
					
					if (svg_glyph) {
						cy = py + parse_double (c[++i]);
					} else {
						cy = py + -parse_double (c[++i]);
					}
					
					p[pi++] = cx;
					p[pi++] = cy;
					
					px2 = cx;
					py2 = cy;
										
					cx = px + parse_double (c[++i]);
					
					if (svg_glyph) {
						cy = py + parse_double (c[++i]);
					} else {
						cy = py + -parse_double (c[++i]);
					}
					
					p[pi++] = cx;
					p[pi++] = cy;
					
					px = cx;
					py = cy;
				}
			}
			
			if (c[i] == "Q") {

				while (is_point (c[i + 1])) {
					command[ci++] = "Q";
					
					cx = parse_double (c[++i]);
					
					if (svg_glyph) {
						cy = parse_double (c[++i]);
					} else {
						cy = -parse_double (c[++i]);
					}
					
					p[pi++] = cx;
					p[pi++] = cy;

					px2 = cx;
					py2 = cy;
										
					cx = parse_double (c[++i]);
					
					if (svg_glyph) {
						cy = parse_double (c[++i]);
					} else {
						cy = -parse_double (c[++i]);
					}
					
					p[pi++] = cx;
					p[pi++] = cy;
					
					px = cx;
					py = cy;			
				}	
			}

			if (c[i] == "t") {
				while (is_point (c[i + 1])) {
					command[ci++] = "Q";
					
					// the first point is the reflection
					cx = 2 * px - px2;
					cy = 2 * py - py2; // if (svg_glyph) ?
					
					p[pi++] = cx;
					p[pi++] = cy;

					px2 = cx;
					py2 = cy;
										
					cx = px + parse_double (c[++i]);
					
					if (svg_glyph) {
						cy = py + parse_double (c[++i]);
					} else {
						cy = py + -parse_double (c[++i]);
					}
					
					px = cx;
					py = cy;
					
					p[pi++] = px;
					p[pi++] = py;
				}
			}

			if (c[i] == "T") {
				while (is_point (c[i + 1])) {
					command[ci++] = "Q";
					
					// the reflection
					cx = 2 * px - px2;
					cy = 2 * py - py2; // if (svg_glyph) ?
					p[pi++] = cx;
					p[pi++] = cy;

					px2 = cx;
					py2 = cy;
					
					cx = parse_double (c[++i]);
					
					if (svg_glyph) {
						cy = parse_double (c[++i]);
					} else {
						cy = -parse_double (c[++i]);
					}
					
					px = cx;
					py = cy;
					
					p[pi++] = px;
					p[pi++] = py;					
				}
			}

			if (c[i] == "s") {
				while (is_point (c[i + 1])) {
					command[ci++] = "C";
					
					// the first point is the reflection
					cx = 2 * px - px2;
					cy = 2 * py - py2; // if (svg_glyph) ?
					p[pi++] = cx;
					p[pi++] = cy;
										
					cx = px + parse_double (c[++i]);
					
					if (svg_glyph) {
						cy = py + parse_double (c[++i]);
					} else {
						cy = py + -parse_double (c[++i]);
					}
					
					px2 = cx;
					py2 = cy;
					
					p[pi++] = px2;
					p[pi++] = py2;

					cx = px + parse_double (c[++i]);
					
					if (svg_glyph) {
						cy = py + parse_double (c[++i]);
					} else {
						cy = py + -parse_double (c[++i]);
					}
					
					p[pi++] = cx;
					p[pi++] = cy;
							
					px = cx;
					py = cy;
				}
			}

			if (c[i] == "S") {
				while (is_point (c[i + 1])) {
					command[ci++] = "C";
					
					// the reflection
					cx = 2 * px - px2;
					cy = 2 * py - py2; // if (svg_glyph) ?			
					p[pi++] = cx;
					p[pi++] = cy;

					// the other two are regular cubic points
					cx = parse_double (c[++i]);
					
					if (svg_glyph) {
						cy = parse_double (c[++i]);
					} else {
						cy = -parse_double (c[++i]);
					}
					
					px2 = cx;
					py2 = cy;
					
					p[pi++] = px2;
					p[pi++] = py2;
					
					cx = parse_double (c[++i]);
					
					if (svg_glyph) {
						cy = parse_double (c[++i]);
					} else {
						cy = -parse_double (c[++i]);
					}
					
					p[pi++] = cx;
					p[pi++] = cy;
					
					px = cx;
					py = cy;					
				}
			}
						
			if (c[i] == "z") {
				command[ci++] = "z";
			}

			if (c[i] == "Z") {
				command[ci++] = "z";
			}
		}

		Path path = new Path ();

		// resize all points
		for (int i = 0; i < pi; i++) {
			p[i] *= units;
		}
					
		// move and resize
		if (svg_glyph) {
			// move only y 
			for (int i = 0; i < pi; i += 2) {
				p[i] += glyph.left_limit;
				p[i+1] -= font.base_line;
			}
		} else {
			for (int i = 0; i < pi; i += 2) {
				p[i] += glyph.left_limit;
				p[i+1] -= font.top_position;
			}
		}
		
		// add points
		int ic = 0;
		double x0, x1, x2;
		double y0, y1, y2;
		EditPoint ep1, ep2;
		double lx, ly;
		for (int i = 0; i < ci; i++) {
			if (is_null (command[i]) || command[i] == "") {
				warning ("Parser error.");
				return;
			}
			
			if (command[i] == "M") {
				path.add (p[ic++], p[ic++]);
			}
			
			if (command[i] == "L") {
				path.add (p[ic++], p[ic++]);
				ep1 = path.points.last ().data;
				ep1.recalculate_linear_handles ();
			}
			
			if (command[i] == "Q") {
				x0 = p[ic++];
				y0 = p[ic++];
				x1 = p[ic++];
				y1 = p[ic++];

				if (is_null (path.points.last ().data)) {
					warning ("Paths must begin with M");
					return;
				}
				
				ep1 = path.points.last ().data;
				ep1.recalculate_linear_handles ();
				ep1.get_right_handle ().type = PointType.QUADRATIC;
				ep1.get_right_handle ().move_to_coordinate (x0, y0);
				ep1.type = PointType.QUADRATIC;		

				path.add (x1, y1);

				ep2 = path.points.last ().data;
				ep2.recalculate_linear_handles ();
				ep2.get_left_handle ().type = PointType.QUADRATIC;
				ep2.get_left_handle ().move_to_coordinate (x0, y0);
				ep2.type = PointType.QUADRATIC;		
			}


			// all the (ep2.get_left_handle ().length == 0) is needed to parse corners in illustrator correctly 
			// it should be a different point type.			
			if (command[i] == "C") {
				x0 = p[ic++];
				y0 = p[ic++];
				x1 = p[ic++];
				y1 = p[ic++];
				x2 = p[ic++];
				y2 = p[ic++];
				
				if (is_null (path.points.last ().data)) {
					warning ("Paths must begin with M");
					return;
				}

				// start with line handles
				ep1 = path.points.last ().data;
				
				if (ep1.get_right_handle ().length != 0) {
					ep1.get_right_handle ().type = PointType.LINE_CUBIC;
					ep1.type = PointType.LINE_CUBIC;
					
					lx = ep1.x + ((x2 - ep1.x) / 3);
					ly = ep1.y + ((y2 - ep1.y) / 3);
													
					ep1.get_right_handle ().move_to_coordinate (lx, ly);
					ep1.recalculate_linear_handles ();
				}			
				
				// set curve handles
				ep1 = path.points.last ().data;
				if (ep1.get_right_handle ().length != 0 || path.points.length () == 1) {
					ep1.recalculate_linear_handles ();
					ep1.get_right_handle ().type = PointType.CUBIC;
					ep1.get_right_handle ().move_to_coordinate (x0, y0);
					ep1.type = PointType.CUBIC;
				} else {
					ep1.get_right_handle ().type = PointType.CUBIC;
					ep1.get_right_handle ().length = 0;
				}

				path.add (x2, y2);
					
				ep2 = path.points.last ().data;
				ep2.recalculate_linear_handles ();
				ep2.type = PointType.CUBIC;
				ep2.get_left_handle ().type = PointType.CUBIC;
				
				ep2.get_left_handle ().move_to_coordinate (x1, y1);
				
				if (ep2.get_left_handle ().length == 0) {
					ep2.get_right_handle ().length = 0;
				}
			}
			
			if (command[i] == "z") {
				// last point is first
				ep1 = path.points.last ().data;
				ep2 = path.points.first ().data;

				if (ep1.x == ep2.x && ep1.y == ep2.y) {
					ep2.left_handle.angle = ep1.left_handle.angle;
					ep2.left_handle.length = ep1.left_handle.length;
					ep2.left_handle.type = ep1.left_handle.type;
					path.points.remove_link (path.points.last ());
				}

				set_tied_handles (path);
				glyph.add_path (path);
				glyph.close_path ();
								
				path = new Path ();
			}
		}

		// TODO: Find out if it is possible to tie handles.
	}
	
	static double parse_double (string? s) {
		if (is_null (s)) {
			warning ("Got null instead of expected string.");
			return 0;
		}
		
		if (!is_point ((!) s)) {
			warning (@"Expecting a double got: $((!) s)");
			return 0;
		}
		
		return double.parse ((!) s);
	}
	
	static bool is_point (string? s) {
		if (s == null) {
			warning ("s is null");
			return false;
		}
		
		return double.try_parse ((!) s);
	}
	
	static void set_tied_handles (Path path) {
		double a, b;
		double d;
		
		foreach (EditPoint p in path.points) {
			a = p.get_left_handle ().angle;
			b = p.get_right_handle ().angle;
			d = a - b;
			if (fabs (d) - PI < 0.001) {
				p.set_tie_handle (true);
			}
		}
	}
}

}
