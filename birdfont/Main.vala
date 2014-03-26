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
	string file;
	BirdFont.BirdFont birdfont;

	Icons.use_high_resolution (true);
	birdfont = new BirdFont.BirdFont ();
	birdfont.init (arg, null);
	Gtk.init (ref arg);
	parse_gtk_rc ();
	
	window = new MainWindow ();
	native_window = new GtkWindow ("birdfont");	

	window.set_native (native_window);
	native_window.init ();

	file = BirdFont.BirdFont.args.get_file ();
	if (file != "") {
		MainWindow.file_tab.load_font (file);
	}

	load_ucd ();
	Gtk.main ();

	return 0;
}

void parse_gtk_rc () {
	File f = FontDisplay.find_file ("layout", "birdfont.rc");
	Gtk.rc_parse ((!) f.get_path ());
}

/** Load descriptions from the unicode character database in a 
 * background thread.
 */
void load_ucd () {	
	CharDatabaseParser db;
	unowned Thread<CharDatabaseParser> db_thread;
	Mutex database_mutex = new Mutex ();
	Cond main_loop_idle = new Cond ();
	bool in_idle = false;
	
	try {
		db = new CharDatabaseParser ();
		db_thread = Thread.create<CharDatabaseParser> (db.load, false);
		
		// wait until main loop is done
		db.sync.connect (() => {
			database_mutex.lock ();
			IdleSource idle = new IdleSource ();
			in_idle = false;
			
			idle.set_callback (() => {
				database_mutex.lock ();
				in_idle = true;
				main_loop_idle.broadcast ();
				database_mutex.unlock ();
				return false;
			});
			idle.attach (null);
			
			while (!in_idle) {
				main_loop_idle.wait (database_mutex);
			}
			
			database_mutex.unlock ();
		});
	} catch (GLib.Error e) {
		warning (e.message);
	}
}


