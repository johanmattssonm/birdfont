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

public class Toolbox : GLib.Object  {
	ToolCollection current_set; 
	
	public DrawingTools drawing_tools;
	public KerningTools kerning_tools;
	
	Tool current_tool;
	
	public Tool press_tool;
	
	public signal void redraw (int x, int y, int w, int h);
	
	public int allocation_width = 0;
	public int allocation_height = 0;
	
	ImageSurface? toolbox_background = null;
	
	bool scrolling_toolbox = false;
	
	public Toolbox (GlyphCanvas glyph_canvas, TabBar tab_bar) {
		current_tool = new Tool ("no_icon");

		press_tool = new Tool (null);
		
		drawing_tools = new DrawingTools (glyph_canvas);
		kerning_tools = new KerningTools ();
		current_set = drawing_tools;
		toolbox_background = Icons.get_icon ("toolbox_background.png");
		
		tab_bar.signal_tab_selected.connect ((tab) => {
			if (tab.get_display ().get_name () == "Kerning") {
				current_set = kerning_tools;
			} else {
				current_set = drawing_tools;
			}
			
			update_expanders ();
			redraw (0, 0, allocation_width, allocation_height);
		});
		
		update_expanders ();
	}

	public void key_press (uint keyval) {
		foreach (Expander exp in current_set.get_expanders ()) {
			foreach (Tool t in exp.tool) {
				t.set_active (false);
				
				if (t.key == keyval 
					&& t.modifier_flag == NONE 
					&& KeyBindings.modifier == NONE) {
					select_tool (t);
				}
			}
		}
	}
	
	public void press (uint button, double x, double y) {
		foreach (Expander exp in current_set.get_expanders ()) {
			if (exp.is_over (x, y)) {
				exp.set_open (! exp.is_open ());					
				update_expanders ();			
				redraw_tool_box ();
			}
			
			foreach (Tool t in exp.tool) {
				if (t.is_over (x, y)) {
					t.panel_press_action (t, button, x, y);
					press_tool = t;
				}
			}
		}
	}
	
	public void release (uint button, double x, double y) {
		foreach (Expander exp in current_set.get_expanders ()) {			
			if (exp.is_open ()) {
				foreach (Tool t in exp.tool) {
					bool active = t.is_over (x, y);
					
					if (active) {
						if (press_tool == t) {
							select_tool (t);
						}
					}
					
					t.panel_release_action (t, button, x, y);
				}
			}
		}
	}

	public void scroll_up (double x, double y) {
		bool action = false;
		
		if (!scrolling_toolbox) {	
			foreach (Expander exp in current_set.get_expanders ()) {
				foreach (Tool t in exp.tool) {
					if (t.is_over (x, y)) {
						action = t.scroll_wheel_up_action (t);
						press_tool = t;
					}
				}
			}
		}
		
		if (!action) {
			current_set.scroll += 35;
			
			if (current_set.scroll > 0) {
				current_set.scroll = 0;
			}
			
			update_expanders ();
			suppress_scroll ();	
		}
		
		redraw_tool_box ();
	}

	public void scroll_down (double x, double y) {
		bool action = false;

		if (!scrolling_toolbox) {	
			foreach (Expander exp in current_set.get_expanders ()) {
				foreach (Tool t in exp.tool) {
					if (t.is_over (x, y)) {
						action = t.scroll_wheel_down_action (t);
						press_tool = t;
					}
				}
			}
		}
		
		if (!action) {
			current_set.scroll -= 35;
			
			if (current_set.content_height < allocation_height) {
				current_set.scroll = 0;
			} else if (current_set.content_height + current_set.scroll < allocation_height) {
				current_set.scroll = allocation_height - current_set.content_height;
			}
			
			update_expanders ();
			suppress_scroll ();
		}

		redraw_tool_box ();
	}
	
	void suppress_scroll () {
		scrolling_toolbox = true;
		
		Timeout.add (2000, () => {
			scrolling_toolbox = false;
			return false;
		});
	}
	
