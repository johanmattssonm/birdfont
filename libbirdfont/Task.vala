/*
    Copyright (C) 2014 2015 Johan Mattsson

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

public class Task : GLib.Object {
	
	public delegate void Runnable ();
	Runnable task;
	bool cancelled = false;
	
	public Task (owned Runnable? r) {
		if (r != null) {
			task = (!) ((owned) r);
		}
	}

	public void cancel () {
		lock (cancelled) {	
			cancelled = true;
		}
	}

	public bool is_cancelled () {
		bool c;
		
		lock (cancelled) {	
			c = cancelled;
		}
		
		return c;
	}
		
	public virtual void run () {
		if (task == null) {
			warning ("No task set.");
			return;
		}
		
		task ();
	}

	public void* perform_task() {
		run ();
		return null;
	}
}

}
