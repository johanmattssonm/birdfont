/*
	Copyright (C) 2015 2016 Johan Mattsson

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
using SvgBird;

namespace BirdFont {

public class PathObject : SvgBird.Object {

	public Path path;
	
	public override double stroke {
		get {
			return path.stroke;
		}
		
		set {
			path.stroke = value;
		}
	}


	// FIXME: flip y axis
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
		
	public PathObject () {
		base ();
		path = new Path ();
		update_region_boundaries ();
	}

	public PathObject.create_copy (PathObject p) {
		base.create_copy (p);
		path = p.path.copy ();
	}

	public PathObject.for_path (Path path) {
		base ();
		this.path = path;
	}

	public override bool is_over (double x, double y) {
		return path.is_over_coordinate (x, y);
	}
	
	public override void draw_outline (Context cr) {
		PathList pl = new PathList ();
		pl.add (path);
		draw_path_list (pl, cr);
	}

	public static void draw_path_list (PathList pl, Context cr) {
		foreach (Path p in pl.paths) {
			p.draw_path (cr);
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
	
	public override SvgBird.Object copy () {
		return new PathObject.create_copy (this);
	}

	public override string to_string () {
		return "PathObject";
	}

}

}
