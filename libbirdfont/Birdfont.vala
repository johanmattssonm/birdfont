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

static void print_export_help (string[] arg) {
	stdout.printf (_("Usage:"));
	stdout.printf (arg[0]);
	stdout.printf (" [OPTION ...] FILE\n");
	stdout.printf ("-h, --help                      " + _("print this message\n"));
	stdout.printf ("-o, --output [DIRECTORY]        " + _("write files to this directory\n"));
	stdout.printf ("-s, --svg                       " + _("write svg file\n"));
	stdout.printf ("-t, --ttf                       " + _("write ttf and eot files\n"));
	stdout.printf ("\n");
}

public static int run_export (string[] arg) {
	string output_directory = ".";
	string file_name = "";
	bool specific_formats = false;	
	bool write_ttf = false;
	bool write_svg = false;
	
	File directory;
		
	if (arg.length < 2) {
		print_export_help (arg);
	}
	
	for (int i = 1; i < arg.length; i++) {

		if (arg[i] == "-f" || arg[i] == "--fatal-warnings") {
			Supplement.Supplement.fatal_wanings = true;
			return 0;
		}

		if (arg[i] == "-h" || arg[i] == "--help") {
			print_export_help (arg);
			return 0;
		}
		
		if ((arg[i] == "-o" || arg[i] == "--output") && i + 1 < arg.length) {
			output_directory = arg[i + 1];
			i++;
			continue;
		}

		if (arg[i] == "-s" || arg[i] == "--svg") {
			write_svg = true;
			specific_formats = true;
			continue;
		}
		
		if (arg[i] == "-t" || arg[i] == "--ttf") {
			write_ttf = true;
			specific_formats = true;
			continue;
		}
		
		if (arg[i].has_prefix ("-")) {
			print_export_help (arg);
			return 1;
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

	if (Supplement.Supplement.fatal_wanings) {
		LogLevelFlags levels = LogLevelFlags.LEVEL_ERROR | LogLevelFlags.LEVEL_CRITICAL | LogLevelFlags.LEVEL_WARNING;
		Log.set_handler (null, levels, Supplement.Supplement.fatal_warning);		
	}
	
	Preferences preferences = new Preferences ();
	Preferences.load ();
			
	Supplement.Supplement.args = new Argument ("");
	Supplement.Supplement.current_font = new Font ();
	Supplement.Supplement.current_glyph = new Glyph ("");
	
	if (!Supplement.Supplement.get_current_font ().load (file_name, false)) {
		stderr.printf (@"Failed to load font $file_name.\n");
		
		if (!file_name.has_suffix (".ffi")) {
			stderr.printf (@"Is it a .ffi file?\n");
		}
		
		return 1;
	}

	directory = File.new_for_path (output_directory);
	
	if (!directory.query_exists ()) {
		stderr.printf (_("Can't find output directory") + @"$((!)directory.get_path ())\n");
		return 1;
	}

	if (!specific_formats || write_svg) {
		print (_("Writing") + @" $(Supplement.Supplement.current_font.get_name ()).svg to $output_directory\n");
		ExportTool.export_svg_font_path (File.new_for_path (output_directory));
	}

	if (!specific_formats || write_ttf) {
		print (_("Writing") + @" $(Supplement.Supplement.current_font.get_name ()).ttf to $output_directory\n");
		ExportTool.export_ttf_font_path (File.new_for_path (output_directory), false);
	}
	
	return 0;
}

public static string wine_to_unix_path (string exec_path) {
	bool drive_c, drive_z;
	int i;
	string p, q;

	p = exec_path;
	p = p.replace ("\\", "/");
	
	drive_c = exec_path.index_of ("C:") == 0;
	drive_z = exec_path.index_of ("Z:") == 0;
	
	i = p.index_of (":");
	
	if (i != -1) {
		p = p.substring (i + 2);
	}

	if (drive_c) {
		q = @"/home/$(Environment.get_user_name ())/.wine/drive_c/" + p;
		
		if (File.new_for_path (q).query_exists ()) {
			return q;
		} else {
			return p;
		}
	}
	
	if (drive_z) {
		return ("/" + p).dup ();
	}

	return exec_path.dup ();
}

}
