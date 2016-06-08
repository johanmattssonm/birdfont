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
using Math;
using Cairo;
using SvgBird;

namespace BirdFont {

public class EmbeddedSvg : SvgBird.Object {
	public string svg_data = "";
	public SvgDrawing drawing = new SvgDrawing ();
	
	public double x { get; set; }
	public double y { get; set; }

	public override double xmin {
		get {
			return x;
		}
		
		set {
		}
	}

	public override double xmax {
		get {
			return x + drawing.width;
		}

		set {
		}
	}
	

	public override double ymin {
		get {
			return y - drawing.height;
		}

		set {
		}
	}

	public override double ymax {
		get {
			return y;
		}

		set {
		}
	}
			
	public EmbeddedSvg (SvgDrawing drawing) {
		this.drawing = drawing;
	}

	public override void update_region_boundaries () {
		drawing.update_region_boundaries ();
	}

	public override bool is_over (double x, double y) {
		return (this.x <= x <= this.x + drawing.width) 
			&& (this.y - drawing.height <= y <= this.y);
	}
	
	public void draw_embedded_svg (Context cr) {
		cr.save ();
		cr.translate (Glyph.xc () + x, Glyph.yc () - y);
		drawing.draw (cr);
		cr.restore ();
	}
	
	public override void draw_outline (Context cr) {
	}
	
	public override void move (double dx, double dy) {
		x += dx;
		y += dy;
	}
	
	public override void rotate (double theta, double xc, double yc) {
		drawing.rotate (theta, xc, yc);
	}
	
	public override bool is_empty () {
		return drawing.is_empty ();
	}
	
	public override void resize (double ratio_x, double ratio_y) {
		drawing.resize (ratio_x, ratio_y);
	}

	public override SvgBird.Object copy () {
		EmbeddedSvg svg = new EmbeddedSvg ((SvgDrawing) drawing.copy ());
		SvgBird.Object.copy_attributes (this, svg);
		svg.svg_data = svg_data;
		svg.x = x;
		svg.y = y;
		return svg;
	}
	
	public override string to_string () {
		return "Embedded SVG";
	}
}

}