	public void move (double x, double y) {
		bool update;
		bool a;
		foreach (Expander exp in current_set.get_expanders ()) {
			a = exp.is_over (x, y);
			update = exp.set_active (a);
			
			if (update) {
				redraw ((int) exp.x - 10, (int) exp.y - 10, (int) (exp.x + exp.w + 10), (int) (exp.y + exp.h + 10));
			}
			
			if (exp.is_open ()) {
				foreach (Tool t in exp.tool) {
					bool active = t.is_over (x, y);
					TooltipArea? tpa = null;
					
					update = t.set_active (active);
					tpa = MainWindow.get_tool_tip ();
					
					if (active && tpa != null) {
						((!)tpa).update_text ();
					}
					
					if (update) {
						redraw (0, 0, allocation_width, allocation_height);
					}
					
					t.panel_move_action (t, x, y);
				}
			}
		}
	}

	public static void redraw_tool_box () {
		Toolbox t = MainWindow.get_toolbox ();
		t.redraw (0, 0, t.allocation_width, t.allocation_height);
	}
	
	public void reset_active_tool () {
		foreach (Expander exp in current_set.get_expanders ()) {
			foreach (Tool t in exp.tool) {
				t.set_active (false);
			}
		}
	}

	public Tool? get_active_tool () {
		foreach (Expander exp in current_set.get_expanders ()) {
			foreach (Tool t in exp.tool) {
				if (t.is_active ()) {
					return t;
				}
			}
		}
		
		return null;
	}

	public Tool get_current_tool () {
		return current_tool;
	}
	
	public void select_tool (Tool tool) {
		foreach (Expander exp in current_set.get_expanders ()) {
			foreach (Tool t in exp.tool) {
				if (tool.get_id () == t.get_id ()) {
					exp.set_open (true);
					
					bool update = false;
					
					update = tool.set_selected (true);
					if (tool.persistent) {
						update = tool.set_active (true);
					}
					
					tool.select_action (tool);
					
					if (update) {							
						redraw ((int) exp.x - 10, (int) exp.y - 10, allocation_width, (int) (allocation_height - exp.y + 10));
					}
					
					if (tool.editor_events) {
						current_tool = tool;
					}
				}
			}
			
		}
	}
	
	public Tool get_tool (string name) {
		foreach (Expander e in current_set.get_expanders ()) {
			foreach (var t in e.tool) {
				if (t.get_name () == name) {
					return t;
				}
			}
		}
				
		warning ("No tool found for name \"%s\".\n", name);
		
		return new Tool ("no_icon");
	}
	
	public static void select_tool_by_name (string name) {
		Toolbox b = MainWindow.get_toolbox ();
		
		if (is_null (b)) {
			return;
		}
				
		b.select_tool (b.get_tool (name));
	}
		
	public void update_expanders () {
		Expander? p = null; 
		Expander pp;

		foreach (Expander e in current_set.get_expanders ()) {
			e.set_scroll (current_set.scroll);
		}
		
		current_set.content_height = 0;
		foreach (Expander e in current_set.get_expanders ()) {
			if (p != null) {
				pp = (!) p;
				e.set_offset (pp.y + pp.margin + 9);
				current_set.content_height += e.get_content_height () + 9;
			} else {
				e.set_offset (9);
			}
			
			p = e;
		}
		
		current_set.content_height += 40;
	}
	
	private void draw_expanders (int w, int h, Context cr) {
		foreach (Expander e in current_set.get_expanders ()) {
			e.draw (w, h, cr);
			if (e.is_open ()) {
				e.draw_content (w, h, cr);
			}
		}
	}
	
	public void draw (int w, int h, Context cr) { 
		cr.save ();
		
		cr.rectangle(0, 0, w, h);
		cr.set_line_width(0);
		cr.set_source_rgba(242/255.0, 241/255.0, 240/255.0, 1);
		cr.fill();
		
		cr.rectangle(0, 0, 1, h);
		cr.set_line_width(0);
		cr.set_source_rgba(0/255.0, 0/255.0, 0/255.0, 1);
		cr.fill();
		
		draw_expanders (w, h, cr);
		
		cr.restore ();
	}
}

}
