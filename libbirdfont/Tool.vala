/*
    Copyright (C) 2012, 2014 Johan Mattsson

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

public class Tool : GLib.Object {
	
	public double x = 0;
	public double y = 0;
	public double w = 30;
	public double h = 30;

	protected bool active = false;
	protected bool selected = false;
	
	ImageSurface? icon = null;
		
	public signal void select_action (Tool selected);
	public signal void deselect_action (Tool selected);
	
	public signal void press_action (Tool selected, int button, int x, int y);
	public signal void double_click_action (Tool selected, int button, int x, int y);
	public signal void move_action (Tool selected, int x, int y);
	public signal void release_action (Tool selected, int button, int x, int y);
	
	/** Returns true if tool is listening for scroll wheel actions. */
	public signal bool scroll_wheel_up_action (Tool selected);
	public signal bool scroll_wheel_down_action (Tool selected);
	
	public signal void key_press_action (Tool selected, uint32 keyval);
	public signal void key_release_action (Tool selected, uint32 keyval);
	
	public signal void panel_press_action (Tool selected, uint button, double x, double y);
	public signal void panel_release_action (Tool selected, uint button, double x, double y);

	/** @return true is event is consumed. */
	public signal bool panel_move_action (Tool selected, double x, double y);
	
	public signal void draw_action (Tool selected, Context cr, Glyph glyph);
	
	protected string name = "";
	
	static int next_id = 1;
	
	int id;
	
	public bool new_selection = false;
	
	bool show_bg = true;
	
	string tip = "";

	// keyboard bindings
	public uint modifier_flag;
	public unichar key;
	
	private static ImageSurface? selected_button = null;
	private static ImageSurface? active_selected_button = null;
	private static ImageSurface? deselected_button = null;
	private static ImageSurface? active_deselected_button = null;
	
	public bool persistent = false;
	public bool editor_events = false;
	
	bool waiting_for_tooltip = false;
	bool showing_this_tooltip = false;
	static Tool active_tooltip = new Tool ();
	
	bool visible = true;
	
	/** Create tool with a certain name and load icon "name".png */
	public Tool (string? name = null, string tip = "", unichar key = '\0', uint modifier_flag = 0) {
		this.tip = tip;
		
		if (selected_button == null) {
			selected_button = Icons.get_icon ("tool_button_selected.png");
			active_selected_button = Icons.get_icon ("tool_button_selected_active.png");
			deselected_button = Icons.get_icon ("tool_button_deselected.png");
			active_deselected_button = Icons.get_icon ("tool_button_deselected_active.png");
		}
		
		if (name != null) {
			set_icon ((!) name);
			this.name = (!) name;
		}
		
		this.key = key;
		this.modifier_flag = modifier_flag;
				
		id = next_id;
		next_id++;
		
		panel_press_action.connect ((self, button, x, y) => {
			MainWindow.get_tooltip ().set_text_from_tool ();
		});
		
		panel_move_action.connect ((self, x, y) => {
			if (is_active ()) {
				wait_for_tooltip ();
			}
			return false;
		});
	}

	public void set_tool_visibility (bool v) {
		visible = v;
	}

	public bool tool_is_visible () {
		return visible;
	}

	void wait_for_tooltip () {
		TimeoutSource timer_show;
		int timeout_interval = 1500;
		
		if (active_tooltip != this) {
			if (active_tooltip.showing_this_tooltip) {
				timeout_interval = 1;
			}
			
			active_tooltip.showing_this_tooltip = false;
			showing_this_tooltip = false;
			active_tooltip = this;

			if (!waiting_for_tooltip) {
				waiting_for_tooltip = true;
				timer_show = new TimeoutSource (timeout_interval);
				timer_show.set_callback (() => {
					if (tip != "" && active_tooltip.is_active () && !active_tooltip.showing_this_tooltip) {
						show_tooltip ();
					}
					waiting_for_tooltip = false;
					return waiting_for_tooltip;
				});
				timer_show.attach (null);
			}
		}
	}
	
	static void show_tooltip () {
		TimeoutSource timer_hide;
		
		// hide tooltip label later
		if (!active_tooltip.showing_this_tooltip) {
			timer_hide = new TimeoutSource (1500);
			timer_hide.set_callback (() => {
				if (!active_tooltip.is_active ()) {
					MainWindow.native_window.hide_tooltip ();
					active_tooltip.showing_this_tooltip = false;
					active_tooltip = new Tool ();
				}				
				return active_tooltip.showing_this_tooltip;
			});
			timer_hide.attach (null);
		}
		
		active_tooltip.showing_this_tooltip = true;
		MainWindow.native_window.hide_tooltip ();
		MainWindow.native_window.show_tooltip (active_tooltip.tip, (int)active_tooltip.x, (int)active_tooltip.y);
	}
	
	public void set_icon (string name) {
		StringBuilder n = new StringBuilder ();
		n.append ((!) name);
		n.append (".png");
		icon = Icons.get_icon (n.str);
	}
	
	public bool is_active () {
		return active;
	}
	
	public void set_show_background (bool bg) {
		show_bg = bg;
	}
	
	public int get_id () {
		return id;
	}

	public string get_name () {
		return name;
	}

	public bool is_selected () {
		return selected;
	}
	
	public string get_tip () {
		return tip;
	}

	public bool is_over (double xp, double yp) {
		return (x <= xp <= x + w  && y <= yp <= y + h);  
	}
	
	public bool set_selected (bool a) {
		TooltipArea? tpa = null;					
		tpa = MainWindow.get_tooltip ();
							
		new_selection = true;
		selected = a;
		set_active (a);
		
		if (!a) {
			deselect_action (this);
		} else {
			((!)tpa).update_text ();
		}
		
		return true;
	}
	
	/** @return true if this tool changes state, */
	public bool set_active (bool ac) {
		bool ret = (active != ac);
		active = ac;	
		return ret;
	}
	
	public virtual void draw (Context cr) {
		double xt = x;
		double yt = y;
		
		double bgx, bgy;
		double iconx, icony;
		
		double scale;

		cr.save ();
		
		scale = w / 111.0; // scale to 320 dpi
		cr.scale (scale, scale);
		
		bgx = xt / scale;
		bgy = yt / scale;

		// Button in four states
		if (selected && selected_button != null) {
			cr.set_source_surface ((!) selected_button, bgx, bgy);
			cr.paint ();
		}

		if (selected && active && active_selected_button != null) {
			cr.set_source_surface ((!) active_selected_button, bgx, bgy);
			cr.paint ();
		}

		if (!selected && deselected_button != null) {
			cr.set_source_surface ((!) deselected_button, bgx, bgy);
			cr.paint ();
		}

		if (!selected && active && active_deselected_button != null) {
			cr.set_source_surface ((!) active_deselected_button, bgx, bgy);
			cr.paint ();
		}
				
		if (icon != null) {
			ImageSurface i = (!) icon;
			
			if (likely (i.status () == Cairo.Status.SUCCESS)) {
				iconx = bgx + w / scale / 2 - i.get_width () / 2;
				icony = bgy + h / scale / 2 - i.get_height () / 2;

				cr.set_source_surface (i, iconx, icony);
				cr.paint ();
			} else {
				warning (@"Falied to load icon for $name");
			}
		}
		
		cr.restore ();
	}

	/** Run pending events in main loop before continuing. */
	public static void @yield () {
		int t = 0;
		TimeoutSource time = new TimeoutSource (500);
		bool timeout;
		unowned MainContext context;
		bool acquired;

		if (TestBirdFont.is_slow_test ()) {
			timeout = false;
			
			time.set_callback (() => {
				timeout = true;
				return false;
			});

			time.attach (null);		
		} else {
			timeout = true;
		}
    
		context = MainContext.default ();
		acquired = context.acquire ();
		
		if (unlikely (!acquired)) {
			warning ("Failed to acquire main loop.\n");
			return;
		}

		while (context.pending () || TestBirdFont.is_slow_test ()) {
			context.iteration (true);
			t++;

			if (!context.pending () && TestBirdFont.is_slow_test ()) {
				if (timeout) break;
			}
		}
		
		context.release ();
	}
	
	public void set_persistent (bool p) {
		persistent = p;
	}
}

}
