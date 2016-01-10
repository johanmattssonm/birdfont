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


using B;
using Cairo;
using Math;

namespace SvgBird {

public class SvgDrawing : Object {
	public Layer root_layer = new Layer ();
	public Defs defs = new Defs ();

	public double x = 0;
	public double y = 0;
	public double width = 0;
	public double height = 0;
		
	public override void update_region_boundaries () {
	}
	
	public override bool is_over (double x, double y) {
		return (this.x <= x <= this.x + width) 
			&& (this.y <= y <= this.y + height);
	}
	
	public override void draw (Context cr) {
		cr.save ();
		cr.translate (x, y);

		foreach (Object o in root_layer.get_visible_objects ().objects) {
			o.draw (cr);
		}

		cr.restore ();
	}
	
	public override Object copy () {
		SvgDrawing drawing = new SvgDrawing ();
		drawing.root_layer = root_layer.copy ();
		drawing.defs = defs.copy ();
		return drawing;
	}
	
	public override void move (double dx, double dy) {
		x += dx;
		y += dy;
	}
	
	public override void rotate (double theta, double xc, double yc) {
	}
	
	public override bool is_empty () {
		return false;
	}
	
	public override void resize (double ratio_x, double ratio_y) {
	}
}

}
