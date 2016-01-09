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
	
	public double x {
		get {
			return drawing.x;
		}

		set {
			drawing.x = value;
		}
	}

	public double y {
		get {
			return drawing.y;
		}
		
		set {
			drawing.y = value;
		}
	}
	
	// FIXME: boundaries for embedded SVG
	
	public override double xmin {
		get {
			Glyph g = MainWindow.get_current_glyph ();
			return g.left_limit;
		}
		
		set {
		}
	}

	public override double xmax {
		get {
			Glyph g = MainWindow.get_current_glyph ();
			return g.right_limit;
		}

		set {
		}
	}
	

	public override double ymin {
		get {
			Font font = BirdFont.get_current_font ();
			return font.bottom_position;
		}

		set {
		}
	}

	public override double ymax {
		get {
			Font font = BirdFont.get_current_font ();
			return font.top_position;
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
		return drawing.is_over (x, y);
	}
	
	public override void draw (Context cr) {
		drawing.draw (cr);
	}
	
	public override Object copy () {
		EmbeddedSvg svg = new EmbeddedSvg (drawing);
		svg.svg_data = svg_data;
		return svg;
	}
	
	public override void move (double dx, double dy) {
		drawing.move (dx, dy);
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
