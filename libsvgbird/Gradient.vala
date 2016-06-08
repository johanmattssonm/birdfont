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

namespace SvgBird {

public class Gradient : GLib.Object {
	public double x1;
	public double y1;
	public double x2;
	public double y2;

	public Gee.ArrayList<Stop> stops;
	
	public string id = "";
	public string? href = null;
	public SvgTransforms transforms;

	public Gradient () {
		x1 = 0;
		y1 = 0;
		x2 = 0;
		y2 = 0;
		stops = new Gee.ArrayList<Stop> ();
		transforms = new SvgTransforms ();
	}
	
	public Gradient copy () {
		Gradient g = new Gradient ();
		g.x1 = x1;
		g.y1 = y1;
		g.x2 = x2;
		g.y2 = y2;
		
		foreach (Stop s in stops) {
			g.stops.add (s.copy ());
		}
	
		g.id = id;
		g.href = href;	
		transforms = transforms.copy ();
		
		print (@"$(this)\n");
		
		return g;
	}
	
	public void copy_stops (Gradient g) {
		foreach (Stop stop in g.stops) {
			stops.add (stop.copy ());
		}
	}
	
	public string to_string () {
		StringBuilder description = new StringBuilder ();
		description.append (@"Gradient $(id): ");
		description.append (@"x1=$x1, y1=$y1, x2=$x2, y2=$y2");
		
		foreach (Stop stop in stops) {
			description.append (" ");
			description.append (stop.to_string ());
		}
		
		return description.str;
	}
	
	public Matrix get_matrix () {
		return transforms.get_matrix ();
	}
}

}
