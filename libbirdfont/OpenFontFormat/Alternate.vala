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
	
	public unichar character;
	public Gee.ArrayList<string> alternates;
	public string tag;
	
	public Alternate (unichar character, string tag) {
		this.character = character;
		this.alternates = new Gee.ArrayList<string> ();
		this.tag = tag;
	}

	public void add (string glyph_name) {
		alternates.add (glyph_name);
	}
	
	public void remove (GlyphCollection g) {
		int i = 0;
		foreach (string a in alternates) {
			if (a == g.get_name ()) {
				break;
			}
			i++;
		}
		
		if (i < alternates.size) {
			alternates.remove_at (i);
		}
	}
	
	public Alternate copy () {
		Alternate n = new Alternate (character, tag);

		foreach (string s in alternates) {
			n.add (s);
		}
		
		return n;
	}
}

}
