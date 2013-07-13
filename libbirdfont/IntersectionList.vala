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

namespace BirdFont {

class IntersectionList {
	public List<Intersection> points = new List<Intersection> ();
	
	public void add (Intersection i) {
		double d;
		Intersection l;
		bool close = false;
			
		if (points.length () == 0) {
			points.append (i);
			return;
		}
		
		if (has_point (i)) {
			return;
		}
	
		for (unowned List<Intersection> pl = points.first (); ; pl = pl.next) {
			l = pl.data;
			d = Math.fabs (Math.sqrt (Math.pow (i.x - l.x, 2) + Math.pow (i.y - l.y, 2)));

			if (l.distance >= i.distance) {
				close = true;
				
				if (d < 0.3) {
					points.remove_link (points.last ());
					points.append (i);
					return;
				}
			}
			
			if (pl == points.last ()) {
				break;
			}
		}
		
		if (!close) {
			points.append (i);
		}
	}
		
	public bool has_edit_point (EditPoint e) {
		foreach (Intersection n in points) {
			if (n.editpoint_a == e || n.editpoint_b == e) {
				return true;
			}
		}
		
		return false;
	}
	
	bool has_point (Intersection i) {
		return has_point_at (i.x, i.y);
	}

	bool has_point_at (double x, double y) {
		foreach (Intersection n in points) {
			if (x == n.x && y == n.y) {
				return true;
			}
		}
		
		return false;
	}
	
	public Intersection? get_intersection (EditPoint e) {
		Intersection? p = null;
		foreach (Intersection n in points) {
			if (n.editpoint_a == e || n.editpoint_b == e) {
				assert (p == null);
				p = n;
			}
		}
		return p;
	}
	
	public void append (IntersectionList i) {
		foreach (Intersection inter in i.points) {
			points.append (inter);
		}
	}

	public static IntersectionList create_intersection_list (Path p1, Path p2) {
		IntersectionList il = new IntersectionList ();
		
		unowned List<EditPoint> a_start, a_stop;
		unowned List<EditPoint> b_start, b_stop;
		
		if (p1 == p2) {
			return il;
		}
		
		// find crossing paths
		a_start = p1.points.first ();
		for (int i = 0; i < p1.points.length (); i++) {
			
			if (a_start.data.next == null) {
				a_stop = p1.points.first ();
			} else {
				a_stop = a_start.data.get_next ();
			}
			
			b_start = p2.points.first ();
			for (int j = 0; j < p2.points.length (); j++) {
				
				if (b_start.data.next == null) {
					b_stop = p2.points.first ();
				} else {
					b_stop = b_start.data.get_next ();
				}

				il.append (find_intersections (a_start.data, a_stop.data, b_start.data, b_stop.data));

				b_start = b_stop;
			}
			
			a_start = a_stop;
		}
		
		return il;
	}

	static IntersectionList find_intersections (EditPoint a0, EditPoint a1, EditPoint b0, EditPoint b1) {
		IntersectionList il = new IntersectionList ();
		
		double mind = double.MAX; ;
		
		Path.all_of (a0, a1, (ax, ay, at) => {
			if (at == 0 || at == 1) {
				return true;
			}
			
			Path.all_of (b0, b1, (bx, by, bt) => {
				double d = Math.fabs (Math.sqrt (Math.pow (ax - bx, 2) + Math.pow (ay - by, 2)));
				
				if (d < 0.2) {
					il.add (new Intersection (ax, ay, d));
				}
				
				if (d < mind) mind = d;
				return true;
			});
			
			return true;
		});

		return il;
	}
}

}
