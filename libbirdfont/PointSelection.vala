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

using Math;
using Cairo;

namespace BirdFont {

/** One selected point and its path. */
public class PointSelection : GLib.Object {

	public EditPointHandle handle;
	public EditPoint point;
	public Path path;

	public PointSelection (EditPoint ep, Path p) {
		path = p;
		point = ep;
		handle = new EditPointHandle.empty ();
	}

	public PointSelection.handle_selection (EditPointHandle h, Path p) {
		path = p;
		point = new EditPoint ();
		handle = h;
	}
	
	public PointSelection.empty () {
		path = new Path ();
		point = new EditPoint ();
		handle = new EditPointHandle.empty ();
	}
	
	/** @return true if this point is the first point in the path. */
	public bool is_first () {
		return_val_if_fail (path.points.size > 0, false);
		return path.points.get (0) == point;
	}

	/** @return true if this point is the last point in the path. */
	public bool is_last () {
		return_val_if_fail (path.points.size > 0, false);
		return path.points.get (path.points.size - 1) == point;
	}
	
	public bool is_endpoint () {
		return is_first () || is_last ();
	}
}

}
