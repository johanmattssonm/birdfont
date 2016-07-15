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

	public double width = 0;
	public double height = 0;

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
			Matrix view_box_matrix = box.get_matrix (width, height);
			Matrix view_matrix = cr.get_matrix ();
			view_box_matrix.multiply (view_box_matrix, view_matrix);		
			cr.set_matrix (view_box_matrix);
		}
	}

	public override void apply_transform (Context cr) {
		apply_view_box (cr);
		base.apply_transform (cr);
		root_layer.apply_transform (cr);
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
		
		if (view_box != null) {
			drawing.view_box = ((!) view_box).copy ();
		}
		
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
