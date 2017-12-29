/*
	Copyright (C) 2012, 2013, 2014 2017 Johan Mattsson

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

public class CoordinateFlags : GLib.Object {
	/** TTF coordinate flags. */

	public const uint8 NONE           = 0;
	public const uint8 ON_PATH        = 1 << 0;
	public const uint8 X_SHORT_VECTOR = 1 << 1;
	public const uint8 Y_SHORT_VECTOR = 1 << 2;
	public const uint8 REPEAT         = 1 << 3;

	// same flag or short vector sign flag
	public const uint8 X_IS_SAME               = 1 << 4; 
	public const uint8 Y_IS_SAME               = 1 << 5;
	public const uint8 X_SHORT_VECTOR_POSITIVE = 1 << 4;
	public const uint8 Y_SHORT_VECTOR_POSITIVE = 1 << 5;

}

/** Data for one entry in the glyf table. */
public class GlyfData : GLib.Object {		
	public Gee.ArrayList<Path> paths = new Gee.ArrayList<Path> ();
	public Gee.ArrayList<EditPoint> points = new Gee.ArrayList<EditPoint> ();
	public Gee.ArrayList<uint16> end_points = new Gee.ArrayList<uint16> ();
	public Gee.ArrayList<uint8> flags = new Gee.ArrayList<uint8> ();
	public Gee.ArrayList<int16> coordinate_x = new Gee.ArrayList<int16> ();
	public Gee.ArrayList<int16> coordinate_y = new Gee.ArrayList<int16> ();
	
	uint16 end_point = 0;
	uint16 nflags = 0;
	
	Glyph glyph;
	
	public int16 bounding_box_xmin = 0;
	public int16 bounding_box_ymin = 0;
	public int16 bounding_box_xmax = 0;
	public int16 bounding_box_ymax = 0;
	
	private static double UNITS {
		get { return HeadTable.UNITS; }
	}
		
	public GlyfData (Glyph g) {
		PathList all_quadratic = g.get_quadratic_paths (); 
		PathList qp = new PathList ();
		
		glyph = g;
						
		int i = 0;
		foreach (Path p in all_quadratic.paths) {
			if (p.points.size < 2) {
				warning (@"Missing points, $(points.size) points in path.");
				continue;
			}

			if (likely (!is_empty (p))) {
				qp.add (p);
			} else {
				warning (@"Path number $i is empty in $(glyph.get_name ())");
			}
			
			i++;
		}

		// Add points at extrema
		add_extrema_to_path (qp);
		
		points.clear ();
		paths.clear ();
		foreach (Path p in qp.paths) {
			paths.add (p);

			foreach (EditPoint ep in p.points) {
				points.add (ep);
			}
		}
			
		if (paths.size > 0) {
			process_end_points ();
			process_flags ();
			process_x ();
			process_y (); 	
			process_bounding_box ();
		}
	}
	
	public static void add_extrema_to_path (PathList path_list) {
		double x0, y0, x1, y1, x2, y2, x3, y3;
		double minx, maxx, miny, maxy;
		Path path_minx, path_maxx, path_miny, path_maxy;
		
		path_minx = new Path ();
		path_maxx = new Path ();
		path_miny = new Path ();
		path_maxy = new Path ();
		
		minx = Glyph.CANVAS_MAX;
		miny = Glyph.CANVAS_MAX;
		maxx = Glyph.CANVAS_MIN;
		maxy = Glyph.CANVAS_MIN;
		
		x0 = 0;
		y0 = 0;	
		x1 = 0;
		y1 = 0;	
		x2 = 0;
		y2 = 0;
		x3 = 0;
		y3 = 0;
		
		foreach (Path next_path in path_list.paths) {	
			if (next_path.points.size < 2) {
				warning (@"Missing points, $(next_path.points.size) points in path.");
				continue;
			}
		
			next_path.all_of_path ((x, y) => {
				if (x < minx) {
					x0 = x;
					y0 = y;
					minx = x;
					path_minx = next_path;
				}
				
				if (x > maxx) {
					x1 = x;
					y1 = y;
					maxx = x;
					path_maxx = next_path;
				}

				if (y < miny) {
					x2 = x;
					y2 = y;
					miny = y;
					path_miny = next_path;
				}
						
				if (y > maxy) {
					x3 = x;
					y3 = y;
					maxy = y;
					path_maxy = next_path;
				}
				
				return true;
			}, 3000);
		}
		
		if (!has_extrema (path_minx, x0 + 0.001, true, true)) {
			path_minx.insert_new_point_on_path_at (x0 - 0.001, y0);
		}
		
		if (!has_extrema (path_maxx, x1 - 0.001, true, false)) {
			path_maxx.insert_new_point_on_path_at (x1 + 0.001, y1);
		}
		
		if (!has_extrema (path_maxy, y2 + 0.001, false, true)) {
			path_maxy.insert_new_point_on_path_at (x2, y2 - 0.001);
		}
		
		if (!has_extrema (path_miny, y3 - 0.001, false, false)) {
			path_miny.insert_new_point_on_path_at (x3, y3 + 0.001);
		}
	}
	
