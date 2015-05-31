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

class ZoomView : GLib.Object {
	public double x;
	public double y;
	public double zoom;
	public WidgetAllocation allocation;
	
	public ZoomView (double x, double y, double zoom, WidgetAllocation allocation) {
		this.x = x;
		this.y = y;
		this.zoom = zoom;
		this.allocation = allocation;
	}
	
	public string to_string () {
		return @"x: $(x), y: $y, zoom: $zoom\n" + allocation.to_string ();
	}
}

}
