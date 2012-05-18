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

class TabBar : DrawingArea {
	
	public List<Tab> tabs = new List<Tab> ();

	int selected = 0;
	int over = -1;
	int over_close = -1;
	
	public signal void signal_tab_selected (Tab selected_tab);

	Tab? previous_tab = null;
	Tab? current_tab = null;

	public TabBar () {		
		set_extension_events (ExtensionMode.CURSOR | EventMask.POINTER_MOTION_MASK);
	  
	  add_events (EventMask.BUTTON_PRESS_MASK | EventMask.POINTER_MOTION_MASK | EventMask.LEAVE_NOTIFY_MASK);
	  
	  motion_notify_event.connect ((t, e)=> {
			Allocation alloc;
			is_over_close (e.x, e.y, out over, out over_close);
			get_allocation (out alloc);
			queue_draw_area (0, 0, alloc.width, alloc.height);
			return true;
		});	
		
		leave_notify_event.connect ((t, e)=> {
			Allocation alloc;
			get_allocation (out alloc);
			over = -1;
			over_close = -1;
			queue_draw_area (0, 0, alloc.width, alloc.height);
			return true;
		});
				
		button_press_event.connect ((t, e)=> {
			select_tab_click (e.x, e.y);
			return true;
			});
			
		expose_event.connect ((t, e)=> {
				draw (e);
				return true;
			});
		
		drag_begin.connect ((t, e)=> {
				stdout.printf("Drag.");
			});
		
		drag_end.connect ((t, e)=> {
				stdout.printf("Drag end.");
			});
			
		drag_motion.connect ((t, e, x, y, time)=> {
				stdout.printf("Drag motion.");
				return true;				
			});
			
		drag_drop.connect ((t, e, x, y, time)=> {
				stdout.printf("Drag motion.");
				return true;
			});	
		
		set_size_request (20, 50);
	}
	
	private void is_over_close (double x, double y, out int over, out int over_close) {
		int i = 0;
		double offset = 40;
		
		foreach (Tab t in tabs) {
						
			if ( offset < x < offset + t.get_width ()) {
				over = i;
				
				if (15 < y < 50 - 15 && x > offset + t.get_width () - 16) {
					over_close =  i;
				} else {
					over_close =  -1;
				}
				
				return;
			}
			
			offset += t.get_width () + 10;
			i++;
		}

		over_close = -1;		
		over = -1;
	}	
	
	
	/** Select tab for a glyph by charcode or name.
	 * @return true if the tab was found
	 */
	public bool select_char (string s) {
		int i = 0;
		foreach (Tab t in tabs) {
			if (t.get_label () == s) {
				select_tab (i);
				return true;
			}
			i++;
		}
		
		return false;
	}

	public bool select_tab_name (string s) {
		return select_char (s);
	}

	public void select_overview () {
		select_tab_name ("Overview");
	}

	private void select_previous_tab () {
		Tab t;
		bool open;
		
		if (previous_tab == null) {
			return;
		}
		
		t = (!) previous_tab;
		open = selected_open_tab (t);
		
		if (!open) {
			select_tab ((int) tabs.length () - 1);
		}
	}
		
	public void close_display (FontDisplay f) {
		int i = -1;
		foreach (var t in tabs) {
			++i;
			
			if (t.get_display () == f) {
				close_tab (i) ;
				return;
			}
		}
		
		return_if_fail (i != -1);
	} 
	
	public bool close_tab (int index, bool background_tab = false) {
		unowned List<Tab?>? lt;
		Tab t;
		Allocation alloc;
		get_allocation(out alloc);
		
		if (!(0 <= index < tabs.length ())) {
			return false;
		}
		
		lt = tabs.nth(index);
		
		if (lt == null || ((!) lt).data == null) {
			return false;
		}

		t = (!) ((!) lt).data;

		if (t.has_close_button ()) {
			tabs.delete_link (tabs.nth(index));
			
			if (!background_tab) {
				select_previous_tab ();
			}
			
			return true;
		}
		
		select_tab (index);
		return false;
	}
	
	public bool close_by_name (string name, bool background_tab = false) {
		int i = 0;
		
		foreach (var t in tabs) {
			if (t.get_label () == name) {
				return close_tab (i, background_tab);
			}
			
			i++;
		}
		
		return false;
	}
	
	public void close_background_tab_by_name (string name) {
		close_by_name (name, true);
	}
	
