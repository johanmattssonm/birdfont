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

using Math;
using Cairo;

namespace BirdFont {

public class RectangleTool : Tool {

	Path rectangle = new Path ();

	double press_x = -1;
	double press_y = -1;
	
	bool resize = false;
	
	public RectangleTool (string n) {
		base (n, _("Rectangle"));

		press_action.connect((self, b, x, y) => {
			press (b, x, y);
		});

		release_action.connect((self, b, x, y) => {
			press_x = -1;
			press_y = -1;
			rectangle = new Path ();
			resize = false;
		});
		
		move_action.connect ((self, x, y)	 => {
			move (x, y);
		});
	}
	
	void move (double x, double y) {
		Glyph g;
		double x1, y1, x2, y2;

		if (resize) {
			g = MainWindow.get_current_glyph ();
			g.delete_path (rectangle);
			
			rectangle = new Path ();
			
			x1 = Glyph.path_coordinate_x (press_x); 
			y1 = Glyph.path_coordinate_y (press_y);
			x2 = Glyph.path_coordinate_x (x); 
			y2 = Glyph.path_coordinate_y (y);

			if (GridTool.is_visible ()) {
				GridTool.tie_coordinate (ref x1, ref y1);
				GridTool.tie_coordinate (ref x2, ref y2);
			}
					
			rectangle.add (x1, y1);
			rectangle.add (x2, y1);
			rectangle.add (x2, y2);
			rectangle.add (x1, y2);

			rectangle.init_point_type ();
			rectangle.close ();
			
			g.add_path (rectangle);
			
			foreach (EditPoint e in rectangle.points) {
				e.recalculate_linear_handles ();
			}
			
			MainWindow.get_glyph_canvas ().redraw ();
		}
	}
	
	void press (int button, double x, double y) {
		press_x = x;
		press_y = y;
		resize = true;
		
		GlyphCanvas.redraw ();
	}
}

}
