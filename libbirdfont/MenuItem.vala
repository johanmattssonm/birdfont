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

	public double y;
	
	// key bindings
	public virtual uint modifiers { get; set; default = NONE; }
	public virtual unichar key { get; set; default = '\0'; }
	
	public Gee.ArrayList<string> displays = new Gee.ArrayList<string> ();	
	
	public MenuItem (string label, string identifier = "") {
		this.label = new Text ();
		this.label.set_text (label);
		this.identifier = identifier;
		y = 0;
	}

	public void add_display (string d) {
		displays.add (d);
	}

	/** @return true if a key binding can be used in @param display. */
	public bool in_display (string display) {
		if (displays.size == 0) {
			return true;
		}

		foreach (string d in displays) {
			if (d == display) {
				return true;
			}
		}
		
		return false;
	}

	public string get_key_bindings () {
		string key_binding = "";
		
		if (key != '\0') {
			key_binding += "(";
			
			if ((modifiers & CTRL) > 0) {
				key_binding += "Ctrl+";
			}
			
			if ((modifiers & ALT) > 0) {
				key_binding += "Alt+";
			}
			
			if ((modifiers & LOGO) > 0) {
				key_binding += "Command+";
	
			}
			
			if ((modifiers & SHIFT) > 0) {
				key_binding += "Shift+";
			}
			
			switch (key) {
				case Key.UP:
					key_binding += t_("UP");
					break;
				case Key.DOWN:
					key_binding += t_("DOWN");
					break;
				case Key.LEFT:
					key_binding += t_("LEFT");
					break;
				case Key.RIGHT:
					key_binding += t_("RIGHT");
					break;
				default:
					key_binding += (!) key.to_string ();
					break;
			}
			
			key_binding += ")";
		}
		
		return key_binding;
	}
}

}
