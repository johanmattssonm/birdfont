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
	public PathList paths;
	public Gee.ArrayList<Layer> subgroups;
	public bool visible = true;
	public string name = "Layer";
	public bool is_counter = false;
	
	public Layer () {
		paths = new PathList ();
		subgroups = new Gee.ArrayList<Layer> ();
	}

	public PathList get_all_paths () {
		PathList p = new PathList ();
		
		p.append (paths);
		
		foreach (Layer sublayer in subgroups) {
			p.append (sublayer.get_all_paths ());
		}
		
		return p;
	}

	public PathList get_visible_paths () {
		PathList p = new PathList ();
		
		if (visible) {
			p.append (paths);
		}
		
		foreach (Layer sublayer in subgroups) {
			if (sublayer.visible) {
				p.append (sublayer.get_all_paths ());
			}
		}
		
		return p;
	}
		
	public void add_layer (Layer layer) {
		subgroups.add (layer);
	}

	public void add_path (Path path) {
		paths.add (path);
	}

	public void remove_path (Path path) {
		paths.remove (path);
		foreach (Layer sublayer in subgroups) {
			sublayer.remove_path (path);
		}
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
		layer.paths = paths.copy ();
		layer.visible = visible;
		
		foreach (Layer l in subgroups) {
			layer.subgroups.add (l.copy ());
		}
		
		return layer;
	}

	public void get_boundaries (out double x, out double y, out double w, out double h) {
		double px, py, px2, py2;
		
		px = Glyph.CANVAS_MAX;
		py = Glyph.CANVAS_MAX;
		px2 = Glyph.CANVAS_MIN;
		py2 = Glyph.CANVAS_MIN;
		
		foreach (Path p in get_all_paths ().paths) {
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
		foreach (Path p in paths.paths) {
			for (int i = 0; i < indent; i++) {
				stdout.printf ("\t");
			}
			stdout.printf (@"Path open: $(p.is_open ())");
			
			if (p.color != null) {
				stdout.printf (" %s", ((!) p.color).to_rgb_hex ());
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
}

}
