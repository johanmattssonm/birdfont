/*
    Copyright (C) 2012 Johan Mattsson

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

public class WidgetAllocation : GLib.Object {
	public int width = 0;
	public int height = 0;
	public int x = 0;
	public int y = 0;
	
	public WidgetAllocation () {
	}
	
	public WidgetAllocation.for_area (int x, int y, int width, int height) {
		this.x = x;
		this.y = y;
		this.width = width;
		this.height = height;
	}
	
	public WidgetAllocation copy () {
		WidgetAllocation w = new WidgetAllocation ();
		w.x = x;
		w.y = y;
		w.width = width;
		w.height = height;
		return w;
	}
	
	public string to_string () {
		return @"x: $x, y: $y, width: $width, height: $height\n";
	}
}

}
