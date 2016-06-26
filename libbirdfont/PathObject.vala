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

	public override double left { 
		get {
			return path.xmin;
		}
		
		set {
		}
	}
	
	public override double right { 
		get {
			return path.xmax;
		}
		
		set {
		}
	}

	public override double top {
		get {
			return -path.ymax;
		}
		
		set {
		}
	}

	public override double bottom {
		get {
			return -path.ymin;
		}
		
		set {
		}
	}
	
	public double stroke {
		get {
			return path.stroke;
		}
		
		set {
			path.stroke = value;
		}
	}
		
	public PathObject () {
		base ();
		path = new Path ();
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
		// drawing is handled in Glyph.draw_bird_font_paths
		
		if (path.stroke > 0) {
			//draw_path_list (path.get_completed_stroke (), cr);
			draw_path_list (path.get_stroke_fast (), cr);
		} else {
			path.draw_path (cr);
		}
	}
	
	public void draw_path (Context cr) {
		cr.save ();
		apply_transform (cr);
		
		if (path.stroke > 0) {
			draw_path_list (path.get_completed_stroke (), cr);
		} else {
			path.draw_path (cr);
		}
		
		cr.restore ();
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

	public override bool update_boundaries (Context cr) {
		if (path.points.size < 2) {
			return false;
		}
		
		return base.update_boundaries (cr);
	}

	public override bool is_empty () {
		return path.points.size == 0;
	}
	
	public override SvgBird.Object copy () {
		return new PathObject.create_copy (this);
	}

	public override string to_string () {
		return "PathObject";
	}

}

}
