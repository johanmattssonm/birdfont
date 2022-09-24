/*
	Copyright (C) 2014 2015 Johan Mattsson

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

public class SaveDialog : Dialog {
	
	SaveDialogListener listener;
	
	Text save_question;
	Button save_button;
	Button discard_button;
	Button cancel_button;
	
	double width = 0;
	double height;
	
	const double question_font_size = 23;
	
	public SaveDialog (SaveDialogListener callbacks) {
		listener = callbacks;
		
		save_question = new Text (t_("Save changes?"), question_font_size);
		
		save_button = new Button (t_("Save"));
		save_button.action.connect (() => {
			MainWindow.hide_dialog ();
			callbacks.signal_save ();
		});
		
		discard_button = new Button (t_("Discard"));
		discard_button.action.connect (() => {
			MainWindow.hide_dialog ();
			callbacks.signal_discard ();
		});
		
		cancel_button = new Button (t_("Cancel"));
		cancel_button.action.connect (() => {
			MainWindow.hide_dialog ();
			callbacks.signal_cancel ();
		});
		
		height = 90;
	}

	public override void layout () {
		double cx = 0;
		double cy = (allocation.height - height) / 2.0;
		double center;
		double qh;
		
		cx = 20;
		save_button.widget_x = cx;

		cx += 10 + save_button.get_width ();
		discard_button.widget_x = cx;

		cx += 10 + discard_button.get_width ();
		cancel_button.widget_x = cx;

		width = cx + 20 + cancel_button.get_width ();;
		
		center = (allocation.width - width) / 2.0;
		
		save_question.widget_x = save_button.widget_x + center;
		save_question.widget_y = cy + 15;
		Theme.text_color (save_question, "Text Tool Box");
		
		qh = (question_font_size + 1);
		
		save_button.widget_x += center;
		save_button.widget_y = cy + qh + 25;
		
		discard_button.widget_x += center;
		discard_button.widget_y = cy + qh + 25;
		
		cancel_button.widget_x += center;
		cancel_button.widget_y = cy + qh + 25;
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
		draw_rounded_rectangle (cr, cx, cy, width, height, 10);
		cr.fill ();
		cr.restore ();
		
		cr.save ();
		Theme.color (cr, "Button Border 4");
		cr.set_line_width (1);
		draw_rounded_rectangle (cr, cx, cy, width, height, 10);
		cr.stroke ();
		cr.restore ();

		save_question.draw (cr);
		save_button.draw (cr);
		discard_button.draw (cr);
		cancel_button.draw (cr);
	}

	public override void button_press (uint button, double x, double y) {
		save_button.button_press (button, x, y);
		discard_button.button_press (button, x, y);
		cancel_button.button_press (button, x, y);
	}

	public override void button_release (uint button, double x, double y) {
		save_button.button_release (button, x, y);
		discard_button.button_release (button, x, y);
		cancel_button.button_release (button, x, y);
	}
}

}
