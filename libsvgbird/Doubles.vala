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

namespace SvgBird {

public class Doubles : GLib.Object {
	public PointValue* data;
	public int size = 0;
	int capacity = 10;
	
	public Doubles () {
		data = new PointValue[capacity];
	}

	~Doubles () {
		delete data;
		data = null;
	}
	
	public Doubles.for_capacity (int capacity) {
		data = new PointValue[capacity];
		this.capacity = capacity;
	}
	
	void increase_capacity () {
		int new_capacity = 2 * capacity;
		PointValue* new_data = new PointValue[new_capacity];
		Posix.memcpy (new_data, data, sizeof (PointValue) * size);
		delete data;
		data = new_data;
		capacity = new_capacity;		
	}

	public void add_type (uchar type) {
		if (size >= capacity) {
			increase_capacity ();
		}

		data[size].type = type;
		size++;
	}

	public void add (double d) {
		if (size >= capacity) {
			increase_capacity ();
		}
		
		data[size].value = d;
		size++;
	}
	
	public Doubles copy () {
		Doubles d = new Doubles ();
		delete d.data;
		d.data = new double[capacity];
		d.capacity = capacity;
		d.size = size;
		Posix.memcpy (d.data, data, sizeof (PointValue) * size);
		return d;
	}
	
	public double get_double (int index) {
		if (unlikely (index < 0)) {
			warning ("index < 0");
			return 0;
		}

		if (unlikely (index >= size)) {
			warning ("index >= size");
			return 0;
		}
		
		return data[index].value;
	}
}

}

