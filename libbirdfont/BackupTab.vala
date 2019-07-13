/*
	Copyright (C) 2019 Johan Mattsson

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

public class BackupTab : Table {
	Gee.ArrayList<Row> rows = new Gee.ArrayList<Row> ();
	
	const int FONT_FOLDER = -2;
	const int FONT_FILE = -1;
	
	private BackupDir? backup_folder = null;
	
	public BackupTab () {
	}

	public override Gee.ArrayList<Row> get_rows () {
		return rows;
	}

	public override void selected_row (Row row, int column, bool delete_button) {	
		if (row.get_index () == FONT_FOLDER) {
			return_if_fail (row.get_row_data () is BackupDir);
			backup_folder = (BackupDir) row.get_row_data ();
			MainWindow.scrollbar.set_size (0);
			update_rows ();
		} else if (row.get_index () == FONT_FILE) {
			return_if_fail (row.get_row_data () is String);
			String backup_file = (String) row.get_row_data ();
			RecentFiles.load_font (backup_file.c_str);
			MainWindow.scrollbar.set_size (0);
		}

		GlyphCanvas.redraw ();
	}

	public override void update_rows () {
		Row row;
				
		rows.clear ();

		if (backup_folder != null) {
			BackupDir folder = (!) backup_folder;
			Gee.ArrayList<string> files = Font.get_sorted_backups (folder.folder_name);

			if (files.size > 0) {
				row = new Row.headline (t_("Backups"));
				rows.add (row);	
			}
			
			if (files.size == 0) {
				row = new Row.headline (t_("No backups for this font."));
				rows.add (row);
			}
			
			foreach (string path in files) {
				string name = Font.get_file_from_full_path (path);
				row = new Row.columns_1 (name, FONT_FILE, false);
				String file_name = new String (path); 
				row.set_row_data (file_name);
				rows.add (row);
			}
		} else {		
			Gee.ArrayList<BackupDir> backup_folders = get_backup_folders ();
			
			if (backup_folders.size == 0) {
				row = new Row.headline (t_("No backups found."));
				rows.add (row);
			}

			if (backup_folders.size > 0) {
				row = new Row.headline (t_("Backups"));
				rows.add (row);	
			}
			
			foreach (BackupDir backup_font in backup_folders) {
				row = new Row.columns_2 (backup_font.folder_name, backup_font.modification_time, FONT_FOLDER, false);
				row.set_row_data (backup_font);
				rows.add (row);
			}
		}
		
		GlyphCanvas.redraw ();
	}

	public override string get_label () {
		return t_("Backups");
	}

	public override string get_name () {
		return "Backups";
	}
	
	public string get_time_stamp_from_file_name (string file_name) {
		int dash = file_name.last_index_of ("-");
		
		if (file_name.has_suffix (".bf_backup") && dash > -1) {
			string time_stamp = file_name.substring (dash + "-".length, file_name.length - dash - ".bf_backup".length);
			time_stamp = time_stamp.replace ("_", " ");
			return time_stamp;
		}
		
		warning("Can't obtain timestamp from " + file_name);
		
		return "Unknown time.";
	}
	
	public Gee.ArrayList<BackupDir> get_backup_folders () {
		FileEnumerator enumerator;
		string folder_name;
		FileInfo? file_info;
		Gee.ArrayList<BackupDir> backup_folders = new Gee.ArrayList<BackupDir> ();
		File dir = Preferences.get_backup_directory ();
		
		try {
			printd ("Backup dir: ");
			printd ((!) dir.get_path ());
			printd ("\n");
				
			enumerator = dir.enumerate_children (FileAttribute.STANDARD_NAME, 0);
			while ((file_info = enumerator.next_file ()) != null) {
				FileInfo info = (!) file_info;
				folder_name = info.get_name ();
				string full_path = (!) get_child (dir, folder_name).get_path ();
				
				printd ("In backup dir: ");
				printd (full_path);
				printd ("\n");
				
				if (!FileUtils.test (full_path, FileTest.IS_DIR)) {
					warning (folder_name + " is not a backup directory.");
					continue;
				}
				
				if (!folder_name.has_suffix (".backup")) {
					warning (folder_name + " is not a backup directory, expecting the suffix .backup");
					continue;
				}
				
				folder_name = folder_name.substring (0, folder_name.length - ".backup".length);
				Gee.ArrayList<string> files = Font.get_sorted_backups (folder_name);
				
				if (files.size > 0) {
					string last_file = files.get (files.size - 1);
					string modification_time = get_time_stamp_from_file_name (last_file);
					BackupDir backup = new BackupDir (folder_name, modification_time);
					backup_folders.add (backup);
				}
			}
		} catch (Error e) {
			warning (e.message);
		}
	
		backup_folders.sort ((a, b) => {
			BackupDir first, next;

			first = (BackupDir) a;
			next = (BackupDir) b;
			
			return Posix.strcmp (b.modification_time, a.modification_time); // descending
		});
		
		return backup_folders;	
	}

	public override void draw (WidgetAllocation allocation, Context cr) {
		MainWindow.get_overview ().allocation = allocation;
		base.draw (allocation, cr);
	}
}

}
