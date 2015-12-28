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
			
	public override void draw (Context cr) {
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
		xmax = path.xmax;
		xmin = path.xmin;
		ymax = path.ymax;
		ymin = path.ymin;	
	}

	public override void rotate (double theta, double xc, double yc) {
		path.rotate (theta, xc, yc);
		rotation += theta;
		rotation %= 2 * Math.PI;
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
}

}
