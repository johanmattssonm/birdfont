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

	public Circle.create_copy (Circle c) {
		Object.copy_attributes (c, this);
		c.cx = cx;
		c.cx = cy;
		c.r = r;
	}
	
	public override bool is_over (double x, double y) {
		return false;
	}
			
	public override void draw (Context cr) {
		cr.save ();
		cr.arc (cx, cy, r, 0, 2 * Math.PI);
		apply_transform (cr);		
		paint (cr);
		cr.restore ();
	}

	public override void move (double dx, double dy) {
	}
	
	public override void update_region_boundaries () {
	}

	public override void rotate (double theta, double xc, double yc) {
	}
	
	public override bool is_empty () {
		return false;
	}
	
	public override void resize (double ratio_x, double ratio_y) {
	}
	
	public override Object copy () {
		return new Circle.create_copy (this);
	}

	public override string to_string () {
		return "Circle";
	}
}

}
