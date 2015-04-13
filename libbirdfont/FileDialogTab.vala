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

public class FileDialogTab : Table {
	Gee.ArrayList<Row> rows;
	
	const int DIRECTORY = -3;
	const int FILE = -2;
	
	Gee.ArrayList<string> files;
	Gee.ArrayList<string> directories;
	
	string title;
	FileChooser action;
	
	File current_dir;
	
	string selected_filename;
	TextListener listener;
	
	private static bool has_drive_letters = false;
	private static Gee.ArrayList<string> drive_letters;

	public FileDialogTab (string title, FileChooser action) {
		this.title = title;
		this.action = action;
		
		rows = new Gee.ArrayList<Row> ();
		files = new Gee.ArrayList<string> ();
		directories = new Gee.ArrayList<string> ();
		
		selected_filename = "";
		selected_canvas ();
	}

	public static void add_drive_letter (char c) {
		if (!has_drive_letters) {
			drive_letters = new Gee.ArrayList<string> ();
			has_drive_letters = true;
		}
		
		drive_letters.add (@"$((!) c.to_string ()):\\");
	}

	public override void update_rows () {
		Row row;
		
		rows.clear ();

		if (directories.size > 0) {
			row = new Row.headline (t_("Directories"));
			rows.add (row);	
		}
		
		foreach (string dir in directories) {
			row = new Row.columns_1 (dir, DIRECTORY, false);
			row.set_row_data (new SelectedFile (dir));
			rows.add (row);
		}

		if (files.size > 0) {
			row = new Row.headline (t_("Files"));
			rows.add (row);	
		}
		
		foreach (string f in files) {
			row = new Row.columns_1 (f, FILE, false);
			row.set_row_data (new SelectedFile (f));
			rows.add (row);
		}
		
		GlyphCanvas.redraw ();
	}

	public override Gee.ArrayList<Row> get_rows () {
		return rows;
	}
	
	public override void selected_row (Row row, int column, bool delete_button) {	
		SelectedFile f;

		if (row.get_index () == FILE) {
			return_if_fail (row.get_row_data () is SelectedFile);
			f = (SelectedFile) row.get_row_data ();
			selected_filename = f.file_name;
		} else if (row.get_index () == DIRECTORY) {
			return_if_fail (row.get_row_data () is SelectedFile);
			f = (SelectedFile) row.get_row_data ();
			selected_filename = "";
			propagate_files (f.file_name);
		}
		
		show_text_area (selected_filename);
	}
	
	public override void selected_canvas () {
		string d;
		show_text_area ("");
		
		d = Preferences.get ("file_dialog_dir");
		
		if (d == "") {
			d = Environment.get_home_dir ();
		}
		
		propagate_files (d);
		base.selected_canvas ();
	}

	public void propagate_files (string dir) {
		FileEnumerator enumerator;
		FileInfo? file_info;
		string fn;
		
		files.clear ();
		directories.clear ();
		
		current_dir = File.new_for_path (dir);
		
		Preferences.set ("file_dialog_dir", dir);
		
		if (current_dir.get_parent () != null) {
			directories.add ("..");
		}

		try {
			enumerator = current_dir.enumerate_children (FileAttribute.STANDARD_NAME + "," + FileAttribute.STANDARD_TYPE, 0);
			
			while ((file_info = enumerator.next_file ()) != null) {
				fn = ((!)file_info).get_name ();
				if (!fn.has_prefix (".")) {
					if (((!)file_info).get_file_type () == FileType.DIRECTORY) {
						directories.add (fn);
					} else {
						files.add (fn);
					}
				}
			}
		} catch (Error e) {
			warning (e.message);
		}
		
		directories.sort ();

		if (has_drive_letters) {
			for (int i = drive_letters.size - 1; i >= 0; i--) {
				directories.insert (0, drive_letters.get (i));
			}
		}

		files.sort ();
		
		selected_canvas ();
	}

	public void show_text_area (string text) {
		listener = new TextListener ("", text, this.title);
		
		listener.signal_text_input.connect ((text) => {
			selected_filename = text;
		});
		
		listener.signal_submit.connect (() => {
			File f;
			
			MainWindow.get_tab_bar ().close_display (this);
			
			if (selected_filename == "") {
				action.cancel ();
			} else {
				f = get_child (current_dir, selected_filename);
				action.file_selected ((!)f.get_path ());
			}
		});
		
		TabContent.show_text_input (listener);
	}
	
	public override void double_click (uint button, double ex, double ey) {	
		File f;

		button_release ((int) button, ex, ey);

		if (is_null (selected_filename)) {
			warning ("No file.");
			return;
		}
		
		if (selected_filename != "") {
			f = get_child (current_dir, selected_filename);
			action.file_selected ((!) f.get_path ());
		}
	}

	public override string get_label () {
		return title;
	}

	public override string get_name () {
		return "FileDialogTab";
	}
	
	class SelectedFile : GLib.Object {
		public string file_name;
		
		public SelectedFile (string fn) {
			file_name = fn;
		}
	}
}

}
