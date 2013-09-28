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

namespace BirdFont {

public class Tool : GLib.Object {
	
	public double x = 0;
	public double y = 0;
	public double w = 30;
	public double h = 30;

	protected bool active = false;
	protected bool selected = false;
	
	double r_default_selected = 131/255.0;
	double g_default_selected = 179/255.0;
	double b_default_selected = 231/255.0;
	double a_default_selected = 1;
	
	double r_default = 185/255.0;
	double g_default = 207/255.0;
	double b_default = 231/255.0;
	double a_default = 1;
	
	double r;
	double g;
	double b;
	double a;
	
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
	public signal void panel_move_action (Tool selected, double x, double y);
	
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
			MainWindow.get_tool_tip ().set_text_from_tool ();
		});
		
		r = r_default;
		g = g_default;
		b = b_default;
		a = a_default;
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
		tpa = MainWindow.get_tool_tip ();
							
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
	
	public bool set_active (bool ac) {
		bool ret = (active != ac);

		if (selected) {
			if (ac) {
				r = r_default_selected;
				g = g_default_selected;
				b = b_default_selected;
				a = a_default_selected * 0.5;
			} else {
				r = r_default_selected;
				g = g_default_selected;
				b = b_default_selected;
				a = a_default_selected;
			}			
		} else {
			if (ac) {
				r = r_default;
				g = g_default;
				b = b_default;
				a = a_default * 0.2;
			} else {
				r = r_default;
				g = g_default;
				b = b_default;
				a = a_default;
			}
		}

		active = ac;
		return ret;
	}
	
	public static double button_width_320dpi () {
		return 111.0;
	}

	public static double button_width_72dpi () {
		return 26.0;
	}
		
	public virtual void draw (Context cr) {
		double xt = x;
		double yt = y;
		
		double bgx, bgy;
		double iconx, icony;
		
		double scale;

		cr.save ();
		if (Icons.get_dpi () == 72) {
			scale = w / button_width_72dpi ();
		} else {
			scale = w / button_width_320dpi ();
		}
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
		
		// FIXME: DELETE
		/*
		cr.save ();
		cr.set_line_width (2);
		cr.set_source_rgba (0/255.0, 100/255.0, 0/255.0, 1);
		cr.rectangle (x, y, w, h);
		cr.stroke ();
		cr.restore ();
		*/
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
		
		while (unlikely (!acquired)) {
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
