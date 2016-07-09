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

	public Doubles.for_capacity (int capacity) {
		data = new PointValue[capacity];
		this.capacity = capacity;
	}
	
	~Doubles () {
		delete data;
		data = null;
	}
	
	public void set_double (int index, double p) {
		if (unlikely (index < 0)) {
			warning ("index < 0");
			return;
		}

		if (unlikely (index >= size)) {
			warning ("index >= size");
			return;
		}
		
		data[index].value = p;
	}

	public void set_type (int index, uchar t) {
		if (unlikely (index < 0)) {
			warning ("index < 0");
			return;
		}

		if (unlikely (index >= size)) {
			warning ("index >= size");
			return;
		}
		
		data[index].type = t;
	}
	
	public void insert (int index, double p) {
		insert_element (index);
		data[index].value = p;
	}
	
	public void insert_type (int index, uchar p) {
		insert_element (index); 
		data[index].type = p;
	}
	
	public void insert_element (int index) {
		if (capacity < size + 1) {
			increase_capacity ();
		}
		
		if (unlikely (index < 0 || index > size)) {
			warning (@"Bad index $index.");
			return;
		}
		
		PointValue* point_data = new PointValue[capacity];
		
		if (index > 0) {
			Posix.memcpy (point_data, data, sizeof (PointValue) * index);
		}
		
		if (index < size) {
			int dest_position = index + 1; 
			Posix.memcpy (point_data + dest_position, data + index, sizeof (PointValue) * (size - index));
		}
		
		size += 1;
		delete data;
		data = point_data;
	}
	
	public void remove_first (int n) {
		if (size < n) {
			return;
		}
		
		size -= n;
		
		for (int i = 0; i < size; i++) {
			data[i] = data[i + n];
		}
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
		d.data = new PointValue[capacity];
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

	public uchar get_point_type (int index) {
		if (unlikely (index < 0)) {
			warning ("index < 0");
			return 0;
		}

		if (unlikely (index >= size)) {
			warning ("index >= size");
			return 0;
		}
		
		return data[index].type;
	}
	
	public string get_string (int i) {
		return round (get_double (i));
	}

	public static string round (double p) {
		string v = p.to_string ();
		char[] c = new char [501];
		
		v = p.format (c, "%3.5f");
		
		if (v.index_of ("e") != -1) {	
			return "0.0";
		}
		
		return v;
	}
}

}

