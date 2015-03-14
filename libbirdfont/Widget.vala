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

using Cairo;
using Math;

namespace BirdFont {

public abstract class Widget : GLib.Object {

	public double margin_bottom = 0;
	public double widget_x = 0;
	public double widget_y = 0;

	public abstract double get_height ();
	public abstract double get_width ();
	public abstract void draw (Context cr);
	
	public WidgetAllocation allocation = new WidgetAllocation ();

	public static void draw_rounded_rectangle (Context cr, double x, double y, double w, double h, double radius) {	
		// fixme radius is padding not margin
		cr.move_to (x, y + radius);
		cr.arc (x + radius, y + radius, radius, 2 * (PI / 2), 3 * (PI / 2));
		cr.line_to (x + w - radius, y);
		cr.arc (x + w - radius, y + radius, radius, 3 * (PI / 2), 4 * (PI / 2));
		cr.line_to (x + w, y + h);		
		cr.arc (x + w - radius, y + h, radius, 4 * (PI / 2), 5 * (PI / 2));
		cr.line_to (x + radius, y + h + radius);
		cr.arc (x + radius, y + h, radius, 5 * (PI / 2), 6 * (PI / 2));
		cr.line_to (x, y + radius);
		cr.close_path ();			
	}

	public bool is_over (double x, double y) {
		return widget_x <= x <= widget_x + get_width () 
			&&  widget_y <= y <= widget_y + get_height ();
	}
	
	public bool is_on_screen () {
		return (widget_y <= 0 <= widget_y + get_height ())
			|| (widget_y <= allocation.height <= widget_y + get_height ())
			|| (0 <= widget_y <= allocation.height);
	}
}

}
