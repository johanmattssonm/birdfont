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

/** Thread specific font cache. */	
public class FontCache {
	Font? font;
	string file_name;
	
	static FontCache? default_cache = null;
	
	public FontCache () {
		font = null;
		file_name = "";
	}
	
	public Font? get_font (string file_name) {
		Font f;
		bool ok;
		
		if (file_name == "") {
			stderr.printf ("No file name provided.\n");
			return null;
		}
		
		if (this.file_name != file_name) {
			f = new Font ();
			this.file_name = file_name;
			
			f.set_file (file_name);
			ok = f.load ();
			if (!ok) {
				stderr.printf ("Can't load %s\n", file_name);
				return null;
			}
			
			font = f;
		}
		
		return font;
	}
	
	public static FontCache get_default_cache () {
		if (default_cache == null) {
			default_cache = new FontCache ();
		}
		
		return (!) default_cache;
	}
}

}
