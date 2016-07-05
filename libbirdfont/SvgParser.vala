/*
	Copyright (C) 2012 - 2016 Johan Mattsson

	This library is free software; you can redistribute it and/or modify 
	it under the terms of the GNU Lesser General Public License as 
	published by the Free Software Foundation; either version 3 of the 
	License, or (at your option) any later version.

	This library is distributed in the hope that it will be useful, but 
	WITHOUT ANY WARRANTY; without even the implied warranty of 
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
	Lesser General Public License for more details.
*/

using B;
using Math;

namespace BirdFont {

public enum SvgFormat {
	NONE,
	INKSCAPE,
	ILLUSTRATOR
}

public class SvgParser {
	
	SvgFormat format = SvgFormat.ILLUSTRATOR;
	
	public SvgParser () {
	}
	
	public void set_format (SvgFormat f) {
		format = f;
	}
	
	public static void import () {
		FileChooser fc = new FileChooser ();
		fc.file_selected.connect ((p) => {
			string path;
				
			if (p == null) {
				return;
			}
			
			path = (!) p;
			import_svg (path);
		});
		
		fc.add_extension ("svg");
		MainWindow.file_chooser (t_("Import"), fc, FileChooser.LOAD);
	}
	
	public static void import_folder () {
		FileChooser fc = new FileChooser ();
		fc.file_selected.connect ((p) => {
			string path;
			File svg_folder;
			File svg;
			bool imported;
			FileEnumerator enumerator;
			FileInfo? file_info;
			string file_name;
			Font font;
			
			if (p == null) {
				return;
			}
			
			path = (!) p;
			svg_folder = File.new_for_path (path);
			font = BirdFont.get_current_font ();
				
			try {
				enumerator = svg_folder.enumerate_children (FileAttribute.STANDARD_NAME, 0);
				while ((file_info = enumerator.next_file ()) != null) {
					file_name = ((!) file_info).get_name ();
					
					if (file_name.has_suffix (".svg")) {
						svg = get_child (svg_folder, file_name);
						imported = import_svg_file (font, svg);
						
						if (!imported) {
							warning ("Can't import %s.", (!) svg.get_path ());
						} else {
							font.touch ();
						}
					}
				}
			} catch (Error e) {
				warning (e.message);
			}
		});
		
		MainWindow.file_chooser (t_("Import"), fc, FileChooser.LOAD | FileChooser.DIRECTORY);
	}
	
	public static void import_svg_data (string xml_data, SvgFormat format = SvgFormat.NONE) {
		PathList path_list = new PathList ();
		Glyph glyph; 
		string[] lines = xml_data.split ("\n");
		bool has_format = false;
		SvgParser parser = new SvgParser ();
		XmlParser xmlparser;

		foreach (string l in lines) {
			if (l.index_of ("Illustrator") > -1 || l.index_of ("illustrator") > -1) {
				parser.set_format (SvgFormat.ILLUSTRATOR);
				has_format = true;
			}
			
			if (l.index_of ("Inkscape") > -1 || l.index_of ("inkscape") > -1) {
				parser.set_format (SvgFormat.INKSCAPE);
				has_format = true;
			}
		}
		
		if (format != SvgFormat.NONE) {
			parser.set_format (format);
		}

		// parse the file
		if (!has_format) {
			warn_if_test ("No format identifier found in SVG parser.\n");
		}

		xmlparser = new XmlParser (xml_data);
		
		if (!xmlparser.validate()) {
			warning("Invalid XML in SVG parser."); 
		}
		
		path_list = parser.parse_svg_file (xmlparser.get_root_tag ());
	
		glyph = MainWindow.get_current_glyph ();
		foreach (Path p in path_list.paths) {
			glyph.add_path (p);
		}
		
		foreach (Path p in path_list.paths) {
			glyph.add_active_path (null, p); // FIXME: groups
			p.update_region_boundaries ();
		}
		
		glyph.close_path ();	
	}
	
