/*
    Copyright (C) 2013 2014 Johan Mattsson

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

public class FileTab : FontDisplay {
	
	int scroll = 0;
	int visible_rows = 0;
	double row_height;
	double top;
	WidgetAllocation allocation = new WidgetAllocation ();
	Gee.ArrayList<Font> recent_fonts = new Gee.ArrayList<Font> ();
	Gee.ArrayList<string> backups = new Gee.ArrayList<string> (); // FIXME: use ref counted object
	
	public signal void open_file ();
	
	public FileTab () {
		row_height = 30 * MainWindow.units;
		top = 2 * row_height;
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
		
		dialog.signal_discard.connect (() => {
			Font f;

			if (MenuTab.suppress_event) {
				return;
			}
					
			f = BirdFont.new_font ();
			
			MainWindow.clear_glyph_cache ();
			MainWindow.close_all_tabs ();
			
			f.set_file (fn);
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
		
		if (!font.is_modified ()) {
			dialog.signal_discard ();
		} else {
			MainWindow.native_window.set_save_dialog (dialog);
		}
	}
	
	public void load_backup (string file_name) {
		File backup_file;
		
		if (MenuTab.suppress_event) {
			return;
		}
		
		backup_file = BirdFont.get_backup_directory ();
		backup_file = get_child (backup_file, file_name);
		load_font ((!) backup_file.get_path ());
	}
	
	public void delete_backup (string file_name) {
		File backup_file;
		
		if (MenuTab.suppress_event) {
			return;
		}
		
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
	
	public override void button_release (int button, double ex, double ey) {
		int r, i;
		
		if (MenuTab.suppress_event) {
			return;
		}
		
		return_if_fail (!is_null(this));
		
		r = (int) rint ((ey - 17) / row_height) + scroll;
		i = scroll; 

		if (scroll == 0) {
			i += 2; // heading
		} else {
			i -= scroll; // no headline
		}

		if (button != 1) {
			return;
		}

		if (is_null (recent_fonts)) {
			warning ("No recent fonts");
			return;
		}
				
		foreach (Font font in recent_fonts) {
			
			if (is_null (font)) {
				warning ("Can't find font in list.");
				break;
			}

			if (is_null (font.font_file)) {
				warning ("File is not set for font.");
				break;
			}
						
			if (i == r) {
				load_font ((!) font.font_file);
				open_file ();

				// open_file will close this tab and the list of files 
				// will be deleted here.

				return;
			}
			i++;
		}

		if (is_null (backups)) {
			// FIXME:
			// warning ("No backups");
			return;
		}

		i += 2;
		foreach (string backup in backups) {
			if (i == r) {
				if (ex < 35) {
					delete_backup (backup);
				} else {
					load_backup (backup);
					open_file ();
					return;
				}
			}
			i++;
		}
	}
	
	public override void draw (WidgetAllocation allocation, Context cr) {
		double y = 0;
		int s = 0;
		bool color = (scroll % 2) == 0;
		
		this.allocation = allocation;
		
		if (scroll == 0) {
			y += top;
		}
		
		visible_rows = (int) (allocation.height / row_height);
		
		cr.save ();
		cr.set_source_rgba (1, 1, 1, 1);
		cr.rectangle (0, 0, allocation.width, allocation.height);
		cr.fill ();
		cr.restore ();

		if (recent_fonts.size == 0 && !has_backup ()) {
			cr.save ();
			cr.set_source_rgba (0.3, 0.3, 0.3, 1);
			cr.set_font_size (18 * MainWindow.units);
			cr.move_to (50 * MainWindow.units, top - 9 * MainWindow.units);
			cr.show_text (t_("No fonts created yet."));
			cr.restore ();
		}
		
		if (scroll == 0 && recent_fonts.size > 0) {
			cr.save ();
			cr.set_source_rgba (0.3, 0.3, 0.3, 1);
			cr.set_font_size (18 * MainWindow.units);
			cr.move_to (50 * MainWindow.units, top - 9 * MainWindow.units);
			cr.show_text (t_("Recent files"));
			cr.restore ();
		}
		
		cr.save ();
		cr.set_source_rgba (0.3, 0.3, 0.3, 1);
		cr.set_font_size (12 * MainWindow.units);

		foreach (Font font in recent_fonts) {
			if (s++ >= scroll) {
				draw_file_row (allocation, cr, font, color, y);
				y += row_height;
				color = !color;
			}
		}
		
		if (has_backup ()) {
			color = true;
			
			if (s >= scroll) {
				cr.save ();
				cr.set_source_rgba (0.3, 0.3, 0.3, 1);
				cr.set_font_size (18 * MainWindow.units);
				cr.move_to (50 * MainWindow.units, y + 2 * row_height - 9 * MainWindow.units);
				cr.show_text (t_("Backup"));
				cr.restore ();
				s += 2;
				y += 2 * row_height;
			}
			
			foreach (string backup in backups) {
				if (s++ >= scroll) {
					draw_backup_row (allocation, cr, backup, color, y);
					y += row_height;
					color = !color;
				}
			}	
		}

		cr.restore ();
	}

	private void draw_file_row (WidgetAllocation allocation, Context cr, Font font, bool color, double y) {
		string fn = (!) font.font_file;
		
		fn = fn.substring (fn.replace ("\\", "/").last_index_of ("/") + 1);
		draw_background (cr, allocation, y, color);
		
		cr.move_to (50 * MainWindow.units, y + row_height / 2 + 5 * MainWindow.units);
		cr.show_text (fn);
	}

	private void draw_backup_row (WidgetAllocation allocation, Context cr, string backup, bool color, double y) {
		File thumbnail;
		double u = MainWindow.units;
		
		thumbnail = get_child (BirdFont.get_thumbnail_directory (), backup);
			
		draw_background (cr, allocation, y, color);
		
		cr.move_to (50 * u, y + row_height / 2 + 5 * u);
		cr.show_text (backup);
		
		// draw x
		cr.move_to ((35 - 5) * u, y + row_height / 2 + (12 - 14) * u);
		cr.line_to ((35 - 10) * u, y + row_height / 2 + (12 - 9) * u);

		cr.move_to ((35 - 10) * u, y + row_height / 2 + (12 - 14) * u);
		cr.line_to ((35 - 5) * u, y + row_height / 2 + (12 - 9) * u);
		
		cr.stroke ();
	}
	
	void draw_background (Context cr, WidgetAllocation allocation, double y, bool color) {
		if (color) {
			draw_background_color (cr, allocation, y, 224);
		} else {
			draw_background_color (cr, allocation, y, 239);
		}
	}
	
	void draw_background_color (Context cr, WidgetAllocation allocation, double y, int color) {
		cr.save ();
		cr.set_source_rgba (color/255.0, color/255.0, color/255.0, 1);
		cr.rectangle (0, y, allocation.width, row_height);
		cr.fill ();
		cr.restore ();
	}

	public override string get_label () {
		return t_("Files");
	}
	
	public override string get_name () {
		return "Files";
	}

	public override bool has_scrollbar () {
		return true;
	}
	
	public override void scroll_wheel_down (double x, double y) {
		uint r = rows ();
		
		if (r > visible_rows) {
			scroll += 2;
		}

		if (scroll > r - visible_rows) {
			scroll = (int) (r - visible_rows);
		}
		
		if (scroll < 0) {
			scroll = 0;
		}
		
		update_scrollbar ();
		redraw_area (0, 0, allocation.width, allocation.height);
	}
	
	public override void scroll_wheel_up (double x, double y) {
		scroll -= 2;
		
		if (scroll < 0) {
			scroll = 0;
		}
		
		update_scrollbar ();
		redraw_area (0, 0, allocation.width, allocation.height);
	}

	public override void selected_canvas () {
		update_recent_files ();
		update_scrollbar ();
		
		backups.clear ();
		
		backups = get_backups ();
		redraw_area (0, 0, allocation.width, allocation.height);
	}
	
	public void update_scrollbar () {
		int r = rows ();

		if (r == 0 || visible_rows == 0) {
			MainWindow.set_scrollbar_size (0);
			MainWindow.set_scrollbar_position (0);
		} else {
			MainWindow.set_scrollbar_size ((double) visible_rows / r);
			MainWindow.set_scrollbar_position ((double) scroll /  r);
		}
	}

	public override void scroll_to (double percent) {
		int r = rows ();
		scroll = (int) (percent * r);
		
		if (scroll > r - visible_rows) {
			scroll = (int) (r - visible_rows);
		}
		
		redraw_area (0, 0, allocation.width, allocation.height);
	}

	int rows () {
		int l = (int) (recent_fonts.size + backups.size);
		
		if (has_backup ()) {
			l += 2;
		}
		
		l += 2;
		return l;
	}

	public void update_recent_files () {
		Font font;

		recent_fonts.clear ();
		
		foreach (var f in Preferences.get_recent_files ()) {
			if (f == "") continue;
			
			File file = File.new_for_path (f);

			font = new Font ();
			
			font.set_font_file (f);
			
			if (file.query_exists ()) { 
				recent_fonts.insert (0, font);
			}
		}		
	}
	
	bool has_backup () {
		return backups.size > 0;
	}

	public static void delete_backups () {
		FileEnumerator enumerator;
		FileInfo? file_info;
		string file_name;
		File backup_file;
		File dir = BirdFont.get_backup_directory ();
		
		try {
			enumerator = dir.enumerate_children (FileAttribute.STANDARD_NAME, 0);
			while ((file_info = enumerator.next_file ()) != null) {
				file_name = ((!) file_info).get_name ();
				backup_file = get_child (dir, file_name);
				backup_file.delete ();
			}
		} catch (Error e) {
			warning (e.message);
		}
	}

	public Gee.ArrayList<string> get_backups () {
		FileEnumerator enumerator;
		string file_name;
		FileInfo? file_info;
		Gee.ArrayList<string> backups = new Gee.ArrayList<string> ();
		File dir = BirdFont.get_backup_directory ();
		Font font = BirdFont.get_current_font ();

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
				
				backups.insert (0, file_name);
			}
		} catch (Error e) {
			warning (e.message);
		}
    
		return backups;	
	}
}

}
