/*
    Copyright (C) 2012, 2014 Johan Mattsson

    This library is free software; you can redistribute it and/or modify 
    it under the terms of the GNU Lesser General Public License as 
    published by the Free Software Foundation; either version 3 of the 
    License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful, but 
    WITHOUT ANY WARRANTY; without even the implied warranty of 
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
    Lesser General Public License for more details.
*/

namespace BirdFont {

public class Test : Object {
	public Callback callback;
	public string name;
	double time_stamp;
	bool benchmark = false;
	
	public Test.time (string name) {
		this.name = name;
		benchmark = true;
		timer_start ();
	}
	
	public Test (Callback callback, string name, bool benchmark = false) {
		this.callback = callback;
		this.name = name;
		this.time_stamp = 0;
		this.benchmark = benchmark;
	}
	
	public void timer_start () {
		time_stamp = GLib.get_real_time ();
	}
	
	public double get_time () {
		double stop_time = GLib.get_real_time ();
		return (stop_time - time_stamp) / 1000000.0;
	}
	
	public bool is_benchmark () {
		return benchmark;
	}
	
	public void print () {
		stdout.printf (get_time ());
	}
	
	public string get_time () {
		double stop_time = GLib.get_real_time ();
		return @"$name $((stop_time - start_time) / 1000000.0)s\n";
	}
}

}
