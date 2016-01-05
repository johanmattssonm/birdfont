/*
	Copyright (C) 2015 Johan Mattsson

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

public class SvgStyle {
	
	Gee.HashMap<string, string> style;
	
	public SvgStyle () {
		style = new Gee.HashMap<string, string> ();
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
				
		return get_stroke_width () > 0 && s;
	}
		
	public double get_stroke_width () {
		if (!style.has_key ("stroke-width")) {
			return 0;
		}

		return double.parse (style.get ("stroke-width"));
	}
	
	
	public static SvgStyle parse (Attributes attributes) {
		SvgStyle s = new SvgStyle ();
		
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
		}
		
		return s;
	}
	
	void parse_key_value_pairs (string svg_style) {
		string[] p = svg_style.split (";");
		string[] pair;
		string k, v;
		
		foreach (string kv in p) {
			pair = kv.split (":");
			
			if (pair.length != 2) {
				warning ("pair.length != 2");
				continue;
			}
			
			k = pair[0];
			v = pair[1];
			
			style.set (k, v);
		}
	}
	
	public void apply (PathList path_list) {
		foreach (Path p in path_list.paths) {
			if (has_stroke ()) {
				p.stroke = get_stroke_width ();
			} else {
				p.stroke = 0;
			}
			
			p.line_cap = get_line_cap ();
			p.reset_stroke ();
			p.update_region_boundaries ();		
		}
	}
}

}
