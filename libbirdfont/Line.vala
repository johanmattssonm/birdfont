/*
    Copyright (C) 2012 2014 Johan Mattsson

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
	
	string label;
	bool vertical;
	
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
		
		r = 0.7;
		g = 0.7;
		b = 0.8;
		a = 1;
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
	
	public void set_visible (bool v) {
		visible = v;
	}

	public bool is_visible () {
		return visible;
	}

	public void set_moveable (bool m) {
		moveable = m;
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
		
		if (get_active ()) {
			if (button == 3 || KeyBindings.has_shift ()) {
				move = false;			
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
					MainWindow.native_window.hide_text_input ();
				});
				
				MainWindow.native_window.set_text_listener (listener);
			} else {
				move = true;
			}
			
			g = MainWindow.get_current_glyph ();
			g.store_undo_state ();
		} else {
			move = false;
			active = false;
		}
		
		return move;
	}

	void redraw_line () {
		double p;
		Glyph g = MainWindow.get_current_glyph ();

		if (vertical) {
			p = Glyph.reverse_path_coordinate_x (pos);
			queue_draw_area ((int)p - 100, 0, 200, g.allocation.height);
		} else {
			p = Glyph.reverse_path_coordinate_y (pos);
			queue_draw_area (0, (int)p - 100, g.allocation.width, 300);
		}
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
		
		if (!visible) {
			return;
		}
		
		cr.save ();
		cr.set_line_width (1);
		
		if (dashed) {
			cr.set_dash ({20, 20}, 0);
		}
		
		if (active) {
			cr.set_source_rgba (0, 0, 0.3, 1);
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
			if (is_vertical ()) {
				h = g.allocation.height;
				cr.move_to (p + 8 , h - 30);
			} else {
				w = g.allocation.width;
				cr.move_to (w - 70, p + 15);
			}

			cr.set_font_size (12);
			cr.select_font_face ("Cantarell", FontSlant.NORMAL, FontWeight.BOLD);
	
			cr.show_text (get_label ());
			cr.stroke ();
		}
		
		cr.restore ();
	}

}

}
