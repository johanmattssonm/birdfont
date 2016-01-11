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
	
	Gee.ArrayList<SelectorPattern> patterns;
	public SvgStyle style { get; set; }

	public Selector (string pattern, SvgStyle style) {
		this.patterns = new Gee.ArrayList<SelectorPattern> ();
		string[] selector_patterns = pattern.split (",");
		
		for (int i = 0; i < selector_patterns.length; i++) {
			patterns.add (new SelectorPattern (selector_patterns[i]));
		}

		this.style = style;
	}
	
	public bool match (string tag, string? id, string? css_class) {
		return false;
	}
}

}
