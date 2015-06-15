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

public class Gradient : GLib.Object {
	public double x1 = 0;
	public double y1 = 0;
	public double x2 = 0;
	public double y2 = 0;
	
	public Gee.ArrayList<Stop> stops = new Gee.ArrayList<Stop> ();
	
	public Gradient () {
	}
	
	public Gradient copy () {
		Gradient g = new Gradient ();
		g.x1 = x1;
		g.y1 = y1;
		g.x2 = x2;
		g.x2 = y2;
		
		foreach (Stop s in stops) {
			g.stops.add (s.copy ());
		}
		
		return g;
	}
}

}
