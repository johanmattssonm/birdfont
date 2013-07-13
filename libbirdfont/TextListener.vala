/*
    Copyright (C) 2013 Johan Mattsson

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

public class TextListener : GLib.Object {

	public string label;
	public string default_text;
	public string button_label;

	public signal void signal_text_input (string text);
	public signal void signal_submit (string text);	

	private string text;

	public TextListener (string label, string default_text, string button_label) {
		this.label = label;
		this.default_text = default_text;
		this.button_label = button_label;
	}
	
	public void set_text (string t) {
		text = t;
		signal_text_input  (text);
	}

	public void submit () {
		signal_text_input  (text);
		signal_submit  (text);
	}
}

}
