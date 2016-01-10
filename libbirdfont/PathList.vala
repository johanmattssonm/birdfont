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

using SvgBird;

namespace BirdFont {

public class PathList : GLib.Object {
	public Gee.ArrayList<Path> paths;
	
	public PathList () {
		 paths = new Gee.ArrayList<Path> ();
	}
	
	public PathList.for_path (Path p) {
		 paths = new Gee.ArrayList<Path> ();
		 paths.add (p);
	}
		
	public void remove (Path p) {
		paths.remove (p);
	}
	
	public void add_unique (Path p) {
		if (paths.index_of (p) == -1) {
			paths.add (p);
		}
	}
	
	public void add (Path p) {
		paths.add (p);
	}
	
	public void append (PathList pl) {
		foreach (Path p in pl.paths) {
			paths.add (p);
		}
	}
	
	public void clear () {
		paths.clear ();
	}
	
	public Path get_first_path () {
		if (unlikely (paths.size == 0)) {
			warning ("No path");
			return new Path ();
		}
		
		return paths.get (0);
	}
	
	public Path merge_all () {
		Path p = get_first_path ();
		
		for (int i = 1; i < paths.size; i++) {
			p.append_path (paths.get (i));
		}
		
		return p;	
	}
	
	public PathList copy () {
		PathList pl = new PathList ();
		
		foreach (Path p in paths) {
			pl.add (p.copy ());
		}
		
		return pl;
	}

	public void apply_style (SvgStyle style) {
		foreach (Path p in paths) {
			if (style.has_stroke ()) {
				p.stroke = style.get_stroke_width ();
			} else {
				p.stroke = 0;
			}
			
			p.line_cap = style.get_line_cap ();
			p.reset_stroke ();
			p.update_region_boundaries ();		
		}
	}
}

}
