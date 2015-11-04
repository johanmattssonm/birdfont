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

public class OverwriteDialog : Dialog {
	
	OverWriteDialogListener listener;
	
	Text question;
	Button overwrite_button;
	Button cancel_button;
	Button dont_ask_again_button;
	
	double width = 0;
	double height;
	
	static const double question_font_size = 23;
	
	public OverwriteDialog (OverWriteDialogListener callbacks) {
		double font_size = question_font_size * MainWindow.units;
		
		listener = callbacks;
		
		question = new Text (callbacks.message, font_size);
		
		overwrite_button = new Button (callbacks.message);
		overwrite_button.action.connect (() => {
			MainWindow.hide_dialog ();
			callbacks.overwrite ();
		});
		
		cancel_button = new Button (callbacks.cancel_message);
		cancel_button.action.connect (() => {
			MainWindow.hide_dialog ();
			callbacks.cancel ();
		});
		
		dont_ask_again_button = new Button (callbacks.dont_ask_again_message);
		dont_ask_again_button.action.connect (() => {
			MainWindow.hide_dialog ();
			callbacks.overwrite_dont_ask_again ();
		});
		
		height = 90 * MainWindow.units;
	}

	public override void layout () {
		double cx = 0;
		double cy = (allocation.height - height) / 2.0;
		double center;
		double qh;
			
		cx = 20 * MainWindow.units;
		overwrite_button.widget_x = cx;

		cx += 10 * MainWindow.units + overwrite_button.get_width ();
		cancel_button.widget_x = cx;

		cx += 10 * MainWindow.units + cancel_button.get_width ();
		dont_ask_again_button.widget_x = cx;

		width = cx + 20 * MainWindow.units + dont_ask_again_button.get_width ();
		
		center = (allocation.width - width) / 2.0;
		
		question.widget_x = overwrite_button.widget_x + center;
		question.widget_y = cy + 15 * MainWindow.units;
		Theme.text_color (question, "Text Tool Box");
		
		qh = (question_font_size + 1) * MainWindow.units;
		
		overwrite_button.widget_x += center;
		overwrite_button.widget_y = cy + qh + 25 * MainWindow.units;
		
		cancel_button.widget_x += center;
		cancel_button.widget_y = cy + qh + 25 * MainWindow.units;
		
		dont_ask_again_button.widget_x += center;
		dont_ask_again_button.widget_y = cy + qh + 25 * MainWindow.units;
	}

	public override void draw (Context cr) {	
		double cx, cy;
		
		layout ();

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

		question.draw (cr);
		overwrite_button.draw (cr);
		cancel_button.draw (cr);
		dont_ask_again_button.draw (cr);
	}

	public override void button_press (uint button, double x, double y) {
		overwrite_button.button_press (button, x, y);
		cancel_button.button_press (button, x, y);
		dont_ask_again_button.button_press (button, x, y);
	}

	public override void button_release (uint button, double x, double y) {
		overwrite_button.button_release (button, x, y);
		cancel_button.button_release (button, x, y);
		dont_ask_again_button.button_release (button, x, y);
	}
}

}
