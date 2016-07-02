/*
	Copyright (C) 2016 Johan Mattsson

	This library is free software; you can redistribute it and/or modify 
	it under the terms of the GNU Lesser General Public License as 
	published by the Free Software Foundation; either version 3 of the 
	License, or (at your option) any later version.

	This library is distributed in the hope that it will be useful, but 
	WITHOUT ANY WARRANTY; without even the implied warranty of 
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
	Lesser General Public License for more details.
*/


using B;
using Cairo;
using Math;

namespace SvgBird {

public class SvgDrawing : Object {
	public Layer root_layer = new Layer ();
	public Defs defs = new Defs ();
	public ViewBox? view_box = null;

	public double width {
		get {			
			return svg_width;
		}
		
		set {
			svg_width = value;
		}
	}

	public double height {
		get {			
			return svg_height;
		}
		
		set {
			svg_height = value;
		}
	}
	
	public double svg_width = 0;
	public double svg_height = 0;

	public override bool update_boundaries (Context cr) {
		apply_transform (cr);
		root_layer.update_boundaries (cr);
		
		left = root_layer.left;
		right = root_layer.right;
		top = root_layer.top;
		bottom = root_layer.bottom;

		return true;
	}

	public override bool is_over (double x, double y) {
		return false;
	}

	void apply_view_box (Context cr) {
		if (view_box != null) {
			ViewBox box = (!) view_box;
			double scale_x = 1;
			double scale_y = 1;
			double scale = 1;
			
			cr.translate (box.minx, box.miny);
			scale_x = width / box.width;
			scale_y = height / box.height;
			
			bool scale_width = height * box.width > width * box.height;
			
			if (box.alignment == ViewBox.NONE) {	
				cr.scale (scale_x, scale_y);
			} else if (scale_width && box.slice) {
				scale = scale_x;
				cr.scale (scale, scale);
			} else {
				scale = scale_y;
				cr.scale (scale, scale);
			}
			
			if (!box.slice) {
				if ((box.alignment & ViewBox.XMID) > 0) {
					cr.translate ((box.width - width) / 2, 0);
				} else if ((box.alignment & ViewBox.XMAX) > 0) {
					cr.translate (box.width - width, 0);
				}

				if ((box.alignment & ViewBox.YMID) > 0) {
					cr.translate (0, (box.height - height) / 2);
				} else if ((box.alignment & ViewBox.YMAX) > 0) {
					cr.translate (0, box.height - height);
				}
			} else {
				Layer layer = new Layer ();
				Rectangle rectangle = new Rectangle ();
				rectangle.width = box.width;
				rectangle.height = box.height;
				layer.add_object (rectangle);
				ClipPath clip = new ClipPath (layer);
				clip_path = clip;
			}
		}
	}

	public override void apply_transform (Context cr) {
		apply_view_box (cr);
		base.apply_transform (cr);
	}

	public void draw (Context cr) {
		cr.save ();
		apply_transform (cr);
		root_layer.draw (cr);
		cr.restore ();
	}
		
	public override void draw_outline (Context cr) {
		root_layer.draw_outline (cr);
	}
	
	public override Object copy () {
		SvgDrawing drawing = new SvgDrawing ();
		SvgBird.Object.copy_attributes (this, drawing);
		drawing.root_layer = (Layer) root_layer.copy ();
		drawing.defs = defs.copy ();
		drawing.width = width;
		drawing.height = height;
		return drawing;
	}
	
	public override void move (double dx, double dy) {
	}

	public override bool is_empty () {
		return false;
	}
	
	public override string to_string () {
		return @"SvgDrawing width: $width, height: $height";
	}
}

}
