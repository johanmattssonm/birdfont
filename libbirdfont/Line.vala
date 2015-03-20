/*
    Copyright (C) 2012 2014 2015 Johan Mattsson

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

/** Help line */
public class Line : GLib.Object {
	public static const bool VERTICAL = true;
	public static const bool HORIZONTAL = false;
	
	public bool dashed { get; set; }
	
	public string label;
	bool vertical;
	string metrics;
	
	public double pos;
	
	bool active = false;
	bool move = false;
	
	public signal void queue_draw_area (int x, int y, int w, int h);
	public signal void position_updated (double pos);
		
	double r;
	double g;
	double b;
	double a;
	
	bool visible = true;
	bool moveable = true;
	
	public Line (string label = "No label set", double position = 10, bool vertical = false) {
		this.label = label;
		this.vertical = vertical;
		this.pos = position;
		
		dashed = false;
		metrics = "";
		
		set_color_theme ("Guide 1");
	}
	
	public Line copy () {
		Line l = new Line (label, pos, vertical);
		
		l.r = r;
		l.g = g;
		l.b = b;
		l.a = a;
		
		l.visible = visible;
		l.dashed = dashed;
		
		return l;
	}
	
	public void set_metrics (double m) {
		string t = @"$m";
		string s = "";
		
		int i;
		unichar c;
		
		i = 0;
		while (t.get_next_char (ref i, out c)) {
			s = s + (!) c.to_string ();
			
			if (i >= 5) {
				break;
			}
		}
		
		metrics = s;
	}
	
	public void set_visible (bool v) {
		visible = v;
	}

	public bool is_visible () {
		return visible;
	}

	public void set_moveable (bool m) {
		moveable = m;
	}
	
	public void set_color_theme (string color) {
		Color c = Theme.get_color (color);
		
		r = c.r;
		g = c.g;
		b = c.b;
		a = c.a;
	}
	
	public void set_color (double r, double g, double b, double a) {
		this.r = r;
		this.g = g;
		this.b = b;
		this.a = a;
	}
	
	public bool is_moving () {
		return move;
	}
	
	public bool set_move (bool moving) {
		bool r = move;
		move = moving;
		return (r == moving);
	}
	
	public bool button_press (uint button) {
		Glyph g;
		TextListener listener;
		string position;
		bool text_input = false;
		
		if (get_active ()) {
			if (button == 3 || KeyBindings.has_shift ()) {
				move = false;
				text_input = true;		
				position = @"$pos";

				listener = new TextListener (t_("Position"), position, t_("Move"));
				
				listener.signal_text_input.connect ((text) => {
					string submitted_value;
					double parsed_value;
					
					submitted_value = text.replace (",", ".");
					parsed_value = double.parse (submitted_value);
					
					pos = parsed_value;
					
					position_updated (parsed_value);
					GlyphCanvas.redraw ();
				});
				
				listener.signal_submit.connect (() => {
					TabContent.hide_text_input ();
				});
				
				TabContent.show_text_input (listener);
			} else {
				move = true;
			}
			
			g = MainWindow.get_current_glyph ();
			g.store_undo_state ();
		} else {
			move = false;
			active = false;
		}
		
		return move || text_input;
	}

	void redraw_line () {
		GlyphCanvas.redraw ();
	}	
	
	public void move_line_to (int x, int y, WidgetAllocation allocation) {
		set_move (true);
		event_move_to (x, y, allocation);
	}
	
