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

public class FileDialogTab : FontDisplay {

	int scroll = 0;
	int visible_rows = 0;
	WidgetAllocation allocation;
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
		allocation = new WidgetAllocation ();
		files = new Gee.ArrayList<string> ();
		directories = new Gee.ArrayList<string> ();
		
		selected_canvas ();
	}

	public static void add_drive_letter (char c) {
		if (!has_drive_letters) {
			drive_letters = new Gee.ArrayList<string> ();
			has_drive_letters = true;
		}
		
		drive_letters.add (@"$((!) c.to_string ()):\\");
	}

	public override void selected_canvas () {
		string d;
		show_text_area ("");
		
		d = Preferences.get ("file_dialog_dir");
		
		if (d == "") {
			d = Environment.get_home_dir ();
		}
		
		propagate_files (d);
		
		update_scrollbar ();
		redraw_area (0, 0, allocation.width, allocation.height);
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
			
		scroll = 0;
		update_scrollbar ();
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
			
	public override void draw (WidgetAllocation allocation, Context cr) {
		double y = 75 * MainWindow.units;
		int s = 0;
		bool color = (scroll % 2) == 0;
		
		this.allocation = allocation;
		
		visible_rows = (int) (allocation.height / 18.0);
		
		cr.save ();
		Theme.color (cr, "Background 4");
		cr.rectangle (0, 0, allocation.width, allocation.height);
		cr.fill ();
		cr.restore ();
		
		cr.save ();
		Theme.color (cr, "Background 5");
		cr.set_font_size (12);

		foreach (string file in directories) {
			if (s++ >= scroll) {
				draw_row (allocation, cr, file, y, color, true);
				y += 18 * MainWindow.units;
				color = !color;
			}
		}
							
		foreach (string file in files) {
			if (s++ >= scroll) {
				draw_row (allocation, cr, file, y, color, false);
				y += 18 * MainWindow.units;
				color = !color;
			}
		}
		
		cr.restore ();
	}	

	private static void draw_row (WidgetAllocation allocation, Context cr,
			string file, double y, bool color, bool dark) {

		if (color) {
			if (dark) {
				cr.save ();
				Theme.color (cr, "Background 8");
				cr.rectangle (0, y - 14 * MainWindow.units, allocation.width, 18 * MainWindow.units);
				cr.fill ();
				cr.restore ();
			} else {
				cr.save ();
				Theme.color (cr, "Background 6");
				cr.rectangle (0, y - 14 * MainWindow.units, allocation.width, 18 * MainWindow.units);
				cr.fill ();
				cr.restore ();
			}
		} else {
			if (dark) {
				cr.save ();
				Theme.color (cr, "Background 9");
				cr.rectangle (0, y - 14 * MainWindow.units, allocation.width, 18 * MainWindow.units);
				cr.fill ();
				cr.restore ();
			} else {
				cr.save ();
				Theme.color (cr, "Foreground");
				cr.rectangle (0, y - 14 * MainWindow.units, allocation.width, 18 * MainWindow.units);
				cr.fill ();
				cr.restore ();
			}
		}
		
		// text
		cr.save ();
		if (dark) {
			Theme.color (cr, "Foreground Inverted Table");
		}
		cr.move_to (60, y);
		cr.set_font_size (12 * MainWindow.units);
		cr.show_text (file);
		cr.restore ();
		
	}

	public override void button_release (int button, double ex, double ey) {
		int s = 0;
		double y = 75 * MainWindow.units - 20 * MainWindow.units;
		string selected;
		bool dir = false;
		File f;
		
		selected = "";

		foreach (string d in directories) {
			if (s++ >= scroll) {
				y += 18 * MainWindow.units;
				
				if (y - 10 * MainWindow.units <= ey <= y + 5 * MainWindow.units) {
					selected = d;
					dir = true;
				}
			}
		}
		
		foreach (string file in files) {
			if (s++ >= scroll) {
				y += 18 * MainWindow.units;
				
				if (y - 10 * MainWindow.units <= ey <= y + 5 * MainWindow.units) {
					selected = file;
				}
			}
		}
		
		if (button == 1) {
			if (!dir) {
				selected_filename = selected;
				show_text_area (selected);
			} else {
				if (selected == "..") {
					propagate_files ((!)((!)current_dir.get_parent ()).get_path ());
				} else {
					
					if (selected.index_of (":\\") != -1) {
						propagate_files (selected);
					} else {
						f = get_child (current_dir, selected);
						propagate_files ((!) f.get_path ());
					}
				}
			}
		}
		
		update_scrollbar ();
		redraw_area (0, 0, allocation.width, allocation.height);
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
			action.file_selected ((!)f.get_path ());
		}
	}

	public override string get_label () {
		return title;
	}

	public override string get_name () {
		return "FileDialogTab";
	}

	public override bool has_scrollbar () {
		return true;
	}
	
	public override void scroll_wheel_down (double x, double y) {
		double rows = 4.16 + files.size + directories.size;
		scroll += 3;

		if (scroll > rows - visible_rows) {
			scroll = (int) (rows - visible_rows);
		}
		
		if (visible_rows > rows) {
			scroll = 0;
		} 
		
		update_scrollbar ();
		redraw_area (0, 0, allocation.width, allocation.height);
	}
	
	public override void scroll_wheel_up (double x, double y) {
		scroll -= 3;
		
		if (scroll < 0) {
			scroll = 0;
		}
		
		update_scrollbar ();
		redraw_area (0, 0, allocation.width, allocation.height);
	}
	
	public override void update_scrollbar () {
		double rows = 4.16 + files.size + directories.size; // 4.16 rows under the text input

		if (rows == 0 || visible_rows == 0) {
			MainWindow.set_scrollbar_size (0);
			MainWindow.set_scrollbar_position (0);
		} else {
			MainWindow.set_scrollbar_size (visible_rows / rows);
			MainWindow.set_scrollbar_position (scroll /  rows);
		}
	}

	public override void scroll_to (double percent) {
		double rows = 4.16 + files.size + directories.size;
		scroll = (int) (percent * rows);
		
		if (scroll > rows - visible_rows) {
			scroll = (int) (rows - visible_rows);
		}
		
		redraw_area (0, 0, allocation.width, allocation.height);
	}
}

}
