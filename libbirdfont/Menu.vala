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

namespace BirdFont {

/** Interface for events from native window to the current tab. */
public class Menu : GLib.Object {

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
				if (tab_name == "Description" || tab_name == "Preview") {
					MenuTab.select_overview ();
				}
			}
		}
	}
	
	public bool menu_visibility = false;
	public SubMenu top_menu;

	SubMenu current_menu;
	WidgetAllocation allocation;

	double width = 250 * MainWindow.units;
	double height = 25 * MainWindow.units;
		
	public Menu () {
		SubMenu menu = new SubMenu ();
		SubMenu file_menu = new SubMenu ();
		
		MenuItem file = new MenuItem (t_("File"));
		file.action.connect (() => {
			set_menu (file_menu);
		});
		
		menu.items.add (file);

		MenuItem new_file = new MenuItem (t_("New"), "new");
		new_file.action.connect (() => {
			MenuTab.new_file ();
			show_menu = false;
		});
		file_menu.items.add (new_file);
				
		MenuItem open = new MenuItem (t_("Open"), "open");
		open.action.connect (() => {
			show_menu = false;
			MenuTab.load ();
		});
		file_menu.items.add (open);

		MenuItem recent_files = new MenuItem (t_("Recent Files"), "recent files");
		recent_files.action.connect (() => {
			show_menu = false;
			MainWindow.open_recent_files_tab ();
		});
		file_menu.items.add (recent_files);
		
		MenuItem save = new MenuItem (t_("Save"), "save");
		save.action.connect (() => {
			MenuTab.save ();
			show_menu = false;
		});
		file_menu.items.add (save);

		MenuItem save_as = new MenuItem (t_("Save As"), "save as");
		save_as.action.connect (() => {
			MenuTab.save_as ();
			show_menu = false;
		});
		file_menu.items.add (save_as);

		MenuItem export = new MenuItem (t_("Export"), "export");
		export.action.connect (() => {
			MenuTab.export_fonts_in_background ();
			show_menu = false;
		});
		file_menu.items.add (export);

		MenuItem preview = new MenuItem (t_("Preview"), "preview");
		preview.action.connect (() => {
			MenuTab.preview ();
			show_menu = false;
		});
		file_menu.items.add (preview);

		MenuItem description = new MenuItem (t_("Name and Description"), "name and description");
		description.action.connect (() => {
			MenuTab.show_description ();
			show_menu = false;
		});
		file_menu.items.add (description);

		MenuItem select_character_set = new MenuItem (t_("Select Character Set"), "select character set");
		select_character_set.action.connect (() => {
			MenuTab.select_language ();
			show_menu = false;
		});
		file_menu.items.add (select_character_set);
		
		MenuItem settings = new MenuItem (t_("Settings"), "settings");
		settings.action.connect (() => {
			MenuTab.show_settings_tab ();
			show_menu = false;
		});
		file_menu.items.add (settings);

		MenuItem quit = new MenuItem (t_("Quit"), "quit");
		quit.action.connect (() => {
			MenuTab.quit ();
			show_menu = false;
		});
		file_menu.items.add (quit);
																		
		current_menu = menu;
		top_menu = menu;
		allocation = new WidgetAllocation ();
	}

	public void button_release (int button, double ex, double ey) {
		double y = 0;
		double x = allocation.width - width;
		
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

	public void set_menu (SubMenu m) {
		current_menu = m;
		GlyphCanvas.redraw ();
	}
	
	public void draw (WidgetAllocation allocation, Context cr) {
		double y = 0;
		double x = allocation.width - width;
		double label_x;
		double label_y;
		double font_size;
		
		this.allocation = allocation;
		
		foreach (MenuItem item in current_menu.items) {
			cr.save ();
			cr.set_source_rgba (38 / 255.0, 39 / 255.0, 43 / 255.0, 1);
			cr.rectangle (x, y, width, height);
			cr.fill ();
			cr.restore ();
			
			cr.save ();
			cr.set_source_rgba (101 / 255.0, 108 / 255.0, 116 / 255.0, 1);
			label_x = allocation.width - width + 0.7 * height * MainWindow.units;
			font_size = 17 * MainWindow.units;
			label_y = y + font_size - 1 * MainWindow.units;
			item.label.draw (cr, label_x, label_y, font_size);
						
			y += height;
		}
	}

	public class SubMenu : GLib.Object { 
		public Gee.ArrayList<MenuItem> items;
		
		public SubMenu () {
			items = new Gee.ArrayList<MenuItem> ();
		}
	}
	
	public class MenuItem : GLib.Object {
		
		public signal void action ();
		public Text label;
		public string identifier;
		
		public MenuItem (string label, string identifier = "") {
			this.label = new Text ();
			this.label.set_text (label);
			this.identifier = identifier;
		}
		
	}
}

}
