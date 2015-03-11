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
using Cairo;
using Math;

namespace BirdFont {

public class SpacingClass : GLib.Object  {

	public string first;
	public string next;

	bool update_first = true;
	TextListener listener;
	
	public signal void updated (SpacingClass s);
	
	public SpacingClass (string first, string next) {
		this.first = first;
		this.next = next;
	}
	
	public void set_first () {	
		update_first = true;
		update (first);
	}
	
	public void set_next () {	
		update_first = false;
		update (next);
	}
	
	void update (string val) {
		listener = new TextListener (t_("Character"), val, t_("Set"));
		
		listener.signal_text_input.connect ((text) => {
			string v = text;
			
			if (v.has_prefix ("U+") || v.has_prefix ("u+")) {
				v = (!) Font.to_unichar (val).to_string ();
			}
			
			if (update_first) {
				first = v.dup ();
			} else {
				next = v.dup ();
			}
			
			updated (this);
		});
		
		listener.signal_submit.connect (() => {
			TabContent.hide_text_input ();
		});
		
		TabContent.show_text_input (listener);
	}
}

}
