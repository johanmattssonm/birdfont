/*
    Copyright (C) 2014 2015 Johan Mattsson

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
using Math;

namespace BirdFont {

public class TableLayout : FontDisplay {
	
	public double scroll = 0;
	public double content_height = 1;
	public WidgetAllocation allocation = new WidgetAllocation ();
	public Gee.ArrayList<Widget> widgets = new Gee.ArrayList<Widget> ();
	public Gee.ArrayList<Widget> focus_ring = new Gee.ArrayList<Widget> ();
	public int focus_index = 0;
	
	public Widget? keyboard_focus = null;
	
	public TableLayout () {
	}

	public override void draw (WidgetAllocation allocation, Context cr) {
		this.allocation = allocation;
		
		layout ();
		
		// background
		cr.save ();
		cr.rectangle (0, 0, allocation.width, allocation.height);
		cr.set_line_width (0);
		
		Theme.color (cr, "Default Background");

		cr.fill ();
		cr.stroke ();
		cr.restore ();

		foreach (Widget w in widgets) {
			if (w.is_on_screen ()) {			
				if (w is Text) {
					cr.save ();
					Theme.color (cr, "Foreground 1");
					w.draw (cr);
					cr.restore ();
				} else {
					w.draw (cr);
				}
			}
		}
	}	

	void layout () {
		double y = -scroll;
		
		foreach (Widget w in widgets) {
			w.widget_x = 17 * MainWindow.units;
			w.widget_y = y;
			w.allocation = allocation;
			
			if (w is TextArea) {
				((TextArea) w).layout ();
			}
			
			y += w.get_height () + w.margin_bottom;
		}
		
		content_height = y + scroll;
		update_scrollbar ();
	}

	public void scroll_event (double p) {
		scroll += p;
		layout ();
		GlyphCanvas.redraw ();
	}

	public override void key_press (uint keyval) {
		Widget focus;

		if (keyval == Key.SHIFT_TAB) {
			focus_previous ();
		} else if (keyval == Key.TAB) {
			focus_next ();
		} else if (keyboard_focus != null) {
			focus = (!) keyboard_focus;
			focus.key_press (keyval);
		}
		
		GlyphCanvas.redraw ();
	}
	
	void focus_previous () {
		focus_index--;
		
		if (focus_index < 0) {
			focus_index = 0;
		}
		
		set_focus (focus_ring.get (focus_index));
	}
	
	void focus_next () {
		focus_index++;
		
		if (focus_index >= focus_ring.size) {
			focus_index = focus_ring.size - 1;
		}
		
		set_focus (focus_ring.get (focus_index));
	}
	
	public override void button_press (uint button, double x, double y) {
		Widget t;
		Widget old;
		CheckBox c;
		
		foreach (Widget w in widgets) {
			if (w.is_over (x, y)) {
				if (w is TextArea) {
					t = (TextArea) w;
					if (keyboard_focus != null && (!) keyboard_focus != t) {
						old = (!) keyboard_focus;
						old.focus (false);
					}
					
					set_focus (t);
					t.button_press (button, x, y);
				} else if (w is CheckBox) {
					c = (CheckBox) w;
					c.set_checked (!c.checked);
				} else {
					w.button_press (button, x, y);
				}
			}
		}

		GlyphCanvas.redraw ();
	}
	
	public void set_focus (Widget w) {
		Widget old;
		
		if (keyboard_focus != null && (!) keyboard_focus != w) {
			old = (!) keyboard_focus;
			old.focus (false);
		}
		
		keyboard_focus = w;
		w.focus (true);
		
		focus_index = focus_ring.index_of (w);

		if (!(0 <= focus_index < focus_ring.size)) {
			focus_index = 0;
		}

		update_scrollbar ();
		GlyphCanvas.redraw ();
	}
	
	public override void button_release (int button, double x, double y) {
		Widget t;
		
		if (keyboard_focus != null) {
			t = (!) keyboard_focus;
			set_focus (t);
			t.button_release (button, x, y);
		}

		foreach (Widget w in widgets) {
			if (w.is_over (x, y)) {
				w.button_release (button, x, y);
			}
		}
					
		GlyphCanvas.redraw ();
	}

	public override void motion_notify (double x, double y) {
		Widget t;
		
		if (keyboard_focus != null) {
			t = (!) keyboard_focus;
			if (t.motion (x, y)) {
				GlyphCanvas.redraw ();
			}
		}
	}

	public override string get_label () {
		return t_("Name and Description");
	}

	public override string get_name () {
		return "Description";
	}

	public override bool has_scrollbar () {
		return true;
	}
	
	public override void scroll_wheel_down (double x, double y) {
		scroll += 25 * MainWindow.units;
		
		if (scroll + allocation.height >=  content_height) {
			scroll = content_height - allocation.height;
			
			if (scroll < 0) {
				scroll = 0;
			}
		}
		
		update_scrollbar ();
		GlyphCanvas.redraw ();
	}
	
	public override void scroll_wheel_up (double x, double y) {
		scroll -= 25 * MainWindow.units;
		
		if (scroll < 0) {
			scroll = 0;
		}
		
		update_scrollbar ();
		GlyphCanvas.redraw ();
	}

	public override void selected_canvas () {
		update_scrollbar ();
		GlyphCanvas.redraw ();
	}
	
	public override void update_scrollbar () {
		double h = content_height - allocation.height;
		MainWindow.set_scrollbar_size (allocation.height / content_height);
		MainWindow.set_scrollbar_position (scroll /  h);
	}

	public override void scroll_to (double percent) {
		double h = content_height - allocation.height;
		scroll = percent * h;
		GlyphCanvas.redraw ();
	}
}

}
