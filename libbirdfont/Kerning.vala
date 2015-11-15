/*
	Copyright (C) 2012 Johan Mattsson

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

public class Kerning : GLib.Object {
	public double val;
	public Glyph? glyph;
	
	public Kerning (double v) {
		val = v;
		glyph = null;
	}
	
	public Kerning.for_glyph (Glyph? g, double v) {
		val = v;
		glyph = g;
	}
	
	public Glyph get_glyph () {
		if (unlikely (glyph == null)) {
			warning ("No glyph");
			return new Glyph ("");
		}
		
		return (!) glyph;
	}
}

}
