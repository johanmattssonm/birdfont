/*
	Copyright (C) 2014 2016 Johan Mattsson

	This library is free software; you can redistribute it and/or modify 
	it under the terms of the GNU Lesser General Public License as 
	published by the Free Software Foundation; either version 3 of the 
	License, or (at your option) any later version.

	This library is distributed in the hope that it will be useful, but 
	WITHOUT ANY WARRANTY; without even the implied warranty of 
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
	Lesser General Public License for more details.
*/

namespace SvgBird {

/** Bezier point container for the SVG parser. */
public class BezierPoints {
	public unichar type = '\0';
	public unichar svg_type = '\0';
	public double x0  = 0;
	public double y0 = 0;
	public double x1 = 0;
	public double y1 = 0;
	public double x2 = 0;
	public double y2 = 0;

	// arc arguments
	public double rx = 0; 
	public double ry = 0;
	public double angle = 0;
	public bool large_arc = false;
	public bool sweep = false;
	// the arc instructions begins at x0, y0 and ends at x1, x1

	public string to_string () {
		if (svg_type == 'A' || svg_type == 'a') {
			return @"SVG type:$((!) svg_type.to_string ()) $x0,$y0 $x1,$y1 rx=$rx, ry=$ry, angle=$angle, large_arc=$large_arc, sweep=$sweep)";
		}
		
		return @"$((!)type.to_string ()) $x0,$y0 $x1,$y1 $x2,$y2 SVG:$((!)svg_type.to_string ())";
	}
}

}
