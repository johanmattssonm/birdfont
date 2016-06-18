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

using Cairo;
using Math;

namespace SvgBird {

public class RadialGradient : Gradient {
	public double cx;
	public double cy;
	public double fx;
	public double fy;
	public double r;

	public RadialGradient () {
		base ();
	}
	
	public override Gradient copy () {
		RadialGradient g = new RadialGradient ();

		g.cx = cx;
		g.cy = cy;
		g.fx = fx;
		g.fy = fy;
		g.r = r;
		
		copy_gradient (this, g);
		
		return g;
	}
	
	public override string to_string () {
		StringBuilder description = new StringBuilder ();
		description.append (@"Radial gradient $(id): ");
		description.append (@"cx=$cx, cy=$cy, fx=$fx, fy=$fy, r=$r");
		
		foreach (Stop stop in stops) {
			description.append (" ");
			description.append (stop.to_string ());
		}
		
		return description.str;
	}
	
}

}