	/** Select a tab and return true if it is open. */
	public bool selected_open_tab (Tab t) {
		int i = 0;
		foreach (var n in tabs) {
			if (n == t) {
				select_tab (i);
				return true;
			}
			
			i++;
		}
		
		return false;
	}
	
	public Tab get_selected_tab () {
		return tabs.nth (get_selected ()).data;
	}
	
	public uint get_length () {
		return tabs.length ();
	}

	public int get_selected () {
		return selected;
	}
	
	public void select_tab (int index)
		requires (0 <= index < tabs.length ())
	{
		Tab t;
		Allocation alloc;
		get_allocation(out alloc);
		
		selected = index;
		
		unowned List<Tab?>? lt = tabs.nth(index);
		
		return_if_fail(lt != null);
		t = (!) ((!) lt).data;
		
		signal_tab_selected (t);

		previous_tab = current_tab;
		current_tab = t;

		queue_draw_area(0, 0, alloc.width, alloc.height);
	}
	
	private void select_tab_click (double x, double y) {
		int over, close;
		is_over_close (x, y, out over, out close);

		if (over >= 0) {
			if (over_close >= 0 && over == selected) {
				close_tab (over_close);
			} else {
				select_tab (over);
			}
		}
	}
	
	public void add_tab (FontDisplay display_item, double tab_width = 30, bool always_open = false) {
		int s = (tabs.length () == 0) ? 0 : selected + 1;
		
		tabs.insert (new Tab (display_item, tab_width, always_open), s);
		select_tab (s);
	}
	
	/** Returns true if the new item was added to the bar. */
	public bool add_unique_tab (FontDisplay display_item, double tab_width = 30, bool always_open = false) {
		
		bool i = select_tab_name (display_item.get_name ());
		
		if (!i) {
			add_tab (display_item, tab_width, always_open);
			return true;
		}
		
		return false;
	}
	
	private void draw (EventExpose event) {
		Allocation alloc;
		Context cr = cairo_create (get_window ());
		
		get_allocation (out alloc);
		
		cr.save ();
		cr.rectangle (0, 0, alloc.width, alloc.height);
		cr.set_line_width (0);
		cr.set_source_rgba (183/255.0, 200/255.0, 223/255.0, 1);
		cr.fill_preserve ();
		cr.stroke ();
		cr.restore ();

		draw_tabs (cr);
	}
	
	private void draw_tabs (Context cr) {
		Allocation alloc;
		get_allocation(out alloc);

		double close_opacity;
		double offset = 40;
		int i = 0;
		foreach (Tab t in tabs) {
			cr.save ();
			cr.translate (offset, 27);

			if (i == selected) {
				cr.set_source_rgba (1, 1, 1, 1);
			} else if (i == over) {
				cr.set_source_rgba (230/255.0, 236/255.0, 244/255.0, 1);
			} else {
				cr.set_source_rgba (142/255.0, 158/255.0, 190/255.0, 1);
			}
			
			cr.rectangle(-2, 10, t.get_width (), 4);
			cr.set_line_width (0);
			cr.fill ();
			
			cr.set_source_rgba (0, 0, 0, 1);
			cr.set_font_size (12);
			cr.move_to (0, 0);
			cr.show_text (t.get_label ());
			cr.stroke ();
	
			// close
			if (t.has_close_button ()) {
				cr.set_line_width (1);
				
				close_opacity = (over_close == i) ? 1 : 0.2; 
				cr.set_source_rgba (0, 0, 0, close_opacity);
				
				cr.move_to (t.get_width () - 5, -6);
				cr.line_to (t.get_width () - 10, -1);

				cr.move_to (t.get_width () - 10, -6);
				cr.line_to (t.get_width () - 5, -1);
				
				cr.stroke ();	
			}
							
			cr.restore ();
			
			offset += t.get_width () + 10; // FIXA 10 shoud be x off marg eller så
			i++;
		}
	}
}

class Tab : GLib.Object {

	bool always_open;
	double width; 
	FontDisplay display;

	public Tab (FontDisplay glyph, double tab_width, bool always_open) {
		width = tab_width;
		this.display = glyph;
		this.always_open = always_open;
	}

	public bool has_close_button () {
		return !always_open;
	}

	public FontDisplay get_display () {
		return display;
	}
	
	public string get_label () {
		return display.get_name ();
	}
	
	public double get_width () {
		return width;
	}
}

}
