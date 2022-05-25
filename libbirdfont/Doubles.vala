/*
	Copyright (C) 2015 2019 Johan Mattsson

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

public class Doubles : GLib.Object {
	public double* data;
	public int size = 0;
	int capacity = 10;
	
	public Doubles () {
		data = new double[capacity];
	}

	public Doubles.for_capacity (int capacity) {
		data = new double[capacity];
		this.capacity = capacity;
	}
	
	~Doubles () {
		delete data;
		data = null;
	}

	public void clear () {
		size = 0;
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
		
		data[index] = p;
	}
	
	public void insert (int index, double p) {
		insert_element (index);
		data[index] = p;
	}

	public void insert_element (int index) {
		if (capacity < size + 1) {
			increase_capacity ();
		}
		
		if (unlikely (index < 0 || index > size)) {
			warning (@"Bad index $index.");
			return;
		}
		
		double* point_data = new double[capacity];
		
		if (index > 0) {
			Posix.memcpy (point_data, data, sizeof (double) * index);
		}
		
		if (index < size) {
			int dest_position = index + 1; 
			Posix.memcpy (point_data + dest_position, data + index, sizeof (double) * (size - index));
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
	
	public void remove (int offset, int length) {
		if (unlikely (offset < 0 || offset + length > size)) {
			warning (@"Invalid offset: $offset, length: $length, size: $size");
			return;
		}
		
		for (int i = offset; i < size; i++) {
			data[i] = data[i + length];
		}
		
		size -= length;
	}
	
	void increase_capacity () {
		int new_capacity = 2 * capacity;
		double* new_data = new double[new_capacity];
		Posix.memcpy (new_data, data, sizeof (double) * size);
		delete data;
		data = new_data;
		capacity = new_capacity;		
	}

	public void add (double d) {
		if (size >= capacity) {
			increase_capacity ();
		}
		
		data[size] = d;
		size++;
	}
	
	public Doubles copy () {
		Doubles d = new Doubles ();
		delete d.data;
		d.data = new double[capacity];
		d.capacity = capacity;
		d.size = size;
		Posix.memcpy (d.data, data, sizeof (double) * size);
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
		
		return data[index];
	}

	
	public string get_string (int i) {
		return round (get_double (i));
	}
	
	public static string round (double p, int decimals = 5) {
		string v = "";
		char[] c = new char [501];
		
		v = p.format (c, @"%.$(decimals)f");
		v = v.replace (",", ".");
		
		if (v.index_of ("e") != -1) {	
			v = "0.0";
		}

		if (v.index_of ("-") == 0 && double.parse (v) == -0) {
			v = "0";
		}

		return remove_last_zeros (v);
	}
	
	public static string remove_last_zeros (string value) {	
		string v = value;
		
		if (v.index_of (".") != -1) {
			while (v.has_suffix ("0")) {
				v = v.substring (0, v.length - "0".length);
			}
			
			if (v.has_suffix (".")) {
				v = v.substring (0, v.length - ".".length);
			}
		}
		
		return v;
	}
}

}

