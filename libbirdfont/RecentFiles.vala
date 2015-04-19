/*
    Copyright (C) 2015 Johan Mattsson

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

/** A list of recently edited fonts. */
public class RecentFiles : Table {
	Gee.ArrayList<Row> rows = new Gee.ArrayList<Row> ();
	
	const int NEW_FONT = -5;
	const int CURRENT_FONT = -4;
	const int RECENT_FONT = -3;
	const int BACKUP = -2;
	
	public RecentFiles () {
	}

	public override Gee.ArrayList<Row> get_rows () {
		return rows;
	}

	public override void selected_row (Row row, int column, bool delete_button) {	
		Font f;

		if (row.get_index () == NEW_FONT) {
			MenuTab.new_file ();
			MenuTab.select_overview ();
		} else if (row.get_index () == RECENT_FONT) {
			return_if_fail (row.get_row_data () is Font);
			f = (Font) row.get_row_data ();
			load_font (f.get_path ());
		} else if (row.get_index () == BACKUP) {
			return_if_fail (row.get_row_data () is Font);
			f = (Font) row.get_row_data ();
			delete_backup (f.get_file_name ());
		}
	}

	public override void update_rows () {
		Row row;
		Gee.ArrayList<Font> recent_fonts = get_recent_font_files ();
		Gee.ArrayList<Font> backups = get_backups ();
		Font current_font = BirdFont.get_current_font ();
		
		rows.clear ();

		if (recent_fonts.size == 0) {
			row = new Row.columns_1 (t_("Create a New Font"), NEW_FONT, false);
			rows.add (row);	
		}

		if (current_font.font_file != null) {
			row = new Row.headline (current_font.get_file_name ());
			rows.add (row);	
						
			row = new Row.columns_1 (t_("Folder") + ": " + (!) current_font.get_folder ().get_path (), CURRENT_FONT, false);
			rows.add (row);
			
			row = new Row.columns_1 (t_("Glyphs") + @": $(current_font.length ())", CURRENT_FONT, false);
			rows.add (row);
		}

		if (recent_fonts.size > 0) {
			row = new Row.headline (t_("Recent Files"));
			rows.add (row);	
		}
		
		foreach (Font font in recent_fonts) {
			row = new Row.columns_1 (font.get_file_name (), RECENT_FONT, false);
			row.set_row_data (font);
			rows.add (row);
		}

		if (backups.size > 0) {			
			row = new Row.headline (t_("Backups"));
			rows.add (row);	
		}
		
		foreach (Font font in backups) {
			row = new Row.columns_1 (font.get_file_name (), BACKUP, true);
			row.set_row_data (font);
			rows.add (row);
		}
		
		GlyphCanvas.redraw ();
	}

	public override string get_label () {
		return t_("Files");
	}

	public override string get_name () {
		return "Files";
	}

	public Gee.ArrayList<Font> get_recent_font_files () {
		File file;
		Font font;
		bool unique;
		Gee.ArrayList<Font> fonts = new Gee.ArrayList<Font> ();

		foreach (string f in Preferences.get_recent_files ()) {
			if (f == "") {
				continue;
			}
			
			file = File.new_for_path (f);

			font = new Font ();
			font.set_font_file (f);

			unique = true;
			foreach (Font recent_font in fonts) {
				if (recent_font.get_path () == f) {
					unique = false;
				}
			}
			
			if (unique && file.query_exists ()) { 
				fonts.insert (0, font);
			}
		}
		
		return fonts;	
	}

	public Gee.ArrayList<Font> get_backups () {
		FileEnumerator enumerator;
		string file_name;
		FileInfo? file_info;
		Gee.ArrayList<Font> backups = new Gee.ArrayList<Font> ();
		File dir = BirdFont.get_backup_directory ();
		Font font = BirdFont.get_current_font ();
		Font backup_font;

		try {
			enumerator = dir.enumerate_children (FileAttribute.STANDARD_NAME, 0);
			while ((file_info = enumerator.next_file ()) != null) {
				file_name = ((!) file_info).get_name ();
				
				// ignore old backup files
				if (file_name.has_prefix ("current_font_")) {
					continue;
				}
				
				// ignore backup of the current font
				if (file_name == @"$(font.get_name ()).bf") {
					continue;
				}
				
				backup_font = new Font ();
				backup_font.set_font_file ((!) get_child (dir, file_name).get_path ());
				backups.insert (0, backup_font);
			}
		} catch (Error e) {
			warning (e.message);
		}
    
		return backups;	
	}

	public void delete_backup (string file_name) {
		File backup_file;
		
		try {
			backup_file = BirdFont.get_backup_directory ();
			backup_file = get_child (backup_file, file_name);
			if (backup_file.query_exists ()) {
				backup_file.delete ();	
			}
		} catch (GLib.Error e) {
			warning (e.message);
		}
		
		selected_canvas ();
	}
	
	public static void load_font (string fn) {
		Font font;
		SaveDialogListener dialog = new SaveDialogListener ();

		if (MenuTab.suppress_event) {
			return;
		}
		
		font = BirdFont.get_current_font ();

		MenuTab.load_callback = new LoadCallback ();
		MenuTab.load_callback.file_loaded.connect (() => {
			Font f;

			if (MenuTab.suppress_event) {
				return;
			}
				
			f = BirdFont.get_current_font ();
			
			MainWindow.get_drawing_tools ().remove_all_grid_buttons ();
			foreach (string v in f.grid_width) {
				MainWindow.get_drawing_tools ().parse_grid (v);
			}
			
			DrawingTools.background_scale.set_value (f.background_scale);
			KerningTools.update_kerning_classes ();
			MenuTab.show_all_available_characters ();
		});

		MenuTab.load_callback.file_loaded.connect (() => {
			Font f = BirdFont.get_current_font ();
			MenuTab.set_font_setting_from_tools (f);
		});
			
		dialog.signal_discard.connect (() => {
			Font f;

			if (MenuTab.suppress_event) {
				return;
			}
					
			f = BirdFont.new_font ();
			
			MainWindow.clear_glyph_cache ();
			MainWindow.close_all_tabs ();
			
			f.set_file (fn);
			Preferences.add_recent_files (fn);
			
			MainWindow.native_window.load (); // background thread
		});

		dialog.signal_save.connect (() => {
			if (MenuTab.suppress_event) {
				warn_if_test ("Event suppressed.");
				return;
			}
			
			MenuTab.set_save_callback (new SaveCallback ());
			MenuTab.save_callback.file_saved.connect (() => {
				dialog.signal_discard ();
			});
			MenuTab.save_callback.save (); // background thread
		});

		dialog.signal_cancel.connect (() => {
			MainWindow.hide_dialog ();
		});
			
		if (!font.is_modified ()) {
			dialog.signal_discard ();
		} else {
			MainWindow.show_dialog (new SaveDialog (dialog));
		}
	}
}

}
