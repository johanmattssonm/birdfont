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

public class FileChooser : GLib.Object {
	
	public const uint NONE = 0;
	public const uint SAVE = 1;
	public const uint LOAD = 1 << 1;
	public const uint DIRECTORY = 1 << 2;
	
	Gee.ArrayList<string> extensions = new Gee.ArrayList<string> ();
	
	public signal void file_selected  (string? path);
	
	public FileChooser () {	
	}
	
	public int extensions_size () {
		return extensions.size;
	}

	public string get_extension (int i) {
		return_val_if_fail (0 <= i < extensions.size, "".dup ());
		return extensions.get (i);
	}
	
	public void add_extension (string file_extension) {
		extensions.add (file_extension);
	}
	
	public void selected (string? path) {
		file_selected (path);
	}
	
	public void cancel () {
		file_selected (null);
	}
}

}
