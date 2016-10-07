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

public enum SvgFormat {
	NONE,
	INKSCAPE,
	ILLUSTRATOR
}

public class SvgFile : GLib.Object {

	SvgDrawing drawing;
	SvgFormat format = SvgFormat.ILLUSTRATOR;

	public SvgFile () {		
	}
	
	public SvgDrawing parse_svg_data (string xml_data) {
		XmlTree tree = new XmlTree (xml_data);

		if (xml_data.index_of ("Illustrator") > -1 || xml_data.index_of ("illustrator") > -1) {
			format = SvgFormat.ILLUSTRATOR;
		} else if (xml_data.index_of ("Inkscape") > -1 || xml_data.index_of ("inkscape") > -1) {
			format = SvgFormat.INKSCAPE;
		}

		return parse_svg_file (tree.get_root (), format);
	}
	
	public SvgDrawing parse_svg_file (XmlElement svg_tag, SvgFormat format) {
		drawing = new SvgDrawing ();
		this.format = format;

		SvgStyle style = new SvgStyle ();
		SvgStyle.parse (drawing.defs, style, svg_tag, null);

		foreach (Attribute attr in svg_tag.get_attributes ()) {	
			if (attr.get_name () == "width") {
				drawing.width = parse_number (attr.get_content ());
			}

			if (attr.get_name () == "height") {
				drawing.height = parse_number (attr.get_content ());
			}

			if (attr.get_name () == "viewBox") {
				drawing.view_box = parse_view_box (svg_tag);
			}
		}
				
		foreach (XmlElement t in svg_tag) {
			string name = t.get_name ();

			if (name == "g") {
				parse_layer (drawing.root_layer, style, t);
			}

			if (name == "svg") {
				SvgDrawing embedded = parse_svg_file (t, format);
				drawing.root_layer.add_object (embedded);
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
		drawing.update_boundaries_for_object ();
		
		return drawing;
	}

	public static ViewBox? parse_view_box (XmlElement tag) {
		string arguments;
		string parameters = "";
		string aspect_ratio = "";
		bool slice = true;
		bool preserve_aspect_ratio = true;
		
		foreach (Attribute attribute in tag.get_attributes ()) {
			if (attribute.get_name () == "viewBox") {
				parameters = attribute.get_content ();
			}
			
			if (attribute.get_name () == "preserveAspectRatio") {
				aspect_ratio = attribute.get_content ();
				
				string[] preserveSettings = aspect_ratio.split (" ");
				
				if (preserveSettings.length >= 1) {
					aspect_ratio = preserveSettings[0];
				}
				
				if (preserveSettings.length >= 2) {
					slice = preserveSettings[1] == "slice";
				}
				
				preserve_aspect_ratio = false;
			}
		}
		
		arguments = parameters.replace (",", " ");
		
		while (arguments.index_of ("  ") > -1) {
			arguments = arguments.replace ("  ", " ");
		}
		
		string[] view_box_parameters = arguments.split (" ");
		
		if (view_box_parameters.length != 4) {
			warning ("Expecting four arguments in view box.");
			return null;
		}

		double minx = parse_number (view_box_parameters[0]);
		double miny = parse_number (view_box_parameters[1]);
		double width = parse_number (view_box_parameters[2]);
		double height = parse_number (view_box_parameters[3]);
		
		uint alignment = ViewBox.XMID_YMID;
		aspect_ratio = aspect_ratio.up ();
		
		if (aspect_ratio == "NONE") {
			alignment = ViewBox.NONE;
		} else if (aspect_ratio == "XMINYMIN") {
			alignment = ViewBox.XMIN_YMIN;
		} else if (aspect_ratio == "XMINYMIN") {
			alignment = ViewBox.XMIN_YMIN;
		} else if (aspect_ratio == "XMAXYMIN") {
			alignment = ViewBox.XMIN_YMIN;
		} else if (aspect_ratio == "XMINYMID") {
			alignment = ViewBox.XMIN_YMIN;
		} else if (aspect_ratio == "XMIDYMID") {
			alignment = ViewBox.XMIN_YMIN;
		} else if (aspect_ratio == "XMAXYMID") {
			alignment = ViewBox.XMIN_YMIN;
		} else if (aspect_ratio == "XMINYMAX") {
			alignment = ViewBox.XMIN_YMIN;
		} else if (aspect_ratio == "XMIDYMAX") {
			alignment = ViewBox.XMIN_YMIN;
		} else if (aspect_ratio == "XMAXYMAX") {
			alignment = ViewBox.XMIN_YMIN;
		}
		
		return new ViewBox (minx, miny, width, height, alignment, slice, preserve_aspect_ratio);
	}

	private void parse_layer (Layer layer, SvgStyle parent_style, XmlElement tag) {		
		foreach (XmlElement t in tag) {
			string name = t.get_name ();

			if (name == "g") {
				Layer sublayer = new Layer ();
				parse_layer (sublayer, parent_style, t);
				layer.objects.add (sublayer);
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
			string name = t.get_name ();
			
			if (name == "linearGradient") {
				parse_linear_gradient (drawing, t);
			} else if (name == "radialGradient") {
				parse_radial_gradient (drawing, t);
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

	void parse_radial_gradient (SvgDrawing drawing, XmlElement tag) {
		RadialGradient gradient = new RadialGradient ();
		
		drawing.defs.add_radial_gradient (gradient);
		
		foreach (Attribute attr in tag.get_attributes ()) {
			string name = attr.get_name ();
			
			// FIXME: gradientUnits
			
			if (name == "gradientTransform") {
				gradient.transforms = parse_transform (attr.get_content ());
			}

			if (name == "href") {
				gradient.href = attr.get_content ();
			}

			if (name == "cx") {
				gradient.cx = parse_number (attr.get_content ());
			}

			if (name == "cy") {	
				gradient.cy = parse_number (attr.get_content ());
			}
			
			if (name == "fx") {
				gradient.fx = parse_number (attr.get_content ());
			}

			if (name == "fy") {
				gradient.fy = parse_number (attr.get_content ());
			}

			if (name == "r") {
				gradient.r = parse_number (attr.get_content ());
			}

			if (name == "id") {
				gradient.id = attr.get_content ();
			}
		}
		
		foreach (XmlElement t in tag) {
			string name = t.get_name ();
			
			if (name == "stop") {
				parse_stop (gradient, t);
			}
		}
	}

	void parse_linear_gradient (SvgDrawing drawing, XmlElement tag) {
		LinearGradient gradient = new LinearGradient ();
		
		drawing.defs.add_linear_gradient (gradient);
		
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
			string name = t.get_name ();
			
			if (name == "stop") {
				parse_stop (gradient, t);
			}
		}
	}

	void parse_stop (Gradient gradient, XmlElement tag) {
		SvgStyle parent_style = new SvgStyle (); // not inherited
		SvgStyle style = SvgStyle.parse (drawing.defs, parent_style, tag, null);
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
		
		if (name == "text") {
			parse_text (layer, parent_style, tag);
		}
		
		if (name == "svg") {
			SvgDrawing embedded = parse_svg_file (tag, format);
			layer.add_object (embedded);
		}

	}

	private void parse_polygon (Layer layer, SvgStyle parent_style, XmlElement tag) {
		Polygon polygon = new Polygon ();

		foreach (Attribute attr in tag.get_attributes ()) {
			if (attr.get_name () == "points") {
				string data = add_separators (attr.get_content ());
				string[] point_data = data.split (" ");
				
				for (int i = 0; i < point_data.length - 1; i++) {
					string number_x = point_data[i];
					string number_y = point_data[i + 1];
					polygon.points.add_type (POINT_LINE);
					polygon.points.add (parse_number (number_x));
					polygon.points.add (parse_number (number_y));
					polygon.points.add (0);
					polygon.points.add (0);
					polygon.points.add (0);
					polygon.points.add (0);
					polygon.points.add (0);
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
		object.style = SvgStyle.parse (drawing.defs, parent_style, tag, null);
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

	private void parse_text (Layer layer, SvgStyle parent_style, XmlElement tag) {
		Text text = new Text ();
		
		foreach (Attribute attr in tag.get_attributes ()) {
			string name = attr.get_name ();
			
			if (name == "font-size") {
				text.set_font_size ((int) parse_number (attr.get_content ()));
			}

			if (name == "font-family") {
				text.set_font (attr.get_content ());
			}

			if (name == "x") {
				text.x = parse_number (attr.get_content ());
			}
			
			if (name == "y") {
				text.y = parse_number (attr.get_content ());
			}
		}
		
		text.set_text (tag.get_content ());
		
		set_object_properties (text, parent_style, tag);
		layer.add_object (text);
	}
	
	// FIXME: reverse order?
	public static SvgTransforms parse_transform (string transforms) {
		string[] functions;
		string transform = transforms;
		SvgTransforms transform_functions;
		
		transform_functions = new SvgTransforms ();
		
		if (transforms == "") {
			return transform_functions;
		}
		
		transform = transform.replace ("\t", " ");
		transform = transform.replace ("\n", " ");
		transform = transform.replace ("\r", " ");
		
		// use only a single space as separator
		while (transform.index_of ("  ") > -1) {
			transform = transform.replace ("  ", " ");
		}
		
		if (unlikely (transform.index_of (")") == -1)) {
			warning (@"No parenthesis in transform function: $transform");
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
			
			if (functions[i].has_prefix ("rotate")) {
				transform_functions.add (rotate (functions[i]));
			}
			// TODO: rotate etc.
		}
		
		return transform_functions;
	}

	private static SvgTransform matrix (string function) {
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
	
	private static SvgTransform rotate (string function) {
		string parameters = get_transform_parameters (function);
		string[] p = parameters.split (" ");
		SvgTransform transform = new SvgTransform ();
		transform.type = TransformType.ROTATE;

		if (p.length > 0) {
			transform.arguments.add (parse_double (p[0]));
		}

		return transform;
	}
	
	private static SvgTransform scale (string function) {
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
	
	private static SvgTransform translate (string function) {
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

	private static string get_transform_parameters (string function) {
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

	public static SvgTransforms get_transform (Attributes attributes) {
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
				path.points = parse_points (attr.get_content (), format);
			}
		}
		
		set_object_properties (path, parent_style, tag);
		layer.add_object (path);
	}

	public static Gee.ArrayList<Points> parse_points (string data, SvgFormat format) {
		Gee.ArrayList<Points> path_data = new Gee.ArrayList<Points> ();
		Points points = new Points ();
		BezierPoints[] bezier_points;
		int points_size;
		
		get_bezier_points (data, out bezier_points, out points_size, true);

		// all instructions are padded

		double first_x = 0;
		double first_y = 0;
		double last_x = 0;
		double last_y = 0;

		if (points_size > 0) {
			first_x = bezier_points[0].x0;
			first_y = bezier_points[0].y0;
		}
		
		for (int i = 0; i < points_size; i++) {
			// FIXME: add more types
			if (bezier_points[i].type == 'M') {
				points.add_type (POINT_LINE);
				points.add (bezier_points[i].x0);
				points.add (bezier_points[i].y0);
				points.add (0);
				points.add (0);
				points.add (0);
				points.add (0);
				points.add (0);
				last_x = bezier_points[i].x0;
				last_y = bezier_points[i].y0;
			} else if (bezier_points[i].type == 'C') {
				points.add_type (POINT_CUBIC);
				points.add (bezier_points[i].x0);
				points.add (bezier_points[i].y0);
				points.add (bezier_points[i].x1);
				points.add (bezier_points[i].y1);
				points.add (bezier_points[i].x2);
				points.add (bezier_points[i].y2);
				points.add (0);
				last_x = bezier_points[i].x2;
				last_y = bezier_points[i].y2;
			} else if (bezier_points[i].type == 'L') {
				points.add_type (POINT_LINE);
				points.add (bezier_points[i].x0);
				points.add (bezier_points[i].y0);
				points.add (0);
				points.add (0);
				points.add (0);
				points.add (0);
				points.add (0);
				last_x = bezier_points[i].x0;
				last_y = bezier_points[i].y0;
			} else if (bezier_points[i].type == 'A') {
				BezierPoints b = bezier_points[i];
				points.add_type (POINT_ARC);
				points.add (b.rx);
				points.add (b.ry);
				points.add (b.rotation);
				points.add (b.large_arc ? 1 : 0);
				points.add (b.sweep ? 1 : 0);
				points.add (b.x1);
				points.add (b.y1);

				last_x = bezier_points[i].x1;
				last_y = bezier_points[i].y1;
			} else if (bezier_points[i].type == 'z') {
				points.closed = true;
				
				if (fabs (first_x - last_x) > 0.0001 && fabs (first_y - last_y) > 0.0001) { 
					points.add_type (POINT_LINE);
					points.add (first_x);
					points.add (first_y);
					points.add (0);
					points.add (0);
					points.add (0);
					points.add (0);
					points.add (0);
				}
				
				path_data.add (points);
				points = new Points ();
				
				if (i + 1 < points_size) {
					first_x = bezier_points[i + 1].x0;
					first_y = bezier_points[i + 1].y0;
				}
			} else {
				string type = (!) bezier_points[i].type.to_string ();
				warning (@"SVG conversion not implemented for $type");
			}			
		}

		if (points.size > 0) {
			path_data.add (points);
		}

		if (format == SvgFormat.ILLUSTRATOR) {
			Gee.ArrayList<Points> illustrator_path_data = new Gee.ArrayList<Points> ();
			
			foreach (Points p in path_data) {
				return_val_if_fail (p.point_data.size % 8 == 0, path_data);
				
				if (p.point_data.size > 8) {
					Points illustrator_points = new Points ();
					
					if (p.point_data.get_point_type (p.point_data.size - 8) == POINT_CUBIC) {
						illustrator_points.insert_type (0, POINT_LINE);
						illustrator_points.insert (1, p.point_data.get_double (p.point_data.size - 3));
						illustrator_points.insert (2, p.point_data.get_double (p.point_data.size - 2));
						illustrator_points.insert (3, 0);
						illustrator_points.insert (4, 0);
						illustrator_points.insert (5, 0);
						illustrator_points.insert (6, 0);
						illustrator_points.insert (7, 0);
					} else {
						illustrator_points.insert_type (0, POINT_LINE);
						illustrator_points.insert (1, p.point_data.get_double (p.point_data.size - 7));
						illustrator_points.insert (2, p.point_data.get_double (p.point_data.size - 6));
						illustrator_points.insert (3, 0);
						illustrator_points.insert (4, 0);
						illustrator_points.insert (5, 0);
						illustrator_points.insert (6, 0);
						illustrator_points.insert (7, 0);
					}
					
					int start = 0;
					
					for (int i = start; i < p.point_data.size; i += 1) {
						illustrator_points.point_data.add (p.point_data.get_double (i));
					}
					
					illustrator_points.closed = p.closed;
					illustrator_path_data.add (illustrator_points);
				}
			}
			
			path_data = illustrator_path_data;
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
	
	public static void get_bezier_points (string point_data, 
		out BezierPoints[] bezier_points, out int points, bool svg_glyph) {
			
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
					bezier_points[bi].rotation = arc_rotation;
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
					bezier_points[bi].rotation = arc_rotation;
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
