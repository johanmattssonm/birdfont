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

class SettingsItem : GLib.Object {	
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
	
	public void draw (WidgetAllocation allocation, Context cr) {
		Tool t;
		double label_x;
		
		if (headline) {
			cr.save ();
			cr.set_source_rgba (101 / 255.0, 108 / 255.0, 116 / 255.0, 1);
			cr.rectangle (0, y, allocation.width, 40 * MainWindow.units);
			cr.fill ();
			cr.restore ();
				
			cr.save ();
			cr.set_source_rgba (1, 1, 1, 1);
			label.draw (cr, 21 * MainWindow.units, y + 25 * MainWindow.units, 20 * MainWindow.units);
			cr.restore ();
		} else {
			if (active) {
				cr.save ();
				cr.set_source_rgba (38 / 255.0, 39 / 255.0, 43 / 255.0, 1);
				cr.rectangle (0, y - 5 * MainWindow.units, allocation.width, 40 * MainWindow.units);
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
			cr.set_source_rgba (101 / 255.0, 108 / 255.0, 116 / 255.0, 1);
			label.draw (cr, label_x, y + 20 * MainWindow.units, 17 * MainWindow.units);
			cr.restore ();
			
			if (key_bindings) {
				Text key_binding_text = new Text ();
				key_binding_text.set_text (menu_item.get_key_bindings ());
				cr.save ();
				cr.set_source_rgba (101 / 255.0, 108 / 255.0, 116 / 255.0, 1);
				label_x += label.get_extent (17 * MainWindow.units) + 20 * MainWindow.units;
				key_binding_text.draw (cr, label_x, y + 20 * MainWindow.units, 17 * MainWindow.units);
				cr.restore ();
			}	
		}
	}
}

}
