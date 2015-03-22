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
	
	public string next () {
		string w = "";
		
		if (0 <= current_position < kerning_strings.size) {
			w = kerning_strings.get (current_position);
		}
		
		current_position++;
		
		return w;
	}

	public string previous () {
		string w = "";

		current_position--;
		
		if (0 <= current_position < kerning_strings.size) {
			w = kerning_strings.get (current_position);
		}

		return w;
		
	}
	
	public void load (Font font) {
		string path;
	
		path = font.settings.get_setting ("kerning_string_file");
		load_new_string (font, path);
	}
	
	public void load_new_string (Font font, string kerning_strings_file) {
		File f;
		string data;
		string[] strings;
		
		try {
			kerning_strings.clear ();

			FileUtils.get_contents(kerning_strings_file, out data);
			strings = data.split ("\n");
			
			foreach (string s in strings) {
				kerning_strings.add (s.replace ("\r", ""));
			}
			
			current_position = int.parse (font.settings.get_setting ("kerning_string_position"));		
			
			font.settings.set_setting ("kerning_string_file", kerning_strings_file);
		} catch (GLib.Error e) {
			warning (e.message);
		}
	}
}

}
