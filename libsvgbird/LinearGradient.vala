/*
	Copyright (C) 2015 2016 Johan Mattsson

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

public class LinearGradient : Gradient {
	public double x1;
	public double y1;
	public double x2;
	public double y2;

	public LinearGradient () {
		base ();
		x1 = 0;
		y1 = 0;
		x2 = 0;
		y2 = 0;
	}
	
	public override Gradient copy () {
		LinearGradient g = new LinearGradient ();
		
		g.x1 = x1;
		g.y1 = y1;
		g.x2 = x2;
		g.y2 = y2;
		
		foreach (Stop s in stops) {
			g.stops.add (s.copy ());
		}
		
		copy_gradient (this, g);
		
		return g;
	}
	
	public override string to_string () {
		StringBuilder description = new StringBuilder ();
		description.append (@"Gradient $(id): ");
		description.append (@"x1=$x1, y1=$y1, x2=$x2, y2=$y2");
		
		foreach (Stop stop in stops) {
			description.append (" ");
			description.append (stop.to_string ());
		}
		
		return description.str;
	}
}

}
