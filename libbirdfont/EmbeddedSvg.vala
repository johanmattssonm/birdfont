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
	
	// the view matrix belongs to the drawing
	public SvgDrawing drawing = new SvgDrawing ();
	
	public double x;
	public double y;
	
	public EmbeddedSvg (SvgDrawing drawing) {
		this.drawing = drawing;
	}

	public override bool update_boundaries (Context context) {
		drawing.update_boundaries (context);
		
		left = x + drawing.left;
		right = x + drawing.right;
		top = -y + drawing.top;
		bottom = -y + drawing.bottom;
	
		return true;
	}

	public override bool is_over (double x, double y) {
		return (xmin <= x <= xmax) 
			&& (ymin <= y <= ymax);
	}
	
	public void draw_embedded_svg (Context cr) {
		cr.save ();
		cr.translate (Glyph.xc () + x, Glyph.yc () - y);
		apply_transform (cr);
		drawing.draw (cr);
		cr.restore ();
	}
	
	public override void draw_outline (Context cr) {
		drawing.draw_outline (cr);
	}
	
	public override void move (double dx, double dy) {
		x += dx;
		y += dy;
		move_bounding_box (dx, -dy);
	}
	
	public override bool is_empty () {
		return drawing.is_empty ();
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

	public string get_transformed_svg_data () {
		StringBuilder svg = new StringBuilder ();
		
		svg.append ("<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>\n");
		svg.append ("""<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">""");
		svg.append ("\n");
		
		string transforms = transforms.get_xml ();
		
		if (transforms != "") {
			svg.append ("<g");
			svg.append (@" transform=\"$(transforms)\"");
			svg.append (">\n");
		}
		
		svg.append (remove_xml_header (svg_data));
		
		if (transforms != "") {
			svg.append ("</g>\n");
		}
		
		svg.append ("</svg>\n");
		
		return svg.str;
	}

	public string remove_xml_header (string xml_data) {
		string xml = xml_data;
		
		int start = xml.index_of ("<?");
		while (start > -1) {
			int end = xml.index_of ("?>");
			
			if (end == -1) {
				return xml;
			}
			
			end += "?>".length;
			
			xml = xml.substring (0, start) + xml.substring (end);
			start = xml.index_of ("<?");
		}
		
		return xml;
	}
}

}
