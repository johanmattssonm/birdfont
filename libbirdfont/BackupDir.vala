/*
	Copyright (C) 2019 Johan Mattsson
	
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

public class BackupDir : GLib.Object {
	public string folder_name;
	public string modification_time;
	
	public BackupDir (string folder_name, string modification_time) {
		this.folder_name = folder_name;
		this.modification_time = modification_time;
	}
}

}
