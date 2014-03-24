/*
    Copyright (C) 2014 Johan Mattsson

    This library is free software; you can redistribute it and/or modify 
    it under the terms of the GNU Lesser General Public License as 
    published by the Free Software Foundation; either version 3 of the 
    License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful, but 
    WITHOUT ANY WARRANTY; without even the implied warranty of 
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
    Lesser General Public License for more details.
*/

using Cairo;
using Xml;

namespace BirdFont {

/** A list of all kerning pairs for one glyph. */
public class KerningPair : GLib.Object {
	public Glyph character;
	public GLib.List<Kerning> kerning;

	GLib.List<Glyph> right; // FIXME: should be fast and sorted
	
	public KerningPair (Glyph left) {
		character = left;
		right = new GLib.List<Glyph> ();
		kerning = new GLib.List<Kerning> ();
	}
	
	public void add_unique (Glyph g, double k) {
		if (right.index ((!) g) < 0) {
			right.append ((!) g);
			kerning.append (new Kerning.for_glyph (g, k));
		}
	}
	
	public void sort () {
		kerning.sort ((a, b) => {
			return strcmp (((!)a.glyph).get_unichar_string (), ((!)b.glyph).get_unichar_string ());
		});		
	}
}
	
}
