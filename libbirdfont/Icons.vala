/*
    Copyright (C) 2012 Johan Mattsson

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

using Cairo;	

public class Icons {
	
	public static string directory = "icons";
	public static bool high_res = true;

	public static int get_dpi () {
		return (high_res) ? 320 : 72;
	}

	public static void use_high_resolution (bool high_res) {
		directory = (high_res) ? "icons" : "icons-72dpi";
		Icons.high_res = high_res;
	}
	
	public static ImageSurface? get_icon (string? name) {
		ImageSurface? img = null;
		File f;
		
		if (name == null) {
			warning ("Can't find a file for name \"null\".");
			return null;
		}

		f = find_icon ((!) name);
		
		if (!f.query_exists ()) {
			warning (@"Can't load icon: $((!)f.get_path ())");
			return null;
		}
		
		img = new ImageSurface.from_png ((!)f.get_path ());
		
		return img;
	}

	public static File find_icon (string name) {
		return FontDisplay.find_file (directory, name);
	}
}
	
}
