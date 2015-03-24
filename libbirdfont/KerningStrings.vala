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

namespace BirdFont {

public class KerningStrings : GLib.Object {

	Gee.ArrayList<string> kerning_strings = new Gee.ArrayList<string> ();
	int current_position = 0;	

	public KerningStrings () {
	}
	
	public bool is_empty () {
		return kerning_strings.size == 0;
	}
	
	public string next () {
		string w = "";
		Font font = BirdFont.get_current_font ();
		
		if (0 <= current_position < kerning_strings.size) {
			w = kerning_strings.get (current_position);
			current_position++;
			font.settings.set_setting ("kerning_string_position", @"$current_position");
		}
		
		return w;
	}

	public string previous () {
		string w = "";
		Font font = BirdFont.get_current_font ();
		
		if (0 <= current_position - 1 < kerning_strings.size) {
			current_position--;
			w = kerning_strings.get (current_position);
			font.settings.set_setting ("kerning_string_position", @"$current_position");
		}

		return w;
		
	}
	
	public void load_file ()  {
		FileChooser fc = new FileChooser ();
		fc.file_selected.connect ((f) => {
			Font font = BirdFont.get_current_font (); 
			if (f != null) {
				load_new_string (font, (!) f);
			}
		});
		
		MainWindow.file_chooser (t_("Load kerning strings"), fc, FileChooser.LOAD);
	}
	
	public void load (Font font) {
		string path;
	
		path = font.settings.get_setting ("kerning_string_file");

		if (path != "") {
			load_new_string (font, path);
			current_position = int.parse (font.settings.get_setting ("kerning_string_position"));
		}
	}
	
	public void load_new_string (Font font, string kerning_strings_file) {
		string data;
		string[] strings;
		string w;
		
		try {
			kerning_strings.clear ();

			FileUtils.get_contents(kerning_strings_file, out data);
			strings = data.replace ("\n", " ").split (" ");
			
			foreach (string s in strings) {
				w = s.replace ("\r", "");
				if (w != "") {
					kerning_strings.add (s);
				}
			}
			
			current_position = 0;
			
			font.settings.set_setting ("kerning_string_file", kerning_strings_file);
		} catch (GLib.Error e) {
			warning (e.message);
		}
	}
}

}
