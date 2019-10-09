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

public class LicenseDialog : Dialog {
	TextArea agreement;
	Button accept;
	Button decline;
	
	double width = 0;
	double height;
	
	const double font_size = 20;
	const double margin = 20;
	
	public LicenseDialog () {
		agreement = new TextArea (font_size);
		agreement.min_width = 300;
		agreement.set_editable (false);
		agreement.draw_border = false;
		agreement.text_color = Theme.get_color ("Text Tool Box");
		agreement.set_text ("BirdFont is developed with donations, please consider donating to the project.\n\nThis is the freeware version of BirdFont. You may use it for creating fonts under the SIL Open Font License.\n\nWhich license do you want to use for your font?");
		
		decline = new Button ("Commercial License");
		decline.action.connect (() => {
			commercial ();
		});
		
		accept = new Button ("SIL Open Font License");
		accept.action.connect (() => {
			MainWindow.hide_dialog ();
			MainWindow.get_toolbox ().set_suppress_event (false);
		});
		
		MainWindow.get_toolbox ().set_suppress_event (true);
		height = 240;
	}

	public override void layout () {
		double cx = 0;
		double cy = (allocation.height - height) / 2.0;
		double center;
		double h;
		
		cx = margin;
		decline.widget_x = cx;

		cx += margin + decline.get_width ();
		accept.widget_x = cx;
		
		width = agreement.get_width () + margin;
		center = (allocation.width - width) / 2.0;
		
		agreement.widget_x = margin + center;
		agreement.widget_y = cy + margin;
		agreement.allocation = new WidgetAllocation.for_area (0, 0, 300, 450);
		agreement.layout ();
		
		h = agreement.get_height () + margin;
		
		decline.widget_x += center;
		decline.widget_y = cy + h + margin;
		
		accept.widget_x += center;
		accept.widget_y = cy + h + margin;
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

		decline.draw (cr);
		accept.draw (cr);
		agreement.draw (cr);
	}

	public override void button_press (uint button, double x, double y) {
		decline.button_press (button, x, y);
		accept.button_press (button, x, y);
	}

	public override void button_release (uint button, double x, double y) {
		decline.button_release (button, x, y);
		accept.button_release (button, x, y);
	}
	
	void commercial () {
		MessageDialog md = new MessageDialog ("You need to get a commercial copy of BirdFont. Visit to birdfont.org");
		md.close.connect (exit);		
		MainWindow.show_dialog (md);
	}
	
	static void exit () {
		MainWindow.native_window.quit ();
	}
}

}
