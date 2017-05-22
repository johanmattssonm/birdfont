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
		base (n, t_("Circle"));
				
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
		double xmin, xmax, ymin;
		
		if (move_circle) {
			circle.move (Glyph.ivz () * -dx * p, Glyph.ivz () * dy * p);
			circle.reset_stroke ();
		}
		
		if (resize_circle) {
			get_boundaries (out xmin, out xmax, out ymin);
			
			diameter = xmax - xmin;
			cx = xmin + diameter / 2;
			cy = ymin + diameter / 2;
		
			radius = Path.distance_pixels (press_x, press_y, x, y);
			ratio = 2 * radius / diameter;
			
			if (diameter * ratio > 0.5) {
				circle.resize (ratio, ratio);
			}
			
			get_boundaries (out xmin, out xmax, out ymin);
		
			diameter = xmax - xmin;
			nx = xmin + diameter / 2;
			ny = ymin + diameter / 2;
			
			circle.move (cx - nx, cy - ny);
			
			last_radius = radius;
			circle.reset_stroke ();
			circle.update_region_boundaries ();
		}
		
		last_x = x;
		last_y = y;

		GlyphCanvas.redraw ();
	}
	
	void get_boundaries (out double xmin, out double xmax, out double ymin) {
		xmin = Glyph.CANVAS_MAX;
		xmax = Glyph.CANVAS_MIN;
		ymin = Glyph.CANVAS_MAX;
		foreach (EditPoint p in circle.points) {
			if (p.x < xmin) {
				xmin = p.x;
			} 

			if (p.x > xmax) {
				xmax = p.x;
			}
			
			if (p.y < ymin) {
				ymin = p.y;
			}
		}
	}
	
	public static Path create_circle (double x, double y,
		double r, PointType pt) {	
		
		double px, py;
		Path path = new Path ();
		double steps = (pt == PointType.QUADRATIC) ? PI / 8 : PI / 4;  
		
		for (double angle = 0; angle < 2 * PI; angle += steps) {
			px = r * cos (angle) + x;
			py = r * sin (angle) + y;
			path.add (px, py);
		}
		
		path.init_point_type (pt);
		path.close ();
		path.recalculate_linear_handles ();

		for (int i = 0; i < 3; i++) {
			foreach (EditPoint ep in path.points) {
				ep.set_tie_handle (true);
				ep.process_tied_handle ();
			}
		}

		path.update_region_boundaries ();

		return path;
	}
	
	public static Path create_ellipse (double x, double y,
		double rx, double ry, PointType pt) {	
		
		double px, py;
		Path path = new Path ();
		double steps = (pt == PointType.QUADRATIC) ? PI / 8 : PI / 4;  
		
		for (double angle = 0; angle < 2 * PI; angle += steps) {
			px = rx * cos (angle) + x;
			py = ry * sin (angle) + y;
			path.add (px, py);
		}
		
		path.init_point_type (pt);
		path.close ();
		path.recalculate_linear_handles ();

		for (int i = 0; i < 3; i++) {
			foreach (EditPoint ep in path.points) {
				ep.set_tie_handle (true);
				ep.process_tied_handle ();
			}
		}

		path.update_region_boundaries ();
		
		return path;
	}
	
	void press (int button, double x, double y) {
		Glyph glyph = MainWindow.get_current_glyph ();
		Path path = new Path ();
		
		press_x = x;
		press_y = y;
		
		move_circle = (button == 3);
		resize_circle = (button == 1);
		
		if (!move_circle && !resize_circle) {
			return;
		}
		
		glyph.store_undo_state ();
		
		double px = Glyph.path_coordinate_x (x);
		double py = Glyph.path_coordinate_y (y);
		
		path = create_circle (px, py, 2, DrawingTools.point_type);

		if (StrokeTool.add_stroke) {
			path.stroke = StrokeTool.stroke_width;
			path.line_cap = StrokeTool.line_cap;
		}
			
		glyph.add_path (path);
	
		if (!PenTool.is_counter_path (circle)) {
			path.reverse  ();
		}

		circle = path;
		
		GlyphCanvas.redraw ();
	}

}

}
