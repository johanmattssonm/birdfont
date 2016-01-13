/*
	Copyright (C) 2015 2016 Johan Mattsson

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

namespace SvgBird {

public class SvgStyle : GLib.Object {
	
	public Gee.HashMap<string, string> style = new Gee.HashMap<string, string> ();
	
	public Color? stroke = null;
	public Color? fill = null;
	public Gradient? stroke_gradient = null;
	public Gradient? fill_gradient = null;

	public double stroke_width = 0;
	
	public SvgStyle () {
	}

	public SvgStyle.for_properties (Defs? defs, string style) {
		parse_key_value_pairs (style);
		set_style_properties (defs, this);
	}

	public LineCap get_line_cap () {
		string l;
		
		if (!style.has_key ("stroke-linecap")) {
			return LineCap.BUTT;
		}
		
		l = style.get ("stroke-linecap");
		
		if (l == "round") {
			return LineCap.ROUND;
		} else if (l == "square") {
			return LineCap.SQUARE;
		}
		
		return LineCap.BUTT; 	
	}
	
	public bool has_stroke () {
		bool s = true;
		
		if (style.has_key ("stroke")) {
			s = style.get ("stroke") != "none";
		}
				
		return stroke_width > 0 && s;
	}
		
	public double get_stroke_width () {
		return stroke_width;
	}
	
	public void inherit (SvgStyle inherited) {
		foreach (string key in inherited.style.keys) {
			style.set (key, inherited.style.get (key));
		}
	}
	
	public static SvgStyle parse (Defs? d, SvgStyle inherited, XmlElement tag) {
		SvgStyle s = new SvgStyle ();
		Attributes attributes = tag.get_attributes ();

		s.style.set ("fill", "#000000"); // default fill value		
		s.inherit (inherited);
		
		if (d != null) {
			StyleSheet style_sheet = ((!) d).style_sheet;
			style_sheet.inherit_style (tag, s);
		}

		foreach (Attribute a in attributes) {
			if (a.get_name () == "style") {
				s.parse_key_value_pairs (a.get_content ());
			}
			
			if (a.get_name () == "stroke-width") {
				s.style.set ("stroke-width", a.get_content ());
			}

			if (a.get_name () == "stroke") {
				s.style.set ("stroke", a.get_content ());
			}

			if (a.get_name () == "fill") {
				s.style.set ("fill", a.get_content ());
			}

			if (a.get_name () == "fill-opacity") {
				s.style.set ("fill-opacity", a.get_content ());
			}

			if (a.get_name () == "stroke-opacity") {
				s.style.set ("stroke-opacity", a.get_content ());
			}
		}
	
		set_style_properties (d, s);
		return s;
	}
	
	static void set_style_properties (Defs? d, SvgStyle s) {
		double fill_opacity = 1;
		double stroke_opacity = 1;

		s.stroke_width = SvgFile.parse_number (s.style.get ("stroke-width"));
		s.stroke = Color.parse (s.style.get ("stroke"));
		s.fill = Color.parse (s.style.get ("fill"));

		string? opacity = s.style.get ("fill-opacity");
		if (opacity != null) {
			fill_opacity = SvgFile.parse_number ((!) opacity);
		}

		opacity = s.style.get ("stroke-opacity");
		if (opacity != null) {
			stroke_opacity = SvgFile.parse_number ((!) opacity);
		}
			
		if (d != null) {
			Defs defs = (!) d;

			s.stroke_gradient = defs.get_gradient_for_url (s.style.get ("stroke"));
			s.fill_gradient = defs.get_gradient_for_url (s.style.get ("fill"));
		}
		
		if (s.fill != null) {
			Color color = (!) s.fill;
			color.a = fill_opacity;
		}
		
		if (s.stroke != null) {
			Color color = (!) s.stroke;
			color.a = stroke_opacity;
		}		
	}
	
	void parse_key_value_pairs (string svg_style) {
		string[] p = svg_style.strip ().split (";");
		string[] pair;
		string k, v;
		
		foreach (string kv in p) {
			if (kv.index_of (":") != -1) {
				pair = kv.split (":");
				
				if (pair.length != 2) {
					warning ("pair.length != 2 in " + svg_style);
					continue;
				}
				
				k = pair[0].strip ();
				v = pair[1].strip ();
				
				style.set (k, v);
			}
		}
	}
}

}
