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

public class OverWriteDialogListener : GLib.Object {
	
	public signal void overwrite_signal ();
	public signal void cancel_signal ();
	
	public static bool dont_ask_again = false;
	
	public string message;
	public string overwrite_message;
	public string cancel_message;
	public string dont_ask_again_message;
	
	public OverWriteDialogListener () {
		message = t_("Overwrite TTF file?");
		overwrite_message = t_("Overwrite");
		cancel_message = t_("Cancel");
		dont_ask_again_message = t_("Yes, don't ask again.");
	}
	
	public void overwrite () {
		overwrite_signal ();
	}
	
	public void cancel () {
		cancel_signal ();	
	}

	public void overwrite_dont_ask_again () {
		dont_ask_again = true;
		overwrite ();
	}
}

}
