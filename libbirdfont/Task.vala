/*
    Copyright (C) 2014 Johan Mattsson

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
	
	public Task (owned Runnable r) {
		task = (owned) r;
	}
	
	public void run () {
		task ();
	}

	public void* perform_task() {
		run ();
		return null;
	}
}

}
