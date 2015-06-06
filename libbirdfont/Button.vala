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

namespace BirdFont {

public class Button : Widget {

	Text label;
	double padding;
	double font_size;

	public signal void action ();

	public Button (string label, double margin_bottom = 0) {
		this.margin_bottom = margin_bottom;
		font_size =  17 * MainWindow.units;
		this.label = new Text (label, font_size);
		padding = 15 * MainWindow.units;
	}

	public override void draw (Context cr) {	
		cr.save ();
		Theme.color (cr, "Button Background 3");
		draw_rounded_rectangle (cr, widget_x, widget_y, get_width (), padding, padding);
		cr.fill ();
		cr.restore ();
		
		cr.save ();
		Theme.color (cr, "Button Border 3");
		cr.set_line_width (1);
		draw_rounded_rectangle (cr, widget_x, widget_y, get_width (), padding, padding);
		cr.stroke ();
		cr.restore ();

		cr.save ();
		Theme.text_color (label, "Button Foreground");
		label.draw_at_top (cr, widget_x + padding, widget_y + (2 * padding - font_size - 3 * MainWindow.units) / 2.0);
		cr.restore ();
	}

	public override double get_height () {
		return 2 * padding;	
	}

	public override double get_width () {
		return label.get_width () + 2 * padding;
	}
	
	public override void button_release (uint button, double x, double y) {
		if (is_over (x, y)) {
			action ();
		}
	}
}

}
