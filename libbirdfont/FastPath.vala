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

public class FastPath : Object {

	Path path;
	
	public override double stroke {
		get {
			return path.stroke;
		}

		set {
			path.stroke = value;
		}
	}

	public override double rotation {
		get {
			return path.rotation;
		}

		set {
			path.rotation = value;
		}
	}

	public override LineCap line_cap {
		get {
			return path.line_cap;
		}

		set {
			path.line_cap = value;
		}
	}

	public override bool fill {
		get {
			return path.fill;
		}

		set {
			path.fill = value;
		}
	}

	public override Color? color {
		get {
			return path.color;
		}

		set {
			path.color = value;
		}
	}

	public override Color? stroke_color {
		get {
			return path.stroke_color;
		}

		set {
			path.stroke_color = value;
		}
	}

	public override Gradient? gradient {
		get {
			return path.gradient;
		}

		set {
			path.gradient = value;
		}
	}

	public override double xmin {
		get {
			return path.xmin;
		}

		set {
			path.xmin = value;
		}
		
		default = Glyph.CANVAS_MAX;
	}

	public override double xmax {
		get {
			return path.xmax;
		}

		set {
			path.xmax = value;
		}
		
		default = Glyph.CANVAS_MIN;
	}

	public override double ymin {
		get {
			return path.ymin;
		}

		set {
			path.ymin = value;
		}
		
		default = Glyph.CANVAS_MAX;
	}

	public override double ymax {
		get {
			return path.ymax;
		}

		set {
			path.ymax = value;
		}
		
		default = Glyph.CANVAS_MIN;
	}
			
	public FastPath () {
		path = new Path ();
		update_region_boundaries ();
	}

	public FastPath.create_copy (FastPath p) {
		base.create_copy (p);
		path = p.path.copy ();
	}

	public FastPath.for_path (Path path) {
		this.path = path;
	}

	public override bool is_over (double x, double y) {
		return path.is_over (x, y);
	}
			
	public override void draw (Context cr, Color? c = null) {
		PathList path_stroke;
		Color path_color;
		bool open;
		
		cr.save ();
		
		if (c != null) {
			path_color = (!) c;
		} else if (color != null) {
			path_color = (!) color;
		} else {
			path_color = Color.black ();
		}

		if (path.stroke > 0) {
			path_stroke = path.get_stroke_fast ();
			draw_path_list (path_stroke, cr, path_color);
		} else {
			open = path.is_open ();
			
			if (open) {
				path.close ();
				path.recalculate_linear_handles ();
			}
			
			path.draw_path (cr, path_color);
			
			if (open) {
				path.reopen ();
			}
		}

		cr.restore ();
	}

	public static void draw_path_list (PathList pl, Context cr, Color? c = null) {
		foreach (Path p in pl.paths) {
			p.draw_path (cr, c);
		}
	}
		
	public override void move (double dx, double dy) {
		path.move (dx, dy);
		path.reset_stroke ();
	}
	
	public Path get_path () {
		return path;
	}

	public override void update_region_boundaries () {
		path.update_region_boundaries ();
	}

	public override void rotate (double theta, double xc, double yc) {
		path.rotate (theta, xc, yc);
	}
	
	public override bool is_empty () {
		return path.points.size == 0;
	}
	
	public override void resize (double ratio_x, double ratio_y) {
		path.resize (ratio_x, ratio_y);
		path.reset_stroke ();
	}
	
	public override Object copy () {
		return new FastPath.create_copy (this);
	}

	public override string to_string () {
		return "FastPath";
	}

}

}
