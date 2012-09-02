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

using Gtk;

namespace Supplement {
	
public static int main(string[] arg) {
	int err_arg;
	File font_file;
	Argument args;
	IdleSource idle;

	Supplement.args = new Argument.command_line (arg);
	args = Supplement.args;
	
	if (Supplement.args.has_argument ("--help")) {
		args.print_help ();
		Process.exit (0);
	}

	err_arg = args.validate ();
	if (err_arg != 0) {
		stdout.printf (@"Unknown parameter $(arg [err_arg])\n\n");
		args.print_help ();
		Process.exit (0);
	}

	stdout.printf ("birdfont version %s\n", VERSION);		

	Supplement.current_font = new Font ();

	Supplement.experimental = args.has_argument ("--test");
	Supplement.show_coordinates = args.has_argument ("--show-coordinates");
	Supplement.fatal_wanings = args.has_argument ("--fatal-warning");
	Supplement.win32 = (arg[0].index_of (".exe") > -1);

	Preferences preferences = new Preferences ();
	preferences.load ();
	
	if (args.get_file () != "") {
		font_file = File.new_for_path (args.get_file ());
		
		if (!font_file.query_exists ()) {
			stderr.printf (@"File $(args.get_file ()) not found.");
			return -1;
		}
	}
	
	Gtk.init (ref arg);
	MainWindow window = new MainWindow ("Birdfont");
	window.show_all ();

	if (Supplement.fatal_wanings) {
		LogLevelFlags levels = LogLevelFlags.LEVEL_ERROR | LogLevelFlags.LEVEL_CRITICAL | LogLevelFlags.LEVEL_WARNING;
		Log.set_handler (null, levels, Supplement.fatal_warning);
	}
	
	idle = new IdleSource ();
	idle.set_callback(() => {
		preferences.load ();
		
		if (args.get_file () != "") {
			Supplement.get_current_font ().load (args.get_file ());
			MainWindow.get_toolbox ().select_tool_by_name ("available_characters");
		} else {
			MainWindow.get_tab_bar ().select_tab_name ("Menu");
		}
		
		return false;
	});
	
	idle.attach (null);
	
	Gtk.main ();
	
	preferences.set_last_file (Supplement.get_current_font ().get_path ());
	
	return 0;
}

}
