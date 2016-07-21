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
	public bool visible = true;
	public SvgStyle style = new SvgStyle ();
	public SvgTransforms transforms = new SvgTransforms ();
	public ClipPath? clip_path = null;
	public string id = "";
	public string css_class = "";
	
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

	public const double CANVAS_MAX = 100000;
	public const double CANVAS_MIN = -100000;
	
	public Matrix view_matrix = Matrix.identity ();
	public Matrix parent_matrix = Matrix.identity ();
		
	public Object () {	
	}

	public Object.create_copy (Object o) {	
	}
	
	public virtual bool is_over (double x, double y) {
		return left <= x <= right && top <= y <= bottom; 
	}
	
	public void to_object_view (ref double x, ref double y) {
		Matrix m = view_matrix;
		m.invert ();
		m.transform_point (ref x, ref y);
	}

	public void to_parent_distance (ref double x, ref double y) {
		Matrix m = parent_matrix;
		m.invert ();
		m.transform_distance (ref x, ref y);
	}
	
	public void to_parent_view (ref double x, ref double y) {
		Matrix m = parent_matrix;
		m.invert ();
		m.transform_point (ref x, ref y);
	}
	
	public void from_object_view (ref double x, ref double y) {
		Matrix m = view_matrix;
		m.transform_point (ref x, ref y);
	}
	
	public void to_object_distance (ref double x, ref double y) {
		Matrix m = view_matrix;
		m.invert ();
		m.transform_distance (ref x, ref y);
	}
	
	public abstract void draw_outline (Context cr);

	public abstract Object copy ();
	public abstract bool is_empty ();
	
	public virtual void move (double dx, double dy) {
		Gradient g;

		left += dx;
		right += dx;
		top += dy;
		bottom += dy;

		if (style.fill_gradient != null) {
			g = (!) style.fill_gradient;
			g.move (dx, dy);
		}
		
		if (style.stroke_gradient != null) {
			g = (!) style.stroke_gradient;
			g.move (dx, dy);
		}

		to_object_distance (ref dx, ref dy);
		transforms.translate (dx, dy);
		
		update_view_matrix ();
	}
	
	public void update_view_matrix () {
		Matrix v = parent_matrix;
		Matrix m = transforms.get_matrix ();
		m.multiply (m, v);
		view_matrix = m;
	}
	
	public Matrix get_parent_matrix () {
		Matrix matrix = view_matrix;
		Matrix object_matrix = transforms.get_matrix ();
		object_matrix.invert ();
		matrix.multiply (matrix, object_matrix);
		return matrix;
	}
	
	public virtual void move_bounding_box (double dx, double dy) {
		top += dy;
		bottom += dy;
		left += dx;
		right += dx;
	}

	public static void copy_attributes (Object from, Object to) {
		to.left = from.left;
		to.right = from.right;
		to.top = from.top;
		to.bottom = from.bottom;
		
		to.visible = from.visible;
		to.style = from.style.copy ();
		to.transforms = from.transforms.copy ();
		
		if (from.clip_path != null) {
			to.clip_path = ((!) from.clip_path).copy ();
		}
	}
	
	public virtual string to_string () {
		return "Object";
	}

	public bool is_over_boundaries (double x, double y) {
		return top <= y <= bottom  && left <= x <= right;
	}

	public void paint (Context cr) {
		Color fill, stroke;
		bool need_fill = (style.fill_gradient != null || style.fill != null);
		bool need_stroke = (style.stroke_gradient != null || style.stroke != null);

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
		LinearGradient linear;
		RadialGradient radial;
		
		if (gradient != null) {
			g = (!) gradient;

			if (g is LinearGradient) {
				linear = (LinearGradient) g;
				pattern = new Cairo.Pattern.linear (linear.x1, linear.y1, linear.x2, linear.y2);
			} else if (g is RadialGradient) {
				radial = (RadialGradient) g;
				pattern = new Cairo.Pattern.radial (radial.cx, radial.cy, 0, radial.cx, radial.cy, radial.r);	
			} else {
				warning ("Unknown gradient.");
				pattern = new Cairo.Pattern.linear (0, 0, 0, 0);
			}
			
			Matrix gradient_matrix = g.get_matrix ();
			gradient_matrix.invert ();
			Matrix object_matrix = transforms.get_matrix ();
			object_matrix.invert ();
			gradient_matrix.multiply (gradient_matrix, object_matrix);
			
			pattern.set_matrix (gradient_matrix);
			
			g.parent_matrix = view_matrix;
			g.view_matrix = gradient_matrix;
			
			foreach (Stop s in g.stops) {
				Color c = s.color;
				pattern.add_color_stop_rgba (s.offset, c.r, c.g, c.b, c.a);
			}
					
			cr.set_source (pattern);
		}
	}
	
	public virtual void apply_transform (Context cr) {
		Matrix view_matrix = cr.get_matrix ();
		Matrix object_matrix = transforms.get_matrix ();
		
		object_matrix.multiply (object_matrix, view_matrix);		
		cr.set_matrix (object_matrix);
	}
	
	/** @return true if the object has an area. */
	public virtual bool update_boundaries (Context context) {
		double x0, y0, x1, y1;
		bool has_stroke = style.has_stroke ();

		apply_transform (context);
		view_matrix = context.get_matrix ();
		
		if (style.fill_gradient != null) {
			apply_gradient (context, (!) style.fill_gradient);
		}
		
		if (style.stroke_gradient != null) {
			apply_gradient (context, (!) style.stroke_gradient);
		}
		
		if (has_stroke) {
			context.set_line_width (style.stroke_width);
		} else {
			context.set_line_width (0);
		}
		
		draw_outline (context);

		context.save ();

		if (has_stroke) {
			context.stroke_extents (out x0, out y0, out x1, out y1);
		} else {
			context.fill_extents (out x0, out y0, out x1, out y1);
		}
		
		Matrix matrix = context.get_matrix ();
		matrix.transform_point (ref x0, ref y0);
		matrix.transform_point (ref x1, ref y1);

		context.fill ();
		context.restore ();

		left = x0;
		top = y0;
		right = x1;
		bottom = y1;
				
		return boundaries_width != 0;
	}

	public Matrix get_view_matrix () {
		return view_matrix;
	}

	public virtual bool update_boundaries_for_object () {
		ImageSurface surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, 1, 1);
		Context context = new Cairo.Context (surface);
		context.set_matrix (parent_matrix);
		return update_boundaries (context);
	}
}

}
