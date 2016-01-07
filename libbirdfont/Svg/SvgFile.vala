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

namespace BirdFont {

public class SvgFile : GLib.Object {

	public SvgFile () {		
	}
	
	public Layer parse (string path) {
		string xml_data;
		
		try {
			FileUtils.get_contents (path, out xml_data);
			XmlParser xmlparser = new XmlParser (xml_data);
			
			if (xmlparser.validate ()) {
				Tag root = xmlparser.get_root_tag ();
				return parse_svg_file (root);
			} else {
				warning ("Invalid xml file.");
			}
		} catch (GLib.Error error) {
			warning (error.message);
		}
		
		return new Layer ();
	}
	
	private Layer parse_svg_file (Tag tag) {
		Layer layer = new Layer ();
	
		foreach (Tag t in tag) {
			string name = t.get_name ();
			
			if (name == "g") {
				parse_layer (layer, t);
			}
			
			parse_object (layer, t);
		}
		
		return layer;
	}

	private void parse_layer (Layer layer, Tag tag) {
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
			layer.visible = !hidden;
		}
					
		foreach (Tag t in tag) {
			if (t.get_name () == "g") {
				Layer sublayer = new Layer ();
				parse_layer (layer, t);
				layer.subgroups.add (sublayer);
			}

			parse_object (layer, t);
		}

		foreach (Attribute attr in tag.get_attributes ()) {	
			if (attr.get_name () == "transform") {
				layer.transforms = parse_transform (attr.get_content ());
			}
		}
	}

	void parse_object (Layer layer, Tag tag) {
		string name = tag.get_name ();
		
		if (name == "path") {
			parse_path (layer, tag);
		}
					
		if (name == "polygon") {
			parse_polygon (layer, tag);
		}

		if (name == "polyline") {
			parse_polyline (layer, tag);
		}
		
		if (name == "rect") {
			parse_rect (layer, tag);
		}

		if (name == "circle") {
			parse_circle (layer, tag);
		}

		if (name == "ellipse") {
			parse_ellipse (layer, tag);
		}
		
		if (name == "line") {
			parse_line (layer, tag);
		}
	}

	private void parse_polygon (Layer layer, Tag tag) {
	}
	
	private void parse_polyline (Layer layer, Tag tag) {
	}
	
	private void parse_rect (Layer layer, Tag tag) {
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
		
		rectangle.transforms = get_transform (tag.get_attributes ());
		rectangle.style = SvgStyle.parse (tag.get_attributes ());
		rectangle.visible = is_visible (tag);	
		
		layer.add_object (rectangle);
	}
	
	private void parse_circle (Layer layer, Tag tag) {
	}
	
	private void parse_ellipse (Layer layer, Tag tag) {
	}
	
	private void parse_line (Layer layer, Tag tag) {
	}
	
	// FIXME: reverse order?
	public Gee.ArrayList<SvgTransform> parse_transform (string transforms) {
		string[] functions;
		string transform = transforms;
		Gee.ArrayList<SvgTransform> transform_functions;
		
		transform_functions = new Gee.ArrayList<SvgTransform> ();
		
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
			double argument = SvgParser.parse_double (p[i]);
			transform.arguments.add (argument);
		}
		
		return transform;
	}

    private string remove_unit (string d) {
		string s = d.replace ("pt", "");
		s = s.replace ("pc", "");
		s = s.replace ("mm", "");
		s = s.replace ("cm", "");
		s = s.replace ("in", "");
		return s;
	}
    
	private double parse_number (string d) {
		string s = remove_unit (d);
		double n = SvgParser.parse_double (s);
		
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
			transform.arguments.add (SvgParser.parse_double (p[0]));
		}
		
		if (p.length > 1) {
			transform.arguments.add (SvgParser.parse_double (p[1]));
		}
		
		return transform;
	}
	
	private SvgTransform translate (string function) {
		string parameters = get_transform_parameters (function);
		string[] p = parameters.split (" ");
		SvgTransform transform = new SvgTransform ();
		transform.type = TransformType.TRANSLATE;
		
		if (p.length > 0) {
			transform.arguments.add (SvgParser.parse_double (p[0]));
		}
		
		if (p.length > 1) {
			transform.arguments.add (SvgParser.parse_double (p[1]));
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

	private bool is_visible (Tag tag) {
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

	private Gee.ArrayList<SvgTransform> get_transform (Attributes attributes) {
		foreach (Attribute attr in attributes) {
			if (attr.get_name () == "transform") {
				return parse_transform (attr.get_content ());
			}
		}
		
		return new Gee.ArrayList<SvgTransform> ();
	}
	
	private void parse_path (Layer layer, Tag tag) {
		SvgPath path = new SvgPath ();

		foreach (Attribute attr in tag.get_attributes ()) {
			if (attr.get_name () == "d") {
				path.points = parse_points (attr.get_content ());
			}
		}
		
		path.transforms = get_transform (tag.get_attributes ());
		path.style = SvgStyle.parse (tag.get_attributes ());
		path.visible = is_visible (tag);	
		
		layer.add_object (path);
	}

	public Gee.ArrayList<Points> parse_points (string data) {
		Gee.ArrayList<Points> path_data = new Gee.ArrayList<Points> ();
		Points points = new Points ();
		BezierPoints[] bezier_points;
		int points_size;
	
		SvgParser.get_bezier_points (data, out bezier_points, out points_size, true);

		for (int i = 0; i < points_size; i++) {
			// FIXME: add more types
			if (bezier_points[i].type == 'M') {
				points.x = bezier_points[i].x0;
				points.y = bezier_points[i].y0;
			} else if (bezier_points[i].type == 'C') {
				points.add (bezier_points[i].x0);
				points.add (bezier_points[i].y0);
				points.add (bezier_points[i].x1);
				points.add (bezier_points[i].y1);
				points.add (bezier_points[i].x2);
				points.add (bezier_points[i].y2);
			} else if (bezier_points[i].type == 'L') {
				points.add (bezier_points[i].x0);
				points.add (bezier_points[i].y0);
				points.add (bezier_points[i].x0);
				points.add (bezier_points[i].y0);
				points.add (bezier_points[i].x0);
				points.add (bezier_points[i].y0);
			} else if (bezier_points[i].type == 'z') {
				path_data.add (points);
				points = new Points ();
			} else {
				string type = (!) bezier_points[i].type.to_string ();
				warning (@"SVG conversion not implemented for $type");
			}
		}

		return path_data;
	}
}

}
