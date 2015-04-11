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

using Math;
using Cairo;

namespace BirdFont {

public class OrientationTool : Tool {

	public OrientationTool (string n, string tip) {
		base (n, tip);

		select_action.connect ((self) => {
			Glyph g = MainWindow.get_current_glyph ();
			
			foreach (Path p in g.active_paths) {
				p.reverse ();
			}
		
			GlyphCanvas.redraw ();
		});

		panel_move_action.connect ((t, x, y) => {
			Glyph g = MainWindow.get_current_glyph ();
			
			if (!g.show_orientation_arrow && is_active ()) {
				g.show_orientation_arrow = true;
				GlyphCanvas.redraw ();
			}
			
			return false;
		});
		
		move_out_action.connect ((t) => {
			Glyph g = MainWindow.get_current_glyph ();
			
			if (g.show_orientation_arrow) {
				g.show_orientation_arrow = false;
				GlyphCanvas.redraw ();
			}
		});
						
		draw_action.connect ((self, cr, glyph) => {
			draw_actions (cr);
		});
	}
	
	public static void draw_actions (Context cr) {

	}
}

}
