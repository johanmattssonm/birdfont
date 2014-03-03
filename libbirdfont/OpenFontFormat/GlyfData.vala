/*
    Copyright (C) 2012, 2013 Johan Mattsson

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

namespace BirdFont {

class Coordinate {
	/** TTF coordinate flags. */

	public static const uint8 NONE           = 0;
	public static const uint8 ON_PATH        = 1 << 0;
	public static const uint8 X_SHORT_VECTOR = 1 << 1;
	public static const uint8 Y_SHORT_VECTOR = 1 << 2;
	public static const uint8 REPEAT         = 1 << 3;

	// same flag or short vector sign flag
	public static const uint8 X_IS_SAME               = 1 << 4; 
	public static const uint8 Y_IS_SAME               = 1 << 5;
	public static const uint8 X_SHORT_VECTOR_POSITIVE = 1 << 4;
	public static const uint8 Y_SHORT_VECTOR_POSITIVE = 1 << 5;

}

/** Data for one entry in the glyf table. */
class GlyfData : GLib.Object {		
	public List<Path> paths = new List<Path> ();
	public List<uint16> end_points = new List<uint16> ();
	public List<uint8> flags = new List<uint8> ();
	public List<int16> coordinate_x = new List<int16> ();
	public List<int16> coordinate_y = new List<int16> ();
	
	uint16 end_point = 0;
	int16 nflags = 0;
	
	Glyph glyph;
	
	public int16 bounding_box_xmin = 0;
	public int16 bounding_box_ymin = 0;
	public int16 bounding_box_xmax = 0;
	public int16 bounding_box_ymax = 0;
	
	private static double UNITS {
		get { return HeadTable.UNITS; }
	}
		
	public GlyfData (Glyph g) {	
		Path q;
		
		glyph = g;
		
		foreach (Path p in g.path_list) {
			q = p.get_quadratic_points ();
			
			if (q.points.length () < 2) {
				warning (@"A path in $(g.get_name ()) contains less than three points, it will not be exported.");
			} else {
				paths.append (q);
			}
		}
		
		process_end_points ();
		process_flags ();
		process_x ();
		process_y ();
		process_bounding_box ();			
	}

	public uint16 get_end_point () {
		return end_point;
	}
			
	public int16 get_ncontours () {
		return (int16) paths.length ();
	}

	public int16 get_nflags () {
		return nflags;
	}
	
	void process_end_points () {	
		uint16 last_end_point = 0;
		PointType type;
		
		end_point = 0;
		
		foreach (Path quadratic in paths) {
			if (quadratic.points.length () == 0) {
				warning (@"No points in path (before conversion $(quadratic.points.length ()))");
				continue;
			}
			
			if (quadratic.points.length () < 2) {
				warning ("A path contains less than three points, it will not be exported.");
				continue;
			}
			
			foreach (EditPoint e in quadratic.points) {
				end_point++;
				type = e.get_right_handle ().type;
				
				// off curve
				end_point++;
				
				if (end_point == 0xFFFF) {
					warning ("Too many points");
				}
			}
			end_points.append (end_point - 1);
			
			if (end_point - 1 < last_end_point) {
				warning (@"Next endpoint has bad value. (end_point - 1 < last_end_point)  ($(end_point - 1) < $last_end_point)");
			}
			
			last_end_point = end_point - 1;
		}
		
		if (end_point == 0) {
			warning ("End point is zero");
		}			
	}

	void process_flags () {
		PointType type;
		
		flags = new List<uint8> ();
		nflags = 0;
		
		foreach (Path p in paths) {
			foreach (EditPoint e in p.points) {
				flags.append (Coordinate.ON_PATH);
				nflags++;
				
				type = e.get_right_handle ().type;
				
				// off curve
				flags.append (Coordinate.NONE);
				nflags++;
			}
		}
	}
	
	public static double tie_to_ttf_grid_x (Glyph glyph, double x) {
		double ttf_x;
		ttf_x = rint (x * UNITS - glyph.left_limit * UNITS);
		return (ttf_x / UNITS) + glyph.left_limit;
	}

	public static double tie_to_ttf_grid_y (Font font, double y) {
		double ttf_y;
		ttf_y = rint (y * UNITS  + font.base_line * UNITS);
		return (ttf_y / UNITS) - font.base_line;
	}
	
	void process_x () {
		double prev = 0;
		double x;
		PointType type;
		
		foreach (Path p in paths) {
			foreach (EditPoint e in p.points) {
				x = rint (e.x * UNITS - prev - glyph.left_limit * UNITS);
				coordinate_x.append ((int16) x);
				
				prev = rint (e.x * UNITS - glyph.left_limit * UNITS);
				
				type = e.get_right_handle ().type;
				
				// off curve
				x = rint (e.get_right_handle ().x () * UNITS - prev - glyph.left_limit * UNITS);
				coordinate_x.append ((int16) x);
				
				prev = rint (e.get_right_handle ().x () * UNITS - glyph.left_limit * UNITS);
			}
		}
	}
	
	void process_y () {
		double prev = 0;
		double y;
		Font font = OpenFontFormatWriter.get_current_font ();
		PointType type;
		
		foreach (Path p in paths) {
			foreach (EditPoint e in p.points) {
				y = rint (e.y * UNITS - prev + font.base_line  * UNITS);
				coordinate_y.append ((int16) y);
				
				prev = rint (e.y * UNITS + font.base_line * UNITS);
				
				type = e.get_right_handle ().type;
				
				// off curve
				y = rint (e.get_right_handle ().y () * UNITS - prev + font.base_line * UNITS);
				coordinate_y.append ((int16) y);
			
				prev = rint (e.get_right_handle ().y () * UNITS + font.base_line  * UNITS);
			}
		}
	}
	
	void process_bounding_box () {
		int16 last = 0;			
		int i = 0;

		bounding_box_xmin = int16.MAX;
		bounding_box_ymin = int16.MAX;
		bounding_box_xmax = int16.MIN;
		bounding_box_ymax = int16.MIN;
				
		if (coordinate_x.length () == 0) {
			warning ("no points in coordinate_y");
		}
		
		foreach (int16 c in coordinate_x) {
			c += last;
			
			// Only on curve points are good for calculating bounding box
			if ((flags.nth (i).data & Coordinate.ON_PATH) > 0) { 
				if (c < bounding_box_xmin) bounding_box_xmin = c;
				if (c > bounding_box_xmax) bounding_box_xmax = c;
			}
				
			last = c;
			i++;
		}

		if (coordinate_y.length () == 0) {
			warning ("no points in coordinate_y");
		}
		
		last = 0;
		i = 0;
		foreach (int16 c in coordinate_y) {
			c += last;
			
			if ((flags.nth (i).data & Coordinate.ON_PATH) > 0) {
				if (c < bounding_box_ymin) bounding_box_ymin = c;
				if (c > bounding_box_ymax) bounding_box_ymax = c;			
			}
			
			last = c;
			i++;
		}
		
		printd (@"Bounding box: $bounding_box_xmin,$bounding_box_ymin  $bounding_box_xmax,$bounding_box_ymax\n");
	}
}

}
