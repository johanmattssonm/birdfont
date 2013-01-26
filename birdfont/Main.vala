/*
    Copyright (C) 2012 Johan Mattsson

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

using Birdfont;
using Supplement;

const string GETTEXT_PACKAGE = "birdfont"; 

void parse_gtk_rc () {
	File f = FontDisplay.find_file ("layout", "birdfont.rc");
	Gtk.rc_parse ((!) f.get_path ());
}

public static int main (string[] arg) {
	GtkWindow native_window;
	MainWindow window;
	string file;
	Supplement.Supplement supplement = new Supplement.Supplement ();
	supplement.init (arg);

	Gtk.init (ref arg);
	parse_gtk_rc ();

	native_window = new GtkWindow ("birdfont");	
	window = new MainWindow ();
	
	window.set_native (native_window);
	native_window.init ();

	file = Supplement.Supplement.args.get_file ();
	if (file != "") {
		MainWindow.menu_tab.load_font (file);
	}
	
	Gtk.main ();

	return 0;
}