	public bool event_move_to (int x, int y, WidgetAllocation allocation) {
		double p, c;
		bool a = false;
		Glyph g = MainWindow.get_current_glyph ();
		double ivz = 1/g.view_zoom;
		double margin = 10;
		double none = 0;
		
		if (!moveable) {
			return false;
		}

		if (is_vertical ()) { // over line handle (y)
			if (y > g.allocation.height - 10) {
				p = pos;
				c = Glyph.path_coordinate_x (x);
				a = (p - margin * ivz <= c <= p + margin * ivz);
			}
					
			if (a != get_active ()) {
				redraw_line ();
			}

			set_active (a);
			
		} else { // over line handle (x)
			if (x > g.allocation.width - 10) {
				p = pos;
				c = Glyph.path_coordinate_y (y);
				a = (p - margin * ivz <= c <= p + margin * ivz);
			}
			
			if (a != get_active ()) {
				redraw_line ();
			}
			
			set_active (a);
		}

		// move the line
		if (move) {
			double np = pos;
			redraw_line (); // clear old position
			
			if (is_vertical ()) {
				pos = Glyph.path_coordinate_x (x);

				if (GridTool.is_visible ()) {
					GridTool.tie_coordinate (ref pos, ref none);
				}
				redraw_line (); // draw at new position
			} else {
				pos = Glyph.path_coordinate_y (y);
				
				if (GridTool.is_visible ()) {
					GridTool.tie_coordinate (ref none, ref pos);
				}
				redraw_line ();
			}

			if (Math.fabs (np - pos) > 10) {
				queue_draw_area (0, 0, g.allocation.width, g.allocation.height);
			}

			position_updated (pos); // signal update

			BirdFont.get_current_font ().touch ();
		}

		if (GridTool.is_visible ()) {
			GridTool.update_lines ();
		}
	
		return move;
	}
	
	public bool get_active () {
		return active;
	}
	
	public void set_active (bool active) {
		this.active = active;
	}
	
	public string get_label () {
		return label;
	}
	
	public bool is_vertical () {
		return vertical;
	}

	public int get_position_pixel () {
		if (is_vertical ()) {
			return Glyph.reverse_path_coordinate_x (pos);
		}
		
		return Glyph.reverse_path_coordinate_y (pos) ;
	}
	
	public double get_pos () {
		return pos;
	}
	
	public void draw (Context cr, WidgetAllocation allocation) {
		Glyph g = MainWindow.get_current_glyph ();
		double p, h, w;
		double size = (active) ? 8 : 5;
		Text glyph_metrics;
		Text line_label;
		
		if (!visible) {
			return;
		}
		
		cr.save ();
		cr.set_line_width (1);
		
		if (dashed) {
			cr.set_dash ({20, 20}, 0);
		}
		
		if (active) {
			Theme.color (cr, "Highlighted Guide");
		} else {
			cr.set_source_rgba (r, this.g, b, a);
		}
		
		// Line
		if (is_vertical ()) {
			p = Glyph.reverse_path_coordinate_x (pos);
			h = g.allocation.height;
			
			cr.move_to (p, 0);
			cr.line_to (p, h);
			cr.stroke ();

			cr.scale (1, 1);

			if (moveable) {
				cr.new_path ();
				cr.move_to (p - size, h);	
				cr.line_to (p, h - size);	
				cr.line_to (p + size, h);
				cr.close_path();
				cr.fill ();
				
				if (get_active ()) { 
					glyph_metrics = new Text (metrics, 17);
					Theme.text_color (glyph_metrics, "Highlighted Guide");
					glyph_metrics.widget_x = p + 10;
					glyph_metrics.widget_y = h - 25;
					glyph_metrics.draw (cr);
				}
			}
			
		} else {
			p = Glyph.reverse_path_coordinate_y (pos);
			w = g.allocation.width;
			
			cr.move_to (0, p);
			cr.line_to (w, p);	
			cr.stroke ();
			
			if (moveable) {
				cr.new_path ();
				cr.move_to (w, p - size);	
				cr.line_to (w - size, p);	
				cr.line_to (w, p + size);
				cr.close_path();
				cr.fill ();
			}
		}
		
		// Label
		if (get_active ()) { 
			line_label = new Text (get_label (), 19 * MainWindow.units);

			if (is_vertical ()) {
				line_label.widget_x = p + 8 * MainWindow.units;
				line_label.widget_y = allocation.height - 55 * MainWindow.units;
			} else {
				line_label.widget_x = g.allocation.width 
					- 10 * MainWindow.units 
					- line_label.get_extent ();
					
				line_label.widget_y = p + 10 * MainWindow.units;
			}
			
			if (active) {
				Theme.text_color (line_label, "Highlighted Guide");
			} else {
				line_label.set_source_rgba (r, this.g, b, a);
			}
			
			line_label.draw (cr);
		}
		
		cr.restore ();
	}

	

}

}
