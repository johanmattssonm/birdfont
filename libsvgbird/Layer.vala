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

namespace SvgBird {

public class Layer : GLib.Object {
	public ObjectGroup objects;
	
	public Gee.ArrayList<Layer> subgroups;
	public bool visible = true;
	public string name = "Layer";
	
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
		
	public void add_layer (Layer layer) {
		subgroups.add (layer);
	}
	
	public void add_object (Object object) {
		objects.add (object);
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
	
	public static void copy_layer (Layer from, Layer to) {
		to.name = from.name;
		to.objects = from.objects.copy ();
		to.visible = from.visible;
		
		foreach (Layer l in from.subgroups) {
			to.subgroups.add (l.copy ());
		}	
	}
	
	public Layer copy () {
		Layer layer = new Layer ();
		copy_layer (this, layer);
		return layer;
	}

	public void get_boundaries (out double x, out double y, out double w, out double h) {
		double px, py, px2, py2;
		
		px = double.MAX;
		py = double.MAX;
		px2 = -double.MAX;
		py2 = -double.MAX;
		
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
}

}
