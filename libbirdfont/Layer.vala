/*
	Copyright (C) 2015 Johan Mattsson

	This library is free software; you can redistribute it and/or modify 
	it under the terms of the GNU Lesser General Public License as 
	published by the Free Software Foundation; either version 3 of the 
	License, or (at your option) any later version.

	This library is distributed in the hope that it will be useful, but 
	WITHOUT ANY WARRANTY; without even the implied warranty of 
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
	Lesser General Public License for more details.
*/

namespace BirdFont {

public class Layer : GLib.Object {
	public ObjectGroup objects;
	
	public Gee.ArrayList<Layer> subgroups;
	public bool visible = true;
	public string name = "Layer";
	
	public bool is_counter = false;
	public Gradient? gradient = null;
	public bool single_path = false;
	
	public SvgTransforms transforms;
	
	public Layer () {
		objects = new ObjectGroup ();
		subgroups = new Gee.ArrayList<Layer> ();
		transforms = new SvgTransforms ();
	}

	public int index_of (Layer sublayer) {
		return subgroups.index_of (sublayer);
	}

	public ObjectGroup get_all_objects () {
		ObjectGroup o = new ObjectGroup ();
		
		o.append (objects);
		
		foreach (Layer sublayer in subgroups) {
			o.append (sublayer.get_all_objects ());
		}
		
		return o;
	}
		
	public PathList get_all_paths () {
		PathList paths = new PathList ();
		
		foreach (Object o in objects) {
			if (o is PathObject) {
				PathObject p = (PathObject) o;
				paths.add (p.get_path ());
			}
		}
		
		foreach (Layer sublayer in subgroups) {
			paths.append (sublayer.get_all_paths ());
		}
		
		return paths;
	}

	public ObjectGroup get_visible_objects () {
		ObjectGroup object_group = new ObjectGroup ();
		
		if (visible) {
			foreach (Object o in objects) {
				object_group.add (o);
			}
		}
		
		foreach (Layer sublayer in subgroups) {
			if (sublayer.visible) {
				object_group.append (sublayer.get_visible_objects ());
			}
		}
		
		return object_group;		
	}

	public PathList get_visible_paths () {
		PathList paths = new PathList ();
		
		if (visible) {
			foreach (Object o in objects) {
				if (o is PathObject) {
					PathObject p = (PathObject) o;
					paths.add (p.get_path ());
				}
			}
		}
		
		foreach (Layer sublayer in subgroups) {
			if (sublayer.visible) {
				paths.append (sublayer.get_visible_paths ());
			}
		}
		
		return paths;
	}
		
	public void add_layer (Layer layer) {
		subgroups.add (layer);
	}

	public void add_path (Path path) {
		PathObject p = new PathObject.for_path (path);
		objects.add (p);
	}

	public void add_object (Object object) {
		objects.add (object);
	}

	public void append_paths (PathList path_list) {
		foreach (Path p in path_list.paths) {
			add_path (p);
		}
	}

	private PathObject? get_fast_path (Path path) {
		foreach (Object o in objects) {
			if (o is PathObject) {
				PathObject p = (PathObject) o;
				if (p.get_path () == path) {
					return p;
				}
			}
		}
		
		return null;
	}
	
	public void remove_path (Path path) {
		PathObject? p = get_fast_path (path);
		
		if (p != null) {
			objects.remove ((!) p);
		}

		foreach (Layer sublayer in subgroups) {
			sublayer.remove_path (path);
		}
	}

	public void remove (Object o) {
		objects.remove (o);
	}
	
	public void remove_layer (Layer layer) {
		subgroups.remove (layer);
		
		foreach (Layer sublayer in subgroups) {
			sublayer.remove_layer (layer);
		}
	}
		
	public Layer copy () {
		Layer layer = new Layer ();
		
		layer.name = name;
		layer.objects = objects.copy ();
		layer.visible = visible;
		
		foreach (Layer l in subgroups) {
			layer.subgroups.add (l.copy ());
		}

		if (gradient != null) {
			layer.gradient = ((!) gradient).copy ();
		}
		
		layer.single_path = single_path;
			
		return layer;
	}

	public void get_boundaries (out double x, out double y, out double w, out double h) {
		double px, py, px2, py2;
		
		px = Glyph.CANVAS_MAX;
		py = Glyph.CANVAS_MAX;
		px2 = Glyph.CANVAS_MIN;
		py2 = Glyph.CANVAS_MIN;
		
		foreach (Object p in get_all_objects ().objects) {
			if (px > p.xmin) {
				px = p.xmin;
			} 

			if (py > p.ymin) {
				py = p.ymin;
			}

			if (px2 < p.xmax) {
				px2 = p.xmax;
			}
			
			if (py2 < p.ymax) {
				py2 = p.ymax;
			}
		}
		
		w = px2 - px;
		h = py2 - py;
		x = px;
		y = py2;
	}
		
	public void print (int indent = 0) {
		stdout.printf (@"Layer: $(name)");

		if (!visible) {
			stdout.printf (" hidden");
		}
		
		stdout.printf (@"\n");
		
		foreach (Object o in objects) {
			for (int i = 0; i < indent; i++) {
				stdout.printf ("\t");
			}
			stdout.printf (@"Object $(o.to_string ())");
			
			if (o.color != null) {
				stdout.printf (" %s", ((!) o.color).to_rgb_hex ());
			}

			if (!o.visible) {
				stdout.printf (" hidden");
			}
			
			stdout.printf ("\n");
		}
		
		foreach (Layer l in subgroups) {
			for (int i = 0; i < indent; i++) {
				stdout.printf ("\t");
			}
			stdout.printf ("%s\n", l.name);
			l.print (indent + 1);
		}
	}

	public PathList get_paths_in_layer () {
		PathList paths = new PathList ();
		
		foreach (Object object in objects) {
			if (object is PathObject) {
				paths.add (((PathObject) object).get_path ());
			}
		}
		
		return paths;
	}
}

}