	public static bool has_extrema (Path path, double coordinate, bool x, bool min) {
		bool has_extrema = false;

		if (x && min) {
			path.all_segments ((start, stop) => {
				if (start.x < coordinate) {
					has_extrema = true;
					return false;
				}
				
				return true;
			});
		}
		
		if (x && !min) {
			path.all_segments ((start, stop) => {
				if (start.x > coordinate) {
					has_extrema = true;
					return false;
				}
				
				return true;
			});
		}
		
		if (!x && min) {
			path.all_segments ((start, stop) => {
				if (start.y < coordinate) {
					has_extrema = true;
					return false;
				}
				
				return true;
			});
		}
		
		if (!x && !min) {
			path.all_segments ((start, stop) => {
				if (start.y > coordinate) {
					has_extrema = true;
					return false;
				}
				
				return true;
			});
		}
		
		return has_extrema;
	}
	
	bool is_empty (Path p) {
		EditPoint? last = null;
		
		if (unlikely (p.points.size < 2)) {
			return true;
		}
		
		foreach (EditPoint ep in p.points) {
			if (last != null && !ep.equals ((!) last)) {
				return false;
			}
			last = ep;
		}

		return true;
	}

	public uint16 get_end_point () {
		return end_point;
	}
			
	public int16 get_ncontours () {
		return (int16) paths.size;
	}

	public uint16 get_nflags () {
		return nflags;
	}

	/** Count off curve points and on curve points.
	 * @return the number of points or uint16.MAX if more than uint16.MAX points where found. 
	 */ 
	public int get_num_points () {
		int points = 0;
		
		foreach (Path quadratic in paths) {
			points += 2 * quadratic.points.size;
			
			if (points >= uint16.MAX) {
				return uint16.MAX;			
			}
		}
		
		return points;
	}			
	
	void process_end_points () {	
		uint16 last_end_point = 0;
		PointType type;
		
		end_points.clear ();
		end_point = 0;
		
		foreach (Path quadratic in paths) {
			if (unlikely (quadratic.points.size == 0)) {
				warning (@"No points in path (before conversion $(quadratic.points.size))");
				continue;
			}
			
			if (unlikely (quadratic.points.size < 2)) {
				warning ("A path contains less than three points, it will not be exported. Path number: $path_number");
				continue;
			}
			
			foreach (EditPoint e in quadratic.points) {
				if (unlikely (nflags == uint16.MAX - 1)) {
					warning (@"Too many end points in $(glyph.get_name ())");
					break;				
				}
				
				end_point++;
				type = e.get_right_handle ().type;
				
				// off curve
				if (unlikely (nflags == uint16.MAX - 1)) {
					warning (@"Too many end points in $(glyph.get_name ())");
					break;				
				}
				
				end_point++;
			}
			end_points.add (end_point - 1);
			
			if (unlikely (end_point - 1 < last_end_point)) {
				warning (@"Next endpoint has bad value. (end_point - 1 < last_end_point)  ($(end_point - 1) < $last_end_point)");
			}
			
			last_end_point = end_point - 1;
		}
		
		if (unlikely (end_point == 0)) {
			warning (@"End point is zero for glyph $(glyph.get_name ())");
		}			
	}

