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

namespace BirdFont {

public class EmbeddedSvg : Object {
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

	// FIXME: handle this in SVG library instead
	public override bool is_over (double x, double y) {
		print (@" $(this.x) <= $(x) <= $(this.x) + $(drawing.width)");
		print (@" $(this.y) <= $(y) <= $(this.y) + $(drawing.height)");
			
		return (this.x <= x <= this.x + drawing.width) 
			&& (this.y - drawing.height <= y <= this.y);
	}
	
	public override void draw (Context cr) {
		cr.save ();
		cr.translate (Glyph.xc () + x, Glyph.yc () - y);
		drawing.draw (cr);
		cr.restore ();
	}
	
	public override Object copy () {
		EmbeddedSvg svg = new EmbeddedSvg (drawing);
		svg.svg_data = svg_data;
		return svg;
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

}

}
