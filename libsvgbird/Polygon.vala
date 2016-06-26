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

public class Polygon : Object {

	public Doubles points = new Doubles ();

	public Polygon () {
	}
	
	public override bool is_over (double x, double y) {
		return false;
	}
	
	public override void draw_outline (Context cr) {
		return_if_fail (points.size % 2 == 0);
		
		if (points.size > 2) {
			cr.move_to (points.data[0].value, points.data[1].value);
			
			for (int i = 2; i < points.size - 1; i += 2) {
				cr.line_to (points.data[i].value, points.data[i + 1].value);
			}
			
			cr.close_path ();
		}		
	}
	
	public override void move (double dx, double dy) {
	}
	
	public override bool is_empty () {
		return false;
	}
	
	public override Object copy () {
		Polygon p = new Polygon ();		
		p.points = points.copy ();
		Object.copy_attributes (this, p);
		return p;
	}

	public override string to_string () {
		return "Polygon";
	}

}

}