	public static string replace (string content, string start, string stop, string replacement) {
		int i_tag = content.index_of (start);
		int end_tag = content.index_of (stop, i_tag);
		string c = "";
		
		if (i_tag > -1) {
			c = content.substring (0, i_tag) 
				+ replacement
				+ content.substring (end_tag + stop.length);
		} else {
			c = content;
		}
		
		return c;
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
	
	private PathList parse_svg_file (Tag tag) {
		Layer pl = new Layer ();
	
		foreach (Tag t in tag) {
			
			if (t.get_name () == "g") {
				parse_layer (t, pl);
			}

			if (t.get_name () == "switch") {
				parse_layer (t, pl);
			}
						
			if (t.get_name () == "path") {
				parse_path (t, pl);
			}
			
			if (t.get_name () == "polygon") {
				parse_polygon (t, pl);
			}

			if (t.get_name () == "polyline") {
				parse_polyline (t, pl);
			}
						
			if (t.get_name () == "circle") {
				parse_circle (t, pl);
			}
			
			if (t.get_name () == "ellipse") {
				parse_ellipse (t, pl);
			}

			if (t.get_name () == "line") {
				parse_line (t, pl);
			}			
		}
		
		return pl.get_all_paths ();
	}
	
	private void parse_layer (Tag tag, Layer pl) {
		Layer layer;
		bool hidden = false;

		foreach (Attribute attr in tag.get_attributes ()) {	
			if (attr.get_name () == "display" && attr.get_content () == "none") {
				hidden = true;
			}
			
			if (attr.get_name () == "visibility"
				&& (attr.get_content () == "hidden" 
					|| attr.get_content () == "collapse")) {
				hidden = true;
			}
		}
		
		if (hidden) {
			return;
		}
					
		foreach (Tag t in tag) {
			if (t.get_name () == "path") {
				parse_path (t, pl);
			}
			
			if (t.get_name () == "g") {
				layer = new Layer ();
				parse_layer (t, layer);
				pl.subgroups.add (layer);
			}
			
			if (t.get_name () == "polygon") {
				parse_polygon (t, pl);
			}

			if (t.get_name () == "polyline") {
				parse_polyline (t, pl);
			}
			
			if (t.get_name () == "rect") {
				parse_rect (t, pl);
			}

			if (t.get_name () == "circle") {
				parse_circle (t, pl);
			}

			if (t.get_name () == "ellipse") {
				parse_ellipse (t, pl);
			}
			
			if (t.get_name () == "line") {
				parse_line (t, pl);
			}
		}

		foreach (Attribute attr in tag.get_attributes ()) {	
			if (attr.get_name () == "transform") {
				transform (attr.get_content (), pl);
			}
		}
	}
	
	private void transform (string transform_functions, Layer layer) {
		transform_paths (transform_functions, layer.paths);
		transform_subgroups (transform_functions, layer);
	}
	
	private void transform_subgroups (string transform_functions, Layer layer) {
		foreach (Layer subgroup in layer.subgroups) {
			transform (transform_functions, subgroup);
		}
	}
	
	private void transform_paths (string transform_functions, PathList pl) {
		string data = transform_functions.dup ();
		string[] functions;
		
		// use only a single space as separator
		while (data.index_of ("  ") > -1) {
			data = data.replace ("  ", " ");
		}
		
		return_if_fail (data.index_of (")") > -1);
		
		 // add separator
		data = data.replace (") ", "|");
		data = data.replace (")", "|"); 
		functions = data.split ("|");
		
		for (int i = functions.length - 1; i >= 0; i--) {
			if (functions[i].has_prefix ("translate")) {
				translate (functions[i], pl);
			}
			
			if (functions[i].has_prefix ("scale")) {
				scale (functions[i], pl);
			}

			if (functions[i].has_prefix ("matrix")) {
				matrix (functions[i], pl);
			}
			
			// TODO: rotate etc.
		}
	}

	/** @param path a path in the cartesian coordinate system
	 * The other parameters are in the SVG coordinate system.
	 */
	public static void apply_matrix (Path path, double a, double b, double c, 
		double d, double e, double f){
		
		double dx, dy;
		Font font = BirdFont.get_current_font ();
		Glyph glyph = MainWindow.get_current_glyph ();
		
		foreach (EditPoint ep in path.points) {
			ep.tie_handles = false;
			ep.reflective_point = false;
		}
		
		foreach (EditPoint ep in path.points) {
			apply_matrix_on_handle (ep.get_right_handle (), a, b, c, d, e, f);
			
			EditPointHandle left = ep.get_left_handle ();
			if (left.type == PointType.QUADRATIC || left.type == PointType.LINE_QUADRATIC) {
				ep.get_right_handle ().process_connected_handle ();
			} else {				
				apply_matrix_on_handle (left, a, b, c, d, e, f);
			}
			
			ep.independent_y = font.top_position - ep.independent_y;
			ep.independent_x -= glyph.left_limit;
			
			dx = a * ep.independent_x + c * ep.independent_y + e;
			dy = b * ep.independent_x + d * ep.independent_y + f;
			
			ep.independent_x = dx;
			ep.independent_y = dy;
			
			ep.independent_y = font.top_position - ep.independent_y;
			ep.independent_x += glyph.left_limit;
		}
	}

	public static void apply_matrix_on_handle (EditPointHandle h, 
		double a, double b, double c, 
		double d, double e, double f){
		
		double dx, dy;
		Font font = BirdFont.get_current_font ();
		Glyph glyph = MainWindow.get_current_glyph ();

		h.y = font.top_position - h.y;
		h.x -= glyph.left_limit;
		
		dx = a * h.x + c * h.y + e;
		dy = b * h.x + d * h.y + f;
		
		h.x = dx;
		h.y = dy;
		
		h.y = font.top_position - h.y;
		h.x += glyph.left_limit;
	}


	private void matrix (string function, PathList pl) {
		string parameters = get_transform_parameters (function);
		string[] p = parameters.split (" ");

		if (p.length != 6) {
			warning ("Expecting six parameters for matrix transformation.");
			return;
		}

		foreach (Path path in pl.paths) {
			apply_matrix (path, parse_double (p[0]), parse_double (p[1]), 
				parse_double (p[2]), parse_double (p[3]), 
				parse_double (p[4]), parse_double (p[5]));
		}
	}
		
	private void scale (string function, PathList pl) {
		string parameters = get_transform_parameters (function);
		string[] p = parameters.split (" ");
		double x, y;
		
		x = 1;
		y = 1;
		
		if (p.length > 0) {
			x = parse_double (p[0]);
		}
		
		if (p.length > 1) {
			y = parse_double (p[1]);
		}
		
		foreach (Path path in pl.paths) {
			path.scale (-x, y);
		}
	}
	
	private void translate (string function, PathList pl) {
		string parameters = get_transform_parameters (function);
		string[] p = parameters.split (" ");
		double x, y;
		
		x = 0;
		y = 0;
		
		if (p.length > 0) {
			x = parse_double (p[0]);
		}
		
		if (p.length > 1) {
			y = parse_double (p[1]);
		}
		
		foreach (Path path in pl.paths) {
			path.move (x, -y);
		}
	}

	private string get_transform_parameters (string function) {
		int i;
		string param = "";
		
		i = function.index_of ("(");
		return_val_if_fail (i != -1, param);
		param = function.substring (i);

		param = param.replace ("(", "");
		param = param.replace ("\n", " ");
		param = param.replace ("\t", " ");
		param = param.replace (",", " ");
		
		while (param.index_of ("  ") > -1) {
			param = param.replace ("  ", " ");
		}
			
		return param.strip();			
	}
	
	private void parse_circle (Tag tag, Layer pl) {
		Path p;
		double x, y, r;
		Glyph g;
		PathList npl;
		BezierPoints[] bezier_points;
		SvgStyle style = new SvgStyle ();
		bool hidden = false;
		
		npl = new PathList ();
		
		x = 0;
		y = 0;
		r = 0;
			
		foreach (Attribute attr in tag.get_attributes ()) {			
			if (attr.get_name () == "cx") {
				x = parse_double (attr.get_content ());
			}
			
			if (attr.get_name () == "cy") {
				y = -parse_double (attr.get_content ());
			}

			if (attr.get_name () == "r") {
				r = parse_double (attr.get_content ());
			}
	
			if (attr.get_name () == "display" && attr.get_content () == "none") {
				hidden = true;
			}
		}
		
		style = SvgStyle.parse (tag.get_attributes ());
		
		if (hidden) {
			return;
		}
		
		bezier_points = new BezierPoints[1];
		bezier_points[0] = new BezierPoints ();
		bezier_points[0].type == 'L';
		bezier_points[0].x0 = x;
		bezier_points[0].y0 = y;

		g = MainWindow.get_current_glyph ();
		move_and_resize (bezier_points, 1, false, 1, g);
			
		p = CircleTool.create_circle (bezier_points[0].x0,
			bezier_points[0].y0, r, PointType.CUBIC);

		npl.add (p);
		
		foreach (Attribute attr in tag.get_attributes ()) {
			if (attr.get_name () == "transform") {
				transform_paths (attr.get_content (), npl);
			}
		}
		
		style.apply (npl);
		pl.paths.append (npl);
	}

	private void parse_ellipse (Tag tag, Layer pl) {
		Path p;
		double x, y, rx, ry;
		Glyph g;
		PathList npl;
		BezierPoints[] bezier_points;
		SvgStyle style = new SvgStyle ();
		bool hidden = false;
		
		npl = new PathList ();
		
		x = 0;
		y = 0;
		rx = 0;
		ry = 0;
		
		foreach (Attribute attr in tag.get_attributes ()) {			
			if (attr.get_name () == "cx") {
				x = parse_double (attr.get_content ());
			}
			
			if (attr.get_name () == "cy") {
				y = -parse_double (attr.get_content ());
			}

			if (attr.get_name () == "rx") {
				rx = parse_double (attr.get_content ());
			}

			if (attr.get_name () == "ry") {
				ry = parse_double (attr.get_content ());
			}
	
			if (attr.get_name () == "display" && attr.get_content () == "none") {
				hidden = true;
			}
		}
		
		style = SvgStyle.parse (tag.get_attributes ());
		
		if (hidden) {
			return;
		}
		
		bezier_points = new BezierPoints[1];
		bezier_points[0] = new BezierPoints ();
		bezier_points[0].type == 'L';
		bezier_points[0].x0 = x;
		bezier_points[0].y0 = y;

		g = MainWindow.get_current_glyph ();
		move_and_resize (bezier_points, 1, false, 1, g);
			
		p = CircleTool.create_ellipse (bezier_points[0].x0,
			bezier_points[0].y0, rx, ry, PointType.CUBIC);

		npl.add (p);
		
		foreach (Attribute attr in tag.get_attributes ()) {
			if (attr.get_name () == "transform") {
				transform_paths (attr.get_content (), npl);
			}
		}
		
		style.apply (npl);
		pl.paths.append (npl);
	}

	private void parse_line (Tag tag, Layer pl) {
		Path p;
		double x1, y1, x2, y2;
		BezierPoints[] bezier_points;
		Glyph g;
		PathList npl = new PathList ();
		SvgStyle style = new SvgStyle ();
		bool hidden = false;
		
		x1 = 0;
		y1 = 0;
		x2 = 0;
		y2 = 0;
			
		foreach (Attribute attr in tag.get_attributes ()) {			
			if (attr.get_name () == "x1") {
				x1 = parse_double (attr.get_content ());
			}
			
			if (attr.get_name () == "y1") {
				y1 = -parse_double (attr.get_content ());
			}

			if (attr.get_name () == "x2") {
				x2 = parse_double (attr.get_content ());
			}
			
			if (attr.get_name () == "xy") {
				y2 = -parse_double (attr.get_content ());
			}
	
			if (attr.get_name () == "display" && attr.get_content () == "none") {
				hidden = true;
			}
		}
		
		style = SvgStyle.parse (tag.get_attributes ());
		
		if (hidden) {
			return;
		}

		bezier_points = new BezierPoints[2];
		bezier_points[0] = new BezierPoints ();
		bezier_points[0].type == 'L';
		bezier_points[0].x0 = x1;
		bezier_points[0].y0 = y1;

		bezier_points[1] = new BezierPoints ();
		bezier_points[1].type == 'L';
		bezier_points[1].x0 = x2;
		bezier_points[1].y0 = y2;
		
		g = MainWindow.get_current_glyph ();
		move_and_resize (bezier_points, 2, false, 1, g);
					
		p = new Path ();	
		
		p.add (bezier_points[0].x0, bezier_points[0].y0);
		p.add (bezier_points[1].x0, bezier_points[1].y0);
						
		p.close ();
		p.create_list ();
		p.recalculate_linear_handles ();		
		
		npl.add (p);
		
		foreach (Attribute attr in tag.get_attributes ()) {
			if (attr.get_name () == "transform") {
				transform_paths (attr.get_content (), npl);
			}
		}
		
		style.apply (npl);
		pl.paths.append (npl);
	}
		
	private void parse_rect (Tag tag, Layer pl) {
		Path p;
		double x, y, x2, y2;
		BezierPoints[] bezier_points;
		Glyph g;
		PathList npl = new PathList ();
		SvgStyle style = new SvgStyle ();
		bool hidden = false;
		EditPoint ep;
		
		x = 0;
		y = 0;
		x2 = 0;
		y2 = 0;
			
		foreach (Attribute attr in tag.get_attributes ()) {			
			if (attr.get_name () == "x") {
				x = parse_double (attr.get_content ());
			}
			
			if (attr.get_name () == "y") {
				y = -parse_double (attr.get_content ());
			}

			if (attr.get_name () == "width") {
				x2 = parse_double (attr.get_content ());
			}
			
			if (attr.get_name () == "height") {
				y2 = -parse_double (attr.get_content ());
			}
	
			if (attr.get_name () == "display" && attr.get_content () == "none") {
				hidden = true;
			}
		}
		
		style = SvgStyle.parse (tag.get_attributes ());
		
		if (hidden) {
			return;
		}
		
		x2 += x;
		y2 += y;

		bezier_points = new BezierPoints[4];
		bezier_points[0] = new BezierPoints ();
		bezier_points[0].type == 'L';
		bezier_points[0].x0 = x;
		bezier_points[0].y0 = y;

		bezier_points[1] = new BezierPoints ();
		bezier_points[1].type == 'L';
		bezier_points[1].x0 = x2;
		bezier_points[1].y0 = y;

		bezier_points[2] = new BezierPoints ();
		bezier_points[2].type == 'L';
		bezier_points[2].x0 = x2;
		bezier_points[2].y0 = y2;

		bezier_points[3] = new BezierPoints ();
		bezier_points[3].type == 'L';
		bezier_points[3].x0 = x;
		bezier_points[3].y0 = y2;
		
		g = MainWindow.get_current_glyph ();
		move_and_resize (bezier_points, 4, false, 1, g);
					
		p = new Path ();	
		
		ep = p.add (bezier_points[0].x0, bezier_points[0].y0);
		ep.set_point_type (PointType.CUBIC);
		
		ep = p.add (bezier_points[1].x0, bezier_points[1].y0);
		ep.set_point_type (PointType.CUBIC);
		
		ep = p.add (bezier_points[2].x0, bezier_points[2].y0);
		ep.set_point_type (PointType.CUBIC);
		
		ep = p.add (bezier_points[3].x0, bezier_points[3].y0);
		ep.set_point_type (PointType.CUBIC);
						
		p.close ();
		p.create_list ();
		p.recalculate_linear_handles ();		
		
		npl.add (p);
		
		// FIXME: right layer for other transforms
		foreach (Attribute attr in tag.get_attributes ()) {
			if (attr.get_name () == "transform") {
				transform_paths (attr.get_content (), npl);
			}
		}
		
		style.apply (npl);
		pl.paths.append (npl);
	}
	
	private void parse_polygon (Tag tag, Layer pl) {
		PathList path_list = get_polyline (tag);
		
		foreach (Path p in path_list.paths) {
			p.close ();
		}
		
		pl.paths.append (path_list);
	}

	
	private void parse_polyline (Tag tag, Layer pl) {	
		pl.paths.append (get_polyline (tag));
	}
	
	private PathList get_polyline (Tag tag) {
		Path p = new Path ();
		bool hidden = false;
		PathList path_list = new PathList ();
		SvgStyle style = new SvgStyle ();
				
		foreach (Attribute attr in tag.get_attributes ()) {
			if (attr.get_name () == "points") {
				p = parse_poly_data (attr.get_content ());
			}
	
			if (attr.get_name () == "display" && attr.get_content () == "none") {
				hidden = true;
			}
		}

		style = SvgStyle.parse (tag.get_attributes ());
		
		if (hidden) {
			return path_list;
		}
		
		path_list.add (p);
		style.apply (path_list);
		
		foreach (Attribute attr in tag.get_attributes ()) {
			if (attr.get_name () == "transform") {
				transform_paths (attr.get_content (), path_list);
			}
		}
		
		return path_list;
	}
	
	private void parse_path (Tag tag, Layer pl) {
		Glyph glyph = MainWindow.get_current_glyph ();
		PathList path_list = new PathList ();
		SvgStyle style = new SvgStyle ();
		bool hidden = false;

		foreach (Attribute attr in tag.get_attributes ()) {
			if (attr.get_name () == "d") {
				path_list = parse_svg_data (attr.get_content (), glyph);
			}
	
			if (attr.get_name () == "display" && attr.get_content () == "none") {
				hidden = true;
			}
			
			if (attr.get_name () == "visibility"
				&& (attr.get_content () == "hidden" 
					|| attr.get_content () == "collapse")) {
				hidden = true;
			}
		}
		
		style = SvgStyle.parse (tag.get_attributes ());
		
		if (hidden) {
			return;
		}
	
		pl.paths.append (path_list);
		style.apply (path_list);

		// assume the even odd rule is applied and convert the path
		// to a path using the non-zero rule
		int inside_count;
		bool inside;
		foreach (Path p1 in pl.paths.paths) {
			inside_count = 0;
			
			foreach (Path p2 in pl.paths.paths) {
				if (p1 != p2) {
					inside = true;
					
					foreach (EditPoint ep in p1.points) {
						if (!is_inside (ep, p2)) {
							inside = false;
						}
					}

					if (inside) {
						inside_count++; 
					}
				}
			}

			if (inside_count % 2 == 0) {
				p1.force_direction (Direction.CLOCKWISE);
			} else {
				p1.force_direction (Direction.COUNTER_CLOCKWISE);
			}
		}
		
		foreach (Attribute attr in tag.get_attributes ()) {
			if (attr.get_name () == "transform") {
				transform_paths (attr.get_content (), path_list);
			}
		}
	}

	public static void create_lines_for_segment (Path path, EditPoint start, EditPoint end, double tolerance) {
		double x1, x2, x3;
		double y1, y2, y3;
		double step_start, step, step_end;

		path.add (start.x, start.y);

		step_start = 0;
		step = 0.5;
		step_end = 1;
					
		while (true) {
			Path.get_point_for_step (start, end, step_start, out x1, out y1);
			Path.get_point_for_step (start, end, step, out x2, out y2);
			Path.get_point_for_step (start, end, step_end, out x3, out y3);
		
			if (!StrokeTool.is_flat (x1, y1, x2, y2, x3, y3, tolerance)
				&& step_end - step / 2.0 > step_start 
				&& step_end - step / 2.0 > 0.1
				&& step > 0.05
				&& Path.distance_to_point (start, end) > 1) {
				
				step /= 2.0;
	
				if (step < 0.05) {
					step = 0.05;
				} else {
					step_end = step_start + 2 * step;
				}
			} else {
				path.add (x3, y3);
				
				if (step_end + step < 1) {
					step_start = step_end;
					step_end += step;
				} else {
					break;
				}
			}
		}
	}

	public static Path get_lines (Path p) {
		EditPoint start;
		Path path = new Path ();
		
		if (p.points.size == 0) {
			return path;
		}
		
		// create a set of straight lines
		start = p.points.get (p.points.size - 1);
		
		foreach (EditPoint end in p.points) {
			create_lines_for_segment (path, start, end, 1);
			start = end;
		}
						
		return path;
	}

	/** Check if a point is inside using the even odd fill rule.
	 * The path should only have straight lines.
	 */
	public static bool is_inside (EditPoint point, Path path) {
		EditPoint prev;
		bool inside = false;
		
		if (path.points.size <= 1) {
			return false;
		}

		if (!(path.xmin <= point.x <= path.xmax)) {
			return false;
		}
		
		if (!(path.ymin <= point.y <= path.ymax)) {
			return false;
		}
				
		prev = path.points.get (path.points.size - 1);
		
		foreach (EditPoint p in path.points) {
			if  ((p.y > point.y) != (prev.y > point.y) 
				&& point.x < (prev.x - p.x) * (point.y - p.y) / (prev.y - p.y) + p.x) {
				inside = !inside;
			}
			
			prev = p;
		}
		
		return inside;
	}

	/** Add space as separator to svg data. 
	 * @param d svg data
	 */
	static string add_separators (string d) {
		string data = d;
		
		data = data.replace (",", " ");
		data = data.replace ("a", " a ");
		data = data.replace ("A", " A ");
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
	
	public void add_path_to_glyph (string d, Glyph g, bool svg_glyph = false, double units = 1) {
		PathList p = parse_svg_data (d, g, svg_glyph, units);
		foreach (Path path in p.paths) {
			g.add_path (path);
		}
	}
	
	/** 
	 * @param d svg data
	 * @param glyph use lines from this glyph but don't add the generated paths
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
		double arc_rx, arc_ry;
		double arc_rotation;
		int large_arc;
		int arc_sweep;
		double arc_dest_x, arc_dest_y;

		font = BirdFont.get_current_font ();
		
		data = add_separators (d);
		c = data.split (" ");
		bezier_points = new BezierPoints[8 * c.length + 1]; // the arc instruction can use up to eight points
		
		for (int i = 0; i < 2 * c.length + 1; i++) {
			bezier_points[i] = new BezierPoints ();
		}
		
		int bi = 0;
		
		// parse path
		int i = -1;
		while (++i < c.length && bi < bezier_points.length) {	
			if (c[i] == "m") {
				while (i + 2 < c.length && is_point (c[i + 1])) {
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
				while (i + 2 < c.length && is_point (c[i + 1])) {
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
				while (i + 1 < c.length && is_point (c[i + 1])) {
					bezier_points[bi].type = 'L';
					bezier_points[bi].svg_type = 'h';
					
					px += parse_double (c[++i]);

					bezier_points[bi].x0 = px;
					bezier_points[bi].y0 = py;
					bi++;
				}
			} else if (i + 1 < c.length && c[i] == "H") {
				while (is_point (c[i + 1])) {
					bezier_points[bi].type = 'L';
					bezier_points[bi].svg_type = 'H';
					
					px = parse_double (c[++i]);

					bezier_points[bi].x0 = px;
					bezier_points[bi].y0 = py;
					bi++;
				}
			} else if (c[i] == "v") {
				while (i + 1 < c.length && is_point (c[i + 1])) {
					bezier_points[bi].type = 'L';
					bezier_points[bi].svg_type = 'v';
										
					if (svg_glyph) {
						py = py + parse_double (c[++i]);
					} else {
						py = py - parse_double (c[++i]);
					}
					
					bezier_points[bi].x0 = px;
					bezier_points[bi].y0 = py;
					bi++;
				}				
			} else if (i + 1 < c.length && c[i] == "V") {
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
				while (i + 2 < c.length && is_point (c[i + 1])) {
					bezier_points[bi].type = 'L';
					bezier_points[bi].svg_type = 'l';
										
					cx = px + parse_double (c[++i]);
					
					if (svg_glyph) {
						cy = py + parse_double (c[++i]);
					} else {
						cy = py - parse_double (c[++i]);
					}
					
					px = cx;
					py = cy;

					bezier_points[bi].x0 = cx;
					bezier_points[bi].y0 = cy;
					bi++;
				}
			} else if (c[i] == "L") {
				while (i + 2 < c.length && is_point (c[i + 1])) {
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
				while (i + 6 < c.length && is_point (c[i + 1])) {
					bezier_points[bi].type = 'C';
					bezier_points[bi].svg_type = 'C';
										
					cx = px + parse_double (c[++i]);
					
					if (svg_glyph) {
						cy = py + parse_double (c[++i]);
					} else {
						cy = py - parse_double (c[++i]);
					}
					
					bezier_points[bi].x0 = cx;
					bezier_points[bi].y0 = cy;
										
					cx = px + parse_double (c[++i]);
					
					if (svg_glyph) {
						cy = py + parse_double (c[++i]);
					} else {
						cy = py - parse_double (c[++i]);
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
				while (i + 6 < c.length && is_point (c[i + 1])) {
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
				while (i + 4 < c.length && is_point (c[i + 1])) {
					bezier_points[bi].type = 'Q';
					bezier_points[bi].svg_type = 'q';
										
					cx = px + parse_double (c[++i]);
					
					if (svg_glyph) {
						cy = py + parse_double (c[++i]);
					} else {
						cy = py - parse_double (c[++i]);
					}
					
					bezier_points[bi].x0 = cx;
					bezier_points[bi].y0 = cy;
										
					px2 = cx;
					py2 = cy;
										
					cx = px + parse_double (c[++i]);
					
					if (svg_glyph) {
						cy = py + parse_double (c[++i]);
					} else {
						cy = py - parse_double (c[++i]);
					}
					
					bezier_points[bi].x1 = cx;
					bezier_points[bi].y1 = cy;
										
					px = cx;
					py = cy;
					
					bi++;
				}
			} else if (c[i] == "Q") {

				while (i + 4 < c.length && is_point (c[i + 1])) {
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
				while (i + 2 < c.length && is_point (c[i + 1])) {
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
						cy = py - parse_double (c[++i]);
					}
					
					px = cx;
					py = cy;
					
					bezier_points[bi].x1 = px;
					bezier_points[bi].y1 = py;
										
					bi++;
				}
			} else if (c[i] == "T") {
				while (i + 2 < c.length && is_point (c[i + 1])) {
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
				while (i + 4 < c.length && is_point (c[i + 1])) {
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
						cy = py - parse_double (c[++i]);
					}
					
					px2 = cx;
					py2 = cy;
					
					bezier_points[bi].x1 = px2;
					bezier_points[bi].y1 = py2;
					
					cx = px + parse_double (c[++i]);
					
					if (svg_glyph) {
						cy = py + parse_double (c[++i]);
					} else {
						cy = py - parse_double (c[++i]);
					}
					
					bezier_points[bi].x2 = cx;
					bezier_points[bi].y2 = cy;
												
					px = cx;
					py = cy;
					
					bi++;
				}
			} else if (c[i] == "S") {
				while (i + 4 < c.length && is_point (c[i + 1])) {
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
			} else if (c[i] == "a") {
				while (i + 7 < c.length && is_point (c[i + 1])) {					
					arc_rx = parse_double (c[++i]);
					arc_ry = parse_double (c[++i]);
					
					arc_rotation = parse_double (c[++i]);
					large_arc = parse_int (c[++i]);
					arc_sweep = parse_int (c[++i]);
							
					cx = px + parse_double (c[++i]);
					
					if (svg_glyph) {
						cy = py + parse_double (c[++i]);
					} else {
						cy = py - parse_double (c[++i]);
					}
					
					arc_dest_x = cx;
					arc_dest_y = cy;
					
					add_arc_points (bezier_points, ref bi, px, py, arc_rx, arc_ry, arc_rotation, large_arc == 1, arc_sweep == 1, cx, cy);
					
					px = cx;
					py = cy;
					
					
				}
			} else if (i + 7 < c.length && c[i] == "A") {
				while (is_point (c[i + 1])) {					
					arc_rx = parse_double (c[++i]);
					arc_ry = parse_double (c[++i]);
					
					arc_rotation = parse_double (c[++i]);
					large_arc = parse_int (c[++i]);
					arc_sweep = parse_int (c[++i]);
							
					cx = parse_double (c[++i]);
					
					if (svg_glyph) {
						cy = parse_double (c[++i]);
					} else {
						cy = -parse_double (c[++i]);
					}
					
					arc_dest_x = cx;
					arc_dest_y = cy;
					
					add_arc_points (bezier_points, ref bi, px, py, arc_rx, arc_ry, arc_rotation, large_arc == 1, arc_sweep == 1, cx, cy);

					px = cx;
					py = cy;
					
					
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
		
		if (bi == 0) {
			warning ("No points in path.");
			return path_list;	
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
				b[i].x0 += glyph.left_limit;
				b[i].y0 += font.base_line;
				b[i].x1 += glyph.left_limit;
				b[i].y1 += font.base_line;
				b[i].x2 += glyph.left_limit;
				b[i].y2 += font.base_line;
			} else {
				b[i].x0 += glyph.left_limit;
				b[i].y0 += font.top_limit;
				b[i].x1 += glyph.left_limit;
				b[i].y1 += font.top_limit;
				b[i].x2 += glyph.left_limit;
				b[i].y2 += font.top_limit;
			}
		}
	}
	
	void find_last_handle (int start_index, BezierPoints[] b, int num_b, out double left_x, out double left_y, out PointType last_type) {
		BezierPoints last = new BezierPoints ();
		bool found = false;
		
		left_x = 0;
		left_y = 0;
		last_type = PointType.NONE;
		
		return_if_fail (b.length != 0);
		return_if_fail (b[0].type != 'z');
		return_if_fail (num_b < b.length);

		if (num_b == 2) {
			left_x = b[0].x0 + (b[1].x0 - b[0].x0) / 3.0;
			left_y = b[0].y0 + (b[1].y0 - b[0].y0) / 3.0;
			last_type = PointType.LINE_CUBIC;
			return;
		}
		
		for (int i = start_index; i < num_b; i++) {
			switch (b[i].type) {
				case 'Q':
					break;
				case 'C':
					break;
				case 'z':
					found = true;
					break;
				default:
					break;
			}
			
			if (found || i + 1 == num_b) {
				
				return_if_fail (i >= 1);
				
				if (b[i - 1].type == 'Q') {
					return_if_fail (i >= 1);
					left_x = b[i - 1].x0;
					left_y = b[i - 1].y0;
					last_type = PointType.QUADRATIC;
				} else if (b[i - 1].type == 'C') {
					return_if_fail (i >= 1);
					left_x = b[i - 1].x1;
					left_y = b[i - 1].y1;
					last_type = PointType.CUBIC;
				} else if (b[i - 1].type == 'S') {
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
			}
			
			last = b[i];
		}
		
		warning ("Last point not found.");
	}

	PathList create_paths_inkscape (BezierPoints[] b, int num_b) {
		double last_x;
		double last_y; 
		PointType last_type;
		Path path;
		PathList path_list = new PathList ();
		EditPoint ep = new EditPoint ();
		Gee.ArrayList<EditPoint> smooth_points = new Gee.ArrayList<EditPoint> ();
				
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
			
			if (i >= num_b) {
				break;
			}
			
			if (b[i].type == 'M') {
				ep = path.add (b[i].x0, b[i].y0);
				ep.set_point_type (PointType.CUBIC);

				ep.get_left_handle ().set_point_type (PointType.LINE_CUBIC);
				
				if (i == 0 || (b[i - 1].type == 'z')) {
					ep.get_left_handle ().set_point_type (last_type);
					ep.get_left_handle ().move_to_coordinate (last_x, last_y);
				} else {
					if (b[i - 1].type == 'C' || b[i - 1].type == 'S') {
						ep.get_left_handle ().set_point_type (PointType.CUBIC);
						ep.get_left_handle ().move_to_coordinate (b[i + 1].x1, b[i + 1].y1);
					} 
					
					if (b[i + 1].type == 'C' || b[i - 1].type == 'S') {
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
				return_val_if_fail (i != 0, path_list);

				ep.set_point_type (PointType.QUADRATIC);
				
				ep.get_right_handle ().set_point_type (PointType.QUADRATIC);
				ep.get_right_handle ().move_to_coordinate (b[i].x0, b[i].y0);
				
				if (b[i + 1].type != 'z') {
					ep = path.add (b[i].x1, b[i].y1);

					ep.get_left_handle ().set_point_type (PointType.QUADRATIC);
					ep.get_left_handle ().move_to_coordinate (b[i].x0, b[i].y0);
				}
			}
	
			if (b[i].type == 'C' || b[i].type == 'S') {
				return_val_if_fail (i != 0, path_list);

				ep.set_point_type (PointType.CUBIC);
				
				ep.get_right_handle ().set_point_type (PointType.CUBIC);
				ep.get_right_handle ().move_to_coordinate (b[i].x0, b[i].y0);
				
				if (b[i].type == 'S') {
					smooth_points.add (ep);
				}
				
				if (b[i + 1].type != 'z') {
					ep = path.add (b[i].x2, b[i].y2);

					ep.get_left_handle ().set_point_type (PointType.CUBIC);
					ep.get_left_handle ().move_to_coordinate (b[i].x1, b[i].y1);
				}
			}
		}

		foreach (EditPoint e in smooth_points) {
			e.set_point_type (PointType.LINE_DOUBLE_CURVE);
			e.get_right_handle ().set_point_type (PointType.LINE_DOUBLE_CURVE);
			e.get_left_handle ().set_point_type (PointType.LINE_DOUBLE_CURVE);
		}

		foreach (EditPoint e in smooth_points) {
			path.recalculate_linear_handles_for_point (e);
		}
		
		for (int i = 0; i < 3; i++) {
			foreach (EditPoint e in smooth_points) {
				e.set_tie_handle (true);
				e.process_tied_handle ();
			}
		}
		
		if (path.points.size > 0) {
			path_list.add (path);
		}

		foreach (Path p in path_list.paths) {
			p.remove_points_on_points ();
		}
				
		return path_list;
	}

	PathList create_paths_illustrator (BezierPoints[] b, int num_b) {
		Path path;
		PathList path_list = new PathList ();
		EditPoint ep;
		bool first_point = true;
		double first_left_x, first_left_y;
		Gee.ArrayList<EditPoint> smooth_points = new Gee.ArrayList<EditPoint> ();
		
		if (num_b > b.length) {
			warning ("num_b > b.length: $num_b > $(b.length)");
			return path_list;
		}
		
		path = new Path ();
				
		if (num_b <= 1) {
			warning ("No SVG data");
			return path_list;
		}
		
		first_left_x = 0;
		first_left_y = 0;

		ep = new EditPoint ();
		
		for (int i = 0; i < num_b; i++) {
			if (b[i].type == '\0') {
				warning ("Parser error.");
				return path_list;
			} else if (b[i].type == 'z') {
				path.close ();
				path.create_list ();
				
				int first_index = 1;

				for (int j = i - 1; j >= 1; j--) {
					if (b[j].type == 'z') {
						first_index = j + 1; // from z to M 
					}
				}
				
				if (b[first_index].type == 'C' || b[first_index].type == 'S') {
					return_val_if_fail (path.points.size != 0, path_list);
					ep = path.points.get (path.points.size - 1);
					
					if (b[i - 1].type != 'L' ) {
						ep.get_right_handle ().set_point_type (PointType.CUBIC);
						ep.get_right_handle ().move_to_coordinate (b[first_index].x0, b[first_index].y0);
					}
				} else if (b[first_index].type == 'L') {
					return_val_if_fail (path.points.size != 0, path_list);
					ep = path.points.get (path.points.size - 1);
					ep.get_right_handle ().set_point_type (PointType.LINE_CUBIC);
					path.recalculate_linear_handles_for_point (ep);
				} else {
					warning ("Unexpected type: %s", (!) b[first_index].type.to_string ());
				}
				
				path.recalculate_linear_handles ();
				path_list.add (path);
				
				path = new Path ();
				first_point = true;				
			} else if (b[i].type == 'L' || b[i].type == 'M') {

				if (first_point) {
					first_left_x = b[i].x0;
					first_left_y = b[i].y0;
				}
				
				ep = path.add (b[i].x0, b[i].y0);
				ep.set_point_type (PointType.CUBIC); // TODO: quadratic
				ep.get_right_handle ().set_point_type (PointType.LINE_CUBIC);

				ep.get_left_handle ().set_point_type (PointType.CUBIC);
				ep.get_left_handle ().move_to_coordinate (b[i].x0 - 0.00001, b[i].y0 - 0.00001);
				
				if (b[i + 1].type == 'C' || b[i + 1].type == 'S') {
					return_val_if_fail (i + 1 < num_b, path_list);
					ep.get_right_handle ().set_point_type (PointType.CUBIC);
					ep.get_right_handle ().move_to_coordinate (b[i + 1].x0, b[i + 1].y0);
				}
				
				first_point = false;
			} else if (b[i].type == 'Q') {
				warning ("Illustrator does not support quadratic control points.");
				warning (@"$(b[i])\n");
			} else if (b[i].type == 'C' || b[i].type == 'S') {
				
				if (first_point) {
					first_left_x = b[i].x0;
					first_left_y = b[i].y0;
				}

				ep = path.add (b[i].x2, b[i].y2);
				ep.set_point_type (PointType.CUBIC);

				ep.get_right_handle ().set_point_type (PointType.CUBIC);
				ep.get_left_handle ().set_point_type (PointType.CUBIC);

				ep.get_left_handle ().move_to_coordinate (b[i].x1, b[i].y1);

				if (b[i].type == 'S') {
					smooth_points.add (ep);
				}		

				if (b[i + 1].type != 'z' && i != num_b - 1) {
					ep.get_right_handle ().move_to_coordinate (b[i + 1].x0, b[i + 1].y0);
				} else {
					ep.get_right_handle ().move_to_coordinate (first_left_x, first_left_y);
				}
				
				first_point = false;
			} else {
				warning ("Unknown control point type.");
				warning (@"$(b[i])\n");
			}
		}
		
		foreach (EditPoint e in smooth_points) {
			e.set_point_type (PointType.LINE_CUBIC);
			e.get_right_handle ().set_point_type (PointType.LINE_CUBIC);
			e.get_left_handle ().set_point_type (PointType.LINE_CUBIC);
		}

		foreach (EditPoint e in smooth_points) {
			path.recalculate_linear_handles_for_point (e);
		}
		
		for (int i = 0; i < 3; i++) {
			foreach (EditPoint e in smooth_points) {
				e.set_tie_handle (true);
				e.get_right_handle ().set_point_type (PointType.CUBIC);
				e.get_left_handle ().set_point_type (PointType.CUBIC);
				e.process_tied_handle ();
			}
		}
				
		if (path.points.size > 0) {
			path_list.add (path);
		}
		
		foreach (Path p in path_list.paths) {
			p.remove_points_on_points ();
		}
		
		return path_list;
	}
	
	// TODO: implement a default svg parser

	static int parse_int (string? s) {
		if (is_null (s)) {
			warning ("null instead of string");
			return 0;
		}
		
		if (!is_point ((!) s)) {
			warning (@"Expecting an integer got: $((!) s)");
			return 0;
		}
		
		return int.parse ((!) s);
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
		
		string d = (!) s;
		d = d.replace ("px", "");
		
		return double.parse (d);
	}
	
	static bool is_point (string? s) {
		if (s == null) {
			warning ("s is null");
			return false;
		}
		
		return double.try_parse ((!) s);
	}
	
	Path parse_poly_data (string polygon_points) {
		string data = add_separators (polygon_points);
		string[] c = data.split (" ");
		Path path;
		BezierPoints[] bezier_points = new BezierPoints[c.length + 1];
		int bi;
		Glyph g;
		EditPoint ep;
		
		bi = 0;
		for (int i = 0; i < c.length - 1; i += 2) {	
			if (i + 1 >= c.length) {
				warning ("No y value.");
				break;
			}

			if (bi >= bezier_points.length) {
				warning ("End of bezier_points");
				break;
			}

			bezier_points[bi] = new BezierPoints ();
			bezier_points[bi].type == 'L';
			bezier_points[bi].x0 = parse_double (c[i]);
			bezier_points[bi].y0 = -parse_double (c[i + 1]);
			bi++;
		}
			
		g = MainWindow.get_current_glyph ();
		move_and_resize (bezier_points, bi, false, 1, g);
		
		path = new Path ();
		for (int i = 0; i < bi; i++) {	
			ep = path.add (bezier_points[i].x0, bezier_points[i].y0);
			ep.set_point_type (PointType.LINE_CUBIC);
		}
		
		path.create_list ();
		path.recalculate_linear_handles ();
		
		return path;
	}
}

}
