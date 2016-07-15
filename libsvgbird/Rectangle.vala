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

public class Rectangle : Object {

	public double x = 0;
	public double y = 0;
	public double width = 0;
	public double height = 0;

	/** Corner radius */
	public double rx = 0;
	public double ry = 0;

	public Rectangle () {
	}
	
	public override bool is_over (double x, double y) {
		return this.x <= x <= this.x + width && this.y <= y <= this.y + height; 
	}
			
	public override void draw_outline (Context cr) {
		if (rx == 0 && ry == 0) {
			cr.rectangle (x, y, width, height);
		} else {
			draw_rounded_corners (cr);
		}
	}
	
	public void draw_rounded_corners (Context cr) {
		cr.save ();
		cr.new_path ();
		cr.translate (-rx, -ry);
		elliptical_arc (cr, x + width - rx, y + ry, -PI / 2, 0);
		elliptical_arc (cr, x + width - rx, y + height - ry, 0, PI / 2);
		elliptical_arc (cr, x + rx, y + height - ry, PI / 2, PI);
		elliptical_arc (cr, x + rx, y + ry, PI, PI + PI / 2);
		cr.close_path ();
		cr.restore ();
	}
	
	public void elliptical_arc (Context cr, double x, double y, double angle_start, double angle_stop) {
		cr.save ();
		cr.translate (x + rx, y + ry);
		cr.scale (rx, ry);
		cr.arc (0, 0, 1, angle_start, angle_stop);
		cr.restore ();
	}
	
	public override void move (double dx, double dy) {
		x += dx;
		y += dy;
	}

	public override bool is_empty () {
		return false;
	}
	
	public override Object copy () {
		Rectangle r = new Rectangle ();
		
		r.x = x;
		r.y = y;
		r.rx = rx;
		r.ry = ry;
		r.width = width;
		r.height = height;
		
		Object.copy_attributes (this, r);
		
		return r;
	}

	public override string to_string () {
		return "Rectangle";
	}

}

}
