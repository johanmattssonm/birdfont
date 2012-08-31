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
	public static Argument args;
	public static bool experimental;
	public static bool show_coordinates;
	public static bool fatal_wanings;
	public static bool win32;

	static Font current_font;

	public static Font get_current_font () {
		return current_font;
	}

	public static void fatal_warning (string? log_domain, LogLevelFlags log_levels, string message) {		
		bool fatal = true;
		
		if (log_domain != null) {
			stderr.printf ("%s: \n", (!) log_domain);
		}
		
		stderr.printf ("\n%s\n\n", message);
		assert (!fatal);
	}
	
	public static void new_font () {
		current_font = new Font ();
	}

	public static File get_thumbnail_directory () {
		File thumbnails = get_settings_directory ().get_child ("thumbnails");
		
		if (!thumbnails.query_exists ()) {
			DirUtils.create ((!) thumbnails.get_path (), 0xFFFFFF);
		}
		
		return thumbnails;
	}
		
	public static File get_settings_directory () {
		File home = File.new_for_path (Environment.get_home_dir ());
		File settings = home.get_child (".birdfont");
		
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
			
	public static int main(string[] arg) {
		int err_arg;
		File font_file;

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

		stdout.printf ("birdfont version %s\n", VERSION);		

		experimental = args.has_argument ("--test");
		show_coordinates = args.has_argument ("--show-coordinates");
		fatal_wanings = has_argument ("--fatal-warning");
		win32 = (arg[0].index_of (".exe") > -1);

		Preferences preferences = new Preferences ();
		preferences.load ();
       
		current_font = new Font ();
		
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

		if (fatal_wanings) {
			LogLevelFlags levels = LogLevelFlags.LEVEL_ERROR | LogLevelFlags.LEVEL_CRITICAL | LogLevelFlags.LEVEL_WARNING;
			Log.set_handler (null, levels, fatal_warning);
		}
			
		IdleSource idle = new IdleSource ();
		idle.set_callback(() => {
			preferences.load ();
			
			if (args.get_file () != "") {
				current_font.load (args.get_file ());
				MainWindow.get_toolbox ().select_tool_by_name ("available_characters");
			} else {
				MainWindow.get_tab_bar ().select_tab_name ("Menu");
			}
			
			return false;
		});
		
		idle.attach (null);
		
		Gtk.main ();
		
		preferences.set_last_file (get_current_font ().get_path ());
		
		return 0;
	}
	
}

internal bool is_null (void* n) {
	return n == null;
}

}
