/*
    Copyright (C) 2013 Johan Mattsson

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

public class PathList : GLib.Object {
	public List<Path> paths = new List<Path> ();
	
	public PathList () {
	}
	
	public void append (PathList pl) {
		foreach (Path p in pl.paths) {
			paths.append (p);
		}
	}
	
	public void clear () {
		while (paths.length () > 0) {
			paths.remove_link (paths.first ());
		}
	}
}

}
