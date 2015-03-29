/*
    Copyright (C) 2014 Johan Mattsson

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
using Math;

namespace BirdFont {

public class StrokeTool : Tool {
	
	public StrokeTool (string tooltip) {
		select_action.connect((self) => {
			stroke_selected_paths ();
		});
	}
	
	public static void set_stroke_for_selected_paths (double width) {
		Glyph g = MainWindow.get_current_glyph ();
		
		foreach (Path p in g.active_paths) {
			p.set_stroke (width);
		}
		
		GlyphCanvas.redraw ();
	}

	/** Create strokes for the selected outlines. */
	void stroke_selected_paths () {
		Glyph g = MainWindow.get_current_glyph ();
		PathList paths = new PathList ();
		
		foreach (Path p in g.active_paths) {
			paths.append (get_stroke (p, p.stroke));
		}
		
		foreach (Path np in paths.paths) {
			g.add_path (np);
		}
	}
	
	public static PathList get_stroke (Path path, double thickness) {
		Path p = path.copy ();
		PathList pl;

		pl = get_stroke_outline (p, thickness);	
		
		return pl;	
	}
	
	public static PathList get_stroke_outline (Path p, double thickness) {
		Path counter, outline, merged;
		PathList paths = new PathList ();
				
		if (!p.is_open () && p.is_filled ()) {
			outline = create_stroke (p, thickness);
			outline.close ();
			paths.add (outline);
			outline.update_region_boundaries ();
		} else if (!p.is_open () && !p.is_filled ()) {
			outline = create_stroke (p, thickness);
			counter = create_stroke (p, -1 * thickness);
			
			paths.add (outline);
			paths.add (counter);
			
			if (p.is_clockwise ()) {
				outline.force_direction (Direction.CLOCKWISE);
			} else {
				outline.force_direction (Direction.COUNTER_CLOCKWISE);
			}
			
			if (outline.is_clockwise ()) {
				counter.force_direction (Direction.COUNTER_CLOCKWISE);
			} else {
				counter.force_direction (Direction.CLOCKWISE);
			}
			
			outline.update_region_boundaries ();
			counter.update_region_boundaries ();
		} else if (p.is_open ()) {
			outline = create_stroke (p, thickness);
			counter = create_stroke (p, -1 * thickness);
			merged = merge_strokes (p, outline, counter, thickness);
			
			if (p.is_clockwise ()) {
				merged.force_direction (Direction.CLOCKWISE);
			} else {
				merged.force_direction (Direction.COUNTER_CLOCKWISE);
			}
			
			merged.update_region_boundaries ();
			paths.add (merged);
		} else {
			warning ("Can not create stroke.");
			paths.add (p);
		}

		return paths;
	}
	
	/** Create one stroke from the outline and counter stroke and close the 
	 * open endings.
	 * 
	 * @param path the path to create stroke for
	 * @param stroke for the outline of path
	 * @param stroke for the counter path
	 */
	static Path merge_strokes (Path path, Path stroke, Path counter, double thickness) {
		Path merged;
		EditPoint corner1, corner2;
		EditPoint corner3, corner4;
		EditPoint end;
		double angle;
		
		if (path.points.size < 2) {
			warning ("Missing points.");
			return stroke;
		}
		
		if (stroke.points.size < 4) {
			warning ("Missing points.");
			return stroke;
		}

		if (counter.points.size < 4) {
			warning ("Missing points.");
			return stroke;
		}
				
		// end of stroke
		end = path.get_last_visible_point ();
		corner1 = stroke.get_last_point ();
		angle = end.get_left_handle ().angle;
		corner1.x = end.x + cos (angle - PI / 2) * thickness;
		corner1.y = end.y + sin (angle - PI / 2) * thickness;		

		corner2 = counter.get_last_point ();
		corner2.x = end.x + cos (angle + PI / 2) * thickness;
		corner2.y = end.y + sin (angle + PI / 2) * thickness;

		// the other end
		end = path.get_first_point ();
		corner3 = stroke.get_first_point ();
		angle = end.get_right_handle ().angle;
		corner3.x = end.x + cos (angle + PI / 2) * thickness;
		corner3.y = end.y + sin (angle + PI / 2) * thickness;		

		corner4 = counter.get_first_point ();
		corner4.x = end.x + cos (angle - PI / 2) * thickness;
		corner4.y = end.y + sin (angle - PI / 2) * thickness;
		
		corner1.get_left_handle ().convert_to_line ();
		corner2.get_right_handle ().convert_to_line ();
		
		corner3.get_left_handle ().convert_to_line ();
		corner4.get_right_handle ().convert_to_line ();
				
		counter.reverse ();

		// Append the other part of the stroke
		merged = stroke.copy ();
		merged.append_path (counter);
		corner2 = merged.points.get (merged.points.size - 1);
		
		merged.close ();
		merged.create_list ();
		merged.recalculate_linear_handles ();
						
		return merged;
	}
	
	static Path create_stroke (Path p, double thickness) {
		Path stroked;
		
		if (p.points.size >= 2) {
			stroked = p.copy ();
			stroked = generate_stroke (stroked, thickness);

			if (!p.is_open ()) {
				stroked.reverse ();
				stroked.close ();
			}
		} else {
			// TODO: create stroke for a path with one point
			warning ("One point.");
			stroked = new Path ();
		}
		
		return stroked;
	}

	static Path generate_stroke (Path p, double thickness) {
		Path stroked = new Path ();
		EditPoint start;
		EditPoint end;
		EditPoint previous = new EditPoint ();
		
		foreach (EditPoint ep in p.points) {	
			start = ep.copy ();
			end = ep.get_next ().copy ();

			move_segment (start, end, thickness);

			add_corner (stroked, previous, start);
			
			stroked.add_point (start);
			stroked.add_point (end);

			// line ends around corner
			start.get_left_handle ().convert_to_line (); 
			end.get_right_handle ().convert_to_line ();
			
			previous = end;
		}
		stroked.recalculate_linear_handles ();
		
		return stroked;
	}

	static void move_segment (EditPoint stroke_start, EditPoint stroke_stop, double thickness) {
		EditPointHandle r, l;
		double m, n;
		double qx, qy;
		
		stroke_start.set_tie_handle (false);
		stroke_stop.set_tie_handle (false);

		r = stroke_start.get_right_handle ();
		l = stroke_stop.get_left_handle ();
		
		m = cos (r.angle + PI / 2) * thickness;
		n = sin (r.angle + PI / 2) * thickness;
		
		stroke_start.get_right_handle ().move_to_coordinate_delta (m, n);
		stroke_start.get_left_handle ().move_to_coordinate_delta (m, n);
		
		stroke_start.independent_x += m;
		stroke_start.independent_y += n;
		
		qx = cos (l.angle - PI / 2) * thickness;
		qy = sin (l.angle - PI / 2) * thickness;

		stroke_stop.get_right_handle ().move_to_coordinate_delta (qx, qy);
		stroke_stop.get_left_handle ().move_to_coordinate_delta (qx, qy);
		
		stroke_stop.independent_x += qx;
		stroke_stop.independent_y += qy;
	}

	static void add_corner (Path stroked, EditPoint previous, EditPoint next) {
		EditPoint corner;
		double corner_x, corner_y;
		EditPointHandle previous_handle;
		EditPointHandle next_handle;
		
		previous_handle = previous.get_left_handle ();
		next_handle = next.get_right_handle ();
		
		previous_handle.angle += PI;
		next_handle.angle += PI;
		
		Path.find_intersection_handle (previous_handle, next_handle, out corner_x, out corner_y);
		corner = new EditPoint (corner_x, corner_y, PointType.LINE_CUBIC); // FIXME: point type
		stroked.add_point (corner);	

		previous_handle.angle -= PI;
		next_handle.angle -= PI;
	}


}

}

