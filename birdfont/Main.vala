/*
	Copyright (C) 2012, 2014 Johan Mattsson

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

using BirdFont;

public static int main (string[] arg) {
	GtkWindow native_window;
	MainWindow window;
	BirdFont.BirdFont birdfont;

	birdfont = new BirdFont.BirdFont ();
	birdfont.init (arg, null, "birdfont", null);
	Gtk.init (ref arg);
	
	window = new MainWindow ();
	native_window = new GtkWindow ("birdfont");	

	window.set_native (native_window);
	native_window.init ();

	BirdFont.BirdFont.load_font_from_command_line ();
	
	Gtk.main ();
	return 0;
}


