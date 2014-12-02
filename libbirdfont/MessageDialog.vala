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

public class MessageDialog : Dialog {

	Button ok_button;
	TextArea message;
	
	public MessageDialog (string message) {
		this.message = new TextArea (20 * MainWindow.units);
		this.message.set_text (message);
		this.message.draw_border = false;
		this.message.editable = false;
		this.message.carret_is_visible = false;
		this.message.min_width = 300 * MainWindow.units;
		this.message.width = this.message.min_width;
		this.message.min_height = 20 * MainWindow.units;
		this.message.height = this.message.min_height;

		ok_button = new Button (t_("Close"));
		ok_button.action.connect (() => {
			MainWindow.hide_dialog ();
		});
	}

	public override void draw (Context cr) {	
		double cx, cy;
		double width, height;

		message.layout ();

		width = message.get_width ();
		height = message.get_height () + ok_button.get_height ();
 
		cx = (allocation.width - width) / 2.0;
		cy = (allocation.height - height) / 2.0;
		
		cr.save ();
		cr.set_source_rgba (0, 0, 0, 0.3);
		cr.rectangle (0, 0, allocation.width, allocation.height);
		cr.fill ();
		cr.restore ();
		
		cr.save ();
		cr.set_source_rgba (101 / 255.0, 108 / 255.0, 116 / 255.0, 1);
		draw_rounded_rectangle (cr, cx, cy, width, height, 10 * MainWindow.units);
		cr.fill ();
		cr.restore ();
		
		cr.save ();
		cr.set_source_rgba (0, 0, 0, 1);
		cr.set_line_width (1);
		draw_rounded_rectangle (cr, cx, cy, width, height, 10 * MainWindow.units);
		cr.stroke ();
		cr.restore ();

		message.widget_x = cx + 10 * MainWindow.units;
		message.widget_y = cy;
		message.allocation = allocation;
		message.layout ();
		message.draw (cr);
	
		ok_button.widget_x = cx + 10 * MainWindow.units;
		ok_button.widget_y = cy + message.get_height ();
		ok_button.draw (cr);
	}

	public override void button_press (uint button, double x, double y) {
		ok_button.button_press (button, x, y);
	}
}

}
