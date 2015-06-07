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

namespace BirdFont {

public class ColorPicker : Tool {
	
	double hue = 0;
	double s = 0;
	double b = 0;
	double a = 1;

	public signal void color_updated ();
	
	bool update_color = false;
	public double bar_height;
	
	int selected_bar = 0;
	
	public ColorPicker (string tooltip = "") {
		base (null, tooltip);
		
		bar_height = 22 * Toolbox.get_scale ();
		h = 4 * bar_height;
		
		color_updated.connect (() => {
			redraw ();
			GlyphCanvas.redraw ();
		});

		panel_press_action.connect ((selected, button, tx, ty) => {	
			if (y <= ty <= y + 4 * bar_height) {
				update_color = true;
				selected_bar = (int) Math.rint ((ty - y) / bar_height);
				set_color_from_pointer (tx);
			}
		});

		panel_move_action.connect ((selected, button, tx, ty) => {
			if (update_color) {
				set_color_from_pointer (tx);
			}
			
			return false;
		});

		panel_release_action.connect ((selected, button, tx, ty) => {
			update_color = false;
		});
	}
	
	public void set_color_from_pointer (double tx) {
		
		if (tx > Toolbox.allocation_width) {
			tx = Toolbox.allocation_width;
		}
		
		if (tx < 0) {
			tx = 0;
		}
		
		if (selected_bar == 0) {
			hue = (double) tx / Toolbox.allocation_width;
		} else if (selected_bar == 1) {
			s = (double) tx / Toolbox.allocation_width;
		} else if (selected_bar == 2) {
			b = (double) tx / Toolbox.allocation_width;
		} else if (selected_bar == 3) {
			a = (double) tx / Toolbox.allocation_width;
		}
				
		redraw ();	
	}
	
	public Color get_color () {
		return new Color.hsba (hue, s, b, a);
	}
	
	public void signal_color_updated () {
		color_updated ();
	}
	
	public override void draw_tool (Context cr, double px, double py) {
		draw_bars (cr, px, py);
		draw_dial (cr, px, py, 0, hue);
		draw_dial (cr, px, py, 1, s);
		draw_dial (cr, px, py, 2, b);
		draw_dial (cr, px, py, 3, a);
	}
	
	public void draw_bars (Context cr, double px, double py) {
		double scale = Toolbox.get_scale ();
		double x = this.x - px;
		double y = this.y - py;
		double step = 1.0 / Toolbox.allocation_width;
		Color c;
		
		for (double p = 0; p < 1; p += step) {
			c = new Color.hsba (p, 1, 0.5, 1);
			cr.save ();
			cr.set_source_rgba (c.r, c.g, c.b, c.a);
			cr.rectangle (p * Toolbox.allocation_width, y, scale, bar_height);
			cr.fill ();
			cr.restore ();

			c = new Color.hsba (hue, p, 0.5, 1);
			cr.save ();
			cr.set_source_rgba (c.r, c.g, c.b, c.a);
			cr.rectangle (p * Toolbox.allocation_width, y + bar_height, scale, bar_height);
			cr.fill ();
			cr.restore ();

			c = new Color.hsba (hue, s, p, 1);
			cr.save ();
			cr.set_source_rgba (c.r, c.g, c.b, c.a);
			cr.rectangle (p * Toolbox.allocation_width, y + 2 * bar_height, scale, bar_height);
			cr.fill ();
			cr.restore ();
			
			c = new Color.hsba (hue, s, b, p);
			cr.save ();
			cr.set_source_rgba (c.r, c.g, c.b, c.a);
			cr.rectangle (p * Toolbox.allocation_width, y + 3 * bar_height, scale, bar_height);
			cr.fill ();
			cr.restore ();
		}
	}
	
	void draw_dial (Context cr, double px, double py, int bar_index, double val) {
		double x = this.x - px;
		double y = this.y - py;
		double scale = Toolbox.get_scale ();
		double p;
		
		p = bar_index * bar_height;
		
		cr.save ();
		cr.set_line_width (1 * scale);
		cr.set_source_rgba (1, 1, 1, 1);
		cr.move_to (val * Toolbox.allocation_width - 3 * scale, y + p + bar_height);
		cr.line_to (val * Toolbox.allocation_width, y + p + bar_height - 2 * scale);
		cr.line_to (val * Toolbox.allocation_width + 3 * scale, y + p + bar_height);
		cr.stroke_preserve ();
		cr.set_source_rgba (0, 0, 0, 1);
		cr.fill ();
		cr.restore ();
		
		cr.save ();
		cr.set_line_width (1 * scale);
		cr.set_source_rgba (1, 1, 1, 1);
		cr.move_to (val * Toolbox.allocation_width - 3 * scale, y + p);
		cr.line_to (val * Toolbox.allocation_width, y + p + 2 * scale);
		cr.line_to (val * Toolbox.allocation_width + 3 * scale, y + p);
		cr.stroke_preserve ();
		cr.set_source_rgba (0, 0, 0, 1);
		cr.fill ();
		cr.restore ();
	}
}

}
