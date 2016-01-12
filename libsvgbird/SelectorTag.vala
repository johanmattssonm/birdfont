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
	string? id = null;
	string? css_class = null;
	Gee.ArrayList<AttributePattern>? attribute_patterns = null;

	public SelectorTag (string pattern) {
		string tag_pattern = pattern.strip ();
		int id_separator = tag_pattern.index_of ("#");
		int class_separator = tag_pattern.index_of (".");
		int attribute_separator = tag_pattern.index_of ("[");

		if (attribute_separator != -1) {
			parse_attributes (tag_pattern.substring (attribute_separator));
		}
				
		if (id_separator != -1) {
			name = tag_pattern.substring (0, id_separator);
			
			id_separator += "#".length;
			if (attribute_separator == -1) {
				id = tag_pattern.substring (id_separator);
			} else {
				id = tag_pattern.substring (id_separator, attribute_separator - id_separator);
			}
		} else if (class_separator != -1) {
			name = tag_pattern.substring (0, class_separator);
			
			class_separator += ".".length;
			if (attribute_separator == -1) {
				css_class = tag_pattern.substring (class_separator);
			} else {
				css_class = tag_pattern.substring (class_separator, attribute_separator - class_separator);
			}
		} else {
			if (attribute_separator == -1) {
				name = tag_pattern;
			} else {
				css_class = tag_pattern.substring (0, attribute_separator);
			}
		}
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

	public bool match (XmlElement tag, string? id, string? css_class) {
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
				print(@"class \"$((!)this.css_class)\"=\"$((!)css_class)\"\n");
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
		
		if (attribute_patterns != null) {
			foreach (AttributePattern a in (!) attribute_patterns) {
				s.append (a.to_string ());
			}
		}
		
		return s.str;
	}
}

}
