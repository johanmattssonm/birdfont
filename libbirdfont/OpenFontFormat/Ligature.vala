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
		unichar first;
		int index = 0;

		get_coverage (substitution).get_next_char (ref index, out first);

		return first;
	}
	
	public static string get_coverage (string ligatures) {
		string[] sp;
		unichar first;
		int index = 0;
		string characters = ligatures;
		
		if (characters.has_prefix ("U+") || characters.has_prefix ("u+")) {
			sp = characters.split (" ");
			return_val_if_fail (sp.length > 0, "");
			characters = (!) Font.to_unichar (sp[0]).to_string ();
		}
		sp = characters.split (" ");
		
		if (sp.length == 0) {
			return "";
		}

		if (sp[0] == "space") {
			sp[0] = " ";
		}
		
		sp[0].get_next_char (ref index, out first);
		
		return (!) first.to_string ();	
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
