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
	
	public GlyphCollection glyph;
	public Gee.ArrayList<GlyphCollection> alternates;
	
	public Alternate (GlyphCollection glyph) {
		this.glyph = glyph;
		this.alternates = new Gee.ArrayList<GlyphCollection> ();
	}

	public void add (GlyphCollection g) {
		alternates.add (g);
	}
	
	public void remove (GlyphCollection g) {
		int i = 0;
		foreach (GlyphCollection a in alternates) {
			if (a.get_name () == g.get_name ()) {
				break;
			}
			i++;
		}
		
		if (i < alternates.size) {
			alternates.remove_at (i);
		}
	}
	
}

}
