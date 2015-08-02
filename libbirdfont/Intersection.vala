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

public class Intersection : GLib.Object {
	public bool done = false;
	public EditPoint point;
	public EditPoint other_point;
	public Path path;
	public Path other_path;
	public bool self_intersection = false;
	
	public Intersection (EditPoint point, Path path,
		EditPoint other_point, Path other_path)  {
		
		this.point = point;
		this.path = path;
		this.other_point = other_point;
		this.other_path = other_path;
	}
	
	public Intersection.empty () {
		this.point = new EditPoint ();
		this.path = new Path ();
		this.other_point = new EditPoint ();
		this.other_path = new Path ();
	}

	public Path get_other_path (Path p) {
		if (p == path) {
			return other_path;
		}

		if (p == other_path) {
			return path;
		}
		
		warning (@"Wrong intersection.");
		return new Path ();
	}
	
	public EditPoint get_point (Path p) {
		if (p == path) {
			return point;
		}

		if (p == other_path) {
			return other_point;
		}

		warning ("Wrong intersection.");
		return new EditPoint ();
	}
	
	public EditPoint get_other_point (Path p) {
		if (p == path) {
			return other_point;
		}

		if (p == other_path) {
			return point;
		}

		warning ("Wrong intersection.");
		return new EditPoint ();
	}
	
	public string to_string () {
		return @"$(point.x), $(point.y) & $(other_point.x), $(other_point.y)";
	}
}

public class IntersectionList : GLib.Object {
	public Gee.ArrayList<Intersection> points = new Gee.ArrayList<Intersection> ();
	
	public IntersectionList () {
	}

	public Intersection get_point (EditPoint ep, out bool other) {
		other = false;
		foreach (Intersection i in points) {
			if (i.other_point == ep || i.point == ep) {
				other = (i.other_point == ep);
				return i;
			}	
		}
		
		warning ("No intersection found for point.");
		return new Intersection.empty ();
	}
}

}
