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

class Headline : Widget {	

	Text label;
	
	public Headline (string text) {
		label = new Text ();
		label.set_text (text);
	}
	
	public override void draw (Context cr) {
		cr.save ();
		Theme.color (cr, "Headline Background");
		cr.rectangle (0, widget_y, allocation.width, 40);
		cr.fill ();
		cr.restore ();
			
		cr.save ();
		label.set_source_rgba (1, 1, 1, 1);
		label.set_font_size (20);
		label.draw_at_baseline (cr, 21, widget_y + 25);
		cr.restore ();
	}
	
	public override double get_height () {
		return 40;
	}
	
	public override double get_width () {
		return allocation.width;
	}	
}

}
