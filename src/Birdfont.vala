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
using Supplement;

namespace Birdfont {

public static int run_gui (string[] arg) {
	int err_arg;
	File font_file;
	Argument args;
	IdleSource idle;

	Supplement.Supplement supplement = new Supplement.Supplement ();

	supplement.args = new Argument.command_line (arg);
	args = supplement.args;
	
	if (supplement.args.has_argument ("--help")) {
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
	stdout.printf ("built on %s\n", BUILD_TIMESTAMP);

	supplement.current_font = new Font ();
	supplement.current_glyph = new Glyph ("");

	supplement.experimental = args.has_argument ("--test");
	supplement.show_coordinates = args.has_argument ("--show-coordinates");
	supplement.fatal_wanings = args.has_argument ("--fatal-warning");
	supplement.win32 = (arg[0].index_of (".exe") > -1);

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
	MainWindow window = new MainWindow ();
	GtkWindow native_window = new GtkWindow ("birdfont");
	window.set_native (native_window);

	if (supplement.fatal_wanings) {
		LogLevelFlags levels = LogLevelFlags.LEVEL_ERROR | LogLevelFlags.LEVEL_CRITICAL | LogLevelFlags.LEVEL_WARNING;
		Log.set_handler (null, levels, supplement.fatal_warning);
	}
	
	idle = new IdleSource ();
	idle.set_callback(() => {
		preferences.load ();
		
		if (args.get_file () != "") {
			supplement.get_current_font ().load (args.get_file ());
			MainWindow.get_toolbox ().select_tool_by_name ("available_characters");
		} else {
			MainWindow.get_tab_bar ().select_tab_name ("Menu");
		}
		
		return false;
	});
	
	idle.attach (null);
	
	Gtk.main ();
	
	preferences.set_last_file (supplement.get_current_font ().get_path ());
	
	return 0;
}

static void print_export_help (string[] arg) {
	stdout.printf ("Usage: ");
	stdout.printf (arg[0]);
	stdout.printf (" [OPTION ...] FILE\n");
	stdout.printf ("-h, --help                      print this message\n");
	stdout.printf ("-o, --output [DIRECTORY]        write files to this directory\n");
	stdout.printf ("-s, --svg                       write file\n");
	stdout.printf ("-t, --ttf                       write ttf and eot files\n");
	stdout.printf ("\n");
}

public static int run_export (string[] arg) {
	string output_directory = ".";
	string file_name = "";
	bool specific_formats = false;	
	bool write_ttf = false;
	bool write_svg = false;
	Supplement.Supplement supplement = new Supplement.Supplement ();
	
	File directory;
		
	if (arg.length < 2) {
		print_export_help (arg);
	}
	
	for (int i = 1; i < arg.length; i++) {

		if (arg[i] == "-f" || arg[i] == "--fatal-warnings") {
			supplement.fatal_wanings = true;
			return 0;
		}

		if (arg[i] == "-h" || arg[i] == "--help") {
			print_export_help (arg);
			return 0;
		}
		
		if (arg[i] == "-o" || arg[i] == "--output" && i + 1 < arg.length) {
			output_directory = arg[i + 1];
			i++;
			continue;
		}

		if (arg[i] == "-t" || arg[i] == "--ttf") {
			write_ttf = true;
			specific_formats = true;
			i++;
			continue;
		}

		if (arg[i] == "-s" || arg[i] == "--svg") {
			write_svg = true;
			specific_formats = true;
			i++;
			continue;
		}
		
		if (arg[i].has_prefix ("-")) {
			print_export_help (arg);
			return 1;
			continue;
		}
		
		if (!arg[i].has_prefix ("-")) {
			file_name = arg[i];
			
			if (i != arg.length - 1) {
				print_export_help (arg);
				return 1;
			}
			
			break;
		}
	}

	if (supplement.fatal_wanings) {
		LogLevelFlags levels = LogLevelFlags.LEVEL_ERROR | LogLevelFlags.LEVEL_CRITICAL | LogLevelFlags.LEVEL_WARNING;
		Log.set_handler (null, levels, supplement.fatal_warning);		
	}

	Preferences preferences = new Preferences ();
	preferences.load ();
		
	supplement.args = new Argument ("");
	supplement.current_font = new Font ();
	supplement.current_glyph = new Glyph ("");
	
	if (!supplement.get_current_font ().load (file_name, false)) {
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

	if (!specific_formats || write_svg) {
		print (@"Writing $(supplement.current_font.get_name ()).svg to $output_directory\n");
		ExportTool.export_svg_font_path (File.new_for_path (output_directory));
	}

	if (!specific_formats || write_ttf) {
		print (@"Writing $(supplement.current_font.get_name ()).ttf to $output_directory\n");
		ExportTool.export_ttf_font_path (File.new_for_path (output_directory), false);
	}
	
	return 0;
}

}
