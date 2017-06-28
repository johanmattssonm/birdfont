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
using B;

namespace BirdFont {

/** A list of all kerning pairs for one glyph. */
public class KerningPair : GLib.Object {
	public Glyph character;
	public Gee.ArrayList<Kerning> kerning;
	public Gee.ArrayList<Glyph> right;
	
	public KerningPair (Glyph left) {
		character = left;
		right = new Gee.ArrayList<Glyph> ();
		kerning = new Gee.ArrayList<Kerning> ();
	}
	
	public void add_unique (Glyph g, double k) {
		if (!right.contains ((!) g)) {
			right.add ((!) g);
			kerning.add (new Kerning.for_glyph (g, k));
		}
	}
	
	public void sort () {
		kerning.sort ((a, b) => {
			Kerning first, next;
			first = (Kerning) a;
			next = (Kerning) b;
			return strcmp (((!)first.glyph).get_unichar_string (), ((!)next.glyph).get_unichar_string ());
		});		
	}
	
	public void print () {
		if (kerning.size == 0) {
			warning ("No pairs.");
		}
		
		foreach (Kerning k in kerning) {
			if (k.glyph != null) {
				stdout.printf (@"$(character.get_name ()) <-> $(((!) k.glyph).get_name ()): $(k.val)\n");
			}
		}
	}
}
	
}
