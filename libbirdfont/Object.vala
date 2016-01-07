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
	
	public bool visible = true;
	public SvgStyle style = new SvgStyle ();
	public Gee.ArrayList<SvgTransform> transforms = new Gee.ArrayList<SvgTransform> ();
	
	public virtual Color? color { get; set; } // FIXME: keep this in svg style
	public virtual Color? stroke_color { get; set; }
	public virtual Gradient? gradient { get; set; }

	/** Path boundaries */
	public virtual double xmax { get; set; }
	public virtual double xmin { get; set; }
	public virtual double ymax { get; set; }
	public virtual double ymin { get; set; }
	
	public virtual double rotation { get; set; }
	public virtual double stroke { get; set; }
	public virtual LineCap line_cap { get; set; default = LineCap.BUTT; }
	public virtual bool fill { get; set; }
		
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

	public static void copy_attributes (Object from, Object to) {
		to.open = from.open;

		to.color = from.color;
		to.stroke_color = from.stroke_color;
		to.gradient = from.gradient;
		
		to.xmax = from.xmax;
		to.xmin = from.xmin;
		to.ymax = from.ymax;
		to.ymin = from.ymin;
		
		to.rotation = from.rotation;
		to.stroke = from.stroke;
		to.line_cap = from.line_cap;
		to.fill = from.fill;	
	}
	
	public virtual string to_string () {
		return "Object";
	}

	public void fill_and_stroke (Context cr) {
		Color fill, stroke;
		
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
	}
}

}
