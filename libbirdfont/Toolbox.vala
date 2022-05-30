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

public class Toolbox : GLib.Object  {
	public static ToolCollection current_set; 
	
	public static HiddenTools hidden_tools;
	public static DrawingTools drawing_tools;
	public static KerningTools kerning_tools;
	public static PreviewTools preview_tools;
	public static OverviewTools overview_tools;
	public static BackgroundTools background_tools;	
	public static SpacingTools spacing_tools;
	public static SpacingClassTools spacing_class_tools;
	public static FileTools file_tools;
	public static ThemeTools theme_tools;
	
	public Tool press_tool;
	
	public signal void redraw (int x, int y, int w, int h);
	
	public static int allocation_width = 0;
	public static int allocation_height = 0;
		
	/** Scrolling with scroll wheel */
	bool scrolling_toolbox = false;
	
	/** Scroll with touch pad. */
	bool scrolling_touch = false;
	double scroll_y = 0;

	public Gee.ArrayList<ToolCollection> tool_sets;

	string? tool_tip = null;
	double tool_tip_x = 0;
	double tool_tip_y = 0;
	
	public signal void new_tool_set (Tab? tab);
	bool suppress_event = false;
	
	public Toolbox (GlyphCanvas glyph_canvas, TabBar tab_bar) {
		tool_sets = new Gee.ArrayList<ToolCollection> ();
		press_tool = new Tool (null);

		hidden_tools = new HiddenTools ();
		drawing_tools = new DrawingTools (glyph_canvas); 
		kerning_tools = new KerningTools ();
		preview_tools = new PreviewTools ();
		overview_tools = new OverviewTools ();
		background_tools = new BackgroundTools ();
		spacing_tools = new SpacingTools ();
		spacing_class_tools = new SpacingClassTools  ();
		file_tools = new FileTools ();
		theme_tools = new ThemeTools ();
		
		tool_sets.add (theme_tools);
		tool_sets.add (file_tools);
		tool_sets.add (hidden_tools);
		tool_sets.add (drawing_tools);
		tool_sets.add (kerning_tools);
		tool_sets.add (preview_tools);
		tool_sets.add (overview_tools);
		tool_sets.add (spacing_class_tools);
		tool_sets.add (background_tools);
		// the menu has all the file_tools commands, it will not be added here
		tool_sets.add (hidden_tools); // tools without buttons
		
		current_set = file_tools;
		current_set.selected ();
		
		tab_bar.signal_tab_selected.connect ((tab) => {
			string tab_name = tab.get_display ().get_name ();
			set_toolbox_from_tab (tab_name, tab);
			new_tool_set (tab);
		});
		
		update_expanders ();
	}

	public void set_suppress_event (bool e) {
		suppress_event = e;
	}

	public static DrawingTools get_drawing_tools () {
		return drawing_tools;
	}

	public void update_all_expanders () {
		foreach (ToolCollection tc in tool_sets) {
			tc.redraw ();
		}
	}
	
	public static void cache_all_tools () {
		Toolbox t = MainWindow.get_toolbox ();
		
		foreach (ToolCollection tc in t.tool_sets) {
			tc.cache ();
		}
	}

