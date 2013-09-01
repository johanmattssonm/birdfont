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
}

}
