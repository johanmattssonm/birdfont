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
using B;

namespace BirdFont {

/** Interface for events from native window to the current tab. */
public class AbstractMenu : GLib.Object {

	public bool show_menu {
		get  {
			return menu_visibility;
		}
		
		set {
			string tab_name;
			
			menu_visibility = value;
			current_menu = top_menu;
			
			if (menu_visibility) {
				tab_name = MainWindow.get_tab_bar ().get_selected_tab ().get_display ().get_name ();
				if (tab_name == "Preview") {
					MenuTab.select_overview ();
				}
			}
		}
	}
	
	public bool menu_visibility = false;
	public SubMenu top_menu;

	SubMenu current_menu;
	WidgetAllocation allocation = new WidgetAllocation ();

	double width = 250 * MainWindow.units;
	double height = 25 * MainWindow.units;
	
	public Gee.HashMap<string, MenuItem> menu_items = new Gee.HashMap<string, MenuItem> ();
	public Gee.ArrayList<MenuItem> sorted_menu_items = new Gee.ArrayList<MenuItem> ();

	public AbstractMenu () {
	}

	public void process_key_binding_events (uint keyval) {
		string display;
		FontDisplay current_display = MainWindow.get_current_display ();
		ToolItem tm;
		
		foreach (MenuItem item in sorted_menu_items) {		
			if (item.key == (unichar) keyval && item.modifiers == KeyBindings.modifier) {
				
				display = current_display.get_name ();

				if (current_display is Glyph) {
					display = "Glyph";
				}

				if (!current_display.needs_modifier () || item.modifiers != NONE) {
					if (!SettingsDisplay.update_key_bindings 
						&& item.in_display (display)
						&& !(item is ToolItem)) {
						item.action ();
						return;
					}
					
					if (item is ToolItem) {
						tm  = (ToolItem) item;
						
						if (tm.in_display (display)) {
							if (tm.tool.editor_events) {
								MainWindow.get_toolbox ().set_current_tool (tm.tool);
								tm.tool.select_action (tm.tool);
								return;
							} else {
								tm.tool.select_action (tm.tool);								
								return;
							}
						}
					}
				}
			}
		}
	}

	public void load_key_bindings () {
		File default_key_bindings = SearchPaths.find_file (null, "key_bindings.xml");
		File user_key_bindings = get_child (BirdFont.get_settings_directory (), "key_bindings.xml");
		
		if (default_key_bindings.query_exists ()) {
			parse_key_bindings (default_key_bindings);
		}

		if (user_key_bindings.query_exists ()) {
			parse_key_bindings (user_key_bindings);
		}
	}

	public void parse_key_bindings (File f) {
		string xml_data;
		XmlParser parser;
		
		try {
			FileUtils.get_contents((!) f.get_path (), out xml_data);
			parser = new XmlParser (xml_data);
			parse_bindings (parser.get_root_tag ());
		} catch (GLib.Error e) {
			warning (e.message);
		}
	}

	public void parse_bindings (Tag tag) {
		foreach (Tag t in tag) {
			if (t.get_name () == "action") {
				parse_binding (t.get_attributes ());
			}
		}
	}

	public void parse_binding (Attributes attr) {
		uint modifier = NONE;
		unichar key = '\0';
		string action = "";
		MenuItem menu_action;
		MenuItem? ma;
		
		foreach (Attribute a in attr) {
			if (a.get_name () == "key") {
				key = a.get_content ().get_char (0);
			}
			
			if (a.get_name () == "ctrl" && a.get_content () == "true") {
				modifier |= CTRL;
			}

			if (a.get_name () == "alt" && a.get_content () == "true") {
				modifier |= ALT;
			}

			if (a.get_name () == "command" && a.get_content () == "true") {
				modifier |= LOGO;
			}
			
			if (a.get_name () == "shift" && a.get_content () == "true") {
				modifier |= SHIFT;
			}
			
			if (a.get_name () == "action") {
				action = a.get_content ();
			}
		}
		
		ma = menu_items.get (action);
		if (ma != null) {
			menu_action = (!) ma;
			menu_action.modifiers = modifier;
			menu_action.key = key;
		}
	}
	
	public MenuItem add_menu_item (string label, string description = "", string display = "") {
		MenuItem i = new MenuItem (label, description);
		
		if (description != "") {
			menu_items.set (description, i);
			sorted_menu_items.add (i);
		}
		
		if (display != "") {
			i.add_display (display);
		}
								
		return i;
	}

	public void button_release (int button, double ex, double ey) {
		double y = 0;
		double x = allocation.width - width;
		
		if (button == 1) {
			foreach (MenuItem item in current_menu.items) {
				if (x <= ex < allocation.width && y <= ey <= y + height) {
					item.action ();
					GlyphCanvas.redraw ();
					return;
				}
				
				y += height;
			}
			
			menu_visibility = false;
			current_menu = (!) top_menu;
			GlyphCanvas.redraw ();
		}
	}

