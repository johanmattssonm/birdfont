/*
    Copyright (C) 2012 Johan Mattsson

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

namespace BirdFont {

public class ColorTool : Tool {
	
	public double color_r = 0;
	public double color_g = 0;
	public double color_b = 0;
	public double color_a = 0;
	
	public signal void color_updated ();
	
	public ColorTool (string tooltip = "") {
		base (null, tooltip);

		select_action.connect((self) => {
			MainWindow.native_window.color_selection (this);
		});
		
		color_updated.connect (() => {
			redraw ();
			GlyphCanvas.redraw ();
		});
	}
	
	public Color get_color () {
		return new Color (color_r, color_g, color_b, color_a);
	}
	
	public void signal_color_updated () {
		print (get_color ().to_string ());
		color_updated ();
	}
	
	public override void draw_tool (Context cr, double px, double py) {
		double scale = Toolbox.get_scale ();
		double x = this.x - px;
		double y = this.y - py;
		double xt = x + w / 2 - 8 * scale;
		double yt = y + h / 2 - 8 * scale;
				
		base.draw_tool (cr, px, py);
		
		cr.save ();
		cr.set_source_rgba (color_r, color_g, color_b, 1);
		cr.rectangle (xt, yt, 16 * scale, 16 * scale);
		cr.fill ();
		cr.restore ();
	}
	
	public void set_r (double c) {
		color_r = c;
	}

	public void set_g (double c) {
		color_g = c;
	}

	public void set_b (double c) {
		color_b = c;
	}

	public void set_a (double c) {
		color_a = c;
	}

}

}
