/*
	Copyright (C) 2016 Johan Mattsson

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
using Cairo;
using Math;

namespace SvgBird {

public class SvgFile : GLib.Object {

	SvgDrawing drawing;

	public SvgFile () {		
	}
	
	public SvgDrawing parse_svg_data (string xml_data) {
		XmlTree tree = new XmlTree (xml_data);
		return parse_svg_file (tree.get_root ());
	}
	
	public SvgDrawing parse_svg_file (XmlElement svg_tag) {
		drawing = new SvgDrawing ();

		SvgStyle style = new SvgStyle ();
		SvgStyle.parse (drawing.defs, style, svg_tag);

		foreach (Attribute attr in svg_tag.get_attributes ()) {	
			if (attr.get_name () == "width") {
				drawing.width = parse_number (attr.get_content ());
			}

			if (attr.get_name () == "height") {
				drawing.height = parse_number (attr.get_content ());
			}
		}
				
		foreach (XmlElement t in svg_tag) {
			string name = t.get_name ();

			if (name == "g") {
				parse_layer (drawing.root_layer, style, t);
			}

			if (name == "defs") {
				parse_defs (drawing, t);
			}
			
			if (name == "a") {
				parse_link (drawing.root_layer, style, svg_tag);
			}
			
			parse_object (drawing.root_layer, style, t);
		}

		set_object_properties (drawing, new SvgStyle (), svg_tag);
		
		return drawing;
	}

	private void parse_layer (Layer layer, SvgStyle parent_style, XmlElement tag) {		
		foreach (XmlElement t in tag) {
			string name = t.get_name ();

			if (name == "g") {
				Layer sublayer = new Layer ();
				parse_layer (layer, parent_style, t);
				layer.subgroups.add (sublayer);
			}

			if (name == "a") {
				parse_link (layer, parent_style, t);
			}
			
			parse_object (layer, parent_style, t);
		}

		set_object_properties (layer, parent_style, tag);
	}

	void parse_clip_path (SvgDrawing drawing, XmlElement tag) {
		ClipPath clip_path;
		
		Layer layer = new Layer ();
		parse_layer (layer, new SvgStyle (), tag);
		clip_path = new ClipPath (layer);
		
		drawing.defs.clip_paths.add (clip_path);
	}

	void parse_defs (SvgDrawing drawing, XmlElement tag) {
		foreach (XmlElement t in tag) {
			// FIXME: radial
			string name = t.get_name ();
			
			if (name == "linearGradient") {
				parse_linear_gradient (drawing, t);
			} else if (name == "clipPath") {
				parse_clip_path (drawing, t);
			}
		}
		
		foreach (Gradient gradient in drawing.defs.gradients) {
			if (gradient.href != null) {
				Gradient? referenced;
				referenced = drawing.defs.get_gradient_for_id ((!) gradient.href);
				
				if (referenced != null) {
					gradient.copy_stops ((!) referenced);
				}
				
				gradient.href = null;
			}
		}
		
		foreach (XmlElement t in tag) {
			// FIXME: radial
			string name = t.get_name ();
			
			if (name == "style") {
				drawing.defs.style_sheet = StyleSheet.parse (drawing.defs, t);
			}
		}
		
	}

	void parse_linear_gradient (SvgDrawing drawing, XmlElement tag) {
		Gradient gradient = new Gradient ();
		
		drawing.defs.add (gradient);
		
		foreach (Attribute attr in tag.get_attributes ()) {
			string name = attr.get_name ();
			
			// FIXME: gradientUnits
			
			if (name == "gradientTransform") {
				gradient.transforms = parse_transform (attr.get_content ());
			}

			if (name == "href") {
				gradient.href = attr.get_content ();
			}

			if (name == "x1") {
				gradient.x1 = parse_number (attr.get_content ());
			}

			if (name == "y1") {	
				gradient.y1 = parse_number (attr.get_content ());
			}
			
			if (name == "x2") {
				gradient.x2 = parse_number (attr.get_content ());
			}

			if (name == "y2") {
				gradient.y2 = parse_number (attr.get_content ());
			}

			if (name == "id") {
				gradient.id = attr.get_content ();
			}
		}
		
		foreach (XmlElement t in tag) {
			// FIXME: radial
			string name = t.get_name ();
			
			if (name == "stop") {
				parse_stop (gradient, t);
			}
		}
	}

	void parse_stop (Gradient gradient, XmlElement tag) {
		SvgStyle parent_style = new SvgStyle (); // not inherited
		SvgStyle style = SvgStyle.parse (drawing.defs, parent_style, tag);
		Stop stop = new Stop ();
		
		gradient.stops.add (stop);
		
		foreach (Attribute attr in tag.get_attributes ()) {
			string name = attr.get_name ();
			
			if (name == "offset") {
				string stop_offset = attr.get_content ();
				
				if (stop_offset.index_of ("%") > -1) {
					stop_offset = stop_offset.replace ("%", "");
					stop.offset = parse_number (stop_offset) / 100.0;
				} else {
					stop.offset = parse_number (stop_offset);
				}
			}
		}
		
		string? stop_color = style.style.get ("stop-color");
		string? stop_opacity = style.style.get ("stop-opacity");
		Color? color = new Color (0, 0, 0, 1);
		
		if (stop_color != null) {
			color = Color.parse (stop_color);
			
			if (color != null) {
				stop.color = (!) color;
			}
		}

		if (stop_opacity != null && color != null) {
			((!) color).a = parse_number (stop_opacity);
		}
	}
	
	// links are ignored, add the content to the layer
	void parse_link (Layer layer, SvgStyle parent_style, XmlElement tag) {
		parse_layer (layer, parent_style, tag);
	}
	
	void parse_object (Layer layer, SvgStyle parent_style, XmlElement tag) {
		string name = tag.get_name ();
		
		if (name == "path") {
			parse_path (layer, parent_style, tag);
		}
							
		if (name == "polygon") {
			parse_polygon (layer, parent_style, tag);
		}

		if (name == "polyline") {
			parse_polyline (layer, parent_style, tag);
		}
		
		if (name == "rect") {
			parse_rect (layer, parent_style, tag);
		}

		if (name == "circle") {
			parse_circle (layer, parent_style, tag);
		}

		if (name == "ellipse") {
			parse_ellipse (layer, parent_style, tag);
		}
		
		if (name == "line") {
			parse_line (layer, parent_style, tag);
		}
	}

	private void parse_polygon (Layer layer, SvgStyle parent_style, XmlElement tag) {
		Polygon polygon = new Polygon ();

		foreach (Attribute attr in tag.get_attributes ()) {
			if (attr.get_name () == "points") {
				string data = add_separators (attr.get_content ());
				string[] point_data = data.split (" ");
				
				foreach (string number in point_data) {
					polygon.points.add (parse_number (number));
				}
			}
		}
		
		set_object_properties (polygon, parent_style, tag);
		layer.add_object (polygon);
	}
	
	void set_object_properties (Object object, SvgStyle parent_style, XmlElement tag) {
		Attributes attributes = tag.get_attributes ();
		
		foreach (Attribute attribute in attributes) {
			string name = attribute.get_name ();
			
			if (name == "id") {
				object.id = attribute.get_content ();
			} else if (name == "class") {
				object.css_class = attribute.get_content ();
			}
		}
		
		object.clip_path = get_clip_path (attributes);
		object.transforms = get_transform (attributes);
		object.style = SvgStyle.parse (drawing.defs, parent_style, tag);
		object.visible = is_visible (tag);
	}
		
	ClipPath? get_clip_path (Attributes attributes) {
		foreach (Attribute attribute in attributes) {
			if (attribute.get_name () == "clip-path") {
				return drawing.defs.get_clip_path_for_url (attribute.get_content ());
			}
		}
		
		return null;
	}
	
	private void parse_polyline (Layer layer, SvgStyle parent_style, XmlElement tag) {
		Polyline polyline = new Polyline ();

		foreach (Attribute attr in tag.get_attributes ()) {
			if (attr.get_name () == "points") {
				string data = add_separators (attr.get_content ());
				string[] point_data = data.split (" ");
				
				foreach (string number in point_data) {
					polyline.points.add (parse_number (number));
				}
			}
		}
		
		set_object_properties (polyline, parent_style, tag);
		layer.add_object (polyline);
	}
	
	private void parse_rect (Layer layer, SvgStyle parent_style, XmlElement tag) {
		Rectangle rectangle = new Rectangle ();

		foreach (Attribute attr in tag.get_attributes ()) {
			string attribute = attr.get_name ();
			
			if (attribute == "x") {
				rectangle.x = parse_number (attr.get_content ());
			}

			if (attribute == "y") {
				rectangle.y = parse_number (attr.get_content ());
			}

			if (attribute == "width") {
				rectangle.width = parse_number (attr.get_content ());
			}

			if (attribute == "height") {
				rectangle.height = parse_number (attr.get_content ());
			}
			
			if (attribute == "rx") {
				rectangle.rx = parse_number (attr.get_content ());
			}

			if (attribute == "ry") {
				rectangle.ry = parse_number (attr.get_content ());
			}
		}
		
		set_object_properties (rectangle, parent_style, tag);
		layer.add_object (rectangle);
	}
	
	private void parse_circle (Layer layer, SvgStyle parent_style, XmlElement tag) {
		Circle circle = new Circle ();
		
		foreach (Attribute attr in tag.get_attributes ()) {
			string name = attr.get_name ();
			
			if (name == "cx") {
				circle.cx = parse_number (attr.get_content ());
			}

			if (name == "cy") {
				circle.cy = parse_number (attr.get_content ());
			}
			
			if (name == "r") {
				circle.r = parse_number (attr.get_content ());
			}
		}
		
		set_object_properties (circle, parent_style, tag);
		layer.add_object (circle);
	}
	
	private void parse_ellipse (Layer layer, SvgStyle parent_style, XmlElement tag) {
		Ellipse ellipse = new Ellipse ();
		
		foreach (Attribute attr in tag.get_attributes ()) {
			string name = attr.get_name ();
			
			if (name == "cx") {
				ellipse.cx = parse_number (attr.get_content ());
			}

			if (name == "cy") {
				ellipse.cy = parse_number (attr.get_content ());
			}
			
			if (name == "rx") {
				ellipse.rx = parse_number (attr.get_content ());
			}
			
			if (name == "ry") {
				ellipse.ry = parse_number (attr.get_content ());
			}
		}
		
		set_object_properties (ellipse, parent_style, tag);
		layer.add_object (ellipse);
	}
	
	private void parse_line (Layer layer, SvgStyle parent_style, XmlElement tag) {
		Line line = new Line ();
		
		foreach (Attribute attr in tag.get_attributes ()) {
			string name = attr.get_name ();
			
			if (name == "x1") {
				line.x1 = parse_number (attr.get_content ());
			}

			if (name == "y1") {
				line.y1 = parse_number (attr.get_content ());
			}
			
			if (name == "x2") {
				line.x2 = parse_number (attr.get_content ());
			}
			
			if (name == "y2") {
				line.y2 = parse_number (attr.get_content ());
			}
		}
		
		set_object_properties (line, parent_style, tag);
		layer.add_object (line);
	}
	
	// FIXME: reverse order?
	public SvgTransforms parse_transform (string transforms) {
		string[] functions;
		string transform = transforms;
		SvgTransforms transform_functions;
		
		transform_functions = new SvgTransforms ();
		
		transform = transform.replace ("\t", " ");
		transform = transform.replace ("\n", " ");
		transform = transform.replace ("\r", " ");
		
		// use only a single space as separator
		while (transform.index_of ("  ") > -1) {
			transform = transform.replace ("  ", " ");
		}
		
		if (unlikely (transform.index_of (")") == -1)) {
			warning ("No parenthesis in transform function.");
			return transform_functions;
		}
		
		 // add separator
		transform = transform.replace (") ", "|");
		transform = transform.replace (")", "|"); 
		functions = transform.split ("|");
		
		for (int i = 0; i < functions.length; i++) {
			if (functions[i].has_prefix ("translate")) {
				transform_functions.add (translate (functions[i]));
			}
			
			if (functions[i].has_prefix ("scale")) {
				transform_functions.add (scale (functions[i]));
			}

			if (functions[i].has_prefix ("matrix")) {
				transform_functions.add (matrix (functions[i]));
			}
			
			// TODO: rotate etc.
		}
		
		return transform_functions;
	}

	private SvgTransform matrix (string function) {
		string parameters = get_transform_parameters (function);
		string[] p = parameters.split (" ");
		SvgTransform transform = new SvgTransform ();
		transform.type = TransformType.MATRIX;
		
		if (unlikely (p.length != 6)) {
			warning ("Expecting six parameters for matrix transformation.");
			return transform;
		}
		
		for (int i = 0; i < 6; i++) {
			double argument = parse_double (p[i]);
			transform.arguments.add (argument);
		}
		
		return transform;
	}

    private static string remove_unit (string d) {
		string s = d.replace ("pt", "");
		s = s.replace ("pc", "");
		s = s.replace ("mm", "");
		s = s.replace ("cm", "");
		s = s.replace ("in", "");
		s = s.replace ("px", "");
		return s;
	}
    
	public static double parse_number (string? number_with_unit) {
		if (number_with_unit == null) {
			return 0;
		}
		
		string d = (!) number_with_unit;
		string s = remove_unit (d);
		double n = parse_double (s);
		
		if (d.has_suffix ("pt")) {
			n *= 1.25;
		} else if (d.has_suffix ("pc")) {
			n *= 15;
		} else if (d.has_suffix ("mm")) {
			n *= 3.543307;
		} else if (d.has_suffix ("cm")) {
			n *= 35.43307;
		} else if (d.has_suffix ("in")) {
			n *= 90;
		}
		
		return n;
	}
	
	private SvgTransform scale (string function) {
		string parameters = get_transform_parameters (function);
		string[] p = parameters.split (" ");
		SvgTransform transform = new SvgTransform ();
		transform.type = TransformType.SCALE;

		if (p.length > 0) {
			transform.arguments.add (parse_double (p[0]));
		}
		
		if (p.length > 1) {
			transform.arguments.add (parse_double (p[1]));
		}
		
		return transform;
	}
	
	private SvgTransform translate (string function) {
		string parameters = get_transform_parameters (function);
		string[] p = parameters.split (" ");
		SvgTransform transform = new SvgTransform ();
		transform.type = TransformType.TRANSLATE;
		
		if (p.length > 0) {
			transform.arguments.add (parse_double (p[0]));
		}
		
		if (p.length > 1) {
			transform.arguments.add (parse_double (p[1]));
		}
		
		return transform;
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
			param.replace ("  ", " ");
		}
			
		return param.strip();			
	}

	private bool is_visible (XmlElement tag) {
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
		
		return !hidden;
	}

	private SvgTransforms get_transform (Attributes attributes) {
		foreach (Attribute attr in attributes) {
			if (attr.get_name () == "transform") {
				return parse_transform (attr.get_content ());
			}
		}
		
		return new SvgTransforms ();
	}
	
	private void parse_path (Layer layer, SvgStyle parent_style, XmlElement tag) {
		SvgPath path = new SvgPath ();

		foreach (Attribute attr in tag.get_attributes ()) {
			if (attr.get_name () == "d") {
				path.points = parse_points (attr.get_content ());
			}
		}
		
		set_object_properties (path, parent_style, tag);
		layer.add_object (path);
	}

	public Gee.ArrayList<Points> parse_points (string data) {
		Gee.ArrayList<Points> path_data = new Gee.ArrayList<Points> ();
		Points points = new Points ();
		BezierPoints[] bezier_points;
		int points_size;
	
		get_bezier_points (data, out bezier_points, out points_size, true);

		// all instructions are padded

		for (int i = 0; i < points_size; i++) {
			// FIXME: add more types
			if (bezier_points[i].type == 'M') {
				if (i == 0) {
					points.x = bezier_points[i].x0;
					points.y = bezier_points[i].y0;
				} else {
					points.add_type (LINE);
					points.add (bezier_points[i].x0);
					points.add (bezier_points[i].y0);
					points.add (0);
					points.add (0);
					points.add (0);
					points.add (0);
					points.add (0);
				}
			} else if (bezier_points[i].type == 'C') {
				points.add_type (CUBIC);
				points.add (bezier_points[i].x0);
				points.add (bezier_points[i].y0);
				points.add (bezier_points[i].x1);
				points.add (bezier_points[i].y1);
				points.add (bezier_points[i].x2);
				points.add (bezier_points[i].y2);
				points.add (0);
			} else if (bezier_points[i].type == 'L') {
				points.add_type (LINE);
				points.add (bezier_points[i].x0);
				points.add (bezier_points[i].y0);
				points.add (0);
				points.add (0);
				points.add (0);
				points.add (0);
				points.add (0);
			} else if (bezier_points[i].type == 'A') {
				BezierPoints b = bezier_points[i];
				double angle_start;
				double angle_extent;
				double center_x;
				double center_y;
				double rotation = b.angle;
								
				get_arc_arguments (b.x0, b.y0, b.rx, b.ry,
					b.angle, b.large_arc, b.sweep, b.x1, b.y1,
					out angle_start, out angle_extent,
					out center_x, out center_y);
				
				points.add_type (ARC);
				points.add (center_x);
				points.add (center_y);
				points.add (b.rx);
				points.add (b.ry);
				points.add (angle_start);
				points.add (angle_extent); 
				points.add (rotation);
			} else if (bezier_points[i].type == 'z') {
				points.closed = true;
				path_data.add (points);
				points = new Points ();
			} else {
				string type = (!) bezier_points[i].type.to_string ();
				warning (@"SVG conversion not implemented for $type");
			}
		}

		if (points.size > 0) {
			path_data.add (points);
		}
		
		return path_data;
	}

	public static double parse_double (string? s) {
		if (unlikely (s == null)) {
			warning ("number is null");
			return 0;
		}
		
		if (unlikely (!double.try_parse ((!) s))) {
			warning (@"Expecting a double got: $((!) s)");
			return 0;
		}
		
		return double.parse ((!) s);
	}
	
	// FIXME: rename to instructions
	public static void get_bezier_points (string point_data, out BezierPoints[] bezier_points, out int points, bool svg_glyph) {
		double px = 0;
		double py = 0;
		double px2 = 0;
		double py2 = 0;
		double cx = 0;
		double cy = 0;
		string[] c;
		double arc_rx, arc_ry;
		double arc_rotation;
		int large_arc;
		int arc_sweep;
		double arc_dest_x, arc_dest_y;
		
		int bi = 0;

		string data = add_separators (point_data);
		c = data.split (" ");

		// the arc instruction can use up to eight points
		int bezier_points_length = 8 * c.length + 1;
		bezier_points = new BezierPoints[bezier_points_length]; 
		
		for (int i = 0; i < bezier_points_length; i++) {
			bezier_points[i] = new BezierPoints ();
		}

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
					cy = 2 * py - py2;
					
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
					
					arc_rotation = PI * (parse_double (c[++i]) / 180.0);
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
					
					bezier_points[bi].type = 'A';
					bezier_points[bi].svg_type = 'a';
					bezier_points[bi].x0 = px;
					bezier_points[bi].y0 = py;
					bezier_points[bi].x1 = cx;
					bezier_points[bi].y1 = cy;
					bezier_points[bi].rx = arc_rx;
					bezier_points[bi].ry = arc_ry;
					bezier_points[bi].angle = arc_rotation;
					bezier_points[bi].large_arc = large_arc == 1;
					bezier_points[bi].sweep = arc_sweep == 1;
					bi++;
					
					px = cx;
					py = cy;
				}
			} else if (i + 7 < c.length && c[i] == "A") {
				while (is_point (c[i + 1])) {					
					arc_rx = parse_double (c[++i]);
					arc_ry = parse_double (c[++i]);
					
					arc_rotation = PI * (parse_double (c[++i]) / 180.0);
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
					
					bezier_points[bi].type = 'A';
					bezier_points[bi].svg_type = 'A';
					bezier_points[bi].x0 = px;
					bezier_points[bi].y0 = py;
					bezier_points[bi].x1 = cx;
					bezier_points[bi].y1 = cy;
					bezier_points[bi].rx = arc_rx;
					bezier_points[bi].ry = arc_ry;
					bezier_points[bi].angle = arc_rotation;
					bezier_points[bi].large_arc = large_arc == 1;
					bezier_points[bi].sweep = arc_sweep == 1;
					bi++;
					
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
		}

		points = bi;
	}

	static int parse_int (string? s) {
		if (unlikely (s == null)) {
			warning ("null instead of string");
			return 0;
		}
		
		if (unlikely (!int64.try_parse ((!) s))) {
			warning (@"Expecting an integer: $((!) s)");
			return 0;
		}
		
		return int.parse ((!) s);
	}

	static bool is_point (string? s) {
		if (unlikely (s == null)) {
			warning ("s is null");
			return false;
		}
		
		return double.try_parse ((!) s);
	}

	/** Add space as separator to svg data. 
	 * @param d svg data
	 */
	public static string add_separators (string d) {
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

}

}
