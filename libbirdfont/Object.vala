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
	
	public abstract Color? color { get; set; }
	public abstract Color? stroke_color { get; set; }
	public abstract Gradient? gradient { get; set; }

	/** Path boundaries */
	public abstract double xmax { get; set; }
	public abstract double xmin { get; set; }
	public abstract double ymax { get; set; }
	public abstract double ymin { get; set; }
	
	public abstract double rotation { get; set; }
	public abstract double stroke { get; set; }
	public abstract LineCap line_cap { get; set; default = LineCap.BUTT; }
	public abstract bool fill { get; set; }
		
	public Object () {	
	}

	public Object.create_copy (Object o) {	
		open = o.open;
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
