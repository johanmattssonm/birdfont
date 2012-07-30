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

class Supplement {

	static Font current_font;

	public static Argument args;
	
	public static Font get_current_font () {
		return current_font;
	}

	public static void new_font () {
		current_font = new Font ();
	}
	
	public static File get_settings_directory () {
		File home = File.new_for_path (Environment.get_home_dir ());
		File settings = home.get_child (".supplement");
		
		if (!settings.query_exists ()) {
			DirUtils.create ((!) settings.get_path (), 0xFFFFFF);
		}
			
		return settings;
	}

	public static File get_backup_directory () {
		File settings = get_settings_directory ();
		File backup = settings.get_child ("backup");
		
		if (!backup.query_exists ()) {
			DirUtils.create ((!) backup.get_path (), 0xFFFFFF);
		}
			
		return backup;
	}

	public static bool has_argument (string param) {
		return args.has_argument (param);
	}
	
	public static string? get_argument (string param) {
		return args.get_argument (param);
	}
			
	public static void main(string[] arg) {
		int err_arg;
		
		args = new Argument.command_line (arg);
		
		if (args.has_argument ("--help")) {
			args.print_help ();
			Process.exit (0);
		}

		err_arg = args.validate ();
		if (err_arg != 0) {
			stdout.printf (@"Unknown parameter $(arg [err_arg])\n\n");
			args.print_help ();
			Process.exit (0);
		}

		Preferences preferences = new Preferences ();
		preferences.load ();
       
		current_font = new Font ();
		
		Gtk.init (ref arg);
		var window = new MainWindow ("Supplement");
		window.show_all ();

		var idle = new IdleSource ();
		idle.set_callback(() => {
			preferences.load ();
			return false;
		});
		
		idle.attach (null);
		
		Gtk.main ();
		
		preferences.set_last_file (get_current_font ().get_path ());
	}
	
}

}
