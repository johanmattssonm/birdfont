/*
    Copyright (C) 2012 Johan Mattsson

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

using Math;

namespace Supplement {

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
	
	public void clear () {
		while (points.length () > 0) {
			points.remove_link (points.first ());
		}
	}
	
	public void remove_point (EditPoint e) {
		foreach (Intersection n in points) {
			if (n.editpoint_a == e || n.editpoint_b == e) {
				points.remove_all (n);
			}
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
		
	public int get_point_index (EditPoint e) {
		int i = 0;
		foreach (Intersection n in points) {
			if (e.x == n.x && e.y == n.y) {
				return i;
			}
			i++;
		}
		return -1;
	}
	
	public Intersection? get_next_intersection (EditPoint e) {
		bool found = false;
		foreach (Intersection n in points) {
			if (found) {
				return n;
			}
			
			if (n.editpoint_a == e || n.editpoint_b == e) {
				found = true;
			}
		}
		return null;
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
		double distance = double.MAX;
		
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

	bool probably_intersecting (EditPoint a0, EditPoint a1, EditPoint b0, EditPoint b1) {
		if (has_intersection (a0.x, a1.x, b0.x, b1.x) && has_intersection (a0.y, a1.y, b0.y, b1.y)) {
			return true;
		}	

		if (has_intersection (a0.x, a1.x, b0.x, b1.x) && has_intersection (a0.y, a1.y, b0.y, b1.y)) {
			return true;
		}	
	
		return false;
	}
	
	/** return true if ranges does overlap */
	bool has_intersection (double a0, double a1, double b0, double b1) {
		if (a0 <= b0 <= a1 || a1 <= b0 <= a0) {
			if (a0 <= b1 <= a1 || a1 <= b1 <= a0) {
				return true;
			}
			
			if (b0 <= a1 <= b1 || b1 <= a1 <= b0) {
				return true;
			}
		}
		
		if (b0 <= a0 <= b1 || b1 <= a0 <= b0) {
			if (a0 <= a0 <= a1 || a1 <= a0 <= a0) {
				return true;
			}
			
			if (b0 <= a0 <= b1 || b1 <= a0 <= b0) {
				return true;
			}
		}
		
		return false;
	}
}

}
