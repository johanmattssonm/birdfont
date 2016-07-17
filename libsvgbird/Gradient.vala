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
using Math;

namespace SvgBird {

public abstract class Gradient : GLib.Object {
	public Gee.ArrayList<Stop> stops;
	
	public string id = "";
	public string? href = null;
	public SvgTransforms transforms;
	public Matrix parent_matrix = Matrix.identity ();
	public Matrix view_matrix = Matrix.identity ();

	public Gradient () {
		stops = new Gee.ArrayList<Stop> ();
		transforms = new SvgTransforms ();
	}
	
	public void copy_stops (Gradient g) {
		foreach (Stop stop in g.stops) {
			stops.add (stop.copy ());
		}
	}

	public void move (double dx, double dy) {
		double x = dx;
		double y = dy;

		Matrix parent = parent_matrix;
		parent.invert ();
		parent.transform_distance (ref x, ref y);
		
		Matrix m = Matrix.identity ();
		m.translate (-x, -y);
		
		transforms.transforms.insert (0, new SvgTransform.for_matrix (m));
		transforms.collapse_transforms ();			
	}

	public Matrix get_matrix () {
		return transforms.get_matrix ();
	}
	
	public void copy_gradient (Gradient from, Gradient to) {
		foreach (Stop s in from.stops) {
			to.stops.add (s.copy ());
		}
	
		to.id = from.id;
		to.href = from.href;	
		to.transforms = from.transforms.copy ();
	
	}

	public abstract Gradient copy ();
	public abstract string to_string ();

}

}
