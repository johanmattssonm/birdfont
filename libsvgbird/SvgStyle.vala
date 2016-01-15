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

	private static Gee.HashMap<string, string>? inheritance;
	private static Mutex inheritance_mutex = new Mutex ();
	
	public SvgStyle () {
	}

	public bool property_equals (string property, string value) {
		string? p = get_css_property (property);
		
		if (p == null) {
			return false;
		}
		
		string css_property = (!) p;
		return css_property == value;
	}

	public bool has_css_property (string property) {
		return style.has_key (property);
	}

	public string? get_css_property (string property) {
		string p = property.down ();
		
		if (!has_css_property (p)) {
			return null;
		}
		
		return style.get (p);
	}
	
	public static bool is_inherited (string property) {
		inheritance_mutex.lock ();
		if (unlikely (inheritance == null)) {
			create_inheritance_table ();
		}
		
		Gee.HashMap<string, string> inheritance = (!) inheritance;
		string? inherited = inheritance.get (property);
		inheritance_mutex.unlock ();

		if (inherited == null) {
			return false;
		}
		
		string inherited_property = (!) inherited;
		return inherited_property == "yes";
	}

	/** Specify inheritance for a CSS property. */
	public static void set_inheritance (string property, bool inherit) {
		inheritance_mutex.lock ();
		if (unlikely (inheritance == null)) {
			create_inheritance_table ();
		}
		
		Gee.HashMap<string, string> inheritance = (!) inheritance;
		string inherit_property = inherit ? "yes" : "no";
		inheritance.set (property, inherit_property);
		inheritance_mutex.unlock ();
	}

	public SvgStyle.for_properties (Defs? defs, string style) {
		parse_key_value_pairs (style);
		set_style_properties (defs, this);
	}

	public SvgStyle copy () {
		SvgStyle style = new SvgStyle ();
		style.apply (this);
		return style;
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
	
	public string to_string () {
		StringBuilder description = new StringBuilder ();
		
		description.append ("SvgStyle: ");
		
		foreach (string key in style.keys) {
			description.append (key);
			description.append (": ");
			description.append (style.get (key));
			description.append ("; ");
		}
		
		return description.str.strip ();
	}
	
	public void inherit (SvgStyle inherited) {
		foreach (string key in inherited.style.keys) {
			if (is_inherited (key)) {
				style.set (key, inherited.style.get (key));
			}
		}
	}

	public void apply (SvgStyle inherited) {
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
			style_sheet.apply_style (tag, s);
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
				
				k = pair[0].strip ().down ();
				v = pair[1].strip ().down ();
				
				if (k == "padding") {
					parse_padding_shorthand (v);
				} else {
					style.set (k, v);
				}
			}
		}
	}
	
	void parse_padding_shorthand (string arguments) {
		string[] args = StyleSheet.replace_whitespace (arguments).split (" ");
		
		if (args.length > 0) {
			style.set ("padding-top", args[0]);
		}
		
		if (args.length > 1) {
			style.set ("padding-right", args[1]);
		}

		if (args.length > 2) {
			style.set ("padding-bottom", args[2]);
		}

		if (args.length > 3) {
			style.set ("padding-left", args[3]);
		}
	}

	private static void create_inheritance_table () {
		inheritance = new Gee.HashMap<string, string> ();
		
		Gee.HashMap<string, string> inherited = (!) inheritance;
		
		inherited.set ("azimuth", "yes");
		inherited.set ("background-attachment", "no");
		inherited.set ("background-color", "no");
		inherited.set ("background-image", "no");
		inherited.set ("background-position", "no");
		inherited.set ("background-repeat", "no");
		inherited.set ("background", "no");
		inherited.set ("border-collapse", "yes");
		inherited.set ("border-color", "no");
		inherited.set ("border-spacing", "yes");
		inherited.set ("border-style", "no");
		inherited.set ("border-top", "no");
		inherited.set ("border-right", "no");
		inherited.set ("border-bottom", "no");
		inherited.set ("border-left", "no");
		inherited.set ("border-top-color", "no");
		inherited.set ("border-right-color", "no");
		inherited.set ("border-bottom-color", "no");
		inherited.set ("border-left-color", "no");
		inherited.set ("border-top-style", "no");
		inherited.set ("border-right-style", "no");
		inherited.set ("border-bottom-style", "no");
		inherited.set ("border-left-style", "no");
		inherited.set ("border-top-width", "no");
		inherited.set ("border-right-width", "no");
		inherited.set ("border-bottom-width", "no");
		inherited.set ("border-left-width", "no");
		inherited.set ("border-width", "no");
		inherited.set ("border", "no");
		inherited.set ("bottom", "no");
		inherited.set ("caption-side", "yes");
		inherited.set ("clear", "no");
		inherited.set ("clip", "no");
		inherited.set ("color", "yes");
		inherited.set ("content", "no");
		inherited.set ("counter-increment", "no");
		inherited.set ("counter-reset", "no");
		inherited.set ("cue-after", "no");
		inherited.set ("cue-before", "no");
		inherited.set ("cue", "no");
		inherited.set ("cursor", "yes");
		inherited.set ("direction", "yes");
		inherited.set ("display", "no");
		inherited.set ("elevation", "yes");
		inherited.set ("empty-cells", "yes");
		inherited.set ("float", "no");
		inherited.set ("font-family", "yes");
		inherited.set ("font-size", "yes");
		inherited.set ("font-style", "yes");
		inherited.set ("font-variant", "yes");
		inherited.set ("font-weight", "yes");
		inherited.set ("font", "yes");
		inherited.set ("height", "no");
		inherited.set ("left", "no");
		inherited.set ("letter-spacing", "yes");
		inherited.set ("line-height", "yes");
		inherited.set ("list-style-image", "yes");
		inherited.set ("list-style-position", "yes");
		inherited.set ("list-style-type", "yes");
		inherited.set ("list-style", "yes");
		inherited.set ("margin-right", "no");
		inherited.set ("margin-left", "no");
		inherited.set ("margin-top", "no");
		inherited.set ("margin-bottom", "no");
		inherited.set ("margin", "no");
		inherited.set ("max-height", "no");
		inherited.set ("max-width", "no");
		inherited.set ("min-height", "no");
		inherited.set ("min-width", "no");
		inherited.set ("orphans", "yes");
		inherited.set ("outline-color", "no");
		inherited.set ("outline-style", "no");
		inherited.set ("outline-width", "no");
		inherited.set ("outline", "no");
		inherited.set ("overflow", "no");
		inherited.set ("padding-top", "no");
		inherited.set ("padding-right", "no");
		inherited.set ("padding-bottom", "no");
		inherited.set ("padding-left", "no");
		inherited.set ("padding", "no");
		inherited.set ("page-break-after", "no");
		inherited.set ("page-break-before", "no");
		inherited.set ("page-break-inside", "no");
		inherited.set ("pause-after", "no");
		inherited.set ("pause-before", "no");
		inherited.set ("pause", "no");
		inherited.set ("pitch-range", "yes");
		inherited.set ("pitch", "yes");
		inherited.set ("play-during", "no");
		inherited.set ("position", "no");
		inherited.set ("quotes", "yes");
		inherited.set ("richness", "yes");
		inherited.set ("right", "no");
		inherited.set ("speak-header", "yes");
		inherited.set ("speak-numeral", "yes");
		inherited.set ("speak-punctuation", "yes");
		inherited.set ("speak", "yes");
		inherited.set ("speech-rate", "yes");
		inherited.set ("stress", "yes");
		inherited.set ("table-layout", "no");
		inherited.set ("text-align", "yes");
		inherited.set ("text-decoration", "no");
		inherited.set ("text-indent", "yes");
		inherited.set ("text-transform", "yes");
		inherited.set ("top", "no");
		inherited.set ("unicode-bidi", "no");
		inherited.set ("vertical-align", "no");
		inherited.set ("visibility", "yes");
		inherited.set ("voice-family", "yes");
		inherited.set ("volume", "yes");
		inherited.set ("white-space", "yes");
		inherited.set ("widows", "yes");
		inherited.set ("width", "no");
		inherited.set ("word-spacing", "yes");
		inherited.set ("z-index", "no");
	}
}

}
