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
using Supplement;
using Birdfont;

namespace Supplement {

public class Supplement {
	internal static Argument args;
	internal static bool experimental = false;
	internal static bool show_coordinates = false;
	internal static bool fatal_wanings = false;
	internal static bool win32 = false;
	internal static string exec_path = "";

	internal static Font current_font;
	internal static Glyph current_glyph;
	
	public void init (string[] arg) {
		int err_arg;
		int i;
		File font_file;
		Argument args;
		IdleSource idle;
		string exec_path;

		stdout.printf ("birdfont version %s\n", VERSION);
		stdout.printf ("built on %s\n", BUILD_TIMESTAMP);
		
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

		current_font = new Font ();
		current_glyph = new Glyph ("");

		experimental = args.has_argument ("--test");
		show_coordinates = args.has_argument ("--show-coordinates");
		fatal_wanings = args.has_argument ("--fatal-warning");
		win32 = (arg[0].index_of (".exe") > -1) || arg[0] == "wine";
		exec_path = "";

		if (win32) {
			// wine hack to get "." folder in win32 environment
			i = arg[0].last_index_of ("\\");
			
			if (i != -1) {	
				exec_path = arg[0];
				exec_path = exec_path.substring (0, i);
				exec_path = wine_to_unix_path (exec_path);			
			}
		} else {
			exec_path = "./";
		}
		
		Preferences preferences = new Preferences ();
		preferences.load ();
		
		if (args.get_file () != "") {
			font_file = File.new_for_path (args.get_file ());
			
			if (!font_file.query_exists ()) {
				stderr.printf (@"File $(args.get_file ()) not found.");
				Process.exit (-1);
			}
		}

		if (fatal_wanings) {
			LogLevelFlags levels = LogLevelFlags.LEVEL_ERROR | LogLevelFlags.LEVEL_CRITICAL | LogLevelFlags.LEVEL_WARNING;
			Log.set_handler (null, levels, fatal_warning);
		}
		
		preferences.set_last_file (get_current_font ().get_path ());
	}
	
	public static Font get_current_font () {
		return current_font;
	}

	internal static void fatal_warning (string? log_domain, LogLevelFlags log_levels, string message) {		
		bool fatal = true;
		
		if (log_domain != null) {
			stderr.printf ("%s: \n", (!) log_domain);
		}
		
		stderr.printf ("\n%s\n\n", message);
		assert (!fatal);
	}
	
	internal static void new_font () {
		current_font = new Font ();
	}

	internal static File get_thumbnail_directory () {
		File thumbnails = get_settings_directory ().get_child ("thumbnails");
		
		if (!thumbnails.query_exists ()) {
			DirUtils.create ((!) thumbnails.get_path (), 0xFFFFFF);
		}
		
		return thumbnails;
	}
		
	internal static File get_settings_directory () {
		File home = File.new_for_path (Environment.get_home_dir ());
		File settings = home.get_child (".birdfont");
		
		if (!settings.query_exists ()) {
			DirUtils.create ((!) settings.get_path (), 0xFFFFFF);
		}
			
		return settings;
	}

	internal static File get_backup_directory () {
		File settings = get_settings_directory ();
		File backup = settings.get_child ("backup");
		
		if (!backup.query_exists ()) {
			DirUtils.create ((!) backup.get_path (), 0xFFFFFF);
		}
			
		return backup;
	}

	internal static bool has_argument (string param) {
		return args.has_argument (param);
	}
	
	internal static string? get_argument (string param) {
		return args.get_argument (param);
	}	
}

internal bool is_null (void* n) {
	return n == null;
}

}
