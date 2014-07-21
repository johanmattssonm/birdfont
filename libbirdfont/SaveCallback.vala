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
	
	public SaveCallback () {	
	}
	
	public void save_as ()  {
		if (MenuTab.suppress_event) {
			warn_if_test ("Event suppressed");
			return;
		}

		FileChooser fc = new FileChooser ();
		fc.file_selected.connect ((fn) => {
			string f;
			string file_name;
			File file;
			bool saved = false;
			Font font = BirdFont.get_current_font ();
			int i;	
			
			if (fn != null) {
				f = (!) fn;
				
				if (f.has_suffix (".bf")) {
					f = f.replace (".bf", "");
				}
				
				file_name = @"$(f).bf";
				file = File.new_for_path (file_name);
				i = 2;
				while (file.query_exists ()) {
					file_name = @"$(f)_$i.bf";
					file = File.new_for_path (file_name);
					i++;
				}
				
				font.font_file = file_name;
				save ();
				saved = true;
			}
		});
		
		MainWindow.file_chooser (t_("Save"), fc, FileChooser.SAVE);
	}

	public void save () {
		Font f;
		string fn;
		
		if (MenuTab.suppress_event) {
			warn_if_test ("Event suppressed");
			return;
		}
		
		f = BirdFont.get_current_font ();

		if (f.is_bfp ()) {
			MainWindow.native_window.save ();
		} else {
			f.delete_backup ();
			fn = f.get_path ();
			
			if (f.font_file != null && fn.has_suffix (".bf")) {
				MenuTab.set_font_setting_from_tools (f);
				f.set_font_file (fn);
				MainWindow.native_window.save ();
			} else {
				save_as ();
			}
		}
	}
}
	
}
