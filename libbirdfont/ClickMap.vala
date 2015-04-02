/*
    Copyright (C) 2014 2015 Johan Mattsson

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

public class ClickMap : GLib.Object {
	public ImageSurface map;
	public int width;
	
	public double xmax;
	public double ymax;
	public double xmin;
	public double ymin;
		
	public ClickMap (int width) {
		this.width = width;
		map = new Cairo.ImageSurface (Cairo.Format.ARGB32, width, width);
		xmax = 0;
		ymax = 0;
		xmin = 0;
		ymin = 0;
	}
		
	public bool get_value (int x, int y) {
		unowned uchar[] d = map.get_data ();
		bool transparent;

		Context c;
		
		c = new Context (map);
		c.set_fill_rule (Cairo.FillRule.WINDING);
		
		if (unlikely (!(0 <= x < width && 0 <= y < width))) {
			warning (@"Array index out of bounds. x: $x  y: $y size: $width");
			return true;
		}
		
		transparent = d[y * map.get_stride () + 4 * x + 3] == 0;
		
		return !transparent;
	}
	
	bool add_point (Context c, double cx, double cy) {
		int px = (int) (width * ((cx - xmin) / (xmax - xmin)));
		int py = (int) (width * ((cy - ymin) / (ymax - ymin)));
		c.line_to (px, py);
		return true;
	}
	
	public void create_click_map (Path path, Path? counter = null) { // FIXME: clean up
		Path p;
		Context c;
		
		c = new Context (map);
		
		if (counter == null) {
			xmax = path.xmax;
			ymax = path.ymax;
			xmin = path.xmin;
			ymin = path.ymin;
		} else {
			p = (!) counter;
			
			xmax = fmax (p.xmax, path.xmax);
			ymax = fmax (p.ymax, path.ymax);
			xmin = fmin (p.xmin, path.xmin);
			ymin = fmin (p.ymin, path.ymin);
		}
		
		c.save ();
		c.set_fill_rule (FillRule.EVEN_ODD);
		c.set_source_rgba (0, 0, 0, 1);
		c.new_path ();
		path.all_of_path ((cx, cy) => {
			add_point (c, cx, cy);
			return true;
		}, 2 * width);
		c.close_path ();	
		
		if (counter != null) {
			c.new_path ();
		
			p = (!) counter;
			p.all_of_path ((cx, cy) => {
				add_point (c, cx, cy);
				return true;
			}, 2 * width);
			
			c.close_path ();
		}
		
		c.fill ();
		c.restore ();
	}  
}

static double fmin (double a, double b) {
	return a < b ? a : b;
}

static double fmax (double a, double b) {
	return a > b ? a : b;
}
	
}
