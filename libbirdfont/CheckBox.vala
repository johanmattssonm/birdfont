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

public class CheckBox : Widget {
	
	public bool checked = false;
	public signal void updated (bool checked);
	public double padding = 3.333 * MainWindow.units;
	
	public double w = 12 * MainWindow.units;
	public double h = 12 * MainWindow.units;
	
	public Text label;
	
	public CheckBox (string text = "", double font_size = -1) {
		if (font_size < 0) {
			font_size  = h;
		}
		
		label = new Text (text, font_size);
	}
	
	public void set_checked (bool c) {
		checked = c;
		updated (c);
	}
	
	public override double get_height () {
		return label.font_size;
	}
	
	public override double get_width () {
		return w + 2 * padding + label.get_sidebearing_extent ();
	}
	
	public override void draw (Context cr) {
		double d = w * 0.25;
		double center_y = (get_height () - (h + 2 * padding)) / 2.0 + padding;

		cr.save ();
		cr.set_source_rgba (101 / 255.0, 108 / 255.0, 116 / 255.0, 1);		
		draw_rounded_rectangle (cr, widget_x, widget_y + center_y, w, h - padding, padding);
		cr.fill ();
		cr.restore ();
		
		cr.save ();
		cr.set_line_width (1);
		draw_rounded_rectangle (cr, widget_x, widget_y + center_y, w, h - padding, padding);
		cr.stroke ();
		cr.restore ();
		
		if (checked) {
			cr.save ();
			
			cr.set_line_width (1);
			
			cr.move_to (widget_x + d, widget_y + d + center_y);
			cr.line_to (widget_x + w - d, widget_y + h - d + center_y);
			cr.stroke ();
			
			cr.move_to (widget_x + w - d, widget_y + d + center_y);
			cr.line_to (widget_x + d, widget_y + h - d + center_y);
			cr.stroke ();
			
			cr.restore ();
		}
		
		label.widget_x = widget_x + 1.5 * w;
		label.widget_y = widget_y;
		label.draw (cr);
	}
	
}

}
