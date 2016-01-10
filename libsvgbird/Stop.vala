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

using Cairo;
using Math;

namespace SvgBird {

public class Stop : GLib.Object {
	public Color color = new Color (0, 0, 0, 1);
	public double offset = 0;
	
	public Stop () {
	}
	
	public Stop copy () {
		Stop s = new Stop ();
		s.color = color.copy  ();
		s.offset = offset;
		return s;
	}
	
	public string to_string () {
		return @"Stop: $(offset), " + color.to_string ();
	}
}

}
