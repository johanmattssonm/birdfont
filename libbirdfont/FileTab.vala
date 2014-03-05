/*
    Copyright (C) 2013 Johan Mattsson

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
	double row_height = 30;
	double top = 60;
	WidgetAllocation allocation = new WidgetAllocation ();
	List<Font> recent_fonts = new List<Font> ();
	List<string> backups = new List<string> ();
	
	public signal void open_file ();
	
	public FileTab () {
	}

	public void load_font (string fn) {
		Font font;
		SaveDialogListener dialog = new SaveDialogListener ();

		if (MenuTab.suppress_event) {
			return;
		}
		
		font = BirdFont.get_current_font ();
		
		dialog.signal_discard.connect (() => {
			Font f;
			bool loaded;
			
			f = BirdFont.new_font ();
			f.delete_backup ();
			
			MainWindow.clear_glyph_cache ();
			MainWindow.close_all_tabs ();
			
			loaded = f.load (fn);
			
			if (!unlikely (loaded)) {
				warning (@"Failed to load fond $fn");
				return;
			}
				
			MainWindow.get_drawing_tools ().remove_all_grid_buttons ();
			foreach (string v in f.grid_width) {
				MainWindow.get_drawing_tools ().parse_grid (v);
			}
			
			MainWindow.get_drawing_tools ().background_scale.set_value (f.background_scale);
			KerningTools.update_kerning_classes ();
			MenuTab.select_overview ();
		});

		dialog.signal_save.connect (() => {
			MenuTab.save ();
			dialog.signal_discard ();
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
		backup_file = backup_file.get_child (file_name);
		load_font ((!) backup_file.get_path ());
	}
	
	public void delete_backup (string file_name) {
		File backup_file;
		
		if (MenuTab.suppress_event) {
			return;
		}
		
		try {
			backup_file = BirdFont.get_backup_directory ();
			backup_file = backup_file.get_child (file_name);
			if (backup_file.query_exists ()) {
				backup_file.delete ();	
			}
		} catch (GLib.Error e) {
			warning (e.message);
		}
		
		selected_canvas ();
	}
	
	public override void button_release (int button, double ex, double ey) {
		int r = (int) rint ((ey - 17) / row_height) + scroll;
		int i = scroll; 

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
			if (i == r) {
				return_if_fail (font.font_file != null);
				load_font ((!) font.font_file);
				open_file ();
			}
			i++;
		}

		if (is_null (backups)) {
			warning ("No backups");
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

		if (recent_fonts.length () == 0 && !has_backup ()) {
			cr.save ();
			cr.set_source_rgba (0.3, 0.3, 0.3, 1);
			cr.set_font_size (18);
			cr.move_to (50, top - 9);
			cr.show_text (t_("No fonts created yet."));
			cr.restore ();
		}
		
		if (scroll == 0 && recent_fonts.length () > 0) {
			cr.save ();
			cr.set_source_rgba (0.3, 0.3, 0.3, 1);
			cr.set_font_size (18);
			cr.move_to (50, top - 9);
			cr.show_text (t_("Recent files"));
			cr.restore ();
		}
		
		cr.save ();
		cr.set_source_rgba (0.3, 0.3, 0.3, 1);
		cr.set_font_size (12);

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
				cr.set_font_size (18);
				cr.move_to (50, y + 2 * row_height - 9);
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
		File thumbnail;
		string fn = (!) font.font_file;
		
		fn = fn.substring (fn.replace ("\\", "/").last_index_of ("/") + 1);
		draw_background (cr, allocation, y, color);
		
		cr.move_to (50, y + row_height / 2 + 5);
		cr.show_text (fn);
	}

	private void draw_backup_row (WidgetAllocation allocation, Context cr, string backup, bool color, double y) {
		File thumbnail;
		thumbnail = BirdFont.get_thumbnail_directory ().get_child (backup);
			
		draw_background (cr, allocation, y, color);
		
		cr.move_to (50, y + row_height / 2 + 5);
		cr.show_text (backup);
		
		cr.move_to (35 - 5, y + row_height / 2 + 12 - 14);
		cr.line_to (35 - 10, y + row_height / 2 + 12 - 9);

		cr.move_to (35 - 10, y + row_height / 2 + 12 - 14);
		cr.line_to (35 - 5, y + row_height / 2 + 12 - 9);
		
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
		
		while (backups.length () != 0) {
			backups.delete_link (backups.first ());
		}
		
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
		int l = (int) (recent_fonts.length () + backups.length ());
		
		if (has_backup ()) {
			l += 2;
		}
		
		l += 2;
		return l;
	}

	public void update_recent_files () {
		Font font;

		while (recent_fonts.length () != 0) {
			recent_fonts.delete_link (recent_fonts.first ());
		}
		
		foreach (var f in Preferences.get_recent_files ()) {
			if (f == "") continue;
			
			File file = File.new_for_path (f);

			font = new Font ();
			
			font.set_font_file (f);
			
			if (file.query_exists ()) { 
				recent_fonts.append (font);
			}
		}
		
		recent_fonts.reverse ();
	}
	
	bool has_backup () {
		return backups.length () > 0;
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
				backup_file = dir.get_child (file_name);
				backup_file.delete ();
			}
		} catch (Error e) {
			warning (e.message);
		}
	}

	public List<string> get_backups () {
		FileEnumerator enumerator;
		string file_name;
		FileInfo? file_info;
		List<string> backups = new List<string> ();
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
				
				backups.append (file_name);
			}
		} catch (Error e) {
			warning (e.message);
		}
    
		return backups;	
	}
}

}
