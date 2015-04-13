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

	double time = 0;
	bool count_down = false;
	
	public OrientationTool (string n, string tip) {
		base (n, tip);

		select_action.connect ((self) => {
			Glyph g = MainWindow.get_current_glyph ();
			
			foreach (Path p in g.active_paths) {
				p.reverse ();
			}

			if (!Glyph.show_orientation_arrow && is_active ()) {
				count_down = true;
				Glyph.show_orientation_arrow = true;
				Glyph.orientation_arrow_opacity = 1;
				time = 10;
				fade_out ();
				GlyphCanvas.redraw ();
			}

			GlyphCanvas.redraw ();
		});
	}
	
	public void fade_out () {
			TimeoutSource timer = new TimeoutSource (100);
			timer.set_callback (() => {
				if (count_down) {
					if (time <= 0) {
						Glyph.show_orientation_arrow = false;
						count_down = false;
					}
					
					if (time < 1) {
						Glyph.orientation_arrow_opacity = time;
						GlyphCanvas.redraw ();
					}
					
					time -= 0.1;
				} else {
					Glyph.show_orientation_arrow = false;
				}
				
				return count_down;
			});
			timer.attach (null);
	}
}

}
