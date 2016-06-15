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

using Cairo;

namespace SvgBird {

public class Layer : Object {
	public ObjectGroup objects;
	public string name = "Layer";

	public Layer () {
		objects = new ObjectGroup ();
		transforms = new SvgTransforms ();
	}

	public Layer.with_name (string name) {
		this.name = name;
		objects = new ObjectGroup ();
		transforms = new SvgTransforms ();
	}
	
	public void update_boundaries () {
		top = CANVAS_MAX;
		bottom = CANVAS_MIN;
		left = CANVAS_MAX;
		right = CANVAS_MIN;

		foreach (Object object in objects) {
			if (object is Layer) {
				Layer sublayer = (Layer) object;
				sublayer.update_boundaries ();
			}
			
			if (object.boundaries_height > 0.000001 
				&& object.boundaries_width > 0.000001) {
				
				if (object.top < top) {
					top = object.top;
				}

				if (object.bottom > bottom) {
					bottom = object.bottom;
				}
				
				if (object.left < left) {
					left = object.left;
				}

				if (object.right > right) {
					right = object.right;
				}
			}
		}
	}
	
	public void draw (Context cr) {
		cr.save ();
		apply_transform (cr);
		
		if (clip_path != null) {
			ClipPath clipping = (!) clip_path;
			clipping.apply (cr);
		}

		foreach (Object object in objects) {
			cr.save ();
			object.apply_transform (cr);
						
			if (object.clip_path != null) {
				ClipPath clipping = (!) object.clip_path;
				clipping.apply (cr);
			}
			
			if (object is Layer) {
				Layer sublayer = (Layer) object;
				sublayer.draw (cr);		
			} else {
				object.draw_outline (cr);
				object.paint (cr);
			}
			cr.restore ();
		}
		
		cr.restore ();
	}

	public override void draw_outline (Context cr) {
		apply_transform (cr);
		
		foreach (Object object in objects) {
			cr.save ();
			object.apply_transform (cr);
			object.draw_outline (cr);
			cr.restore ();
		}
		
		cr.restore ();
	}

	public int index_of (Layer sublayer) {
		return objects.index_of (sublayer);
	}
		
	public void add_layer (Layer layer) {
		objects.add (layer);
		update_boundaries ();
	}
	
	public void add_object (Object object) {
		objects.add (object);
		update_boundaries ();
	}

	public void remove (Object o) {
		objects.remove (o);
		update_boundaries ();
	}
	
	public void remove_layer (Layer layer) {
		objects.remove (layer);
		
		foreach (Object object in objects) {
			if (object is Layer) {
				Layer sublayer = (Layer) object;
				sublayer.remove_layer (layer);
			}
		}
		
		update_boundaries ();
	}
	
	public static void copy_layer (Layer from, Layer to) {
		to.name = from.name;
		to.objects = from.objects.copy ();
	}

	public override Object copy () {
		Layer layer = new Layer ();
		copy_layer (this, layer);
		Object.copy_attributes (this, layer);
		return layer;
	}
	
	public Gee.ArrayList<Layer> get_sublayers () {
		Gee.ArrayList<Layer> sublayers = new Gee.ArrayList<Layer> ();
		
		foreach (Object object in objects) {
			if (likely (object is Layer)) {
				Layer sublayer = (Layer) object;
				sublayers.add (sublayer);
			} else {
				warning ("An object in the group " + name + " is not a layer.");
			}
		}
		
		return sublayers;
	}
		
	public void print (int indent = 0) {
		stdout.printf (@"Layer: $(name)");

		if (!visible) {
			stdout.printf (" hidden");
		}
		
		stdout.printf (@" $(transforms) $(style)");
		stdout.printf (@"\n");

		foreach (Object object in objects) {
			stdout.printf (@"$(object.to_string ()) $(object.transforms) $(object.style)");
			
			if (!object.visible) {
				stdout.printf (" hidden");
			}
			
			stdout.printf ("\n");

			for (int i = 0; i < indent; i++) {
				stdout.printf ("\t");
			}

			if (object is Layer) {
				Layer sublayer = (Layer) object;
				sublayer.print (indent + 1);
			}
		}
	}

	public override bool is_over (double x, double y) {
		return false;
	}
		
	public override void move (double dx, double dy) {
	}
	
	public override void update_region_boundaries () {
	}

	public override void rotate (double theta, double xc, double yc) {
	}
	
	public override bool is_empty () {
		return false;
	}
	
	public override void resize (double ratio_x, double ratio_y) {
	}
	
	public override string to_string () {
		return "Layer: " + name;
	}
}

}
