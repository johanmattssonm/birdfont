/*
    Copyright (C) 2013 Johan Mattsson

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

namespace BirdFont {

public class OverWriteDialogListener : GLib.Object {
	
	public signal void overwrite_signal ();
	public signal void cancel_signal ();
	
	public static bool dont_ask_again = false;
	
	public string message = _("Overwrite TTF file?");
	public string overwrite_message = _("Overwrite");
	public string cancel_message = _("Cancel");
	public string dont_ask_again_message = _("Yes, don't ask again.");
	
	public OverWriteDialogListener () {
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
