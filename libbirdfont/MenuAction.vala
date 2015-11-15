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

using Cairo;

namespace BirdFont {

public class MenuAction : GLib.Object {
	public string label;
	public signal void action (MenuAction a);
	public int index = -1;
	public bool has_delete_button = true;
	public double width = 100;
	public Text text;
	
	bool selected = false;
	
	public MenuAction (string label) {
		this.label = label;
	}
	
	public void set_selected (bool s) {
		selected = s;
	}
	
	public virtual void draw (double x, double y, Context cr) {
		if (selected) {
			cr.save ();
			Theme.color (cr, "Highlighted 1");
			cr.rectangle (x - 2, y - 12, width, 15);
			cr.fill_preserve ();
			cr.stroke ();
			cr.restore ();			
		}

		if (has_delete_button) {
			cr.save ();
			Theme.color (cr, "Foreground 1");
			cr.move_to (x + width - 10, y - 2);
			cr.line_to (x + width - 10 - 5, y - 2 - 5);
			cr.move_to (x + width - 10 - 5, y - 2);
			cr.line_to (x + width - 10, y - 2 - 5);
			cr.set_line_width (1);
			cr.stroke ();
			cr.restore ();
		}
		
		text = new Text (label);
		Theme.text_color (text, "Foreground 1");
		text.draw_at_baseline (cr, x, y);
	}
}

}
