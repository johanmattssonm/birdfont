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

/** Testing class for an experimental implementation of a birdfont rendering engine. */
public class TextTab : FontDisplay {

	TextArea text_area;
	TextArea text_area2;

	public TextTab () {	
		text_area = new TextArea ();
		text_area.load_font ("testfont.bf");
		text_area.set_text ("Test");

		text_area2 = new TextArea ();
		text_area2.load_font ("testfont.bf");
		text_area2.set_text ("Birdfont ÅÄÖ");
	}

	public override void draw (WidgetAllocation allocation, Context cr) {
		text_area.draw (cr, 0, 0, 200, 200, 16);
		text_area2.draw (cr, 0, 100, 200, 200, 16);
	}	
}

}
