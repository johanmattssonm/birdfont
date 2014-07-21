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
	
	public static uint NONE = 0;
	public static uint SAVE = 1;
	public static uint LOAD = 1 << 1;
	
	public signal void file_selected  (string? path);
	
	public FileChooser () {	
	}
	
	public void selected (string? path) {
		file_selected (path);
	}
	
	public void cancel () {
		file_selected (null);
	}
}

}