	void process_flags () {
		PointType type;
		
		flags = new Gee.ArrayList<uint8> ();
		nflags = 0;
		
		foreach (Path p in paths) {
			foreach (EditPoint e in p.points) {
				flags.add (CoordinateFlags.ON_PATH);
				nflags++;
				
				type = e.get_right_handle ().type;
				
				// off curve
				flags.add (CoordinateFlags.NONE);
				
				if (unlikely (nflags == uint16.MAX)) {
					warning (@"Too many flags in $(glyph.get_name ())");
					return;				
				}	
								
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
		ttf_y = rint (y * UNITS - font.base_line * UNITS);
		return (ttf_y / UNITS) + font.base_line;
	}
	
	void process_x () {
		double prev = 0;
		double x;
		PointType type;
		
		coordinate_x.clear ();
		foreach (Path p in paths) {
			foreach (EditPoint e in p.points) {
				x = rint (e.x * UNITS - prev - glyph.left_limit * UNITS);
				coordinate_x.add ((int16) x);
				
				prev = rint (e.x * UNITS - glyph.left_limit * UNITS);
				
				type = e.get_right_handle ().type;
				
				// off curve
				x = rint (e.get_right_handle ().x * UNITS - prev - glyph.left_limit * UNITS);
				coordinate_x.add ((int16) x);
				
				prev = rint (e.get_right_handle ().x * UNITS - glyph.left_limit * UNITS);
			}
		}
	}
	
	void process_y () {
		double prev = 0;
		double y;
		Font font = OpenFontFormatWriter.get_current_font ();
		PointType type;
		int epi = 0;
		
		coordinate_y.clear ();

		int path_number = 0;		
		
		foreach (Path p in paths) {
			foreach (EditPoint e in p.points) {
				y = rint (e.y * UNITS - prev - font.base_line  * UNITS);
				coordinate_y.add ((int16) y);
				
				if ((int16) y == 0 && (int16) coordinate_x.get (coordinate_y.size - 1) == 0) {
					warning (@"Point on point in TTF. Index $(coordinate_y.size - 1) "
						+ @"Path: $path_number in $(glyph.get_name ())");
				}
				
				prev = rint (e.y * UNITS - font.base_line * UNITS);
				
				type = e.get_right_handle ().type;
				
				// off curve
				y = rint (e.get_right_handle ().y * UNITS - prev - font.base_line * UNITS);
				coordinate_y.add ((int16) y);
							
				prev = rint (e.get_right_handle ().y * UNITS - font.base_line  * UNITS);
				epi++;
			}
			
			path_number++;
		}
	}
	
	void process_bounding_box () {
		int16 last = 0;			
		int i = 0;

		bounding_box_xmin = int16.MAX;
		bounding_box_ymin = int16.MAX;
		bounding_box_xmax = int16.MIN;
		bounding_box_ymax = int16.MIN;
				
		if (coordinate_x.size == 0) {
			warning ("no points in coordinate_y");
		}
		
		foreach (int16 c in coordinate_x) {
			c += last;
	
			if (c < bounding_box_xmin) {
				bounding_box_xmin = c;
			}
			
			if (c > bounding_box_xmax) {
				bounding_box_xmax = c;
			}
			
			last = c;
			i++;
		}

		if (coordinate_y.size == 0) {
			warning ("no points in coordinate_y");
		}
		
		last = 0;
		i = 0;
		foreach (int16 c in coordinate_y) {
			c += last;
					
			if (c < bounding_box_ymin) {
				bounding_box_ymin = c;
			}
			
			if (c > bounding_box_ymax) {
				bounding_box_ymax = c;
			}
				
			last = c;
			i++;
		}
		
		printd (@"Bounding box: $bounding_box_xmin,$bounding_box_ymin  $bounding_box_xmax,$bounding_box_ymax\n");
	}
}

}

