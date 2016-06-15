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

	public override double left {
		get {
			return cx - rx - style.stroke_width / 2;
		}
		
		set {
		}
	}

	public override double right  {
		get {
			return cx + rx + style.stroke_width / 2;
		}
		
		set {
		}
	}
	
	public override double top  {
		get {
			return cy - ry - style.stroke_width / 2;
		}
		
		set {
		}
	}
	
	public override double bottom  {
		get {
			return cy + ry + style.stroke_width / 2;
		}
		
		set {
		}
	}
		
	public Ellipse () {
	}
	
	public override bool is_over (double x, double y) {
		return false;
	}
			
	public override void draw_outline (Context cr) {
		cr.save ();
		cr.translate (cx, cy);
		cr.scale (rx, ry);
		cr.move_to (1, 0);
		cr.arc (0, 0, 1, 0, 2 * PI);
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
		Ellipse e = new Ellipse ();
		Object.copy_attributes (this, e);
		e.cx = cx;
		e.cy = cy;
		e.rx = rx;
		e.ry = ry;
		return e;
	}

	public override string to_string () {
		return "Ellipse";
	}
}

}
