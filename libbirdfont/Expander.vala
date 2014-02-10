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
using Math;

namespace BirdFont {

public class Expander : GLib.Object {
	
	public double x = 7;
	public double y = 5;
	public double scroll = 0;

	public double w = 6;
	public double h = 5;
	
	public double margin = 0;
	
	protected double opacity = 0;
	
	protected bool active = false;
	protected bool open = false;

	public List<Tool> tool;

	bool persist = false;
	bool unique = false;
	
	double content_height = 0;
	
	public Expander () {
	}

	public double get_content_height () {
		return content_height;
	}

	/** Returns true if tools can be used with the current canvas after
	 * they have been selectes and false if they are a commands to be executed.
	 */
	public bool is_persistent () {
		return persist;
	}

	/** Returns true if all other tools in thid expander should be deselected 
	 * when a tool is selected.
	 */
	public bool is_unique () {
		return unique;
	}

	public void set_persistent (bool p) {
		persist = p;
	}

	public void set_unique (bool u) {
		unique = u;
	}
	
	private void update_tool_position () {
		double scale = Toolbox.get_scale ();
		double margin_small = 5 * scale;
		double xt = x;
		double yt = y + scroll + margin_small;
		bool new_row = false;

		foreach (Tool t in tool) {
			if (t is KerningRange) {
				t.w = Toolbox.allocation_width * scale;
				t.h = 17 * scale;				
			} else {
				t.w = 33 * scale;
				t.h = (33 / 1.11) * scale;
			}
		}
		
		if (tool.length () > 0) {
			content_height = tool.first ().data.h + margin_small;
		} else {
			warning ("No tools in box.");
			content_height = 0;
		}

		foreach (Tool t in tool) {
			if (new_row) {
				content_height += t.h + margin_small; 
				xt = x;
				yt += t.h + margin_small;
			}
			
			t.x = xt;
			t.y = yt;
			
			xt += t.w + margin_small;

			new_row = xt + t.w > Toolbox.allocation_width - margin_small;
		}
	}
	
	public void set_scroll (double scroll) {
		this.scroll = scroll;
	}
	
	public void set_offset (double ty) {
		y = ty;
		
		if (open) {
			update_tool_position ();
		}
	}
	
	public void add_tool (Tool t) {
		tool.append (t);
		update_tool_position ();
		
		t.select_action.connect ((selected) => {
				MainWindow.get_toolbox ().redraw ((int) x, (int) y, (int) w  + 300, (int) (h + margin));
			
				if (is_unique ()) {
					foreach (var deselected in tool) {
						if (selected.get_id () != deselected.get_id ()) {
							deselected.set_selected (false);
						}
					}
				}

				if (!selected.new_selection && selected.persistent) {
					if (is_persistent ()) {
						selected.set_selected (true);
					} else {
						selected.set_selected (false);
					}
				}
				
				if (!is_persistent () && !selected.persistent) {
						var time = new TimeoutSource(200);
						time.set_callback(() => {
							selected.set_selected (false);
							MainWindow.get_toolbox ().redraw ((int) x, (int) y, (int) w  + 300, (int) (h + margin));
							return false;
						});
						time.attach(null);
				}

				selected.new_selection = false;
			});
	}
	
	public bool is_over (double xp, double yp) {
		double yt = y + scroll + 2;
		return yt - 7 <= yp <= yt + 7 && xp < 17;
	}
	
	public bool set_active (bool a) {
		bool r = (active != a);
		opacity = (a) ? 1 : 0;
		active = a;
		return r;
	}
	
	public bool is_open () {
		return open;
	}
	
	public virtual bool set_open (bool o) {
		bool r = (open != o);
		margin = 0;
		open = o;
		return r;
	}
	
	public void draw (int wd, int hd, Context cr) {
		double yt = y + scroll + 2;
		double ih2 = 5.4 / 2;
		double iw2 = 5.4 / 2;
				
		cr.save ();
		cr.set_line_width (0.5);
		cr.set_source_rgba (0, 0, 0, 0.25);
		cr.move_to (x, yt);
		cr.line_to (wd - w - x + 4, yt);	
		cr.stroke ();
		cr.restore ();
		
		// arrow
		cr.save ();
		cr.new_path ();
		cr.set_line_width (1);
		cr.set_source_rgba (0, 0, 0, opacity);
		if (!open) {
			cr.move_to (x - iw2 + 3, yt - ih2 - 0.7);
			cr.line_to (x + iw2 + 3, yt);	
			cr.line_to (x - iw2 + 3, ih2 + yt - 0.7);
		} else {
			cr.move_to (x - iw2 + 3, yt - ih2 - 0.7 + 1);
			cr.line_to (x + iw2 + 3, yt - ih2 - 0.7 + 1);
			cr.line_to (x + iw2, yt + 2 + 1);	
		}
		cr.close_path();
		cr.stroke ();
		cr.restore ();
	}
	
	public void draw_content (int w, int h, Context cr) {
		if (open) {
			cr.save ();
			foreach (var t in tool) {
				t.draw (cr);
			}
			cr.restore ();
		}
	}
	
}

}