	public void add_tool_key_bindings () {
		ToolItem tool_item;
		foreach (ToolCollection tool_set in MainWindow.get_toolbox ().tool_sets) {
			foreach (Expander e in tool_set.get_expanders ()) {
				foreach (Tool t in e.tool) {
					tool_item = new ToolItem (t);
					if (tool_item.identifier != "" && !has_menu_item (tool_item.identifier)) {
						menu_items.set (tool_item.identifier, tool_item);
						sorted_menu_items.add (tool_item);
					}
					
					foreach (string d in tool_set.get_displays ()) {
						tool_item.add_display (d);
					}
				}
			}
		}
	}

	public bool has_menu_item (string identifier) {
		foreach (MenuItem mi in sorted_menu_items) {
			if (mi.identifier == identifier) {
				return true;
			}
		}
		
		return false;
	}

	public void set_menu (SubMenu m) {
		current_menu = m;
		GlyphCanvas.redraw ();
	}
	
	public double layout_width () {
		Text key_binding = new Text ();
		double font_size = 17 * MainWindow.units;;
		double w;
		
		width = 0;
		foreach (MenuItem item in current_menu.items) {
			key_binding.set_text (item.get_key_bindings ());
			
			item.label.set_font_size (font_size);
			key_binding.set_font_size (font_size);
			
			w = item.label.get_extent ();
			w += key_binding.get_extent ();
			w += 3 * height * MainWindow.units;
			
			if (w > width) {
				width = w;
			}
		}
		
		return width;
	}
	
	public void draw (WidgetAllocation allocation, Context cr) {
		double y;
		double x;
		double label_x;
		double label_y;
		double font_size;
		Text key_binding;
		double binding_extent;
		
		width = layout_width ();
		
		key_binding = new Text ();
		
		x = allocation.width - width;
		y = 0;
		font_size = 17 * MainWindow.units;
		this.allocation = allocation;
		
		foreach (MenuItem item in current_menu.items) {
			cr.save ();
			Theme.color (cr, "Menu Background");
			cr.rectangle (x, y, width, height);
			cr.fill ();
			cr.restore ();
			
			cr.save ();
			label_x = allocation.width - width + 0.7 * height * MainWindow.units;
			label_y = y + font_size - 1 * MainWindow.units;
			Theme.text_color (item.label, "Menu Foreground");
			item.label.draw_at_baseline (cr, label_x, label_y);
			
			key_binding.set_text (item.get_key_bindings ());
			key_binding.set_font_size (font_size);
			binding_extent = key_binding.get_extent ();
			label_x = x + width - binding_extent - 0.6 * height * MainWindow.units;
			key_binding.set_font_size (font_size);
			Theme.text_color (key_binding, "Menu Foreground");
			key_binding.draw_at_baseline (cr, label_x, label_y);
			
			y += height;
		}
	}

	public void write_key_bindings () {
		DataOutputStream os;
		File file;
		bool has_ctrl, has_alt, has_command, has_shift;
		
		file = get_child (BirdFont.get_settings_directory (), "key_bindings.xml");
		
		try {
			if (file.query_exists ()) {
				file.delete ();
			}
		} catch (GLib.Error e) {
			warning (e.message);
		}
		
		try {
			os = new DataOutputStream (file.create (FileCreateFlags.REPLACE_DESTINATION));
			os.put_string ("""<?xml version="1.0" encoding="utf-8" standalone="yes"?>""");
			os.put_string ("\n");
			
			os.put_string ("<bindings>\n");
			
			foreach (MenuItem item in sorted_menu_items) {
				os.put_string ("\t<action ");
				
				os.put_string (@"key=\"$((!)item.key.to_string ())\" ");
				
				has_ctrl = (item.modifiers & CTRL) > 0;
				os.put_string (@"ctrl=\"$(has_ctrl.to_string ())\" ");

				has_alt = (item.modifiers & ALT) > 0;
				os.put_string (@"alt=\"$(has_alt.to_string ())\" ");		

				has_command = (item.modifiers & LOGO) > 0;
				os.put_string (@"command=\"$(has_command.to_string ())\" ");
					
				has_shift = (item.modifiers & SHIFT) > 0;
				os.put_string (@"shift=\"$(has_shift.to_string ())\" ");			
				
				os.put_string (@"action=\"$(item.identifier)\" ");
				
				os.put_string ("/>\n");
			}
			os.put_string ("</bindings>\n");
			
			os.close ();
		} catch (GLib.Error e) {
			warning (e.message);
		}
	}
	
	public void set_current_menu (SubMenu menu) {
		current_menu = menu;	
	}
}

}
