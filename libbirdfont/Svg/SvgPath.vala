/*
	Copyright (C) 2015 Johan Mattsson

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

namespace BirdFont {

public class SvgPath : Object {
	public override double stroke { get; set; }
	public override double rotation { get; set; }
	public override LineCap line_cap { get; set; }
	public override bool fill { get; set; }

	public override Color? color { get; set; }
	public override Color? stroke_color { get; set; }
	public override Gradient? gradient { get; set; }

	public override double xmin { get; set; }
	public override double xmax { get; set; }
	public override double ymin { get; set; }
	public override double ymax { get; set; }
	
	public Gee.ArrayList<Points> points = new Gee.ArrayList<Points> ();
	
	public SvgPath () {
	}

	public SvgPath.create_copy (SvgPath p) {
		Object.copy_attributes (p, this);
	}
	
	public override bool is_over (double x, double y) {
		return false;
	}
			
	public override void draw (Context cr, Color? c = null) {
		Color fill, stroke;

		cr.save ();
		
		foreach (Points p in points) {
			cr.new_path ();
			cr.move_to (p.x, p.y);			
			draw_points (cr, p);
		}
		
		if (style.fill != null) {
			fill = (!) style.fill;
			cr.set_source_rgba (fill.r, fill.g, fill.b, fill.a);
			
			if (style.stroke != null) {
				cr.fill_preserve ();
			} else {
				cr.fill ();
			}
		}
		
		if (style.stroke != null) {
			stroke = (!) style.stroke;
			cr.set_source_rgba (stroke.r, stroke.g, stroke.b, stroke.a);
			cr.stroke ();
		}

		cr.restore ();
	}

	public void draw_points (Context cr, Points points) {
		Doubles p = points.point_data;
		
		return_if_fail (p.size % 6 == 0);
		
		for (int i = 0; i < p.size; i += 6) {
			cr.curve_to (p.data[i], p.data[i + 1], 
				p.data[i + 2], p.data[i + 3],
				p.data[i + 4], p.data[i + 5]);
		}		
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
		return new SvgPath.create_copy (this);
	}

	public override string to_string () {
		return "SvgPath";
	}
}

}
