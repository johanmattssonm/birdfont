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
public class Menu : AbstractMenu {
	
	public Menu () {
		base ();
		
		SubMenu menu = new SubMenu ();
		SubMenu file_menu = new SubMenu ();
		SubMenu edit_menu = new SubMenu ();
		SubMenu layers_menu = new SubMenu ();
		SubMenu export_menu = new SubMenu ();
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

		MenuItem select_all_glyphs = add_menu_item (t_("Select All Glyphs"), "select all glyphs", "Overview");
		select_all_glyphs.action.connect (() => {
			MainWindow.get_overview ().select_all_glyphs ();
			show_menu = false;
		});
		edit_menu.items.add (select_all_glyphs);

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

		MenuItem simplify_path = add_menu_item (t_("Simplify Path"), "simplify path", "Glyph");
		simplify_path.action.connect (() => {
			MenuTab.simplify_path ();
			show_menu = false;
		});
		edit_menu.items.add (simplify_path);

		MenuItem merge_paths = add_menu_item (t_("Merge Paths"), "merge_paths", "Glyph");
		merge_paths.action.connect (() => {
			Task t = new Task ();
			t.task.connect (merge_selected_paths);
			MainWindow.native_window.run_background_thread (t);
		
			show_menu = false;
		});
		edit_menu.items.add (merge_paths);

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
		
		// layers
		MenuItem layers = add_menu_item (t_("Layers"));
		layers.action.connect (() => {
			set_menu (layers_menu);
		});
		menu.items.add (layers);
		
		MenuItem layer_up = add_menu_item (t_("Move Layer Up"), "move layer up", "Glyph");
		layer_up.action.connect (() => {
			MainWindow.get_current_glyph ().move_layer_up ();
			DrawingTools.update_layers ();
		});
		layers_menu.items.add (layer_up);

		MenuItem layer_down = add_menu_item (t_("Move Layer Down"), "move layer down", "Glyph");
		layer_down.action.connect (() => {
			MainWindow.get_current_glyph ().move_layer_down ();
			DrawingTools.update_layers ();
		});
		layers_menu.items.add (layer_down);
		
		// import and export
		MenuItem export = add_menu_item (t_("Import and Export"));
		export.action.connect (() => {
			set_menu (export_menu);
		});
		menu.items.add (export);

		MenuItem export_fonts = add_menu_item (t_("Export Fonts"), "export");
		export_fonts.action.connect (() => {
			MenuTab.export_fonts_in_background ();
			show_menu = false;
		});
		export_menu.items.add (export_fonts);

		MenuItem export_glyph = add_menu_item (t_("Export Glyph as SVG"), "export glyph as svg", "Glyph");
		export_glyph.action.connect (() => {
			ExportTool.export_current_glyph ();
			show_menu = false;
		});
		export_menu.items.add (export_glyph);

		MenuItem import_svg = add_menu_item (t_("Import SVG file"), "import svg file", "Glyph");
		import_svg.action.connect (() => {
			SvgParser.import ();
			show_menu = false;
		});
		export_menu.items.add (import_svg);
		
		MenuItem import_svg_folder = add_menu_item (t_("Import SVG folder"), "import svg folder", "");
		import_svg_folder.action.connect (() => {
			SvgParser.import_folder ();
			show_menu = false;
		});
		export_menu.items.add (import_svg_folder);
		
		MenuItem import_background_image = add_menu_item (t_("Import Background Image"), "import background image");
		import_background_image.action.connect (() => {
			MenuTab.show_background_tab ();
			show_menu = false;
		});
		export_menu.items.add (import_background_image);

		MenuItem export_settings = add_menu_item (t_("Export Settings"), "export settings");
		export_settings.action.connect (() => {
			MenuTab.show_export_settings_tab ();
			show_menu = false;
		});
		export_menu.items.add (export_settings);
		
		MenuItem preview = add_menu_item (t_("Preview"), "preview");
		preview.action.connect (() => {
			MenuTab.preview ();
			show_menu = false;
		});
		export_menu.items.add (preview);
		
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

		MenuItem version = add_menu_item (t_("Version"), "birdfont version");
		version.action.connect (() => {
			MainWindow.show_message (t_("Version") + ": " + get_version ());
			show_menu = false;
		});
		menu.items.add (version);
	
		set_current_menu (menu);
		top_menu = menu;
		
		add_tool_key_bindings ();
		load_key_bindings ();
	}
	
	void merge_selected_paths () {
		StrokeTool.merge_selected_paths ();
	}
}

}
