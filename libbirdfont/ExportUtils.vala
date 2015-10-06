/*
    Copyright (C) 2012 2014 Johan Mattsson

    This library is free software; you can redistribute it and/or modify 
    it under the terms of the GNU Lesser General Public License as 
    published by the Free Software Foundation; either version 3 of the 
    License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful, but 
    WITHOUT ANY WARRANTY; without even the implied warranty of 
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
    Lesser General Public License for more details.
*/
namespace BirdFont {

static void print_export_help (string[] arg) {
	stdout.printf (t_("Usage:"));
	stdout.printf (arg[0]);
	stdout.printf (" [" + t_("OPTION") + "...] " + t_("FILE") +"\n");
	stdout.printf ("-h, --help                      " + t_("print this message") + "\n");
	stdout.printf ("-o, --output [DIRECTORY]        " + t_("write files to this directory") + "\n");
	stdout.printf ("-s, --svg                       " + t_("write svg file") + "\n");
	stdout.printf ("-t, --ttf                       " + t_("write ttf and eot file") + "\n");
	stdout.printf ("\n");
}


public static int run_export (string[] arg) {
	string output_directory = ".";
	string file_name = "";
	bool specific_formats = false;	
	bool write_ttf = false;
	bool write_svg = false;	
	File directory;
	Font font;
	MainWindow main_window;

	stdout.printf ("birdfont-export version %s\n", VERSION);

	if (arg.length < 2) {
		print_export_help (arg);
		return -1;
	}

	Theme.set_default_colors ();
	BirdFont.current_font = BirdFont.new_font ();
	BirdFont.current_glyph_collection = new GlyphCollection.with_glyph ( '\0', "null");
	main_window = new MainWindow ();
	
	// FIXME: create a option for this and add structure the log messages
	
	if (BirdFont.has_logging ()) {
		init_logfile ();
	}
	
	for (int i = 1; i < arg.length; i++) {

		if (arg[i] == "-f" || arg[i] == "--fatal-warnings") {
			BirdFont.fatal_wanings = true;
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

	if (BirdFont.fatal_wanings) {
		LogLevelFlags levels = LogLevelFlags.LEVEL_ERROR | LogLevelFlags.LEVEL_CRITICAL | LogLevelFlags.LEVEL_WARNING;
		Log.set_handler (null, levels, BirdFont.fatal_warning);		
	}
	
	Preferences.load ();
			
	BirdFont.args = new Argument ("");
	BirdFont.current_glyph_collection = new GlyphCollection.with_glyph ('\0', "");
	
	file_name = build_absoulute_path (file_name);
	
	font = BirdFont.get_current_font ();
	font.set_file (file_name);
	if (!font.load ()) {
		warning (@"Failed to load font $file_name.\n");
		
		if (!file_name.has_suffix (".bf")) {
			warning (@"Is it a .bf file?\n");
		}
		
		return 1;
	}

	directory = File.new_for_path (output_directory);
	
	if (!directory.query_exists ()) {
		stderr.printf (t_("Can't find output directory") + @"$((!)directory.get_path ())\n");
		return 1;
	}

	if (!specific_formats || write_svg) {
		print (@"Writing $(ExportSettings.get_file_name (font)).svg to $output_directory\n");
		ExportTool.export_svg_font_path (File.new_for_path (output_directory));
	}

	if (!specific_formats || write_ttf) {
		print (@"Writing $(ExportSettings.get_file_name (font)).ttf to $output_directory\n");
		ExportTool.export_ttf_font_path (File.new_for_path (output_directory));
	}
	
	return 0;
}

}
