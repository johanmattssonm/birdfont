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
using Math;

namespace BirdFont {

public class Toolbox : GLib.Object  {
	public static ToolCollection current_set; 
	
	public static DrawingTools drawing_tools;
	public static KerningTools kerning_tools;
	public static PreviewTools preview_tools;
	public static OverviewTools overview_tools;
	public static BackgroundTools background_tools;
	
	Tool current_tool;
	
	public Tool press_tool;
	
	public signal void redraw (int x, int y, int w, int h);
	
	public static int allocation_width = 0;
	public static int allocation_height = 0;
	
	/** Scrolling with scroll wheel */
	bool scrolling_toolbox = false;
	
	/** Scroll with touch pad. */
	bool scrolling_touch = false;
	double scroll_y = 0;

	public List<ToolCollection> tool_sets = new List<ToolCollection> ();
		
	public Toolbox (GlyphCanvas glyph_canvas, TabBar tab_bar) {	
		current_tool = new Tool ("no_icon");
		press_tool = new Tool (null);

		drawing_tools = new DrawingTools (glyph_canvas); 
		kerning_tools = new KerningTools ();
		preview_tools = new PreviewTools ();
		overview_tools = new OverviewTools ();
		background_tools = new BackgroundTools ();
		
		tool_sets.append (drawing_tools);
		tool_sets.append (kerning_tools);
		tool_sets.append (preview_tools);
		tool_sets.append (overview_tools);
		tool_sets.append (background_tools);
		
		current_set = drawing_tools;
		
		tab_bar.signal_tab_selected.connect ((tab) => {
			string tab_name = tab.get_display ().get_name ();
			set_toolbox_from_tab (tab_name, tab);
		});
		
		update_expanders ();
	}

	public static void set_toolbox_from_tab (string tab_name, Tab? t = null) {		
		if (tab_name == "Kerning") {
			current_set = (ToolCollection) kerning_tools;
		} else if (tab_name == "Preview") {
			current_set = (ToolCollection) preview_tools;
		} else if (tab_name == "Overview") {
			current_set = (ToolCollection) overview_tools;
		} else if (tab_name == "Backgrounds") {
			current_set = (ToolCollection) background_tools;
		} else if (t != null && ((!) t).get_display () is Glyph) {
			current_set = (ToolCollection) drawing_tools;
		} else {
			current_set = new EmptySet ();
		}
		
		MainWindow.get_toolbox ().update_expanders ();
		redraw_tool_box ();
	}

	public static Tool get_move_tool () {
		return DrawingTools.move_tool;
	}
	
	public static void set_object_stroke (double width) {
		DrawingTools.object_stroke.set_value_round (width);
		redraw_tool_box ();
	}

	public static void set_allocation (int w, int h) {
		if (w != allocation_width || allocation_height != h) {
			allocation_width = w;
			allocation_height = h;
			Toolbox.redraw_tool_box ();
		}
	}
	
	public void press (uint button, double x, double y) {
		if (MenuTab.suppress_event) {
			warn_if_test ("Event suppressed");
			return;
		}
		
		foreach (Expander exp in current_set.get_expanders ()) {	
			foreach (Tool t in exp.tool) {
				if (t.tool_is_visible () && t.is_over (x, y)) {
					t.panel_press_action (t, button, x, y);
					press_tool = t;
				}
			}
		}
		
		scrolling_touch = true;
		scroll_y = y;
	}
	
	public void release (uint button, double x, double y) {
		bool active;
		
		if (MenuTab.suppress_event) {
			warn_if_test ("Event suppressed");
			return;
		}
				
		foreach (Expander exp in current_set.get_expanders ()) {			
			foreach (Tool t in exp.tool) {
				if (t.tool_is_visible ()) {
					active = t.is_over (x, y);
					
					if (active) {
						if (press_tool == t) {
							select_tool (t);
						}
					}
					
					t.panel_release_action (t, button, x, y);
				}
			}
		}
		
		scrolling_touch = false;
	}

	public void scroll_up (double x, double y) {
		bool action = false;
		
		if (MenuTab.suppress_event) {
			warn_if_test ("Event suppressed");
			return;
		}
				
		if (!scrolling_toolbox) {	
			foreach (Expander exp in current_set.get_expanders ()) {
				foreach (Tool t in exp.tool) {
					if (t.tool_is_visible () && t.is_over (x, y)) {
						action = t.scroll_wheel_up_action (t);
						press_tool = t;
					}
				}
			}
		}
		
		if (!action) {
			scroll_current_set (35);
		}
		
		redraw_tool_box ();
	}

	void scroll_current_set (double d) {
		current_set.scroll += d;
		
		if (current_set.scroll > 0) {
			current_set.scroll = 0;
		}

		if (current_set.content_height < allocation_height) {
			current_set.scroll = 0;
		} else if (current_set.content_height + current_set.scroll < allocation_height) {
			current_set.scroll = allocation_height - current_set.content_height;
		}
					
		update_expanders ();
		suppress_scroll ();	
	}

