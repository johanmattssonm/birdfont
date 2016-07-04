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

public class Selector : GLib.Object {
	
	Gee.ArrayList<SelectorPattern> tag_patterns = new Gee.ArrayList<SelectorPattern> ();
	Gee.ArrayList<SelectorPattern> class_patterns = new Gee.ArrayList<SelectorPattern> ();
	Gee.ArrayList<SelectorPattern> pseudo_class_patterns = new Gee.ArrayList<SelectorPattern> ();
	Gee.ArrayList<SelectorPattern> id_patterns = new Gee.ArrayList<SelectorPattern> ();
	
	public SvgStyle style { get; set; }

	public Selector (string pattern, SvgStyle style) {
		string[] selector_patterns = pattern.split (",");
		
		for (int i = 0; i < selector_patterns.length; i++) {
			SelectorPattern p = new SelectorPattern (selector_patterns[i]);
			
			if (p.has_id ()) {
				SelectorPattern id = p.get_id_patterns ();
				id_patterns.add (id);
			}
			
			if (p.has_class ()) {
				SelectorPattern css_class = p.get_class_patterns ();
				class_patterns.add (css_class);
			}

			if (p.has_pseudo_class ()) {
				SelectorPattern pseudo_class = p.get_pseudo_class_patterns ();
				pseudo_class_patterns.add (pseudo_class);
			}
			
			tag_patterns.add (p);
		}

		this.style = style;
	}
	
	public Selector.copy_constructor (Selector selector) {
		style = selector.style.copy ();
		
		foreach (SelectorPattern pattern in selector.tag_patterns) {
			tag_patterns.add (pattern.copy ());
		}
		
		foreach (SelectorPattern pattern in selector.class_patterns) {
			class_patterns.add (pattern.copy ());
		}
		
		foreach (SelectorPattern pattern in selector.id_patterns) {
			id_patterns.add (pattern.copy ());
		}
		
		foreach (SelectorPattern pattern in selector.pseudo_class_patterns) {
			pseudo_class_patterns.add (pattern.copy ());
		}
	}
	
	public string to_string () {
		StringBuilder s = new StringBuilder ();
		
		foreach (SelectorPattern pattern in tag_patterns) {
			if (s.str != "") {
				s.append (", ");
			}
			
			s.append (pattern.to_string ());
		}
		
		return s.str;
	}
	
	public Selector copy () {
		return new Selector.copy_constructor (this);
	}
	
	public bool match_tag (XmlElement tag, string? id, string? css_class, string? psedo_class) {
		foreach (SelectorPattern pattern in tag_patterns) {
			if (pattern.match (tag, id, css_class, psedo_class)) {
				return true;
			}
		}
		
		return false;
	}
	
	public bool match_id (XmlElement tag, string? id, string? css_class, string? psedo_class) {
		foreach (SelectorPattern pattern in id_patterns) {
			if (pattern.match (tag, id, css_class, psedo_class)) {
				return true;
			}
		}
		
		return false;
	}
	
	public bool match_class (XmlElement tag, string? id, string? css_class, string? psedo_class) {
		foreach (SelectorPattern pattern in class_patterns) {
			if (pattern.match (tag, id, css_class, psedo_class)) {
				return true;
			}
		}
		
		return false;
	}
	
	public bool match_pseudo_class (XmlElement tag, string? id, string? css_class, string? psedo_class) {
		foreach (SelectorPattern pattern in pseudo_class_patterns) {
			if (pattern.match (tag, id, css_class, psedo_class)) {
				return true;
			}
		}
		
		return false;
	}
}

}
