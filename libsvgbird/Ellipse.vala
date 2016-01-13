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

public class Ellipse : Object {	

	public double cx = 0;
	public double cy = 0;
	public double rx = 0;
	public double ry = 0;
	
	public Ellipse () {
	}

	public Ellipse.create_copy (Ellipse c) {
		Object.copy_attributes (c, this);
		c.cx = cx;
		c.cx = cy;
		c.rx = rx;
		c.ry = ry;
	}
	
	public override bool is_over (double x, double y) {
		return false;
	}
			
	public override void draw (Context cr) {
		cr.save ();
		cr.translate (cx, cy);
		cr.scale (rx, ry);
		cr.arc (0, 0, 1, 0, 2 * PI);
		cr.restore ();	
		
		cr.save ();
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
		return new Ellipse.create_copy (this);
	}

	public override string to_string () {
		return "Ellipse";
	}
}

}
