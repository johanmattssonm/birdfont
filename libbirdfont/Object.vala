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
using Math;

namespace BirdFont {

public abstract class Object : GLib.Object {
	bool open = false;
	
	public Color? color = null;
	public Color? stroke_color = null;
	public Gradient? gradient = null;

	/** Path boundaries */
	public double xmax = Glyph.CANVAS_MIN;
	public double xmin = Glyph.CANVAS_MAX;
	public double ymax = Glyph.CANVAS_MIN;
	public double ymin = Glyph.CANVAS_MAX;
	
	public double rotation = 0;
	public virtual double stroke { get; set; }
	public LineCap line_cap = LineCap.BUTT;
	
	public Object () {	
	}

	public Object.create_copy (Object o) {	
		open = o.open;
		
		if (color != null) {
			color = ((!) color).copy ();
		} else {
			color = null;
		}

		if (stroke_color != null) {
			stroke_color = ((!) stroke_color).copy ();
		} else {
			stroke_color = null;
		}

		if (gradient != null) {
			gradient = ((!) gradient).copy ();
		} else {
			gradient = null;
		}
		
		xmax = o.xmax;
		xmin = o.xmin;
		ymax = o.ymax;
		ymin = o.ymin;
		
		rotation = o.rotation;
		stroke = o.stroke;
	}
		
	public void set_open (bool open) {
		this.open = open;
	}
	
	public bool is_open () {
		return open;
	}

	public abstract void update_region_boundaries ();
	public abstract bool is_over (double x, double y);
	public abstract void draw (Context cr, Color? c = null);
	public abstract Object copy ();
	public abstract void move (double dx, double dy);
	public abstract void rotate (double theta, double xc, double yc);
	public abstract bool is_empty ();
	public abstract void resize (double ratio_x, double ratio_y);
}

}
