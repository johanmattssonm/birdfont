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

public class ThemeTab : SettingsDisplay {
	
	public ThemeTab () {
		base ();
		create_setting_items ();
	}
	
	public override void create_setting_items () {
		tools.clear ();
		tools.add (new SettingsItem.head_line (t_("Themes")));
		
		Gee.ArrayList<Tool> theme_buttons = new Gee.ArrayList<Tool> ();
		
		foreach (string theme in Theme.themes) {
			string label;
			Tool select_theme = new Tool (theme);
			
			select_theme.deselect_action.connect((self) => {
				self.set_active (false);
			});
			
			select_theme.select_action.connect((self) => {
				string theme_file = self.get_name ();
				TabBar tb;
				
				Preferences.set ("theme", theme_file);
				Theme.load_theme (theme_file);
					
				foreach (Tool t in theme_buttons) {
					t.set_selected (false);
					t.set_active (false);
				}
				
				self.set_selected (true);
				create_setting_items ();
				
				Toolbox.redraw_tool_box ();
				GlyphCanvas.redraw ();
				
				tb = MainWindow.get_tab_bar ();
				tb.redraw (0, 0, tb.width, tb.height);
			});
			
			select_theme.set_icon ("theme");
			
			label = get_label_from_file_name (theme);
			
			tools.add (new SettingsItem (select_theme, label));
			theme_buttons.add (select_theme);
			
			if (select_theme.get_name () == Theme.current_theme) {
				select_theme.set_selected (true);
			}
		}

		foreach (Tool t in theme_buttons) {
			t.set_selected (t.name == Theme.current_theme);
		}

		Tool add_theme = new Tool ("add_new_theme");
		add_theme.select_action.connect((self) => {
			foreach (Tool t in theme_buttons) {
				t.set_selected (false);
			}
			
			self.set_selected (false);
			Theme.add_new_theme (this); 
			GlyphCanvas.redraw ();
		});
		tools.add (new SettingsItem (add_theme, t_("Add new theme")));
		
		tools.add (new SettingsItem.head_line (t_("Colors")));

		foreach (string color in Theme.color_list) {
			SettingsItem s = new SettingsItem.color (color);
			ColorTool c = (ColorTool) ((!) s.button);
			
			tools.add (s);
			
			c.color_updated.connect (() => {
				create_setting_items ();
				GlyphCanvas.redraw ();
			});
		}		
	}

	public static string get_label_from_file_name (string theme) {
		string label;
		
		if (theme == "dark.theme") {
			label = t_("Dark");
		} else if (theme == "bright.theme") {
			label = t_("Bright");
		} else if (theme == "high_contrast.theme") {
			label = t_("High contrast");
		} else if (theme == "custom.theme") {
			label = t_("Custom");
		} else {
			label = theme.replace (".theme", "");
		}
		
		return label;
	}

	public override string get_label () {
		return t_("Themes");
	}

	public override string get_name () {
		return "Themes";
	}
}

}
