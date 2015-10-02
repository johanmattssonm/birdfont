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

namespace BirdFont {

public class OtfTags : GLib.Object {
	public Gee.ArrayList<string> elements = new Gee.ArrayList<string> ();
	
	public void add (string tag) {
		elements.add (tag);
	}
	
	public void remove (string tag) {
		while (elements.index_of (tag) > -1) {
			elements.remove (tag);
		}
	}

	public OtfTags copy () {
		OtfTags tags = new OtfTags ();
		
		foreach (string e in elements) {
			tags.add (e);
		}
		
		return tags;
	}
	
	public string to_string () {
		StringBuilder sb = new StringBuilder ();
		foreach (string s in elements) {
			sb.append (s);
		}
		return sb.str;
	}
}

}
