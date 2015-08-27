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

public abstract class SettingsDisplay : FontDisplay {
	
	double scroll = 0;
	double content_height = 1;
	WidgetAllocation allocation;
	public Gee.ArrayList<SettingsItem> tools;

	public static SpinButton precision;
	
	SettingsItem new_key_bindings = new SettingsItem.head_line ("");
	public static bool update_key_bindings = false;
	
	public SettingsDisplay () {
		allocation = new WidgetAllocation ();
		tools = new Gee.ArrayList<SettingsItem> ();
		content_height = 200;
		precision = new SpinButton ("precision");
	}
	
	public abstract void create_setting_items ();

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
		
		foreach (SettingsItem s in tools) {
			if (-20 * MainWindow.units <= s.y <= allocation.height + 20 * MainWindow.units) {
				s.draw (allocation, cr);
			}
		}
	}	

	public void layout () {
		double y = -scroll;
		bool first = true;
		foreach (SettingsItem s in tools) {
			
			if (!first && s.headline) {
				y += 30 * MainWindow.units;
			}
			
			s.y = y;
			
			if (s.button != null) {
				((!) s.button).y = y;
				((!) s.button).x = 20 * MainWindow.units;
			}
			
			if (s.headline) {
				y += 50 * MainWindow.units;
			} else {
				y += 40 * MainWindow.units;
			}
			
			first = false;
		}

		content_height = y + scroll;
	}

	void set_key_bindings (SettingsItem item) {	
		if (new_key_bindings.active) {
			new_key_bindings.active = false;
			update_key_bindings = false;
		} else {	
			new_key_bindings.active = false;
			new_key_bindings = item;
			update_key_bindings = true;
			new_key_bindings.active = true;
		}
	}

	public override void key_release (uint keyval) {
		SettingsItem old_key_binding;
		
		if (!is_modifier_key (keyval) || keyval == Key.BACK_SPACE || keyval == Key.DEL) {
			if (update_key_bindings) {
				if (keyval == Key.BACK_SPACE || keyval == Key.DEL) {
					update_key_bindings = false;
					new_key_bindings.active = false;
					new_key_bindings.menu_item.modifiers = NONE;
					new_key_bindings.menu_item.key = '\0';
				} else if (KeyBindings.get_mod_from_key (keyval) == NONE) {
					
					if (has_key_binding (KeyBindings.modifier, (unichar) keyval)) {
						old_key_binding = (!) get_key_binding (KeyBindings.modifier, (unichar) keyval);
						old_key_binding.menu_item.modifiers = NONE;
						old_key_binding.menu_item.key = '\0';
					}
					
					new_key_bindings.menu_item.modifiers = KeyBindings.modifier;
					new_key_bindings.menu_item.key = (unichar) keyval;
					update_key_bindings = false;
					new_key_bindings.active = false;
				}
				
				MainWindow.get_menu ().write_key_bindings ();
				GlyphCanvas.redraw ();	
			}
		}
	}

	bool has_key_binding (uint modifier, unichar key) {
		return get_key_binding (modifier, key) != null;
	}
	
	SettingsItem? get_key_binding (uint modifier, unichar key) {
		foreach (SettingsItem i in tools) {
			if (i.menu_item.modifiers == modifier && i.menu_item.key == key) {
				return i;
			}
		}
		
		return null; 
	}

	public override void button_press (uint button, double x, double y) {
		foreach (SettingsItem s in tools) {
			if (s.handle_events && s.button != null) {
				if (((!) s.button).is_over (x, y)) {
					
					((!) s.button).set_selected (! ((!) s.button).selected);
					
					if (((!) s.button).selected) {
						((!) s.button).select_action ((!) s.button);
					}
					
					((!) s.button).panel_press_action ((!) s.button, button, x, y);
				}
			}
		}
		GlyphCanvas.redraw ();
	}
	
	public override void button_release (int button, double x, double y) {
		foreach (SettingsItem s in tools) {
			if (s.handle_events && s.button != null) {
				((!) s.button).panel_release_action (((!) s.button), button, x, y);
			}
			
			if (s.key_bindings && s.y <= y < s.y + 40 * MainWindow.units && button == 1) {
				set_key_bindings (s);
			}
		}
		GlyphCanvas.redraw ();
	}

	public override void motion_notify (double x, double y) {
		bool consumed = false;
		bool active;
		bool update = false;
		
		foreach (SettingsItem si in tools) {
			
			if (si.handle_events && si.button != null) {
				active = ((!) si.button).is_over (x, y);

				if (!active && ((!) si.button).is_active ()) {
					((!) si.button).move_out_action ((!) si.button);
				}
						
				if (((!) si.button).set_active (active)) {
					update = true;
				}	
			}	
		}
		
		foreach (SettingsItem s in tools) {
			if (s.handle_events && s.button != null) {
				if (((!) s.button).panel_move_action ((!) s.button, x, y)) {
					consumed = true;
				}
			}
		}
		
		if (consumed || update) {
			GlyphCanvas.redraw ();
		}
	}

	public override string get_label () {
		return t_("Settings");
	}

	public override string get_name () {
		return "Settings";
	}

	public override bool has_scrollbar () {
		return true;
	}
	
	public override void scroll_wheel (double x, double y, double pixeldelta, double dy) {
		if (dy < 0) {
			foreach (SettingsItem s in tools) {
				if (s.handle_events && s.button != null) {
					if (((!) s.button).is_over (x, y)) {
						((!) s.button).scroll_wheel_down_action ((!) s.button);
						return;
					}
				}
			}
		} else {
			foreach (SettingsItem s in tools) {
				if (s.handle_events && s.button != null) {
					if (((!) s.button).is_over (x, y)) {
						((!) s.button).scroll_wheel_up_action ((!) s.button);
						return;
					}
				}
			}		
		}
		
		scroll -= dy * MainWindow.units;

		if (scroll + allocation.height >=  content_height) {
			scroll = content_height - allocation.height;
		}

		if (scroll < 0) {
			scroll = 0;
		}
				
		update_scrollbar ();
		GlyphCanvas.redraw ();
	}

	public override void selected_canvas () {
		MainWindow.get_toolbox ().set_default_tool_size ();
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
