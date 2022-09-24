/*
	Copyright (C) 2014 Johan Mattsson

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

public class SettingsItem : GLib.Object {	
	public bool handle_events;
	public bool key_bindings = false;
	public double y = 0;
	public Tool? button = null;
	public bool headline = false;
	public MenuItem menu_item = new MenuItem ("");
	public bool active = false;
	
	Text label;
	
	public SettingsItem (Tool tool, string description) {
		button = tool;
		label = new Text ();
		label.set_text (description);
		handle_events = true;
	}
	
	public SettingsItem.key_binding (MenuItem item) {
		if (item is ToolItem) {
			button = ((ToolItem) item).tool;
		}
		
		label = item.label;
		handle_events = false;
		key_bindings = true;
		menu_item = item;
	}
	
	public SettingsItem.head_line (string label) {
		this.label = new Text ();
		this.label.set_text (label);
		
		handle_events = false;
		headline = true;
	}

	public SettingsItem.color (string color) {
		ColorTool cb;
		Color c;
		
		c = Theme.get_color (color);

		label = new Text ();
		label.set_text (color);
		handle_events = true;
		
		cb = new ColorTool (color);
		cb.set_r (c.r);
		cb.set_g (c.g);
		cb.set_b (c.b);
		cb.set_a (c.a);
		
		cb.color_updated.connect (() => {
			TabBar tab_bar;
			
			Theme.save_color (color, cb.color_r, cb.color_g, cb.color_b, cb.color_a);
			
			tab_bar = MainWindow.get_tab_bar ();
			tab_bar.redraw (0, 0, tab_bar.width, tab_bar.height);
			GlyphCanvas.redraw ();
			Toolbox.redraw_tool_box ();
		});
	
		button = cb;
	}
	
	public void draw (WidgetAllocation allocation, Context cr) {
		Tool t;
		double label_x;
		
		if (headline) {
			cr.save ();
			Theme.color (cr, "Headline Background");
			cr.rectangle (0, y, allocation.width, 40);
			cr.fill ();
			cr.restore ();
				
			cr.save ();
			Theme.text_color (label, "Foreground Inverted");
			label.set_font_size (20);
			label.draw_at_baseline (cr, 21, y + 25);
			cr.restore ();
		} else {
			if (active) {
				cr.save ();
				Theme.color (cr, "Menu Background");
				cr.rectangle (0, y - 5, allocation.width, 40);
				cr.fill ();
				cr.restore ();
			}
			
			label_x = button != null ? 70 : 20;
			label_x *= MainWindow.units;
			
			if (button != null) {
				t = (!) button;
				t.draw (cr);
			}
			
			cr.save ();
			Theme.text_color (label, "Text Tool Box");
			label.set_font_size (17);
			label.draw_at_baseline (cr, label_x, y + 20);
			cr.restore ();
			
			if (key_bindings) {
				Text key_binding_text = new Text ();
				key_binding_text.set_text (menu_item.get_key_bindings ());
				cr.save ();
				
				if (active) {
					Theme.text_color (key_binding_text, "Foreground Inverted");
				} else {
					Theme.text_color (key_binding_text, "Text Tool Box");
				}
				
				key_binding_text.set_font_size (17);
				label_x += label.get_extent () + 20;
				key_binding_text.draw_at_baseline (cr, label_x, y + 20);
				cr.restore ();
			}	
		}
	}
}

}
