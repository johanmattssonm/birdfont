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

public class Ligature : GLib.Object {
	public string ligature = "";
	public string substitution = "";

	public Ligature (string ligature, string substitution = "") {
		this.ligature = ligature;
		this.substitution = substitution;
	}
	
	public unichar get_first_char () {
		return substitution.get (0);
	}
	
	public void set_ligature () {
		TextListener listener;
		
		listener = new TextListener (t_("Ligature"), ligature, t_("Set"));
		
		listener.signal_text_input.connect ((text) => {
			ligature = text;
		});
		
		listener.signal_submit.connect (() => {
			TabContent.hide_text_input ();
			MainWindow.get_ligature_display ().update_rows ();
		});
		
		TabContent.show_text_input (listener);
	}
	
	public void set_substitution () {
		TextListener listener;
		
		listener = new TextListener (t_("Text"), substitution, t_("Set"));
		
		listener.signal_text_input.connect ((text) => {
			Font f = BirdFont.get_current_font ();
			Ligatures l = f.get_ligatures ();
			substitution = text;
			l.sort_ligatures ();
		});
		
		listener.signal_submit.connect (() => {
			TabContent.hide_text_input ();
			MainWindow.get_ligature_display ().update_rows ();
		});
		
		TabContent.show_text_input (listener);
	}
}

}
