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
using Math;

namespace BirdFont {

public class Expander : GLib.Object {

	private static const double HEADLINE_MARGIN = 4;
		
	public double x = 7;
	public double y = 5;
	public double scroll = 0;

	public double w = 6;
	public double h = 5;
	
	public double margin = 0;
	
	protected double opacity = 0;
	
	protected bool active = false;

	public Gee.ArrayList<Tool> tool;

	bool persist = false;
	bool unique = false;
	
	double content_height = 0;
	
	string? headline;
	Text title;
			
	public bool visible = true;
	Surface? cached = null;
	
	public Expander (string? headline = null) {
		this.headline = headline;

		title = new Text ();

		if (headline != null) {
			title.set_text ((!) headline);
		}
				
		tool = new Gee.ArrayList<Tool> ();
	}

	public void set_headline (string? h) {
		headline = h;
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
	
	public void update_tool_position () {
		double scale = Toolbox.get_scale ();
		double margin_small = 5 * scale;
		double xt = x;
		double yt = y + margin_small; // + scroll
		bool new_row = false;
		bool has_visible_tools = false;
		Tool previous;
		bool first_row;

		foreach (Tool t in tool) {
			if (t.tool_is_visible ()) {
				has_visible_tools = true;				
				break;
			}
		}

		if (!has_visible_tools) {
			content_height = 0;
			return;
		}
		
		foreach (Tool t in tool) {
			if (t is ZoomBar) {
				t.w = Toolbox.allocation_width * scale;
				t.h = 10 * scale; // 7
			} else if (t is LabelTool) {
				t.w = Toolbox.allocation_width * scale;
				t.h = 22 * scale;
			} else if (t is FontName) {
				t.w = Toolbox.allocation_width * scale;
				t.h = 20 * scale;
			} else if (t is KerningRange) {
				t.w = Toolbox.allocation_width * scale;
				t.h = 17 * scale;
			} else if (t is LayerLabel) {
				t.w = Toolbox.allocation_width * scale;
				t.h = 21 * scale;
			} else {
				t.w = 33 * scale;
				t.h = (33 / 1.11) * scale;
			}
		}
		
		if (tool.size > 0) {
			content_height = tool.get (0).h + margin_small;
		} else {
			content_height = 0;
		}

		if (headline != null && tool.size > 0) {
			yt += 17 * scale + HEADLINE_MARGIN;
			content_height += 17 * scale + HEADLINE_MARGIN;
		}
		
		if (tool.size > 0) {
			previous = tool.get (0);
			first_row = true;
			foreach (Tool t in tool) {
				if (t.tool_is_visible ()) {
					new_row = xt + t.w > Toolbox.allocation_width - 7 * scale;
					
					if (t is ZoomBar) {
						t.x = xt;
						t.y = yt;
						yt += t.h + 7 * scale;
						previous = t;
						continue;
					}
					
					if (previous is ZoomBar) {
						content_height += t.h;
					}
					
					if (new_row && !first_row) {
						content_height += previous.h; 
						xt = x;
						yt += previous.h;
						
						if (!(t is LabelTool) && !(previous is LayerLabel)) {
							yt += 7 * scale;
						}
						
						if (!(previous is LayerLabel)) {
							content_height += margin_small;
						}
					}
				
					t.x = xt;
					t.y = yt;
				
					xt += t.w + 7 * scale;

					if (previous is ZoomBar) {
						content_height += 7 * scale;
					}
										
					previous = t;
					first_row = false;
				}
			}
			
			content_height += 5 * scale;
		}
	}
	
	public void set_scroll (double scroll) {
		this.scroll = scroll;
	}
	
	public void set_offset (double ty) {
		y = ty;
		update_tool_position ();
	}
	
	public void redraw () {
		cached = null;
		Toolbox.redraw_tool_box ();
	}
	
	public void add_tool (Tool t, int position = -1) {
		if (position < 0) {
			tool.add (t);
		} else {
			return_if_fail (position <= tool.size);
			tool.insert (position, t);
		}
		
		t.redraw_tool.connect (() => {
			cached = null;
		});
		
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

	public void draw (Context cr) {
		Surface cache;
	
		if (unlikely (cached == null)) {
			Context cc;
			
			double text_height = 17 * Toolbox.get_scale ();
			double offset_y = 0;
		
			cache = new Surface.similar (cr.get_target (), Cairo.Content.COLOR_ALPHA, Toolbox.allocation_width, (int) (h + content_height));
			cc = new Context (cache);
		
			if (tool.size > 0 && headline != null) {
				Theme.text_color (title, "Text Tool Box");
				title.set_font_size (text_height);
				title.draw_at_top (cc, x, 0);
				offset_y = text_height + HEADLINE_MARGIN;
			}
			
			draw_content (cc, offset_y);
			cached = (!) cache;
		}
		
		if (cached != null) {
			cache = (!) cached;
			cr.save ();
			cr.set_antialias (Cairo.Antialias.NONE);
			cr.set_source_surface (cache, 0, (int) (y + scroll));
			cr.paint ();
			cr.restore ();
		}
	}
		
	public void draw_content (Context cr, double text_end) {
		double offset_y = 0;
		double offset_x = 0;
		
		update_tool_position (); //FIXME
		
		if (tool.size > 0) {
			offset_x = tool.get (0).x;
			offset_y = tool.get (0).y - text_end;
		}
		
		cr.save ();
		foreach (Tool t in tool) {
			if (t.tool_is_visible ()) {
				t.draw_tool (cr, offset_x - x, offset_y);
			}
		}
		cr.restore ();
	}
	
}

}
