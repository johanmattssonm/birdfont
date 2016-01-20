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

namespace BirdFont {

public class SaveCallback : GLib.Object {
	
	public signal void file_saved ();
	public bool is_done = false;
	
	public string font_file_path = "";
	
	public SaveCallback () {	
		file_saved.connect (() => {
			is_done = true;
		});
	}
	
	public void save_as ()  {
		if (unlikely (MenuTab.has_suppress_event ())) {
			warn_if_test ("Event suppressed");
			return;
		}

		FileChooser fc = new FileChooser ();
		fc.file_selected.connect ((fn) => {
			string f;
			File file;
			OverwriteBfFile dialog;
			string file_name;
			
			if (fn != null) {
				f = (!) fn;

#if MAC
				font_file_path = f;
				save ();
#else
				if (!f.has_suffix (".bf")) {
					f = @"$f.bf";
				}
				
				file_name = @"$(f)";
				file = File.new_for_path (file_name);
				font_file_path = (!) file.get_path ();
				
				if (!file.query_exists ()) {
					save ();
				} else {
					dialog = new OverwriteBfFile (this);
					MainWindow.show_dialog (dialog);
				}
#endif	
			}
		});
		
		fc.add_extension ("bf");
		MainWindow.file_chooser (t_("Save"), fc, FileChooser.SAVE);
	}

	public void save () {
		Font f;
		string fn;
		
		if (MenuTab.has_suppress_event ()) {
			warn_if_test ("Event suppressed");
			return;
		}
		
		f = BirdFont.get_current_font ();
		
		if (font_file_path != "") {
			f.font_file = font_file_path;
		}

#if !MAC
		Preferences.add_recent_files (f.get_path ());
#endif

		if (f.is_bfp ()) {
			MainWindow.native_window.save ();
		} else {
			f.delete_backup ();
			fn = f.get_path ();
			
			if (f.font_file != null && fn.has_suffix (".bf")) {
				f.set_font_file (fn);
				MainWindow.native_window.save ();
			} else {
				save_as ();
			}
		}
	}
}

}
