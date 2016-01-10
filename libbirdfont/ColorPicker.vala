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
using SvgBird;

namespace BirdFont {

public class ColorPicker : Tool {
	
	double hue = 0;
	double s = 0;
	double b = 0;
	double a = 1;

	public signal void fill_color_updated ();
	public signal void stroke_color_updated ();
	public signal void gradient_color_updated ();
	
	bool update_color = false;
	public double bar_height;
	
	int selected_bar = 0;
	
	public bool has_stroke_color = false;
	bool stroke_selected = false;
	
	public Color stroke_color = new Color (0, 0, 0, 1);
	public Color fill_color = new Color (0, 0, 0, 1);
	
	public Gradient gradient = new Gradient ();
	bool update_gradient = false; 
	int bars;
	Stop current_stop = new Stop ();
	
	public ColorPicker (string tooltip = "") {
		base (null, tooltip);
		
		bar_height = 22 * Toolbox.get_scale ();
		bars = 5;
		h = bars * bar_height;
		
		stroke_color_updated.connect (() => {
			redraw ();
			GlyphCanvas.redraw ();
		});

		panel_press_action.connect ((selected, button, tx, ty) => {	
			if (y <= ty <= y + bars * bar_height) {
				update_color = true;
				selected_bar = (int) ((ty - y) / bar_height);
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
	
	public void set_gradient (Gradient g, Stop stop, bool update_gradient) {
		gradient = g;
		this.update_gradient = update_gradient;
		current_stop = stop;
		redraw ();
	}
	
	public void set_color (Color c) {
		c.to_hsva (out hue, out s, out b, out a);
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
		} else if (!update_gradient && selected_bar == 4) {
			if (has_stroke_color) {
				stroke_selected = tx > Toolbox.allocation_width / 2.0;
				
				if (stroke_selected) {
					set_color (stroke_color);
				} else {
					set_color (fill_color);
				}
			}
		} else if (update_gradient && selected_bar == 4) {
			if (gradient.stops.size > 0) {
				int g = (int) ((tx / Toolbox.allocation_width) * gradient.stops.size);
				return_if_fail (0 <= g < gradient.stops.size);
				current_stop = gradient.stops.get (g);
				set_color (new Color.create_copy (current_stop.color));
			}
		}
		
		if (selected_bar != 4) {
			if (update_gradient) {
				current_stop.color = new Color.hsba (hue, s, b, a);
				gradient_color_updated ();
			} else {
				if (has_stroke_color && stroke_selected) {
					stroke_color = new Color.hsba (hue, s, b, a);
					stroke_color_updated ();
				} else {
					fill_color = new Color.hsba (hue, s, b, a);
					fill_color_updated ();
				}
			}
		}
	}
	
	public Color get_stroke_color () {
		return stroke_color;
	}
	
	public Color get_fill_color () {
		return fill_color;
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
		double step = 1.0 / Toolbox.allocation_width;
		Color c;
		double y = this.y - py;

		for (double p = 0; p < 1; p += step) {
			c = new Color.hsba (p, 1, 1, 1);
			cr.save ();
			cr.set_source_rgba (c.r, c.g, c.b, c.a);
			cr.rectangle (p * Toolbox.allocation_width, y, scale, bar_height);
			cr.fill ();
			cr.restore ();

			c = new Color.hsba (hue, p, 1, 1);
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

		if (!update_gradient) {
			if (!has_stroke_color) {
				c = fill_color;
				cr.save ();
				cr.set_source_rgba (c.r, c.g, c.b, c.a);
				cr.rectangle (0, y + 4 * bar_height, Toolbox.allocation_width, bar_height);
				cr.fill ();
				cr.restore ();
			} else {
				double cw = Toolbox.allocation_width / 2.0 - 2 * scale;
				
				cr.save ();
				cr.set_source_rgba (fill_color.r, fill_color.g, fill_color.b, fill_color.a);
				cr.rectangle (0, y + 4 * bar_height, cw, bar_height);
				cr.fill ();
				cr.restore ();

				cr.save ();
				cr.set_source_rgba (stroke_color.r, stroke_color.g, stroke_color.b, stroke_color.a);
				cr.rectangle (cw + 4 * scale, y + 4 * bar_height, cw, bar_height);
				cr.fill ();
				cr.restore ();
				
				if (has_stroke_color) {
					if (stroke_selected) {
						cr.save ();
						Theme.color (cr, "Tool Foreground");
						cr.set_line_width (1);
						cr.rectangle (cw + 4 * scale, y + 4 * bar_height, cw, bar_height);
						cr.stroke ();
						cr.restore ();
					} else {
						cr.save ();
						Theme.color (cr, "Tool Foreground");
						cr.set_line_width (1);
						cr.rectangle (0, y + 4 * bar_height, cw, bar_height);
						cr.stroke ();
						cr.restore ();
					}
				}
			}
		} else { // update gradient
			int stop_size = (int) ((double) Toolbox.allocation_width / gradient.stops.size);
			for (int i = 0; i < gradient.stops.size; i++) {
				Stop s = gradient.stops.get (i);
				c = new Color.create_copy (s.color);
				cr.save ();
				cr.set_source_rgba (c.r, c.g, c.b, c.a);
				cr.rectangle (i * stop_size, y + 4 * bar_height, stop_size, bar_height);
				cr.fill ();
				cr.restore ();
			}
			
			bool found = false;
			for (int i = 0; i < gradient.stops.size; i++) {
				Stop s = gradient.stops.get (i);
				if (s == current_stop) {
					found = true;
					cr.save ();
					Theme.color (cr, "Tool Foreground");
					cr.set_line_width (1);
					cr.rectangle (i * stop_size, y + 4 * bar_height, stop_size, bar_height);
					cr.stroke ();
					cr.restore ();
				}
			}
			
			if (!found) {
				warning ("No stop selected.");
			}
		}
			
	}
	
	void draw_dial (Context cr, double px, double py, int bar_index, double val) {
		double y = this.y - py;
		double scale = Toolbox.get_scale ();
		double p;
		p = bar_index * bar_height;
			
		return_if_fail (y + p + bar_height - 2 * scale > 0);			
		
		cr.save ();
		cr.set_line_width (1 * scale);
		cr.set_source_rgba (1, 1, 1, 1);
		cr.move_to (val * Toolbox.allocation_width * scale - 3 * scale, y + p + bar_height);
		cr.line_to (val * Toolbox.allocation_width, y + p + bar_height - 2 * scale);
		cr.line_to (val * Toolbox.allocation_width + 3 * scale, y + p + bar_height);
		cr.stroke_preserve ();
		cr.set_source_rgba (0, 0, 0, 1);
		cr.fill ();
		cr.restore ();
		
		cr.save ();
		cr.set_line_width (1 * scale);
		cr.set_source_rgba (1, 1, 1, 1);
		cr.move_to (val * Toolbox.allocation_width * scale - 3 * scale, y + p);
		cr.line_to (val * Toolbox.allocation_width, y + p + 2 * scale);
		cr.line_to (val * Toolbox.allocation_width + 3 * scale, y + p);
		cr.stroke_preserve ();
		cr.set_source_rgba (0, 0, 0, 1);
		cr.fill ();
		cr.restore ();
	}
}

}
