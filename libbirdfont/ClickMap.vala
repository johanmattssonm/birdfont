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
	ImageSurface map;
	int width;
	
	public ClickMap (int width) {
		this.width = width;
		map = new Cairo.ImageSurface (Cairo.Format.ARGB32, width, width);
	}
		
	public bool get_value (int x, int y) {
		unowned uchar[] d = map.get_data ();
		bool transparent;
		
		if (unlikely (!(0 <= x < width && 0 <= y < width))) {
			warning ("Array index out of bounds.");
			return true;
		}
		
		transparent = d[y * map.get_stride () + 4 * x + 3] == 0;
				
		return !transparent;
	}
		
	public void create_click_map (Path path) {
		Context c;
				
		c = new Context (map);
		
		c.save ();
		
		c.set_source_rgba (0, 0, 0, 1);
		c.new_path ();

		path.all_of_path ((cx, cy, ct) => {
			int px = (int) (width * ((cx - path.xmin) / (path.xmax - path.xmin)));
			int py = (int) (width * ((cy - path.ymin) / (path.ymax - path.ymin)));
			
			c.line_to (px, py);
			
			return true;
		}, 2 * width);
		
		c.close_path ();
		c.fill ();
		
		c.restore ();
	}
}

}
