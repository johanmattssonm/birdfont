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

public class MenuItem : GLib.Object {
	
	public signal void action ();
	public Text label;
	public string identifier;
	
	// key bindings
	public uint modifiers = NONE;
	public unichar key = '\0';
	
	public MenuItem (string label, string identifier = "") {
		this.label = new Text ();
		this.label.set_text (label);
		this.identifier = identifier;
	}
	
}

}
