/*
	Copyright (C) 2015 2016 Johan Mattsson

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

	public override void move (double dx, double dy) {
		left += dx;
		right += dx;
		top += dy;
		bottom += dy;

		foreach (Object object in objects.objects) {
			object.move (dx, dy);
		}
		
		update_view_matrix ();
	}


	public override bool update_boundaries (Context cr) {
		if (objects.size == 0) {
			return false;
		}

		top = CANVAS_MAX;
		bottom = CANVAS_MIN;
		left = CANVAS_MAX;
		right = CANVAS_MIN;

		cr.save ();
		parent_matrix = copy_matrix (cr.get_matrix ());
		apply_transform (cr);
		view_matrix = copy_matrix (cr.get_matrix ());

		foreach (Object object in objects) {
			bool has_size = false;

			if (object is Layer) {
				Layer sublayer = (Layer) object;
				has_size = sublayer.update_boundaries (cr);
			} else {
				has_size = object.update_boundaries (cr);
			}
			
			if (has_size) {
				left = fmin (left, object.left);
				right = fmax (right, object.right);
				top = fmin (top, object.top);
				bottom = fmax (bottom, object.bottom);
			}			
		}
		
		cr.restore ();
		
		return boundaries_width != 0;
	}
	
	public void draw (Context cr) {
		draw_layer (cr, true);
	}

	public override void draw_outline (Context cr) {
		draw_layer (cr, false);
	}
	
	private void draw_layer (Context cr, bool paint) {
		cr.save ();

		apply_transform (cr);
		
		if (clip_path != null) {
			ClipPath clipping = (!) clip_path;
			clipping.apply (cr);
		}

		foreach (Object object in objects) {
			cr.save ();
						
			if (object.clip_path != null) {
				ClipPath clipping = (!) object.clip_path;
				clipping.apply (cr);
			}
			
			if (object is Layer) {
				Layer sublayer = (Layer) object;

				if (paint) {
					sublayer.draw (cr);
				} else {
					sublayer.draw_outline (cr);
				}
			} else if (object.visible) {
				object.apply_transform (cr);
				object.draw_outline (cr);
				
				if (paint) {
					object.paint (cr);
				}
			}
			cr.restore ();
		}
		
		cr.restore ();
	}

	public int index_of (Layer sublayer) {
		return objects.index_of (sublayer);
	}
		
	public void add_layer (Layer layer) {
		objects.add (layer);
		update_boundaries_for_object ();
	}
	
	public void add_object (Object object) {
		objects.add (object);
		update_boundaries_for_object ();
	}

	public void remove (Object o) {
		objects.remove (o);
		
		foreach (Object object in objects) {
			if (object is Layer) {
				Layer sublayer = (Layer) object;
				sublayer.remove (o);
			}
		}
		
		update_boundaries_for_object ();
	}
	
	public void remove_layer (Layer layer) {
		objects.remove (layer);
		
		foreach (Object object in objects) {
			if (object is Layer) {
				Layer sublayer = (Layer) object;
				sublayer.remove_layer (layer);
			}
		}
		
		update_boundaries_for_object ();
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
	
	public override bool is_empty () {
		return false;
	}
	
	public override string to_string () {
		return "Layer: " + name;
	}
}

}
