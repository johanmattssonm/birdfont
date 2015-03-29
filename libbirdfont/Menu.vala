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
using Bird;

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
				if (tab_name == "Preview") {
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
	
	public Gee.HashMap<string, MenuItem> menu_items = new Gee.HashMap<string, MenuItem> ();
	public Gee.ArrayList<MenuItem> sorted_menu_items = new Gee.ArrayList<MenuItem> ();

	public Menu () {
		SubMenu menu = new SubMenu ();
		SubMenu file_menu = new SubMenu ();
		SubMenu edit_menu = new SubMenu ();
		SubMenu tab_menu = new SubMenu ();
		SubMenu kerning_menu = new SubMenu ();
		SubMenu ligature_menu = new SubMenu ();
		SubMenu git_menu = new SubMenu ();
		
		// file menu
		MenuItem file = add_menu_item (t_("File"));
		file.action.connect (() => {
			set_menu (file_menu);
		});
		menu.items.add (file);

		MenuItem new_file = add_menu_item (t_("New"), "new");
		new_file.action.connect (() => {
			MenuTab.new_file ();
			show_menu = false;
		});
		file_menu.items.add (new_file);
				
		MenuItem open = add_menu_item (t_("Open"), "open");
		open.action.connect (() => {
			show_menu = false;
			MenuTab.load ();
		});
		file_menu.items.add (open);

		MenuItem recent_files = add_menu_item (t_("Recent Files"), "recent files");
		recent_files.action.connect (() => {
			show_menu = false;
			MainWindow.open_recent_files_tab ();
		});
		file_menu.items.add (recent_files);
		
		MenuItem save = add_menu_item (t_("Save"), "save");
		save.action.connect (() => {
			MenuTab.save ();
			show_menu = false;
		});
		file_menu.items.add (save);

		MenuItem save_as = add_menu_item (t_("Save As"), "save as");
		save_as.action.connect (() => {
			MenuTab.save_as ();
			show_menu = false;
		});
		file_menu.items.add (save_as);

		MenuItem export = add_menu_item (t_("Export"), "export");
		export.action.connect (() => {
			MenuTab.export_fonts_in_background ();
			show_menu = false;
		});
		file_menu.items.add (export);

		MenuItem preview = add_menu_item (t_("Preview"), "preview");
		preview.action.connect (() => {
			MenuTab.preview ();
			show_menu = false;
		});
		file_menu.items.add (preview);

		MenuItem select_character_set = add_menu_item (t_("Select Character Set"), "select character set");
		select_character_set.action.connect (() => {
			MenuTab.select_language ();
			show_menu = false;
		});
		file_menu.items.add (select_character_set);

		MenuItem quit = add_menu_item (t_("Quit"), "quit");
		quit.action.connect (() => {
			MenuTab.quit ();
			show_menu = false;
		});
		file_menu.items.add (quit);

		// edit menu
		MenuItem edit = add_menu_item (t_("Edit"));
		edit.action.connect (() => {
			set_menu (edit_menu);
		});
		menu.items.add (edit);

		MenuItem undo = add_menu_item (t_("Undo"), "undo");
		undo.action.connect (() => {
			TabContent.undo ();
			show_menu = false;
		});
		edit_menu.items.add (undo);

		MenuItem redo = add_menu_item (t_("Redo"), "redo");
		redo.action.connect (() => {
			TabContent.redo ();
			show_menu = false;
		});
		edit_menu.items.add (redo);

		MenuItem copy = add_menu_item (t_("Copy"), "copy");
		copy.action.connect (() => {
			ClipTool.copy ();
			show_menu = false;
		});
		edit_menu.items.add (copy);

		MenuItem paste = add_menu_item (t_("Paste"), "paste");
		paste.action.connect (() => {
			ClipTool.paste ();
			show_menu = false;
		});
		edit_menu.items.add (paste);

		MenuItem paste_in_place = add_menu_item (t_("Paste In Place"), "paste in place", "Glyph");
		paste_in_place.action.connect (() => {
			ClipTool.paste_in_place ();
			show_menu = false;
		});
		edit_menu.items.add (paste_in_place);
		
		MenuItem select_all_paths = add_menu_item (t_("Select All Paths"), "select all paths", "Glyph");
		select_all_paths.action.connect (() => {
			MainWindow.select_all_paths ();
			show_menu = false;
		});
		edit_menu.items.add (select_all_paths);

		MenuItem move_to_baseline = add_menu_item (t_("Move To Baseline"), "move to baseline", "Glyph");
		move_to_baseline.action.connect (() => {
			MenuTab.move_to_baseline ();
			show_menu = false;
		});
		edit_menu.items.add (move_to_baseline);

		MenuItem search = add_menu_item (t_("Search"), "search");
		search.action.connect (() => {
			OverView.search ();
			show_menu = false;
		});
		edit_menu.items.add (search);

		MenuItem export_glyph = add_menu_item (t_("Export Glyph as SVG"), "export glyph as svg", "Glyph");
		export_glyph.action.connect (() => {
			ExportTool.export_current_glyph ();
			show_menu = false;
		});
		edit_menu.items.add (export_glyph);

		MenuItem import_svg = add_menu_item (t_("Import SVG file"), "import svg file", "Glyph");
		import_svg.action.connect (() => {
			SvgParser.import ();
			show_menu = false;
		});
		edit_menu.items.add (import_svg);

		MenuItem import_background_image = add_menu_item (t_("Import Background Image"), "import background image");
		import_background_image.action.connect (() => {
			MenuTab.show_background_tab ();
			show_menu = false;
		});
		edit_menu.items.add (import_background_image);

		MenuItem simplify_path = add_menu_item (t_("Simplify Path"), "simplify path", "Glyph");
		simplify_path.action.connect (() => {
			MenuTab.simplify_path ();
			show_menu = false;
		});
		edit_menu.items.add (simplify_path);

		MenuItem close_path = add_menu_item (t_("Close Path"), "close path", "Glyph");
		close_path.action.connect (() => {
			PenTool.close_all_paths ();
			show_menu = false;
		});
		edit_menu.items.add (close_path);

		MenuItem glyph_sequence = add_menu_item (t_("Glyph Sequence"), "glyph sequence");
		glyph_sequence.action.connect (() => {
			MainWindow.update_glyph_sequence ();
			show_menu = false;
		});
		edit_menu.items.add (glyph_sequence);

		MenuItem set_background_glyph = add_menu_item (t_("Set Background Glyph"), "set background glyph", "Glyph");
		set_background_glyph.action.connect (() => {
			MenuTab.use_current_glyph_as_background ();
			show_menu = false;
		});
		edit_menu.items.add (set_background_glyph);

		MenuItem remove_background_glyph = add_menu_item (t_("Remove Background Glyph"), "remove background glyph", "Glyph");
		remove_background_glyph.action.connect (() => {
			MenuTab.reset_glyph_background ();
			show_menu = false;
		});
		edit_menu.items.add (remove_background_glyph);

		MenuItem create_guide = add_menu_item (t_("Create Guide"), "create guide");
		create_guide.action.connect (() => {
			MainWindow.get_current_glyph ().add_custom_guide ();
			show_menu = false;
		});
		edit_menu.items.add (create_guide);

		MenuItem show_guide_guide = add_menu_item (t_("List Guides"), "show guide tab");
		show_guide_guide.action.connect (() => {
			MenuTab.show_guide_tab ();
			show_menu = false;
		});
		edit_menu.items.add (show_guide_guide);
		
		MenuItem select_point_above = add_menu_item (t_("Select Point Above"), "select point above", "Glyph");
		select_point_above.action.connect (() => {
			PenTool.select_point_up ();
			show_menu = false;
		});
		edit_menu.items.add (select_point_above);

		MenuItem select_next_point = add_menu_item (t_("Select Next Point"), "select next point", "Glyph");
		select_next_point.action.connect (() => {
			PenTool.select_point_right ();
			show_menu = false;
		});
		edit_menu.items.add (select_next_point);
		
		MenuItem select_previous_point = add_menu_item (t_("Select Previous Point"), "select previous point", "Glyph");
		select_previous_point.action.connect (() => {
			PenTool.select_point_left ();
			show_menu = false;
		});
		edit_menu.items.add (select_previous_point);

		MenuItem select_point_below = add_menu_item (t_("Select Point Below"), "select point below", "Glyph");
		select_point_below.action.connect (() => {
			PenTool.select_point_down ();
			show_menu = false;
		});
		edit_menu.items.add (select_point_below);

		// tab menu
		MenuItem tab = add_menu_item (t_("Tab"));
		tab.action.connect (() => {
			set_menu (tab_menu);
		});
		menu.items.add (tab);

		MenuItem next_tab = add_menu_item (t_("Next Tab"), "next tab");
		next_tab.action.connect (() => {
			MainWindow.next_tab ();
			show_menu = false;
		});
		tab_menu.items.add (next_tab);

		MenuItem previous_tab = add_menu_item (t_("Previous Tab"), "previous tab");
		previous_tab.action.connect (() => {
			MainWindow.previous_tab ();
			show_menu = false;
		});
		tab_menu.items.add (previous_tab);

		MenuItem close_tab = add_menu_item (t_("Close Tab"), "close tab");
		close_tab.action.connect (() => {
			MainWindow.close_tab ();
			show_menu = false;
		});
		tab_menu.items.add (close_tab);
		
		MenuItem close_all_tabs = add_menu_item (t_("Close All Tabs"), "close all tabs");
		close_all_tabs.action.connect (() => {
			MainWindow.close_all_tabs ();
			show_menu = false;
		});
		tab_menu.items.add (close_all_tabs);
		
		// tab menu
		MenuItem kerning = add_menu_item (t_("Spacing and Kerning"));
		kerning.action.connect (() => {
			set_menu (kerning_menu);
		});
		menu.items.add (kerning);

		MenuItem spacing_tab = add_menu_item (t_("Show Spacing Tab"), "show spacing tab");
		spacing_tab.action.connect (() => {
			MenuTab.show_spacing_tab ();
			show_menu = false;
		});
		kerning_menu.items.add (spacing_tab);
		
		MenuItem kerning_tab = add_menu_item (t_("Show Kerning Tab"), "show kerning tab");
		kerning_tab.action.connect (() => {
			MenuTab.show_kerning_context ();
			show_menu = false;
		});
		kerning_menu.items.add (kerning_tab);

		MenuItem list_kernings = add_menu_item (t_("List Kerning Pairs"), "list kerning pairs");
		list_kernings.action.connect (() => {
			MenuTab.list_all_kerning_pairs ();
			show_menu = false;
		});
		kerning_menu.items.add (list_kernings);

		MenuItem show_spacing = add_menu_item (t_("Spacing Classes"), "show spacing classes");
		show_spacing.action.connect (() => {
			MenuTab.show_spacing_class_tab ();
			show_menu = false;
		});
		kerning_menu.items.add (show_spacing);

		MenuItem next_kerning_pair = add_menu_item (t_("Select Next Kerning Pair"), "select next kerning pair");
		next_kerning_pair.action.connect (() => {
			KerningDisplay.next_pair ();
			show_menu = false;
		});
		next_kerning_pair.add_display("Kerning");
		next_kerning_pair.add_display("Spacing");
		kerning_menu.items.add (next_kerning_pair);

		MenuItem previous_kerning_pair = add_menu_item (t_("Select Previous Kerning Pair"), "select previous kerning pair");
		previous_kerning_pair.action.connect (() => {
			KerningDisplay.previous_pair ();
			show_menu = false;
		});
		previous_kerning_pair.add_display("Kerning");
		previous_kerning_pair.add_display("Spacing");
		kerning_menu.items.add (previous_kerning_pair);

		MenuItem load_kerning_strings = add_menu_item (t_("Load Kerning Strings"), "load kerning strings");
		load_kerning_strings.action.connect (() => {
			BirdFont.get_current_font ().kerning_strings.load_file ();
			show_menu = false;
		});
		kerning_menu.items.add (load_kerning_strings);

		MenuItem reload_kerning_strings = add_menu_item (t_("Reload Kerning Strings"), "reloadload kerning strings");
		reload_kerning_strings.action.connect (() => {
			Font f = BirdFont.get_current_font ();
			f.kerning_strings.load (f);
			show_menu = false;
		});
		kerning_menu.items.add (reload_kerning_strings);
				
		// ligature menu
		MenuItem ligature = add_menu_item (t_("Ligatures"));
		ligature.action.connect (() => {
			set_menu (ligature_menu);
		});
		menu.items.add (ligature);

		MenuItem ligature_tab = add_menu_item (t_("Show Ligatures"), "show ligature tab");
		ligature_tab.action.connect (() => {
			MenuTab.show_ligature_tab ();
			show_menu = false;
		});
		ligature_menu.items.add (ligature_tab);

		MenuItem add_ligature = add_menu_item (t_("Add Ligature"), "add ligature");
		add_ligature.action.connect (() => {
			MenuTab.add_ligature ();
			show_menu = false;
		});
		ligature_menu.items.add (add_ligature);
		
		// git menu
		if (BirdFont.has_argument ("--test")) {
			MenuItem git = add_menu_item (t_("Git"));
			git.action.connect (() => {
				set_menu (git_menu);
			});
			menu.items.add (git);

			MenuItem save_bfp = add_menu_item (t_("Save As .bfp"), "save as .bfp");
			save_bfp.action.connect (() => {
				MenuTab.save_as_bfp ();
				show_menu = false;
			});
			git_menu.items.add (save_bfp);	
		}
												
		// show overview
		MenuItem overview = add_menu_item (t_("Overview"));
		overview.action.connect (() => {
			MenuTab.select_overview ();
			show_menu = false;
		});
		menu.items.add (overview);

		// settings 
		MenuItem settings = add_menu_item (t_("Settings"), "settings");
		settings.action.connect (() => {
			MenuTab.show_settings_tab ();
			show_menu = false;
		});
		menu.items.add (settings);

		MenuItem description = add_menu_item (t_("Name and Description"), "name and description");
		description.action.connect (() => {
			MenuTab.show_description ();
			show_menu = false;
		});
		menu.items.add (description);
																						
		current_menu = menu;
		top_menu = menu;
		allocation = new WidgetAllocation ();

		add_tool_key_bindings ();
		load_key_bindings ();
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

	void load_key_bindings () {
		File default_key_bindings = SearchPaths.find_file (null, "key_bindings.xml");
		File user_key_bindings = get_child (BirdFont.get_settings_directory (), "key_bindings.xml");
		
		if (default_key_bindings.query_exists ()) {
			parse_key_bindings (default_key_bindings);
		}

		if (user_key_bindings.query_exists ()) {
			parse_key_bindings (user_key_bindings);
		}
	}

	void parse_key_bindings (File f) {
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

	void parse_bindings (Tag tag) {
		foreach (Tag t in tag) {
			if (t.get_name () == "action") {
				parse_binding (t.get_attributes ());
			}
		}
	}

	void parse_binding (Attributes attr) {
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
	
	MenuItem add_menu_item (string label, string description = "", string display = "") {
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

	void add_tool_key_bindings () {
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
			Theme.color (cr, "Background 3");
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

	public class SubMenu : GLib.Object { 
		public Gee.ArrayList<MenuItem> items;
		
		public SubMenu () {
			items = new Gee.ArrayList<MenuItem> ();
		}
	}
}

}
