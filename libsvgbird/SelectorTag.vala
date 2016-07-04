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

/** A part of a CSS selector pattern. */
public class SelectorTag : GLib.Object {
	public string name;
	public string? id = null;
	public string? css_class = null;
	public string? pseudo_class = null;
	Gee.ArrayList<AttributePattern>? attribute_patterns = null;

	public SelectorTag.empty () {
	}
	
	public SelectorTag (string pattern) {
		string tag_pattern = pattern.strip ();
		int attribute_separator = tag_pattern.index_of ("[");

		if (attribute_separator != -1) {
			parse_attributes (tag_pattern.substring (attribute_separator));
			tag_pattern = tag_pattern.substring (0, attribute_separator - "[".length);
		}

		tag_pattern = create_part (tag_pattern, ":", out pseudo_class);
		tag_pattern = create_part (tag_pattern, ".", out css_class);
		tag_pattern = create_part (tag_pattern, "#", out id);
		name = tag_pattern;
	}
	
	string create_part (string tag_pattern, string separator, out string? part) {
		int separator_index = tag_pattern.index_of (separator);
		int separator_length = separator.length;
	
		part = null;
		
		if (separator_index == -1) {
			return tag_pattern;
		}
		
		if (separator_index > -1 && separator_index + separator_length < tag_pattern.length) {
			part = tag_pattern.substring (separator_index + separator_length);
		}
		
		if (separator_index > separator_length) {
			return tag_pattern.substring (0, separator_index);
		} 
		
		return "";
	}
	
	public SelectorTag copy () {
		SelectorTag tag = new SelectorTag.empty();
		
		tag.name = name;
		tag.id = id;
		tag.css_class = css_class;
		tag.pseudo_class = pseudo_class;
		
		if (attribute_patterns != null) { 
			foreach (AttributePattern p in (!) attribute_patterns) {
				((!) attribute_patterns).add (p.copy ());
			}
		}
		
		return tag;
	}
	
	void parse_attributes (string attributes) {
		int index = 0;
		Gee.ArrayList<AttributePattern> patterns = new Gee.ArrayList<AttributePattern> ();
		
		while (index != -1) {
			int start = attributes.index_of ("[", index);
			
			if (start == -1) {
				return;
			}
			
			int stop = attributes.index_of ("]", start);
			
			if (stop == -1) {
				return;
			}
			
			AttributePattern pattern;
			pattern = parse_attribute (attributes.substring (start, stop));
			patterns.add (pattern);
			
			index = stop + "]".length;
		}
		
		attribute_patterns = patterns;
	}
	
	AttributePattern parse_attribute (string attribute) {
		int starts_with = attribute.index_of ("|=");
		int in_list = attribute.index_of ("~=");
		int equals = attribute.index_of ("=");
		AttributePattern pattern = new AttributePattern ();

		if (starts_with != -1) {
			pattern.name = attribute.substring (0, starts_with);
			pattern.type = AttributePatternType.STARTS_WITH;
			pattern.content = attribute.substring (0, equals + "~=".length);
		} else if (in_list != -1) {
			pattern.name = attribute.substring (0, in_list);
			pattern.type = AttributePatternType.LIST;
			pattern.content = attribute.substring (0, equals + "~=".length);
		} else if (equals != -1) {
			pattern.name = attribute.substring (0, equals);
			pattern.type = AttributePatternType.EQUALS;
			pattern.content = attribute.substring (0, equals + "=".length);
		} else {
			pattern.name = attribute;
			pattern.type = AttributePatternType.ANYTHING;
		}
		
		return pattern;
	}

	public bool match (XmlElement tag, string? id, string? css_class, string? pseudo_class) {
		string tag_name = tag.get_name ();
		
		if (this.name != "*" && this.name != "" && tag_name != "") {
			if (this.name != tag_name) {
				return false;
			}
		}
		
		if (this.id != null) {
			if (id == null) {
				return false;
			} 

			if (((!) this.id) != ((!) id)) {
				return false;
			}
		}
		
		if (this.css_class != null) {
			if (css_class == null) {
				return false;
			} 
			
			if (((!) this.css_class) != ((!) css_class)) {
				return false;
			}
		}
		
		if (this.pseudo_class != null) {
			if (pseudo_class == null) {
				return false;
			} 
			
			if (((!) this.pseudo_class) != ((!) pseudo_class)) {
				return false;
			}
		}
		
		if (attribute_patterns != null) {
			foreach (AttributePattern pattern in (!) attribute_patterns) {
				if (!pattern.match (tag.get_attributes ())) {
					return false;
				}
			}
		}
		
		return true;
	}

	public string to_string () {
		StringBuilder s = new StringBuilder ();
		s.append ((!) name);
		
		if (id != null) {
			s.append ("#");
			s.append ((!) id);
		}

		if (css_class != null) {
			s.append (".");
			s.append ((!) css_class);
		}

		if (pseudo_class != null) {
			s.append (":");
			s.append ((!) pseudo_class);
		}
		
		if (attribute_patterns != null) {
			foreach (AttributePattern a in (!) attribute_patterns) {
				s.append (a.to_string ());
			}
		}
		
		return s.str;
	}
}

}
