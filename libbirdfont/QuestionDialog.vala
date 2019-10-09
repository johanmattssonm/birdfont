/*
	Copyright (C) 2015 Johan Mattsson

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

public class QuestionDialog : Dialog {
	TextArea question;
	public Gee.ArrayList<Button> buttons;
	
	const double font_size = 20;
	const double margin = 20;
	const double margin_small = 5;
	
	double width = 300;
	double height = 0;
	
	public QuestionDialog (string message) {
		question = new TextArea (font_size);
		question.min_width = 300;
		question.min_height = font_size;
		question.set_editable (false);
		question.draw_border = false;
		question.text_color = Theme.get_color ("Text Tool Box");
		question.set_text (message);
		buttons = new Gee.ArrayList<Button> ();
	}

	public void add_button (Button button) {
		buttons.add (button);
	}

	public override void layout () {
		double cx = 0;
		double cy;
		double center;
		double h;
		
		cx = margin;
		
		foreach (Button button in buttons) {
			button.widget_x = cx;
			cx += margin + button.get_width ();
		}
		
		width = question.get_width () + margin;
		center = (allocation.width - width) / 2.0;
		
		question.widget_x = margin + center;
		question.allocation = new WidgetAllocation.for_area (0, 0, 3000, 3000);
		question.layout ();
		
		h = question.get_height () + margin;

		foreach (Button button in buttons) {
			button.widget_x += center;
		}
		
		height = h + margin + margin_small;
		
		if (buttons.size > 0) {
			height += buttons.get (0).get_height ();
		}
		
		cy = (allocation.height - height) / 2.0;

		foreach (Button button in buttons) {
			button.widget_y = cy + h + margin_small;
		}
		
		question.widget_y = cy + margin;
	}

	public override void draw (Context cr) {	
		double cx, cy;
		
		cx = (allocation.width - width) / 2.0;
		cy = (allocation.height - height) / 2.0;
		
		cr.save ();
		Theme.color (cr, "Dialog Shadow");
		cr.rectangle (0, 0, allocation.width, allocation.height);
		cr.fill ();
		cr.restore ();
		
		cr.save ();
		Theme.color (cr, "Dialog Background");
		draw_rounded_rectangle (cr, cx, cy, width, height, 10 * MainWindow.units);
		cr.fill ();
		cr.restore ();
		
		cr.save ();
		Theme.color (cr, "Button Border 4");
		cr.set_line_width (1);
		draw_rounded_rectangle (cr, cx, cy, width, height, 10 * MainWindow.units);
		cr.stroke ();
		cr.restore ();

		foreach (Button button in buttons) {
			button.draw (cr);
		}
		
		question.draw (cr);
	}

	public override void button_press (uint button, double x, double y) {
		foreach (Button b in buttons) {
			b.button_press (button, x, y);
		}
	}

	public override void button_release (uint button, double x, double y) {
		foreach (Button b in buttons) {
			b.button_release (button, x, y);
		}
	}
}

}