	public void scroll_down (double x, double y) {
		bool action = false;

		if (!scrolling_toolbox) {	
			foreach (Expander exp in current_set.get_expanders ()) {
				foreach (Tool t in exp.tool) {
					if (t.tool_is_visible () && t.is_over (x, y)) {
						action = t.scroll_wheel_down_action (t);
						press_tool = t;
					}
				}
			}
		}

		if (!action) {
			scroll_current_set (-35);
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
		bool consumed = false;
		bool active;
		TooltipArea? tpa = null;
					
		foreach (Expander exp in current_set.get_expanders ()) {
			a = exp.is_over (x, y);
			update = exp.set_active (a);
			
			if (update) {
				redraw ((int) exp.x - 10, (int) exp.y - 10, (int) (exp.x + exp.w + 10), (int) (exp.y + exp.h + 10));
			}
			

			foreach (Tool t in exp.tool) {
				if (t.tool_is_visible ()) {
					active = t.is_over (x, y);
					tpa = null;
					
					if (!active && t.is_active ()) {
						t.move_out_action (t);
					}
					
					update = t.set_active (active);
					tpa = MainWindow.get_tooltip ();
					
					if (active && tpa != null) {
						((!)tpa).update_text ();
					}
					
					if (update) {
						redraw (0, 0, allocation_width, allocation_height);
					}
					
					if (t.panel_move_action (t, x, y)) {
						consumed = true;
					}
				}
			}
		}
		
		if (scrolling_touch && !consumed && BirdFont.android) {
			scroll_current_set (y - scroll_y);
			scroll_y = y;
			redraw_tool_box ();
		}
	}

	public static void redraw_tool_box () {
		if (MenuTab.suppress_event) {
			warn_if_test ("Don't redraw toolbox when background thread is running.");
			return;
		}
		
		Toolbox t = MainWindow.get_toolbox ();
		if (!is_null (t)) {
			t.redraw (0, 0, allocation_width, allocation_height);
		}
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

	public void set_current_tool (Tool tool) {
		if (tool.editor_events) {
			current_tool = tool;
		}
	}

	public Tool get_current_tool () {
		return current_tool;
	}
	
	public void select_tool (Tool tool) {
		bool update;
		
		foreach (Expander exp in current_set.get_expanders ()) {
			foreach (Tool t in exp.tool) {
				if (tool.get_id () == t.get_id ()) {
					if (!t.tool_is_visible ()) {
						warning ("Tool is hidden");
					} else {						
						update = false;
						
						update = tool.set_selected (true);
						if (tool.persistent) {
							update = tool.set_active (true);
						}
						
						tool.select_action (tool);
						
						if (update) {							
							redraw ((int) exp.x - 10, (int) exp.y - 10, allocation_width, (int) (allocation_height - exp.y + 10));
						}
						
						set_current_tool (tool);
					}
				}
			}
			
		}
	}
	
	public Tool get_tool (string name) {
		foreach (ToolCollection tc in tool_sets) {
			foreach (Expander e in tc.get_expanders ()) {
				foreach (Tool t in e.tool) {
					if (t.get_name () == name) {
						return t;
					}
				}
			}
		}
				
		warning ("No tool found for name \"%s\".\n", name);
		
		return new Tool ("no_icon");
	}
	
	public static void set_tool_visible (string name, bool visible) {
		Toolbox tb = MainWindow.get_toolbox ();
		Tool t = tb.get_tool (name); 
		t.set_tool_visibility (visible);
		tb.update_expanders ();
		Toolbox.redraw_tool_box ();
	}
	
	public static void select_tool_by_name (string name) {
		Toolbox b = MainWindow.get_toolbox ();
		
		if (is_null (b)) {
			return;
		}
				
		b.select_tool (b.get_tool (name));
	}
	
	public static double get_scale () {
		return Toolbox.allocation_width / 160.0;
	}
	
	public void set_default_tool_size () {
		foreach (ToolCollection t in tool_sets) {
			foreach (Expander e in t.get_expanders ()) {
				e.update_tool_position ();
			}
		}
	}
	
	public void update_expanders () {
		double pos;
		
		foreach (Expander e in current_set.get_expanders ()) {
			e.set_scroll (current_set.scroll);
		}
		
		pos = 4 * get_scale ();
		foreach (Expander e in current_set.get_expanders ()) {
			e.set_offset (pos);
			
			pos += e.get_content_height () + 4 * get_scale ();
					
			current_set.content_height = pos;
			
			if (BirdFont.android) {
				current_set.content_height *= 1.15;
			}
		}

		foreach (Expander e in current_set.get_expanders ()) {
			e.set_active (false);
		}
	}
	
	private void draw_expanders (int w, int h, Context cr) {
		foreach (Expander e in current_set.get_expanders ()) {
			e.draw (w, h, cr);
			e.draw_content (w, h, cr);
		}
	}
	
	public void draw (int w, int h, Context cr) { 
		EmptySet empty_set;
		ImageSurface bg;
		double scale_x, scale_y, scale;
		
		if (current_set is EmptySet) {
			empty_set = (EmptySet) current_set;
			
			if (empty_set.background != null) {
				bg = (!) empty_set.background;
				
				scale_x = (double) allocation_width / bg.get_width ();
				scale_y = (double) allocation_height / bg.get_height ();
				
				scale = fmax (scale_x, scale_y);
				
				cr.save ();
				cr.scale (scale, scale);
				cr.set_source_surface (bg, 0, 0);
				cr.paint ();				
				cr.restore ();
				
				draw_expanders (w, h, cr);
			}
		} else {
			cr.save ();
			
			cr.rectangle (0, 0, w, h);
			cr.set_line_width (0);
			cr.set_source_rgba (51/255.0, 54/255.0, 59/255.0, 1);
			cr.fill ();

			draw_expanders (w, h, cr);
			
			cr.restore ();
		}
	}
	
	public class EmptySet : ToolCollection  {
		
		public ImageSurface? background;
		Gee.ArrayList<Expander> expanders;
		
		public EmptySet () {
			background = Icons.get_icon ("corvus_monedula.png");
			expanders = new Gee.ArrayList<Expander> ();
		}
		
		public override Gee.ArrayList<Expander> get_expanders () {
			return expanders;
		}
	}

}

}
