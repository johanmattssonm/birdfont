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

/** A CSS selector pattern. */
public class SelectorPattern : GLib.Object {
	Gee.ArrayList<SelectorTag> tags = new Gee.ArrayList<SelectorTag> ();

	public SelectorPattern.empty () {
	}
	
	public SelectorPattern (string pattern) {
		string p = pattern.strip ();
		string[] elements = p.split (" ");

		foreach (string element in elements) {
			if (element != "") {
				tags.add (new SelectorTag (element));
			}
		}
	}
	
	public SelectorPattern copy () {
		SelectorPattern pattern = new SelectorPattern.empty ();
		
		foreach (SelectorTag tag in tags) {
			pattern.tags.add (tag.copy ());
		}
		
		return pattern;
	}
	
	public bool match (XmlElement tag, string? id, string? css_class) {
		for (int i = tags.size - 1; i >= 0; i--) {
			SelectorTag pattern = tags.get (i);
						
			if (pattern.name == ">") {
				if (i - 1 < 0) {
					return false;
				}
				
				string parent = tags.get (i - 1).name;
				
				if (!has_parent (tag, parent)) {
					return false;
				}
			} else if (pattern.name == "+") {
				if (i - 1 < 0) {
					return false;
				}
				
				string previous = tags.get (i - 1).name;
				
				if (!is_immediately_following (tag, previous)) {
					return false;
				}
			} else if (!pattern.match (tag, id, css_class)) {
				return false;
			}
		}
		
		return true;
	}
	
	public bool is_immediately_following (XmlElement tag, string previous) {
		return get_previous (tag) == tag;
	}
	
	XmlElement? get_previous (XmlElement? xml_parent) {
		if (xml_parent == null) {
			return null;
		}
		
		XmlElement element = (!) xml_parent;
		XmlElement? parent = element.get_parent ();
		
		if (parent != null) {
			XmlElement? previous = null;
			
			foreach (XmlElement e in (!) parent) {
				if (e == xml_parent) {
					return previous;
				}
				
				previous = e;
			}
		}
		
		return null;
	}
	
	public bool has_parent (XmlElement tag, string parent) {
		XmlElement? xml_parent = tag.get_parent ();
		
		while (xml_parent != null) {
			if (((!) xml_parent).get_name () == parent) {
				return true;
			}
			
			xml_parent = tag.get_parent ();
		}
		
		return false;
	}
}

}
