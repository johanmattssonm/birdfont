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

public class CircleTool : Tool {

	Path circle = new Path ();

	double press_x = -1;
	double press_y = -1;
	
	double last_x = -1;
	double last_y = -1;
	
	double last_radius = 2;
	
	bool move_circle = false;
	bool resize_circle = false;
	
	public CircleTool (string n) {
		base (n, _("Circle"));
				
		press_action.connect((self, b, x, y) => {
			press (b, x, y);
		});

		release_action.connect((self, b, x, y) => {
			press_x = -1;
			press_y = -1;
			circle = new Path ();
		});
		
		move_action.connect ((self, x, y)	 => {
			move (x, y);
		});
	}
	
	void move (double x, double y) {
		double dx = last_x - x;
		double dy = last_y - y; 
		double p = PenTool.precision;
		double ratio, diameter, radius, cx, cy, nx, ny;
		
		if (move_circle) {
			circle.move (Glyph.ivz () * -dx * p, Glyph.ivz () * dy * p);
		}
		
		if (resize_circle) {
			circle.update_region_boundries ();
			diameter = circle.xmax - circle.xmin;
			cx = circle.xmin + diameter / 2;
			cy = circle.ymin + diameter / 2;
		
			radius = Path.distance_pixels (press_x, press_y, x, y);
			ratio = 2 * radius / diameter;
			
			if (diameter * ratio > 0.5) {
				circle.resize (ratio);
			}
			
			diameter = circle.xmax - circle.xmin;
			nx = circle.xmin + diameter / 2;
			ny = circle.ymin + diameter / 2;
			
			circle.update_region_boundries ();
			circle.move (cx - nx, cy - ny);
			
			last_radius = radius;
		}
		
		last_x = x;
		last_y = y;

		MainWindow.get_glyph_canvas ().redraw ();
	}
	
	void press (int button, double x, double y) {
		Glyph glyph = MainWindow.get_current_glyph ();
		double radius = 2;
		double px, py, steps;
		Path path = new Path ();
		
		press_x = x;
		press_y = y;
		
		move_circle = (button == 1);
		resize_circle = (button == 3);
		
		if (!move_circle && !resize_circle) {
			return;
		}
		
		glyph.store_undo_state ();
		
		steps = (DrawingTools.point_type == PointType.QUADRATIC) ? PI / 8 : PI / 4;  
		
		for (double angle = 0; angle < 2 * PI; angle += steps) {
			px = radius * cos (angle) + Glyph.path_coordinate_x (x);
			py = radius * sin (angle) + Glyph.path_coordinate_y (y);
			path.add (px, py);
		}
		
		path.init_point_type ();
		path.close ();
		path.recalculate_linear_handles ();

		for (int i = 0; i < 3; i++) {
			foreach (EditPoint ep in path.points) {
				ep.set_tie_handle (true);
				ep.process_tied_handle ();
			}
		}
	
		glyph.add_path (path);
	
		if (!PenTool.is_counter_path (circle)) {
			path.reverse  ();
		}

		circle = path;
		
		MainWindow.get_glyph_canvas ().redraw ();
	}

}

}
