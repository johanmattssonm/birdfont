/*
    Copyright (C) 2013 Johan Mattsson

    This library is free software; you can redistribute it and/or modify 
    it under the terms of the GNU Lesser General Public License as 
    published by the Free Software Foundation; either version 3 of the 
    License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful, but 
    WITHOUT ANY WARRANTY; without even the implied warranty of 
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
    Lesser General Public License for more details.
*/

using Math;
using Cairo;

namespace BirdFont {

/** Move control points. */
public class PointTool : Tool {
	
	public PointTool (string name) {
		base (name, t_ ("Move control points"));

		select_action.connect ((self) => {
		});

		deselect_action.connect ((self) => {
		});
		
		press_action.connect ((self, b, x, y) => {
			Tool p = pen ();
			if (b == 1) {
				p.press_action (p, 3, x, y);
			} else if (b == 2) {
				p.press_action (p, 2, x, y);
			} else if (b == 3) {
				p.press_action (p, 1, x, y);
			}
		});
		
		double_click_action.connect ((self, b, x, y) => {
			Tool p = pen ();
			
			if (!BirdFont.android) {
				p.double_click_action (p, b, x, y);
			}
		});

		release_action.connect ((self, b, x, y) => {
			Tool p = pen ();
			if (b == 1) {
				p.release_action (p, 3, x, y);
			} else if (b == 2) {
				p.release_action (p, 2, x, y);
			} else if (b == 3) {
				p.release_action (p, 1, x, y);
			}
		});

		move_action.connect ((self, x, y) => {
			Tool p = pen ();
			p.move_action (p, x, y);
		});
		
		key_press_action.connect ((self, keyval) => {
			Tool p = pen ();
			p.key_press_action (p, keyval);
		});
		
		key_release_action.connect ((self, keyval) => {
			Tool p = pen ();
			p.key_release_action (p, keyval);
		});
		
		draw_action.connect ((tool, cairo_context, glyph) => {
			Tool p = pen ();
			p.draw_action (p, cairo_context, glyph);
		});
	}
	
	public static Tool pen () {
		return MainWindow.get_toolbox ().get_tool ("pen_tool");
	}
}

}
