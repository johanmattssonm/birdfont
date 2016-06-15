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

public abstract class Object : GLib.Object {
	bool open = false;
	
	public bool visible = true;
	public SvgStyle style = new SvgStyle ();
	public SvgTransforms transforms = new SvgTransforms ();
	public ClipPath? clip_path = null;
	public string id = "";
	public string css_class = "";
	
	public virtual Color? color { get; set; } // FIXME: keep this in svg style
	public virtual Color? stroke_color { get; set; }
	public virtual Gradient? gradient { get; set; }

	/** Path boundaries */
	public virtual double left { get; set; }
	public virtual double right { get; set; }
	public virtual double top { get; set; }
	public virtual double bottom { get; set; }
	
	public virtual double boundaries_height { 
		get {
			return bottom - top;
		}
	}

	public virtual double boundaries_width { 
		get {
			return right - left;
		}
	}

	/** Cartesian coordinates for the old BirdFont system. */
	public double xmax { 
		get {
			return right;
		}
		
		set {
			right = value;
		}
	}
	
	public double xmin { 
		get {
			return left;
		}
		
		set {
			left = value;
		}
	}

	public double ymin {
		get {
			return -top - boundaries_height;
		}
		
		set {
			top = boundaries_height - value;
		}
	}

	public double ymax {
		get {
			return -top;
		}
		
		set {
			top = -value;
		}
	}

	// FIXME: DELETE
	public virtual double rotation { get; set; }
	public virtual double stroke { get; set; }
	public virtual LineCap line_cap { get; set; default = LineCap.BUTT; }
	public virtual bool fill { get; set; }
	
	public const double CANVAS_MAX = 100000;
	public const double CANVAS_MIN = -100000;
	
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
	public abstract void draw_outline (Context cr);

	public abstract Object copy ();
	public abstract void move (double dx, double dy);
	public abstract void rotate (double theta, double xc, double yc);
	public abstract bool is_empty ();
	public abstract void resize (double ratio_x, double ratio_y);

	public static void copy_attributes (Object from, Object to) {
		to.open = from.open;

		if (from.color != null) {
			to.color = ((!) from.color).copy ();
		} else {
			to.color = null;
		}
		
		if (from.stroke_color != null) {
			to.stroke_color = ((!) from.stroke_color).copy ();
		} else {
			to.stroke_color = null;
		}
		
		if (to.gradient != null) {
			to.gradient = ((!) from.gradient).copy ();
		} else {
			to.gradient = null;
		}
		
		to.xmax = from.xmax;
		to.xmin = from.xmin;
		to.ymax = from.ymax;
		to.ymin = from.ymin;
		
		to.rotation = from.rotation;
		to.stroke = from.stroke;
		to.line_cap = from.line_cap;
		to.fill = from.fill;
		
		to.style = from.style.copy ();
		to.transforms = from.transforms.copy ();
		
		if (from.clip_path != null) {
			to.clip_path = ((!) from.clip_path).copy ();
		}
	}
	
	public virtual string to_string () {
		return "Object";
	}

	public void paint (Context cr) {
		Color fill, stroke;
		bool need_fill = style.fill_gradient != null || style.fill != null;
		bool need_stroke = style.stroke_gradient != null || style.stroke != null;

		cr.set_line_width (style.stroke_width);
		
		if (style.fill_gradient != null) {
			apply_gradient (cr, (!) style.fill_gradient);
		} else if (style.fill != null) {
			fill = (!) style.fill;
			cr.set_source_rgba (fill.r, fill.g, fill.b, fill.a);
		}

		if (need_fill) {
			if (need_stroke) {
				cr.fill_preserve ();
			} else {
				cr.fill ();
			}	
		}

		if (style.stroke_gradient != null) {
			apply_gradient (cr, (!) style.stroke_gradient);
		} else if (style.stroke != null) {
			stroke = (!) style.stroke;
			cr.set_source_rgba (stroke.r, stroke.g, stroke.b, stroke.a);
		}

		if (need_stroke) {
			cr.stroke ();
		}
	}
	
	public void apply_gradient (Context cr, Gradient? gradient) {
		Cairo.Pattern pattern;
		Gradient g;
		
		if (gradient != null) {
			g = (!) gradient;
			
			pattern = new Cairo.Pattern.linear (g.x1, g.y1, g.x2, g.y2);

			Matrix gradient_matrix = g.get_matrix ();
			gradient_matrix.invert ();
			pattern.set_matrix (gradient_matrix);
			
			foreach (Stop s in g.stops) {
				Color c = s.color;
				pattern.add_color_stop_rgba (s.offset, c.r, c.g, c.b, c.a);
			}
					
			cr.set_source (pattern);
		}
	}
	
	public void apply_transform (Context cr) {
		Matrix view_matrix = cr.get_matrix ();
		Matrix object_matrix = transforms.get_matrix ();
		
		object_matrix.multiply (object_matrix, view_matrix);
		cr.set_matrix (object_matrix);
	}
	
	public virtual void update_boundaries (Matrix view_matrix) {	
	}
}

}
