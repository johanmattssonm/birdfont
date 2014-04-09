/*
    Copyright (C) 2012, 2013, 2014 Johan Mattsson

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

public enum SvgFormat {
	INKSCAPE,
	ILLUSTRATOR
}

public class SvgParser {
	
	SvgFormat format = SvgFormat.INKSCAPE;
	
	public SvgParser () {
	}
	
	public void set_format (SvgFormat f) {
		format = f;
	}
	
	public static void import () {
		string? p;
		string path;
		
		p = MainWindow.file_chooser_open (t_("Import"));

		if (p == null) {
			return;
		}
		
		path = (!) p;
		import_svg (path);
	}
	
	public static void import_svg_data (string xml_data) {
		PathList path_list = new PathList ();
		Glyph glyph; 
		Xml.Doc* doc;
		Xml.Node* root = null;
		string[] lines = xml_data.split ("\n");
		string xml_document;
		bool has_format = false;
		StringBuilder sb = new StringBuilder ();
		SvgParser parser = new SvgParser ();
		TextReader tr;

		foreach (string l in lines) {
			if (l.index_of ("<!--") > -1 && l.index_of ("Illustrator") > -1) {
				parser.set_format (SvgFormat.ILLUSTRATOR);
				has_format = true;
			}
			
			if (l.index_of ("<!--") > -1 && l.index_of ("Inkscape") > -1) {
				parser.set_format (SvgFormat.INKSCAPE);
				has_format = true;
			}	
			
			// FIXME: libxml2 (2.7.8) refuses to parse svg files created with Adobe Illustrator on 
			// windows. This is a way around it.
			if (l.index_of ("<!") == -1 && l.index_of ("]>") == -1) {
				sb.append (l);
				sb.append ("\n");
			}
		}
		
		xml_document = sb.str;

		if (!has_format) {
			warning ("No format identifier found.");
		}

		Parser.init ();
		
		tr = new TextReader.for_doc (xml_document, "");
		tr.read ();
		root = tr.expand ();
				
		if (root == null) {
			warning ("Failed to load SVG file");
			delete doc;
			return;
		}

		path_list = parser.parse_svg_file (root);

		delete doc;
		Parser.cleanup ();
	
		glyph = MainWindow.get_current_glyph ();
		foreach (Path p in path_list.paths) {
			glyph.add_path (p);
		}
		
		foreach (Path p in path_list.paths) {
			glyph.add_active_path (p);
			p.update_region_boundaries ();
		}
		
		glyph.close_path ();	
	}
	
	public static void import_svg (string path) {
		string svg_data;
		try {
			FileUtils.get_contents (path, out svg_data);
		} catch (GLib.Error e) {
			warning (e.message);
		}
		import_svg_data (svg_data);
	}
	
	private PathList parse_svg_file (Xml.Node* root) {
		Xml.Node* node;
		PathList pl = new PathList ();
		
		node = root;
		
		for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
			if (iter->name == "g") {
				parse_layer (iter, pl);
			}
			
			if (iter->name == "path") {
				parse_path (iter, pl);
			}
			
			if (iter->name == "polygon") {
				parse_polygon (iter, pl);
			}
		}
		
		return pl;
	}
	
	private void parse_layer (Xml.Node* node, PathList pl) {
		return_if_fail (node != null);
				
		for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
			if (iter->name == "path") {
				parse_path (iter, pl);
			}
			
			if (iter->name == "g") {
				parse_layer (iter, pl);
			}
			
			if (iter->name == "polygon") {
				parse_polygon (iter, pl);
			}
		}
	}
	
	private void parse_polygon (Xml.Node* node, PathList pl) {
		string attr_name = "";
		string attr_content;
		Glyph glyph = MainWindow.get_current_glyph ();
		Path p;
			
		for (Xml.Attr* prop = node->properties; prop != null; prop = prop->next) {
			attr_name = prop->name;
			attr_content = prop->children->content;
			
			if (attr_name == "points") {
				p = parse_polygon_data (attr_content, glyph);
				pl.paths.append (p);
			}
		}		
	}
	
	private void parse_path (Xml.Node* node, PathList pl) {
		string attr_name = "";
		string attr_content;
		Glyph glyph = MainWindow.get_current_glyph ();
		PathList path_list;
			
		for (Xml.Attr* prop = node->properties; prop != null; prop = prop->next) {
			attr_name = prop->name;
			attr_content = prop->children->content;
			
			if (attr_name == "d") {
				path_list = parse_svg_data (attr_content, glyph);
				pl.append (path_list);
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
	
	public void add_path_to_glyph (string d, Glyph g) {
		PathList p = parse_svg_data (d, g);
		foreach (Path path in p.paths) {
			g.add_path (path);
		}
	}
	
	/** 
	 * @param d svg data
	 * @param glyph add paths to this glyph
	 * @param svg_glyph parse svg glyph with origo in lower left corner
	 * 
	 * @return the new paths
	 */
	public PathList parse_svg_data (string d, Glyph glyph, bool svg_glyph = false, double units = 1) {
		double px = 0;
		double py = 0;
		double px2 = 0;
		double py2 = 0;
		double cx = 0;
		double cy = 0;
		string data;
		Font font;
		PathList path_list = new PathList ();
		BezierPoints[] bezier_points;
		string[] c;
		
		if (d.index_of ("z") == -1) { // ignore all open paths
			return path_list;
		}

		font = BirdFont.get_current_font ();
		
		data = add_separators (d);
		c = data.split (" ");
		bezier_points = new BezierPoints[2 * c.length + 1];
		
		for (int i = 0; i < 2 * c.length + 1; i++) {
			bezier_points[i] = new BezierPoints ();
		}
		
		int bi = 0;
		
		// parse path
		int i = -1;
		while (++i < c.length) {	
			if (c[i] == "m") {
				while (is_point (c[i + 1])) { // FIXME: check array bounds
					bezier_points[bi].type = 'M';
					bezier_points[bi].svg_type = 'm';
					
					px += parse_double (c[++i]);
					
					if (svg_glyph) {
						py += parse_double (c[++i]);
					} else {
						py += -parse_double (c[++i]);
					}
					
					bezier_points[bi].x0 = px;
					bezier_points[bi].y0 = py;
					bi++;
				}
			} else if (c[i] == "M") {
				while (is_point (c[i + 1])) {
					bezier_points[bi].type = 'M';
					bezier_points[bi].svg_type = 'M';
					
					px = parse_double (c[++i]);
					
					if (svg_glyph) {
						py = parse_double (c[++i]);
					} else {
						py = -parse_double (c[++i]);
					}
					
					bezier_points[bi].x0 = px;
					bezier_points[bi].y0 = py;
					bi++;
				}
			} else if (c[i] == "h") {
				while (is_point (c[i + 1])) {
					bezier_points[bi].type = 'L';
					bezier_points[bi].svg_type = 'h';
					
					px += parse_double (c[++i]);

					bezier_points[bi].x0 = px;
					bezier_points[bi].y0 = py;
					bi++;
				}
			} else if (c[i] == "H") {
				while (is_point (c[i + 1])) {
					bezier_points[bi].type = 'L';
					bezier_points[bi].svg_type = 'H';
					
					px = parse_double (c[++i]);

					bezier_points[bi].x0 = px;
					bezier_points[bi].y0 = py;
					bi++;
				}
			} else if (c[i] == "v") {
				while (is_point (c[i + 1])) {
					bezier_points[bi].type = 'L';
					bezier_points[bi].svg_type = 'v';
										
					if (svg_glyph) {
						py = py + parse_double (c[++i]);
					} else {
						py = py + -parse_double (c[++i]);
					}
					
					bezier_points[bi].x0 = px;
					bezier_points[bi].y0 = py;
					bi++;
				}				
			} else if (c[i] == "V") {
				while (is_point (c[i + 1])) {
					bezier_points[bi].type = 'L';
					bezier_points[bi].svg_type = 'V';
										
					if (svg_glyph) {
						py = parse_double (c[++i]);
					} else {
						py = -parse_double (c[++i]);
					}
					
					bezier_points[bi].x0 = px;
					bezier_points[bi].y0 = py;
					bi++;
				}
			} else if (c[i] == "l") {
				while (is_point (c[i + 1])) {
					bezier_points[bi].type = 'L';
					bezier_points[bi].svg_type = 'l';
										
					cx = px + parse_double (c[++i]);
					
					if (svg_glyph) {
						cy = py + parse_double (c[++i]);
					} else {
						cy = py + -parse_double (c[++i]);
					}
					
					px = cx;
					py = cy;

					bezier_points[bi].x0 = cx;
					bezier_points[bi].y0 = cy;
					bi++;
				}
			} else if (c[i] == "L") {
				while (is_point (c[i + 1])) {
					bezier_points[bi].type = 'L';
					bezier_points[bi].svg_type = 'L';
										
					cx = parse_double (c[++i]);
					
					if (svg_glyph) {
						cy = parse_double (c[++i]);
					} else {
						cy = -parse_double (c[++i]);
					}
					
					px = cx;
					py = cy;
					
					bezier_points[bi].x0 = cx;
					bezier_points[bi].y0 = cy;
					bi++;				
				}	
			} else if (c[i] == "c") {
				while (is_point (c[i + 1])) {
					bezier_points[bi].type = 'C';
					bezier_points[bi].svg_type = 'C';
										
					cx = px + parse_double (c[++i]);
					
					if (svg_glyph) {
						cy = py + parse_double (c[++i]);
					} else {
						cy = py + -parse_double (c[++i]);
					}
					
					bezier_points[bi].x0 = cx;
					bezier_points[bi].y0 = cy;
										
					cx = px + parse_double (c[++i]);
					
					if (svg_glyph) {
						cy = py + parse_double (c[++i]);
					} else {
						cy = py + -parse_double (c[++i]);
					}
					
					px2 = cx;
					py2 = cy;
										
					bezier_points[bi].x1 = px2;
					bezier_points[bi].y1 = py2;
										
					cx = px + parse_double (c[++i]);
					
					if (svg_glyph) {
						cy = py + parse_double (c[++i]);
					} else {
						cy = py + -parse_double (c[++i]);
					}
					
					bezier_points[bi].x2 = cx;
					bezier_points[bi].y2 = cy;
										
					px = cx;
					py = cy;
					
					bi++;
				}
			} else if (c[i] == "C") {
				while (is_point (c[i + 1])) {
					bezier_points[bi].type = 'C';
					bezier_points[bi].svg_type = 'C';
										
					cx = parse_double (c[++i]);
					
					if (svg_glyph) {
						cy = parse_double (c[++i]);
					} else {
						cy = -parse_double (c[++i]);
					}
									
					bezier_points[bi].x0 = cx;
					bezier_points[bi].y0 = cy;
					
					cx = parse_double (c[++i]);
					
					if (svg_glyph) {
						cy = parse_double (c[++i]);
					} else {
						cy = -parse_double (c[++i]);
					}
					
					px2 = cx;
					py2 = cy;
					
					bezier_points[bi].x1 = cx;
					bezier_points[bi].y1 = cy;
										
					cx = parse_double (c[++i]);
					
					if (svg_glyph) {
						cy = parse_double (c[++i]);
					} else {
						cy = -parse_double (c[++i]);
					}
					
					bezier_points[bi].x2 = cx;
					bezier_points[bi].y2 = cy;
										
					px = cx;
					py = cy;
					
					bi++;				
				}	
			} else if (c[i] == "q") {
				while (is_point (c[i + 1])) {
					bezier_points[bi].type = 'Q';
					bezier_points[bi].svg_type = 'q';
										
					cx = px + parse_double (c[++i]);
					
					if (svg_glyph) {
						cy = py + parse_double (c[++i]);
					} else {
						cy = py + -parse_double (c[++i]);
					}
					
					bezier_points[bi].x0 = cx;
					bezier_points[bi].y0 = cy;
										
					px2 = cx;
					py2 = cy;
										
					cx = px + parse_double (c[++i]);
					
					if (svg_glyph) {
						cy = py + parse_double (c[++i]);
					} else {
						cy = py + -parse_double (c[++i]);
					}
					
					bezier_points[bi].x1 = cx;
					bezier_points[bi].y1 = cy;
										
					px = cx;
					py = cy;
					
					bi++;
				}
			} else if (c[i] == "Q") {

				while (is_point (c[i + 1])) {
					bezier_points[bi].type = 'Q';
					bezier_points[bi].svg_type = 'Q';
										
					cx = parse_double (c[++i]);
					
					if (svg_glyph) {
						cy = parse_double (c[++i]);
					} else {
						cy = -parse_double (c[++i]);
					}
					
					bezier_points[bi].x0 = cx;
					bezier_points[bi].y0 = cy;
					
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

					bezier_points[bi].x1 = cx;
					bezier_points[bi].y1 = cy;
										
					bi++;					
				}	
			} else if (c[i] == "t") {
				while (is_point (c[i + 1])) {
					bezier_points[bi].type = 'Q';
					bezier_points[bi].svg_type = 't';
										
					// the first point is the reflection
					cx = 2 * px - px2;
					cy = 2 * py - py2; // if (svg_glyph) ?
					
					bezier_points[bi].x0 = cx;
					bezier_points[bi].y0 = cy;
					
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
					
					bezier_points[bi].x1 = px;
					bezier_points[bi].y1 = py;
										
					bi++;
				}
			} else if (c[i] == "T") {
				while (is_point (c[i + 1])) {
					bezier_points[bi].type = 'Q';
					bezier_points[bi].svg_type = 'T';
										
					// the reflection
					cx = 2 * px - px2;
					cy = 2 * py - py2; // if (svg_glyph) ?
					
					bezier_points[bi].x0 = cx;
					bezier_points[bi].y0 = cy;
										
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
					
					bezier_points[bi].x1 = px;
					bezier_points[bi].y1 = py;
										
					bi++;				
				}
			} else if (c[i] == "s") {
				while (is_point (c[i + 1])) {
					bezier_points[bi].type = 'C';
					bezier_points[bi].svg_type = 's';
										
					// the first point is the reflection
					cx = 2 * px - px2;
					cy = 2 * py - py2; // if (svg_glyph) ?

					bezier_points[bi].x0 = cx;
					bezier_points[bi].y0 = cy;
															
					cx = px + parse_double (c[++i]);
					
					if (svg_glyph) {
						cy = py + parse_double (c[++i]);
					} else {
						cy = py + -parse_double (c[++i]);
					}
					
					px2 = cx;
					py2 = cy;
					
					bezier_points[bi].x1 = px2;
					bezier_points[bi].y1 = py2;
					
					cx = px + parse_double (c[++i]);
					
					if (svg_glyph) {
						cy = py + parse_double (c[++i]);
					} else {
						cy = py + -parse_double (c[++i]);
					}
					
					bezier_points[bi].x2 = cx;
					bezier_points[bi].y2 = cy;
												
					px = cx;
					py = cy;
					
					bi++;
				}
			} else if (c[i] == "S") {
				while (is_point (c[i + 1])) {
					bezier_points[bi].type = 'C';
					bezier_points[bi].svg_type = 'S';
										
					// the reflection
					cx = 2 * px - px2;
					cy = 2 * py - py2; // if (svg_glyph) ?			

					bezier_points[bi].x0 = cx;
					bezier_points[bi].y0 = cy;
					
					// the other two are regular cubic points
					cx = parse_double (c[++i]);
					
					if (svg_glyph) {
						cy = parse_double (c[++i]);
					} else {
						cy = -parse_double (c[++i]);
					}
					
					px2 = cx;
					py2 = cy;
					
					bezier_points[bi].x1 = px2;
					bezier_points[bi].y1 = py2;
					
					cx = parse_double (c[++i]);
					
					if (svg_glyph) {
						cy = parse_double (c[++i]);
					} else {
						cy = -parse_double (c[++i]);
					}
					
					bezier_points[bi].x2 = cx;
					bezier_points[bi].y2 = cy;
					
					px = cx;
					py = cy;	
					
					bi++;				
				}
			} else if (c[i] == "z") {
				bezier_points[bi].type = 'z';
				bezier_points[bi].svg_type = 'z';
				
				bi++;
			} else if (c[i] == "Z") {
				bezier_points[bi].type = 'z';
				bezier_points[bi].svg_type = 'z';
									
				bi++;
			} else if (c[i] == "") {
			} else if (c[i] == " ") {
			} else {
				warning (@"Unknown instruction: $(c[i])");
			}
		}

		move_and_resize (bezier_points, bi, svg_glyph, units, glyph);

		if (format == SvgFormat.ILLUSTRATOR) {
			path_list = create_paths_illustrator (bezier_points, bi);
		} else {
			path_list = create_paths_inkscape (bezier_points, bi);
		}

		// TODO: Find out if it is possible to tie handles.
		return path_list;
	}

	void move_and_resize (BezierPoints[] b, int num_b, bool svg_glyph, double units, Glyph glyph) {
		Font font = BirdFont.get_current_font ();
		
		for (int i = 0; i < num_b; i++) {
			// resize all points
			b[i].x0 *= units;
			b[i].y0 *= units;
			b[i].x1 *= units;
			b[i].y1 *= units;
			b[i].x2 *= units;
			b[i].y2 *= units;

			// move all points
			if (svg_glyph) {
				// move only y 
				b[i].x0 += glyph.left_limit;
				b[i].y0 += font.base_line;
				b[i].x1 += glyph.left_limit;
				b[i].y1 += font.base_line;
				b[i].x2 += glyph.left_limit;
				b[i].y2 += font.base_line;
			} else {
				b[i].x0 += glyph.left_limit;
				b[i].y0 += font.top_position;
				b[i].x1 += glyph.left_limit;
				b[i].y1 += font.top_position;
				b[i].x2 += glyph.left_limit;
				b[i].y2 += font.top_position;
			}
		}
	}
	
	void find_last_handle (int start_index, BezierPoints[] b, int num_b, out double left_x, out double left_y, out PointType last_type) {
		BezierPoints last = new BezierPoints ();
		
		left_x = 0;
		left_y = 0;
		last_type = PointType.NONE;
		
		return_if_fail (b.length != 0);
		return_if_fail (b[0].type != 'z');
		
		for (int i = start_index; i < num_b; i++) {
			switch (b[i].type) {
				case 'Q':
					break;
				case 'C':
					break;
				case 'z':
					if (b[i - 1].type == 'Q') {
						return_if_fail (i >= 1);
						warning ("Unexpected qubic points in Inkscape SVG");
						left_x = b[i - 1].x0;
						left_y = b[i - 1].y0;
						last_type = PointType.QUADRATIC;
					} else if (b[i - 1].type == 'C') {
						return_if_fail (i >= 1);
						left_x = b[i - 1].x1;
						left_y = b[i - 1].y1;
						last_type = PointType.CUBIC;
					} else if (b[i - 1].type == 'L' || last.type == 'M') {
						return_if_fail (i >= 2); // FIXME: -2 can be C or L
						left_x = b[i - 2].x0 + (b[i - 1].x0 - b[i - 2].x0) / 3.0;
						left_y = b[i - 2].y0 + (b[i - 1].y0 - b[i - 2].y0) / 3.0;
						last_type = PointType.LINE_CUBIC;
					} else {
						warning (@"Unexpected type. $(b[i - 1])\n");
					}
					return;
				default:
					break;
			}
			
			last = b[i];
		}
		
		warning ("Expecting z");
	}

	PathList create_paths_inkscape (BezierPoints[] b, int num_b) {
		double last_x;
		double last_y; 
		PointType last_type;
		Path path;
		PathList path_list = new PathList ();
		EditPoint ep = new EditPoint ();
		
		path = new Path ();
		
		if (num_b == 0) {
			warning ("No SVG data");
			return path_list;
		}

		if (b[0].type != 'M') {
			warning ("Path must begin with M or m.");
			return path_list;
		}
		
		find_last_handle (0, b, num_b, out last_x, out last_y, out last_type);

		for (int i = 0; i < num_b; i++) {
			if (b[i].type == '\0') {
				warning ("Parser error.");
				return path_list;
			}

			if (b[i].type == 'z') {
				path.close ();
				path.create_list ();
				path.recalculate_linear_handles ();
				path_list.add (path);
				path = new Path ();
				
				if (i + 1 >= num_b) {
					break;
				} else {
					find_last_handle (i + 1, b, num_b, out last_x, out last_y, out last_type);
				}
			}
	
			return_val_if_fail (i + 1 < num_b, path_list);
	
			if (b[i].type == 'M') {
				ep = path.add (b[i].x0, b[i].y0);
				ep.set_point_type (PointType.CUBIC);

				ep.get_left_handle ().set_point_type (PointType.LINE_CUBIC);
				
				if (i == 0) {
					ep.get_left_handle ().set_point_type (last_type);
					ep.get_left_handle ().move_to_coordinate (last_x, last_y);
				} else {
					if (b[i - 1].type == 'C') {
						ep.get_left_handle ().set_point_type (PointType.CUBIC);
						ep.get_left_handle ().move_to_coordinate (b[i + 1].x1, b[i + 1].y1);
					} 
					
					if (b[i + 1].type == 'C') {
						ep.get_right_handle ().set_point_type (PointType.CUBIC);
						ep.get_right_handle ().move_to_coordinate (b[i + 1].x0, b[i + 1].y0);
					} else if (b[i + 1].type == 'L' || b[i + 1].type == 'M') {
						ep.get_right_handle ().set_point_type (PointType.LINE_CUBIC);					
					}
				}
			}

			if (b[i].type == 'L') {
				return_val_if_fail (i != 0, path_list);
				
				ep = path.add (b[i].x0, b[i].y0);
				ep.set_point_type (PointType.CUBIC);
				ep.get_right_handle ().set_point_type (PointType.LINE_CUBIC);
				ep.get_left_handle ().set_point_type (PointType.LINE_CUBIC);

				if (b[i + 1].type == 'L' || b[i + 1].type == 'M' || b[i + 1].type == 'z') {
					ep.get_right_handle ().set_point_type (PointType.LINE_CUBIC);
				}

				if (b[i -1].type == 'L' || b[i - 1].type == 'M') {
					ep.get_left_handle ().set_point_type (PointType.LINE_CUBIC);
				}
			}
			
			if (b[i].type == 'Q') {
				warning ("Inkscape does not support quadratic control points.");
			}
	
			if (b[i].type == 'C') {
				return_val_if_fail (i != 0, path_list);

				ep.set_point_type (PointType.CUBIC);
				
				ep.get_right_handle ().set_point_type (PointType.CUBIC);
				ep.get_right_handle ().move_to_coordinate (b[i].x0, b[i].y0);
				
				if (b[i + 1].type != 'z') {
					ep = path.add (b[i].x2, b[i].y2);

					ep.get_left_handle ().set_point_type (PointType.CUBIC);
					ep.get_left_handle ().move_to_coordinate (b[i].x1, b[i].y1);
				}
			}
		}
		
		if (path.points.length () > 0) {
			warning ("Open path.");
			path_list.add (path);
		}
		
		return path_list;
	}

	PathList create_paths_illustrator (BezierPoints[] b, int num_b) {
		Path path;
		PathList path_list = new PathList ();
		EditPoint ep;
		bool first_point = true;
		double first_left_x, first_left_y;
		
		path = new Path ();
		
		if (num_b == 0) {
			warning ("No SVG data");
			return path_list;
		}
		
		if (b[num_b - 1].type != 'z') {
			warning ("Path is open.");
			return path_list;
		}
		
		first_left_x = 0;
		first_left_y = 0;
		
		for (int i = 0; i < num_b; i++) {
			if (b[i].type == '\0') {
				warning ("Parser error.");
				return path_list;
			} else if (b[i].type == 'z') {
				path.close ();
				path.create_list ();
				path.recalculate_linear_handles ();
				path_list.add (path);
				path = new Path ();
				first_point = true;
			} else if (b[i].type == 'M') {
			} else if (b[i].type == 'L') {
				ep = path.add (b[i].x0, b[i].y0);
				ep.set_point_type (PointType.LINE_CUBIC); // TODO: quadratic
				ep.get_right_handle ().set_point_type (PointType.LINE_CUBIC);
				
				if (b[i -1].type == 'L' || first_point) {
					ep.get_left_handle ().set_point_type (PointType.LINE_CUBIC);
				}
				
				if (b[i + 1].type == 'C') {
					return_val_if_fail (i + i < num_b, path_list);
					ep.get_right_handle ().set_point_type (PointType.CUBIC);
					ep.get_right_handle ().move_to_coordinate (b[i + 1].x0, b[i + 1].y0);
				}
				
				first_point = false;
			} else if (b[i].type == 'Q') {
				warning ("Illustrator does not support quadratic control points.");
				print (@"$(b[i])\n");
			} else if (b[i].type == 'C') {
				
				if (first_point) {
					first_left_x = b[i].x0;
					first_left_y = b[i].y0;
				}
				
				ep = path.add (b[i].x2, b[i].y2);
				ep.set_point_type (PointType.CUBIC);

				ep.get_right_handle ().set_point_type (PointType.CUBIC);
				ep.get_left_handle ().set_point_type (PointType.CUBIC);
				
				ep.get_left_handle ().move_to_coordinate (b[i].x1, b[i].y1);
				
				if (b[i + 1].type != 'z') {
					ep.get_right_handle ().move_to_coordinate (b[i + 1].x0, b[i + 1].y0);
				} else {
					ep.get_right_handle ().move_to_coordinate (first_left_x, first_left_y);
				}
				
				first_point = false;
			} else {
				warning ("Unknown control point type.");
				print (@"$(b[i])\n");
			}
		}
		
		if (path.points.length () > 0) {
			warning ("Open path.");
			path_list.add (path);
		}
		
		return path_list;
	}
	
	// TODO: implement a default svg parser
	
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
	
	Path parse_polygon_data (string polygon_points, Glyph glyph) {
		string data = add_separators (polygon_points);
		string[] c = data.split (" ");
		Path path = new Path ();
		
		for (int i = 0; i < c.length - 1; i += 2) {	
			if (i + 1 == c.length) {
				warning ("No y value.");
				break;
			}
			
			path.add (parse_double (c[i]), -parse_double (c[i + 1]));
		}
		
		glyph.add_path (path);
		path.close ();
		path.create_list ();
		glyph.close_path ();
		
		return path;
	}

	private class BezierPoints {
		public unichar type = '\0';
		public unichar svg_type = '\0';
		public double x0  = 0;
		public double y0 = 0;
		public double x1 = 0;
		public double y1 = 0;
		public double x2 = 0;
		public double y2 = 0;
		
		public string to_string () {
			return @"$((!)type.to_string ()) $x0,$y0 $x1,$y1 $x2,$y2 SVG:$((!)svg_type.to_string ())";
		}
	}
}

}