	public static void set_toolbox_from_tab (string tab_name, Tab? t = null) {		
		if (tab_name == "Spacing") {
			current_set = (ToolCollection) spacing_tools;
		} else if (tab_name == "Kerning") {
			current_set = (ToolCollection) kerning_tools;
		} else if (tab_name == "Preview") {
			current_set = (ToolCollection) preview_tools;
		} else if (tab_name == "Overview") {
			current_set = (ToolCollection) overview_tools;
		} else if (tab_name == "Backgrounds") {
			current_set = (ToolCollection) background_tools;
		} else if (tab_name == "SpacingClasses") {
			current_set = (ToolCollection) spacing_class_tools;
		} else if (tab_name == "Themes") {
			current_set = (ToolCollection) theme_tools;
		} else if (t != null && ((!) t).get_display () is GlyphTab) {
			current_set = (ToolCollection) drawing_tools;
		} else if (t != null && ((!) t).get_display () is Glyph) {
			warning ("Expecting GlyphTab instead of Glyph.");
			current_set = (ToolCollection) drawing_tools;
		} else {
			current_set = (ToolCollection) file_tools;
		}
		
		current_set.selected ();
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

	public static void set_allocation (int width, int height) {
		if (width != allocation_width || allocation_height != height) {
			allocation_width = width;
			allocation_height = height;
			Toolbox.redraw_tool_box ();
		}
	}
	
	public void press (uint button, double x, double y) {
		if (MenuTab.has_suppress_event () || suppress_event) {
			warn_if_test ("Event suppressed");
			return;
		}
		
		y -= current_set.scroll;
		
		foreach (Expander exp in current_set.get_expanders ()) {
			if (exp.visible) {
				foreach (Tool t in exp.tool) {
					if (t.tool_is_visible () && t.is_over (x, y)) {
						t.panel_press_action (t, button, x, y);
						press_tool = t;
					}
				}
			}
		}
		
		scrolling_touch = true;
		scroll_y = y;
	}
	
	public void release (uint button, double x, double y) {
		bool active;
		
		y -= current_set.scroll;
		
		if (MenuTab.has_suppress_event () || suppress_event) {
			warn_if_test ("Event suppressed");
			return;
		}
				
		foreach (Expander exp in current_set.get_expanders ()) {
			if (exp.visible) {	
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
		}
		
		scrolling_touch = false;
	}

	public void double_click (uint button, double x, double y) {
		if (MenuTab.has_suppress_event () || suppress_event) {
			warn_if_test ("Event suppressed");
			return;
		}
		
		y -= current_set.scroll;
		
		foreach (Expander e in current_set.get_expanders ()) {
			if (e.visible) {
				foreach (Tool t in e.tool) {
					t.panel_double_click_action (t, button, x, y);
				}
			}
		}
	}

	public void scroll_wheel (double x, double y, double dx, double dy) {
		bool action = false;
		
		y -= current_set.scroll;
		
		if (MenuTab.has_suppress_event () || suppress_event) {
			warn_if_test ("Event suppressed");
			return;
		}
				
		if (!scrolling_toolbox) {	
			foreach (Expander exp in current_set.get_expanders ()) {
				if (exp.visible) {
					foreach (Tool t in exp.tool) {
						if (t.tool_is_visible () && t.is_over (x, y)) {
							if (dy < 0) {
								action = t.scroll_wheel_up_action (t);
							} else {
								action = t.scroll_wheel_down_action (t);
							}
							press_tool = t;
						}
					}
				}
			}
		}
		
		if (!action) {
			scroll_current_set (dy);
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

	public void scroll_up (double x, double y) {
		scroll_wheel (x, y, 0, 20);
	}
	
	public void scroll_down (double x, double y) {
		scroll_wheel (x, y, 0, -20);
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
		
		y -= current_set.scroll;
		
		MainWindow.set_cursor (NativeWindow.VISIBLE);
			
		foreach (Expander exp in current_set.get_expanders ()) {
			if (exp.visible) {
				a = exp.is_over (x, y);
				update = exp.set_active (a);
				
				if (update) {
					redraw ((int) exp.x - 10, (int) exp.y - 10, (int) (exp.x + exp.w + 20), (int) (exp.y + exp.h + 20));
				}
				
				foreach (Tool t in exp.tool) {
					if (t.tool_is_visible ()) {
						active = t.is_over (x, y);

						if (!active && t.is_active ()) {
							t.move_out_action (t);
						}
						
						update = t.set_active (active);
						
						if (update) {
							redraw (0, 0, allocation_width, allocation_height);
						}
						
						if (t.panel_move_action (t, x, y)) {
							consumed = true;
						}
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
		if (MenuTab.has_suppress_event ()) {
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
			current_set.set_current_tool (tool);
		}
	}

	public Tool get_current_tool () {
		return current_set.get_current_tool ();
	}
	
	public void select_tool (Tool tool) {
		bool update;
		int offset_y;
		foreach (Expander exp in current_set.get_expanders ()) {
			if (exp.visible) {
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
								offset_y = (int) (exp.y - scroll_y);
								redraw ((int) exp.x - 10, (int) offset_y - 10, allocation_width, (int) (allocation_height - offset_y + 10));
							}
							
							set_current_tool (tool);
						}
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
		return MainWindow.units;
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
			if (e.visible) {
				e.set_offset (pos);
				pos += e.get_content_height () + 4 * get_scale ();
				current_set.content_height = pos;
				
				if (BirdFont.android) {
					current_set.content_height *= 1.15;
				}
			}
		}

		foreach (Expander e in current_set.get_expanders ()) {
			e.set_active (false);
		}
	}
	
	private void draw_expanders (int w, int h, Context cr) {
		foreach (Expander e in current_set.get_expanders ()) {
			if (e.visible) {
				e.draw (cr);
			}
		}
	}
	
	public void draw (int w, int h, Context cr) { 
		cr.save ();
			
		Theme.color (cr, "Default Background");
		
		cr.rectangle (0, 0, w, h);
		cr.set_line_width (0);
		cr.fill ();
				
		draw_expanders (w, h, cr);
	
		cr.restore ();
		
		draw_tool_tip (cr);
	}

	private void draw_tool_tip (Context cr) {
		TextArea t;
		
		if (tool_tip != null && tool_tip != "") {
			t = new TextArea (17 * get_scale ());
   
			t.allocation = new WidgetAllocation.for_area (0, 0, allocation_width, allocation_height);
			t.set_editable (false);
			t.set_text ((!) tool_tip);
			
			t.width = allocation_width - 20 * get_scale ();
			
			t.min_height = 17 * get_scale ();
			t.height = 17 * get_scale ();

			t.layout ();

			t.widget_x = 10 * get_scale ();
			t.widget_y = tool_tip_y - t.height - 5 * get_scale ();		

			if (t.widget_y < 5) {
				t.widget_y = 5;
			}

			t.draw (cr);
		}
	}
	
	public void hide_tooltip () {
		if (tool_tip != null) {
			tool_tip = null;
			redraw_tool_box ();
		}
	}
	
	public void show_tooltip (string tool_tip, double x, double y) {
		if (tool_tip != "") {
			this.tool_tip = tool_tip;
			this.tool_tip_x = x;
			this.tool_tip_y = y;
			
			redraw_tool_box ();
		}
	}
	
	public void set_current_tool_set (ToolCollection ts) {
		current_set = ts;
	}
	
	public class EmptySet : ToolCollection  {
		Gee.ArrayList<Expander> expanders;
		
		public EmptySet () {
			expanders = new Gee.ArrayList<Expander> ();
		}
		
		public override Gee.ArrayList<Expander> get_expanders () {
			return expanders;
		}
	}
}

}
