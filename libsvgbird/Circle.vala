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

namespace SvgBird {

public class Circle : Object {	

	public double cx = 0;
	public double cy = 0;
	public double r = 0;
	
	public Circle () {
	}
	
	public override bool is_over (double x, double y) {
		double dx = x - cx;
		double dy = y - cy;
		return Math.sqrt (dx * dx + dy * dy) <= r;
	}
			
	public override void draw_outline (Context cr) {
		cr.move_to (cx + r, cy);
		cr.arc (cx, cy, r, 0, 2 * Math.PI);
	}

	public override void move (double dx, double dy) {
	}

	public override bool is_empty () {
		return false;
	}
	
	public override Object copy () {
		Circle c = new Circle ();
		
		Object.copy_attributes (this, c);
		c.cx = cx;
		c.cy = cy;
		c.r = r;
		
		return c; 
	}

	public override string to_string () {
		return "Circle";
	}
}

}
