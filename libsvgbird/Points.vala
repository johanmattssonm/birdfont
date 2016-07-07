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

namespace SvgBird {

public class Points : GLib.Object {
	public Doubles point_data = new Doubles.for_capacity (100);
	public double x = 0;
	public double y = 0;
	public bool closed = false;
	public int size {
		get {
			return point_data.size;
		}
	}
	
	public void add (double p) {
		point_data.add (p);
	}
	
	public void add_type (uchar type) {
		point_data.add_type (type);
	}

	public Points copy () {
		Points p = new Points ();
		p.point_data = point_data.copy ();
		p.x = x;
		p.y = y;
		p.closed = closed;
		return p;
	}

	public double get_double (int index) {
		return point_data.get_double (index);
	}

	public uchar get_point_type (int index) {
		return point_data.get_point_type (index);
	}
}

}

