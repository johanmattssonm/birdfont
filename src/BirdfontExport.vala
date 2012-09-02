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

namespace Supplement {

/** Stand alone command line utility for exporting fonts. */
class BirdfontExport {
	
	static string folder;
	
	public BirdfontExport () {
	}
	
	static void print_help (string[] arg) {
		stdout.printf ("Usage: ");
		stdout.printf (arg[0]);
		stdout.printf (" [OPTION ...] FILE\n");
		stdout.printf ("-h, --help                      print this message\n");
		stdout.printf ("-o, --output [DIRECTORY]        write files to this directory\n");
		stdout.printf ("\n");
	}
	
	public static int main (string[] arg) {
		OptionContext opt;
		
		LogLevelFlags levels = LogLevelFlags.LEVEL_ERROR | LogLevelFlags.LEVEL_CRITICAL | LogLevelFlags.LEVEL_WARNING;
		Log.set_handler (null, levels, Supplement.fatal_warning);
		
		string output_directory = ".";
		string file_name = "";
		
		File directory;
		
		if (arg.length < 2) {
			print_help (arg);
		}
		
		for (int i = 1; i < arg.length; i++) {
			if (arg[i] == "-h" || arg[i] == "--help") {
				print_help (arg);
				return 0;
			}
			
			if (arg[i] == "-o" || arg[i] == "--output" && i + 1 < arg.length) {
				output_directory = arg[i + 1];
				i++;
				continue;
			}
			
			if (arg[i].has_prefix ("-")) {
				print_help (arg);
				return 1;
				continue;				
			}
			
			if (!arg[i].has_prefix ("-")) {
				file_name = arg[i];
				
				if (i != arg.length - 1) {
					print_help (arg);
					return 1;
				}
				
				break;
			}
		}

		Preferences preferences = new Preferences ();
		preferences.load ();
			
		Supplement.args = new Argument ("");
		Supplement.current_font = new Font ();

		// TODO: refactor and remove all the gtk stuff from this program
		Gtk.init (ref arg);
		MainWindow window = new MainWindow ("Birdfont");
		window.show_all ();
		
		if (!Supplement.get_current_font ().load (file_name, false)) {
			stderr.printf (@"Failed to load font $file_name.\n");
			
			if (!file_name.has_suffix (".ffi")) {
				stderr.printf (@"Is it a .ffi file?\n");
			}
			
			return 1;
		}

		directory = File.new_for_path (output_directory);
		
		if (!directory.query_exists ()) {
			stderr.printf ("Can't find output directory $directory\n");
			return 1;
		}

		ExportTool.export_svg_font_path (File.new_for_path (output_directory));
		ExportTool.export_ttf_font_path (File.new_for_path (output_directory), false);
						
		return 0;
	}
	
}

}
