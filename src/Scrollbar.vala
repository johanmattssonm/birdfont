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
using Gdk;
using Gtk;

namespace Supplement {

class Scrollbar : DrawingArea {
	Allocation alloc;

	double pos = 0;
	double height = 0.1;
	
	double y = 0;
	double h = 0;
	
	double y_begin = 0;
	double y_last = 0;
	bool move = false;
	bool visible = true;

	public signal void signal_scroll (double delta, double delta_last, double absolute);

	public Scrollbar () {
		add_events (EventMask.BUTTON_PRESS_MASK | EventMask.BUTTON_RELEASE_MASK | EventMask.POINTER_MOTION_MASK);
		
		expose_event.connect ((t, e)=> {
			Context cr = cairo_create (get_window ());
			
			get_allocation (out alloc);
			allocation = alloc;
			
			draw (cr, alloc);
			
			return true;
		});
		
		button_press_event.connect ((t, e)=> {
			button_press (e);			
			return true;
		});

		button_release_event.connect ((t, e)=> {
			button_release (e);
			return true;
		});
		
		motion_notify_event.connect ((t, e)=> {
			motion_notify (e);		
			return true;
		});
	}
	
	public void set_handle_size (double s) {
		height = (s < 0.01) ? 0.01 : s;
		print (@"height $height\n");
		
		if (height > 1) {
			height = 1;
		}
		
		h = height * alloc.height;
	}

	public void set_handle_position (double p) {
		print (@"p: $p\n");
		pos = (p > 0) ? p : 0;
		y = pos * alloc.height;
	}
	
	public void button_press (EventButton e) {
		move = true;
		y_begin = e.y;
		y_last = e.y;
		
		print ("press\n");
	}
	
	public void button_release (EventButton event) {
		move = false;
	}
	
	public double get_height () {
		return alloc.height;
	}
	
	public void motion_notify (EventMotion e) {
		print (@"notify $move \n");
		double d = 0;
		double dl = 0;
		double m;
		
		h = height * alloc.height;
		m = alloc.height;
				
		if (move && 0 < e.y < m) {
			d = e.y - y_begin;
			dl = e.y - y_last;
			y += dl;
			y_last = e.y;
		}

		if (y < 0) {
			y = 0;
		}

		if (y > alloc.height - h) {
			y = alloc.height - h;
			d = 0;
			dl = 0;
		}
		
		if (move) {
			pos = y / alloc.height;
		}
		
		print (@"pos $pos\n");
		
		if (move) {
			signal_scroll (d / (m - h), dl / (m -h), y / (m - h));
			pos = y / m;
		}

	}
		
	public void draw (Context cr, Allocation alloc) {
		double ax, ay, aw, ah;

		this.alloc = alloc;

		ax = alloc.width - 10;
		ay = 0;
		aw = alloc.width;
		ah = alloc.height;
						
		if (!visible) {
			cr.save ();
			cr.rectangle (ax, ay, aw, ah);
			cr.set_line_width (0);
			cr.set_source_rgba (194/255.0, 194/255.0, 194/255.0, 1);
			cr.fill_preserve ();
			cr.stroke ();
			cr.restore ();
			return;
		}
		
		cr.save ();
		cr.rectangle (ax, ay, aw, ah);
		cr.set_line_width (0);
		cr.set_source_rgba (183/255.0, 200/255.0, 223/255.0, 1);
		cr.fill_preserve ();
		cr.stroke ();
		cr.restore ();	
		
		cr.save ();
		cr.rectangle (ax, pos * alloc.height, alloc.width, ah * height);
		cr.set_line_width (0);
		cr.set_source_rgba (133/255.0, 143/255.0, 174/255.0, 1);
		cr.fill_preserve ();
		cr.stroke ();
		cr.restore ();			
	}
}

}
