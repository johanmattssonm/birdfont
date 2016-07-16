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

	public Points points = new Points ();

	public Polygon () {
	}
	
	public override void draw_outline (Context cr) {
		return_if_fail (points.size % 2 == 0);
		
		if (points.size > 8) {
			cr.move_to (points.point_data.get_double (0), points.get_double (1));
			
			for (int i = 8; i < points.size - 8; i += 8) {
				cr.line_to (points.get_double (i + 1), points.get_double (i + 2));
			}
			
			cr.close_path ();
		}		
	}

	public override bool is_over (double x, double y) {
		bool inside = false;
		
		to_object_view (ref x, ref y);
		
		if (SvgPath.is_over_points (points, x, y)) {
			inside = !inside;
		}
		
		return inside;
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
