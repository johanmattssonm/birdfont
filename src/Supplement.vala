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

	static string[]? args = null;
	
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
		return (get_argument (param) != null);
	}
	
	/** Get commandline argument. */
	public static string? get_argument (string param) 
		requires (args != null)
	{
		var a = (!) args;
		int i = 0;
		string? n;
				
		foreach (string s in a) {
			string p;

			if (s.substring (0, 1) != "-") continue;

			if (s.substring (0, 2) != "--") {
				p = expand_param (s);
			} else {				
				p = s;
			}
			
			if (param == p) {
				if (i + 2 >= a.length) {
					return "";
				}
				
				n = a[i + 2];
				if (n == null || ((!)n).length == 0) {
					return "";
				}
				
				if (a[i + 2].substring (0, 1) == "-") {
					return "";
				}
				
				return a[i + 2];
			}
			
			i++;
		}
		
		return null;
	}

	private static void print_padded (string cmd, string desc) {
		int l = 25 - cmd.char_count ();

		stdout.printf (cmd);
		
		for (int i = 0; i < l; i++) {
				stdout.printf (" ");
		}
		
		stdout.printf (desc);
		stdout.printf ("\n");
	}

	/** Return full command line parameter for an abbrevation.
	 * -t becomes --test.
	 */
	private static string expand_param (string? param) {
		if (param == null) return "";
		var p = (!) param;
		
		if (p.length == 0) return "";
		if (p.get_char (0) != '-') return "";
		if (p.char_count () != 2) return "";
		
		switch (p.get_char (1)) {
			case 'a': 
				return "--autosave";
			case 'e': 
				return "--exit";
			case 's': 
				return "--slow";
			case 'h': 
				return "--help";
			case 't': 
				return "--test";
		}
		
		return "";
	}

	// FIXME: It seems broken:
	public static string[] split_compound_parameters (string[] a) {
		int ti = 0;
		string[] na = new string [a.length];
		
		foreach (string s in a) {
			if (s.substring (0, 2) != "--" && s.length > 2) {
				unichar c;
				int t = 1;
				
				while (s.get_next_char (ref t, out c)) {
					if (c != ' ' && c != '-') {
						StringBuilder b = new StringBuilder ();
						b.append_unichar (c);
						na += @"-$(b.str)";
					}
				}
			}
			
			na[ti] = a[ti];
			ti++;
		}
		
		return na;
	}

	public static void print_help (string[] args) 
		requires (args.length > 0)
	{
		
		stdout.printf ("Usage: ");
		stdout.printf (args[0]);
		stdout.printf (" [OPTION ...]\n");

		print_padded ("-e, --exit", "exit if a testcase failes");
		print_padded ("-h, --help", "show this message");
		print_padded ("-s, --slow", "sleep between each command in test suite");
		print_padded ("-t, --test[=TEST]", "run test case");
		
		stdout.printf ("\n");
	}

	public static void main(string[] args) {		
		Supplement.args = split_compound_parameters (args);
		Supplement.args = args;
		
		if (has_argument ("--help")) {
			print_help (args);
			Process.exit(0);
		}

		Preferences preferences = new Preferences ();
		preferences.load ();
       
		current_font = new Font ();
		
		Gtk.init (ref args);
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
