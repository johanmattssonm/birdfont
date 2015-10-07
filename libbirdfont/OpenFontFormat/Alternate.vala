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

public class Alternate : GLib.Object {
	
	public string glyph_name;
	public Gee.ArrayList<string> alternates;
	public string tag;
	
	public Alternate (string glyph_name, string tag) {
		this.glyph_name = glyph_name;
		this.alternates = new Gee.ArrayList<string> ();
		this.tag = tag;
	}

	public bool is_empty () {
		return alternates.size == 0;
	}

	public void add (string alternate_name) {
		alternates.add (alternate_name);
	}
	
	public void remove_alternate (string alt) {
		int i = 0;
		foreach (string a in alternates) {
			if (a == alt) {
				break;
			}
			i++;
		}
		
		if (i < alternates.size) {
			alternates.remove_at (i);
		}		
	}
	
	public void remove (GlyphCollection g) {
		remove_alternate (g.get_name ());
	}
	
	public Alternate copy () {
		Alternate n = new Alternate (glyph_name, tag);

		foreach (string s in alternates) {
			n.add (s);
		}
		
		return n;
	}
}

}
