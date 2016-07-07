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
using Math;

namespace SvgBird {


public class StyleSheet : GLib.Object {
	
	public string css_data { get; set; default = ""; }
	public Gee.ArrayList<Selector> styles = new Gee.ArrayList<Selector> ();
	
	public StyleSheet () {
	}
	
	/** Copy references to all selectors in this style sheet. */
	public StyleSheet shallow_copy () {
		StyleSheet style_sheet = new StyleSheet ();
		
		foreach (Selector selector in styles) {
			style_sheet.styles.add (selector);
		}
		
		return style_sheet;
	}

	public StyleSheet copy () {
		StyleSheet style_sheet = new StyleSheet ();
		
		foreach (Selector selector in styles) {
			style_sheet.styles.add (selector.copy ());
		}
		
		return style_sheet;
	}
	
	public SvgStyle get_style (string tag_name, string? css_class = null,
		string? id = null, string? pseudo_class = null) {
			
		SvgStyle style = new SvgStyle ();

		string xml = @"<$(tag_name) />";
		XmlTree xml_component = new XmlTree (xml);	
		
		if (!xml_component.validate ()) {
			warning (@"Bad tag: $xml");
			warning (xml);
		}
		
		XmlElement tag = xml_component.get_root ();

		foreach (Selector selector in styles) {
			if (selector.match_tag (tag, id, css_class, pseudo_class)) {
				style.apply (selector.style);
			}
		}
		
		if (css_class != null) {
			foreach (Selector selector in styles) {
				if (selector.match_class (tag, id, css_class, pseudo_class)) {
					style.apply (selector.style);
				}
			}
		}

		if (id != null) {
			foreach (Selector selector in styles) {
				if (selector.match_id (tag, id, css_class, pseudo_class)) {
					style.apply (selector.style);
				}
			}
		}

		if (pseudo_class != null) {
			foreach (Selector selector in styles) {
				if (selector.match_pseudo_class (tag, id, css_class, pseudo_class)) {
					style.apply (selector.style);
				}
			}
		}
		
		SvgStyle.set_style_properties (null, style);
		
		return style;
	}
	
	public void apply_style (XmlElement tag, SvgStyle style, string? pseudo_class) {
		string? id = null;
		string? css_class = null;
		string tag_name = tag.get_name ();
		
		if (tag.get_name () == "") {
			warning ("No tag name provided.");
			
			if (pseudo_class != null) {
				warning ((!) pseudo_class);
			}
			return;
		}
		
		foreach (Attribute attribute in tag.get_attributes ()) {
			string name = attribute.get_name ();
			
			if (name == "id") {
				id = attribute.get_content ();
			} else if (name == "class") {
				css_class = attribute.get_content ();
			}
		}

		SvgStyle new_style = get_style (tag_name, css_class, id, pseudo_class);
		style.apply (new_style);
		SvgStyle.set_style_properties (null, style);
	}
	
	public void merge (StyleSheet style_sheet) {
		foreach (Selector selector in style_sheet.styles) {
			styles.add (selector.copy ());
		}
	}

	public static StyleSheet parse (Defs defs, XmlElement style_tag) {
		return parse_css_data (defs, style_tag.get_content ());
	}
	
	public static StyleSheet parse_css_data (Defs defs, string css_data) {
		StyleSheet style_sheet = new StyleSheet ();
		string css = get_cdata (css_data);
		style_sheet.css_data = css;
		css = add_separators (css);
		css = replace_whitespace (css);
		
		int index = 0;
		int start_bracket_length = "{".length;
		int end_bracket_length = "}".length;
		int css_length = css.length;
		
		while (index < css_length) {
			int style_rules_start = css.index_of ("{", index);
			int style_rules_end = css.index_of ("}", style_rules_start);
			
			if (style_rules_start == -1 || style_rules_end == -1) {
				break;
			}
			
			int selector_end = style_rules_start - start_bracket_length;
			string selectors = css.substring (index, selector_end - index);
			
			int style_start = style_rules_start + start_bracket_length;
			int style_end = style_rules_end;
			string style_rules = css.substring (style_start, style_end - style_start);
			
			index = style_rules_end + end_bracket_length;
			SvgStyle style = new SvgStyle.for_properties (defs, style_rules);
			
			Selector selector = new Selector (selectors, style);
			style_sheet.styles.add (selector);
		}
		
		return style_sheet;
	}
	
	public static string get_cdata (string tag_content) {
		StringBuilder data = new StringBuilder ();
		
		int index = 0;
		int cdata_tag_length = "<![CDATA[".length;
		int cdata_end_tag_length = "]]>".length;
		int content_length = tag_content.length;
		
		while (index < content_length) {
			int cdata_start = tag_content.index_of ("<![CDATA[", index);
			int cdata_end = tag_content.index_of ("]]>", cdata_start);
			
			if (cdata_start == -1 || cdata_end == -1) {
				break;
			}
			
			cdata_start += cdata_tag_length;
			data.append (tag_content.substring (cdata_start, cdata_end - cdata_start));
			index = cdata_end + cdata_end_tag_length;
		}
		
		if (index < tag_content.length) {
			data.append (tag_content.substring (index));
		}
		
		return data.str;
	}

	public static string add_separators (string data) {
		string style_data = data.replace (">", " > ");
		style_data = data.replace ("+", " + ");
		return style_data;
	}
	
	public static string replace_whitespace (string data) {
		string style_data = data.replace ("\n", " ");
		style_data = style_data.replace ("\r", " ");
		style_data = style_data.replace ("\t", " ");
		
		while (style_data.index_of ("  ") != -1) {
			style_data = style_data.replace ("  ", " ");
		}
		
		return style_data;
	}
}

}
