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

/** Interface for creating drawing callbacks. */
[Compact]
[CCode (ref_function = "bird_font_drawing_ref", unref_function = "bird_font_drawing_unref")]
public class Drawing {
	
	public int iterator_refcount = 1;
		
	public Drawing () {
	}

	public void new_path (double x, double y) {
	}

	public void curve_to (double xb, double yb, double xc, double yc, double xd, double yd) {
	}

	public void close_path (double x, double y) {
	}

	public unowned Drawing @ref () {
		iterator_refcount++;
		return this;
	}
	
	public void unref () {
		if (--iterator_refcount == 0) {
			this.free ();
		}
	}
	
	private extern void free ();
}

}
