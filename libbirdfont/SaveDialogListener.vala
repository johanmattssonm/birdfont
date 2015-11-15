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

public class SaveDialogListener : GLib.Object {
	
	public signal void signal_save ();
	public signal void signal_discard ();
	public signal void signal_cancel ();
	
	public string message;
	public string discard_message;
	public string save_message;
	
	public SaveDialogListener () {
		this.message = t_("Save?");
		this.save_message = t_("Save");
		this.discard_message = t_("Discard");
	}
	
	public void save () {
		signal_save ();
	}

	public void discard () {
		signal_discard ();
	}
}

}
