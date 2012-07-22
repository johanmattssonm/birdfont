/*
    Copyright (C) 2012 Johan Mattsson

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

using Cairo;
using Gtk;
using Gdk;

namespace Supplement {

/** Help line */
class Line : GLib.Object {
	public static const bool VERTICAL = true;
	public static const bool HOROIZONTAL = false;
	
	string label;
	bool vertical;
	
	public double pos;
	
	bool active = false;
	bool move = false;
	
	public signal void queue_draw_area (int x, int y, int w, int h);
	public signal void position_updated (double pos);
	
	public unowned List<Line>? list_item = null;
	
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
		
		return l;
	}
	
	public void set_visible (bool v) {
		visible = v;
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
	
	// Valabug: should be public “void set_list_item (unowned List<Line> ll) {”
	// Keeping list_item public for now
	public void set_list_item (void* ll) {
		// list_item = ll;
	}
	
	public bool is_moving () {
		return move;
	}
	
	public bool set_move (bool moving) {
		bool r = move;
		move = moving;
		return (r == moving);
	}
	
	public bool button_press (EventButton e, Allocation allocation) {
		Glyph g;
		if (get_active ()) {
			move = true;
			
			g = MainWindow.get_current_glyph ();
			g.store_undo_state ();
			
			return true;
		}
		
		return false;
	}

	public void redraw_line () {
		double p;
		Glyph g = MainWindow.get_current_glyph ();
		
		if (vertical) {
			p = (pos - g.view_offset_x + (g.allocation.width / 2.0)) * g.view_zoom;
			queue_draw_area ((int)p - 10, 0, 200, g.allocation.height);
		} else {
			p = (pos - g.view_offset_y + (g.allocation.height / 2.0)) * g.view_zoom;
			queue_draw_area (0, (int)p - 10, g.allocation.width, 300);
		}
	}	
	
	public void move_line_to (double x, double y, Allocation allocation) {
		set_move (true);
		event_move_to (x, y, x, y, allocation);
	}
	
	/** Move to line to @param x, @param y and execute ove line handle 
	 * event for @param x, @param y.
	 */
	public void event_move_to (double x, double y, double ax, double ay, Allocation allocation) {
		double p, c, mx, my;
		bool a = false;
		Glyph g = MainWindow.get_current_glyph ();
		double ivz = 1/g.view_zoom;
		double margin = 10;

		if (!moveable) return;

		if (move) {
			double np = pos;
		
			redraw_line (); // clear old position
			
			if (is_vertical ()) {
				pos = x * ivz + g.view_offset_x - (g.allocation.width / 2.0);
				redraw_line (); // draw at new position
			} else {
				pos = y * ivz + g.view_offset_y - (g.allocation.height / 2.0);
				redraw_line ();
			}

			if (Math.fabs (np - pos) > 10) {
				queue_draw_area (0, 0, g.allocation.width, g.allocation.height);
			}

			position_updated (pos); // sinal update

			Supplement.get_current_font ().touch ();
			
			swap_lines ();
		}

		if (is_vertical ()) {
			if (ay > g.allocation.height - 10) {
				
				p = get_coordinate ();

				c = ax * ivz + g.view_offset_x;
				a = (p - margin * ivz <= c <= p + margin * ivz);
			}
					
			if (a != get_active ()) {
				redraw_line ();
			}

			set_active (a);
			
		} else {
			if (ax > g.allocation.width - 10) {
				p = get_coordinate ();
				c = ay * ivz + g.view_offset_y;
				a = (p - margin * ivz <= c <= p + margin * ivz);
			}
			
			if (a != get_active ()) {
				redraw_line ();
			}
			
			set_active (a);
		}
	}
	
	private void swap_lines () {
		double ivz = 1 / MainWindow.get_current_glyph ().view_zoom;
		
		if (!moveable) return;
		
		// switch to correct line if this line passes the next one in the sorted list
		if (list_item != null) {
			unowned List<Line> ll = (!) list_item;
			
			if (ll != ll.first ()) {
				if (ll.prev.data.pos > pos) {
					ll.prev.data.set_move (true);
					ll.prev.data.set_visible (true);
					set_move (false);
					pos = ll.prev.data.pos;
					ll.prev.data.pos += 1 * ivz;
				}
			}
			
			if (ll != ll.last ()) {
				if (ll.next.data.pos < pos) {
					ll.next.data.set_move (true);
					ll.next.data.set_visible (true);
					pos = ll.next.data.pos;
					ll.next.data.pos -= 1 * ivz;
					set_move (false);
				}
			}
			
		}
		
	}
	
	public bool get_active () {
		return active;
	}
	
	protected void set_active (bool active) {
		this.active = active;
	}
	
	public string get_label () {
		return label;
	}
	
	public bool is_vertical () {
		return vertical;
	}

	public double get_coordinate () {
		Glyph g = MainWindow.get_current_glyph ();
		double t = (is_vertical ()) ? (g.allocation.width / 2.0) : (g.allocation.height / 2.0);
		return pos + t;
	}
	
	public double get_pos () {
		return pos;
	}
	
	private double get_handle_size () {
		Glyph g = MainWindow.get_current_glyph ();
		double ivz = 1/g.view_zoom;
		return (get_active ()) ? (10 * ivz) : (5 * ivz);
	}
	
	public void draw (Context cr, Allocation allocation) {
		Glyph g = MainWindow.get_current_glyph ();
		
		double p, h, w;
		double ivz = 1/g.view_zoom;

		double size = get_handle_size ();
		
		if (!visible) return;
		
		cr.save ();
		cr.set_line_width (ivz);
		
		if (active) cr.set_source_rgba (0, 0, 0.3, 1);
		else cr.set_source_rgba (r, this.g, b, a);
		
		// Line
		if (is_vertical ()) {
			p = get_coordinate ();
			
			h = g.allocation.height * ivz + g.view_offset_y;
			
			cr.move_to (p, g.view_offset_y);
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
			p = get_coordinate ();
			
			w = g.allocation.width * ivz  + g.view_offset_x;
			
			cr.move_to (g.view_offset_x, p);
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
				h = g.allocation.height * ivz + g.view_offset_y;
				cr.move_to (p + 8*ivz, h - 30*ivz);
			} else {
				w = g.allocation.width * ivz + g.view_offset_x;
				cr.move_to (w - 70*ivz, p + 15*ivz);
			}

			cr.set_font_size (12 * ivz);
			cr.select_font_face ("Cantarell", FontSlant.NORMAL, FontWeight.BOLD);
	
			cr.show_text (get_label ());
			cr.stroke ();
		}
		
		cr.restore ();
	}

}

}
