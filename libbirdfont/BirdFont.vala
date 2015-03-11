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
using BirdFont;
public const string GETTEXT_PACKAGE = "birdfont"; 

namespace BirdFont {

public static string? settings_directory = null;

static void print_import_help (string[] arg) {
	stdout.printf (t_("Usage:"));
	stdout.printf (arg[0]);
	stdout.printf (" " + t_("BF-FILE") + " " + t_("SVG-FILES ...") +"\n");
	stdout.printf ("\n");
}

public static int run_import (string[] arg) {
	string bf_file = "";
	Gee.ArrayList<string> svg_files = new Gee.ArrayList<string> ();
	File bf;
	File svg;
	Font font;
	bool imported;
	
	Preferences.load ();
	BirdFont.args = new Argument ("");
	BirdFont.current_font = new Font ();
	BirdFont.current_glyph_collection = new GlyphCollection.with_glyph ('\0', "");
	MainWindow.init ();

	if (arg.length < 3) {
		print_import_help (arg);
		return -1;
	}
	
	bf_file = build_absoulute_path (arg[1]);
	
	for (int i = 2; i < arg.length; i++) {
		svg_files.add (arg[i]);
	}
	
	bf = File.new_for_path (bf_file);
	foreach (string f in svg_files) {
		svg = File.new_for_path (f);
		
		if (!svg.query_exists ()) {
			stdout.printf (@"$f " + t_("does not exist.") + "\n");
			return -1;
		}
	}
	
	font = BirdFont.get_current_font ();

	if (!bf.query_exists ()) {
		stdout.printf (@"$bf_file " + t_("does not exist.") + " ");
		stdout.printf (t_("A new font will be created.") + "\n");
		font.set_file (bf_file);
	} else {
		font.set_file (bf_file);
		if (!font.load ()) {
			warning (@"Failed to load font $bf_file.\n");
			
			if (!bf_file.has_suffix (".bf")) {
				warning (@"Is it a .bf file?\n");
			}
			
			return -1;
		}
	}

	font.save_backup ();

	foreach (string f in svg_files) {
		svg = File.new_for_path (f);
		imported = import_svg_file (font, svg);
		
		if (!imported) {
			stdout.printf (t_("Failed to import") + " " + f + "\n");
			stdout.printf (t_("Aborting") + "\n");
			return -1;
		}
	}
	
	font.save_bf ();
	
	return 0;
}

internal static string build_absoulute_path (string file_name) {
	File f = File.new_for_path (file_name);
	return (!) f.get_path ();
}

static bool import_svg_file (Font font, File svg_file) {
	string file_name = (!) svg_file.get_basename ();
	string glyph_name;
	StringBuilder n;
	Glyph glyph;
	GlyphCollection? gc = null;
	GlyphCollection glyph_collection;
	unichar character;
	GlyphCanvas canvas;
	
	glyph_name = file_name.replace (".svg", "");
	glyph_name = glyph_name.replace (".SVG", "");
	
	if (glyph_name.char_count () > 1) {
		if (glyph_name.has_prefix ("U+")) {
			n = new StringBuilder ();
			n.append_unichar (Font.to_unichar (glyph_name));
			glyph_name = n.str;
			gc = font.get_glyph_collection (glyph_name);
		} else {
			gc = font.get_glyph_collection_by_name (glyph_name);
			
			if (gc == null) {
				stdout.printf (file_name + " " + t_("is not the name of a glyph or a Unicode value.") + "\n");
				stdout.printf (t_("Unicode values must start with U+.") + "\n");
				return false;
			}
		}		
	} else {
		gc = font.get_glyph_collection (glyph_name);
	}

	if (gc != null) {
		glyph_collection = (!) gc;
		character = glyph_collection.get_unicode_character ();
		glyph = new Glyph (glyph_collection.get_name (), character);
		glyph.version_id = glyph_collection.get_last_id () + 1;
		glyph_collection.insert_glyph (glyph, true);
	} else {
		return_val_if_fail (glyph_name.char_count () == 1, false);
		character = glyph_name.get_char (0);
		glyph_collection = new GlyphCollection (character, glyph_name);
		glyph = new Glyph (glyph_name, character);
		glyph_collection.insert_glyph (glyph, true);
		font.add_glyph_collection (glyph_collection);
	}

	canvas = MainWindow.get_glyph_canvas ();
	canvas.set_current_glyph_collection (glyph_collection);

	stdout.printf (t_("Adding"));
	stdout.printf (" ");
	stdout.printf ((!) svg_file.get_basename ());
	stdout.printf (" ");
	stdout.printf (t_("to"));
	stdout.printf (" ");
	stdout.printf (t_("Glyph"));
	stdout.printf (": ");
	stdout.printf (glyph.get_name ());
	stdout.printf (" ");
	stdout.printf (t_("Version"));
	stdout.printf (": ");
	stdout.printf (@"$(glyph.version_id)");
	stdout.printf ("\n");
	
	SvgParser.import_svg ((!) svg_file.get_path ());
	
	return true;
}

static void print_export_help (string[] arg) {
	stdout.printf (t_("Usage:"));
	stdout.printf (arg[0]);
	stdout.printf (" [" + t_("OPTION") + "...] " + t_("FILE") +"\n");
	stdout.printf ("-h, --help                      " + t_("print this message\n"));
	stdout.printf ("-o, --output [DIRECTORY]        " + t_("write files to this directory\n"));
	stdout.printf ("-s, --svg                       " + t_("write svg file\n"));
	stdout.printf ("-t, --ttf                       " + t_("write ttf and eot files\n"));
	stdout.printf ("\n");
}

public static string get_version () {
	return VERSION;
}

public static string get_build_stamp () {
	return BUILD_TIMESTAMP;
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
	stdout.printf ("built on %s\n", BUILD_TIMESTAMP);

	if (arg.length < 2) {
		print_export_help (arg);
		return -1;
	}

	BirdFont.current_font = BirdFont.new_font ();
	BirdFont.current_glyph_collection = new GlyphCollection.with_glyph ( '\0', "null");
	main_window = new MainWindow ();
	
	// FIXME: create a option for this and add structure the log messages
	// init_logfile ();
	
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
		print (@"Writing $(BirdFont.current_font.get_full_name ()).svg to $output_directory\n");
		ExportTool.export_svg_font_path (File.new_for_path (output_directory));
	}

	if (!specific_formats || write_ttf) {
		print (@"Writing $(BirdFont.current_font.get_full_name ()).ttf to $output_directory\n");
		ExportTool.export_ttf_font_path (File.new_for_path (output_directory));
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

public bool is_null (void* n) {
	return n == null;
}

public bool has_flag (uint32 flag, uint32 mask) {
	return (flag & mask) > 0;
}

public class BirdFont {
	public static Argument args;
	public static bool experimental = false;
	public static bool show_coordinates = false;
	public static bool fatal_wanings = false;
	public static bool win32 = false;
	public static bool mac = false;
	public static bool android = false;
	public static string exec_path = "";
	public static string bundle_path = "";

	public static bool logging = false;
	public static DataOutputStream? logstream = null;

	public static Font current_font;
	public static GlyphCollection current_glyph_collection;
	
	public static Drawing? drawing = null;
	
	public BirdFont () {
		set_defaul_drawing_callbacks ();
	}
	
	void set_defaul_drawing_callbacks () {
		if (drawing == null) {
			drawing = new Drawing ();
		}
	}	
	
	/**
	 * @param arg command line arguments
	 * @param program path
	 */
	public void init (string[] arg, string? program_path) {
		int err_arg;
		int i;
		File font_file;
		string exec_path;

		args = new Argument.command_line (arg);

#if ANDROID
		BirdFont.logging = true;
		
		__android_log_print (ANDROID_LOG_WARN, "BirdFont", @"libbirdfont version $VERSION");
		LogLevelFlags log_levels = LogLevelFlags.LEVEL_ERROR | LogLevelFlags.LEVEL_CRITICAL | LogLevelFlags.LEVEL_WARNING;
		Log.set_handler (null, log_levels, android_warning);
		
		android = true;
#else
		stdout.printf ("birdfont version %s\n", VERSION);
		stdout.printf ("built on %s\n", BUILD_TIMESTAMP);
		
		android = args.has_argument ("--android");
		BirdFont.logging = args.has_argument ("--log");
#endif

		if (BirdFont.logging) {
			init_logfile ();
		}
		
		if (!args.has_argument ("--no-translation")) {
			init_gettext ();
		}

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

		Preferences.load ();
		
		// FIXME: DELETE
		Theme.load_theme ();
		save_default_colors ();

		Theme.load_theme ();
		
		current_font = new Font ();
		current_font.set_name ("");
		current_font.initialised = false;
		current_glyph_collection = new GlyphCollection.with_glyph ('\0', "");
		
		experimental = args.has_argument ("--test");
		show_coordinates = args.has_argument ("--show-coordinates") || experimental;
		fatal_wanings = args.has_argument ("--fatal-warning");
		win32 = (arg[0].index_of (".exe") > -1) 
			|| arg[0] == "wine"
			|| args.has_argument ("--windows");

#if MAC
		mac = true;
#else
		mac = args.has_argument ("--mac");
#endif
	
		if (program_path == null) {
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
		} else {
			exec_path = (!) program_path;
		}
		
		if (args.get_file () != "") {
			font_file = File.new_for_path (args.get_file ());
			
			if (!font_file.query_exists ()) {
				stderr.printf (@"The file \"$(args.get_file ())\" was not found.\n");
				Process.exit (-1);
			}
		}

		if (fatal_wanings) {
			LogLevelFlags levels = LogLevelFlags.LEVEL_ERROR | LogLevelFlags.LEVEL_CRITICAL | LogLevelFlags.LEVEL_WARNING;
			Log.set_handler (null, levels, fatal_warning);
		}
		
		Preferences.set_last_file (get_current_font ().get_path ());

		DefaultCharacterSet.create_default_character_sets ();
		DefaultCharacterSet.get_characters_for_prefered_language ();

		HeadTable.init ();

		if (TestBirdFont.get_singleton ().test_cases_to_run != "All") {
			TestBirdFont.run_tests ();
		}
	}

	public static Argument get_arguments () {
		return args;
	}

	void save_default_colors () {
		Theme.save_color ("Background 1", 1, 1, 1, 1);
		Theme.save_color ("Background 2", 101 / 255.0, 108 / 255.0, 116 / 255.0, 1);
		Theme.save_color ("Background 3", 38 / 255.0, 39 / 255.0, 43 / 255.0, 1);
		Theme.save_color ("Background 4", 51 / 255.0, 54 / 255.0, 59 / 255.0, 1);
		Theme.save_color ("Background 5", 0.3, 0.3, 0.3, 1);
		Theme.save_color ("Background 6", 224/255.0, 224/255.0, 224/255.0, 1);
		Theme.save_color ("Background 7", 56 / 255.0, 59 / 255.0, 65 / 255.0, 1);
		Theme.save_color ("Background 8", 55/255.0, 55/255.0, 55/255.0, 1);
		Theme.save_color ("Background 9", 72/255.0, 72/255.0, 72/255.0, 1);
		
		Theme.save_color ("Foreground 1", 0, 0, 0, 1);
		Theme.save_color ("Foreground 2", 101 / 255.0, 108 / 255.0, 116 / 255.0, 1);
		Theme.save_color ("Foreground 3", 26 / 255.0, 30 / 255.0, 32 / 255.0, 1);
		Theme.save_color ("Foreground 4", 40 / 255.0, 57 / 255.0, 65 / 255.0, 1);
		Theme.save_color ("Foreground 5", 70 / 255.0, 77 / 255.0, 83 / 255.0, 1);
		
		Theme.save_color ("Highlighted 1", 234 / 255.0, 77 / 255.0, 26 / 255.0, 1);
		
		Theme.save_color ("Highlighted Guide", 0, 0, 0.3, 1);
		Theme.save_color ("Guide 1", 0.7, 0.7, 0.8, 1);
		Theme.save_color ("Guide 2", 0.7, 0, 0, 0.5);
		Theme.save_color ("Guide 3", 120 / 255.0, 68 / 255.0, 120 / 255.0, 120 / 255.0);
		
		Theme.save_color ("Grid",0.2, 0.6, 0.2, 0.2);
		
		Theme.save_color ("Background Glyph", 0.2, 0.2, 0.2, 0.5);
		
		Theme.save_color ("Tool Border 1", 38 / 255.0, 39 / 255.0, 43 / 255.0, 1);
		Theme.save_color ("Tool Background 1", 14 / 255.0, 16 / 255.0, 17 / 255.0, 1);

		Theme.save_color ("Tool Border 2", 38 / 255.0, 39 / 255.0, 43 / 255.0, 1);
		Theme.save_color ("Tool Background 2", 26 / 255.0, 30 / 255.0, 32 / 255.0, 1);

		Theme.save_color ("Tool Border 3", 38 / 255.0, 39 / 255.0, 43 / 255.0, 1);
		Theme.save_color ("Tool Background 3", 44 / 255.0, 47 / 255.0, 51 / 255.0, 1);

		Theme.save_color ("Tool Border 4", 38 / 255.0, 39 / 255.0, 43 / 255.0, 1);
		Theme.save_color ("Tool Background 4", 33 / 255.0, 36 / 255.0, 39 / 255.0, 1);
			
		N_("Background 1");
		N_("Background 2");
		N_("Background 3");
		N_("Background 4");
		N_("Background 5");
		N_("Background 6");
		N_("Background 7");
		N_("Background 8");
		N_("Background 9");
		
		N_("Foreground 1");
		N_("Foreground 2");
		N_("Foreground 3");
		N_("Foreground 4");
		N_("Foreground 5");
		
		N_("Highlighted 1");
		N_("Highlighted Guide");
		
		N_("Grid");
		
		N_("Guide 1");
		N_("Guide 2");
		N_("Guide 3");
		
		N_("Tool Border 1");
		N_("Tool Background 1");
		N_("Tool Border 2");
		N_("Tool Background 2");
		N_("Tool Border 3");
		N_("Tool Background 3");
		N_("Tool Border 4");
		N_("Tool Background 4");
	}

	public static void set_bundle_path (string path) {
		bundle_path = path;	
	}

	public static void init_gettext () {
		// FIXME: android, this should be OK now
#if !ANDROID
		string locale_directory = SearchPaths.get_locale_directory ();
		Intl.setlocale (LocaleCategory.MESSAGES, "");
		Intl.bind_textdomain_codeset (GETTEXT_PACKAGE, "utf-8");
		Intl.bindtextdomain (GETTEXT_PACKAGE, locale_directory);
#endif
	}
	
	public static void load_font_from_command_line () {
		string file = args.get_file ();
		if (file != "") {
			FileTab.load_font (file);
		}	
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

#if ANDROID
	internal static void android_warning (string? log_domain, LogLevelFlags log_levels, string message) {
		__android_log_print (ANDROID_LOG_WARN, "BirdFont", message);
	}
#endif
	
	public static Font new_font () {
		current_font = new Font ();
		
		if (!is_null (MainWindow.tools)) {
			MainWindow.get_drawing_tools ().remove_all_grid_buttons ();
			MainWindow.get_drawing_tools ().add_new_grid (1);
			MainWindow.get_drawing_tools ().add_new_grid (2);
			MainWindow.get_drawing_tools ().add_new_grid (4);
		}
		
		if (!is_null (Toolbox.background_tools)) {
			Toolbox.background_tools.remove_images ();
		}
		
		KerningTools.update_kerning_classes ();
		
		return current_font;
	}

	public static void set_settings_directory (string directory) {
		settings_directory = directory;
	}
	
	public static File get_preview_directory () {
		File settings = get_settings_directory ();
		File backup = get_child(settings, "preview");
		
		if (!backup.query_exists ()) {
			DirUtils.create ((!) backup.get_path (), 0755);
		}
			
		return backup;
	}

	internal static File get_thumbnail_directory () {
		File thumbnails = get_child (get_settings_directory (), "thumbnails");
		
		if (!thumbnails.query_exists ()) {
			DirUtils.create ((!) thumbnails.get_path (), 0755);
		}
		
		return thumbnails;
	}

	internal static File get_settings_directory () {
		string home_path;
		File home;
		File settings;

#if ANDROID
		home_path = "/data/data/org.birdfont.sefyr/files";
		home = File.new_for_path (home_path);

		if (!home.query_exists ()) {
			printd ("Create settings directory.");
			DirUtils.create ((!) home.get_path (),0755);
		}
#else	
		home_path = (settings_directory != null) 
			? (!) settings_directory : Environment.get_user_config_dir ();
						
		if (is_null (home_path)) {
			warning ("No home directory set.");
			home_path = ".";
		}
		
		home = File.new_for_path (home_path);
#endif
		settings = get_child(home, "birdfont");
				
		if (!settings.query_exists ()) {
			DirUtils.create ((!) settings.get_path (), 0755);
		}
			
		return settings;
	}

	internal static File get_backup_directory () {
		File settings = get_settings_directory ();
		File backup = get_child (settings, "backup");
		
		if (!backup.query_exists ()) {
			DirUtils.create ((!) backup.get_path (), 0755);
		}
			
		return backup;
	}

	public static bool has_argument (string param) {
		if (is_null (args)) {
			return false;
		}
		
		return args.has_argument (param);
	}
	
	internal static string? get_argument (string param) {
		return args.get_argument (param);
	}	
}

void init_logfile () {
	DateTime t;
	File settings;
	string s;
	File log;
	
	try {
		t = new DateTime.now_local ();
		settings = BirdFont.get_settings_directory ();
		s = t.to_string ().replace (":", "_");
		log = get_child (settings, @"birdfont_$s.log");
		
		BirdFont.logstream = new DataOutputStream (log.create (FileCreateFlags.REPLACE_DESTINATION));
		((!)BirdFont.logstream).put_string ((!) log.get_path ());
		((!)BirdFont.logstream).put_string ("\n");
		
		warning ("Logging to " + (!) log.get_path ());	
	} catch (GLib.Error e) {
		warning (e.message);
		warning ((!) log.get_path ());
	}

	LogLevelFlags levels = LogLevelFlags.LEVEL_ERROR | LogLevelFlags.LEVEL_CRITICAL | LogLevelFlags.LEVEL_WARNING | LogLevelFlags.LEVEL_DEBUG;
	Log.set_handler (null, levels, log_warning);		
		
	BirdFont.logging = true;

	printd (@"Program version: $(VERSION)\n");
	printd (@"built on $(BUILD_TIMESTAMP)\n");
}

internal static void log_warning (string? log_domain, LogLevelFlags log_levels, string message) {
	if (log_domain != null) {
		printd ((!) log_domain);
	}
	
	printd ("\n");
	printd (message);
	printd ("\n");
	printd ("\n");
}

/** Write debug output to logfile. */
void printd (string s) {
#if ANDROID
	__android_log_print (ANDROID_LOG_WARN, "BirdFont", s);
#else
	if (unlikely (BirdFont.logging)) {
		try {
			if (BirdFont.logstream != null) {
				((!)BirdFont.logstream).put_string (s);
			} else {
				warning ("No logstream.");
			}
			
			stderr.printf (s);
		} catch (GLib.Error e) {
			warning (e.message);
		}
	}
#endif
}

/** Translate string */
public string t_ (string t) {
	return _(t);
}

/** Translate mac menu items */
public static string translate_mac (string t) {
	string s = t_(t);
	return s.replace ("_", "");
}

/** Print a warning if Birdfont was started with the --test argument. */
public static void warn_if_test (string message) {
	if (BirdFont.has_argument ("--test")) {
		warning (message);
	}
}

/** Obtain a handle to a file in a folder. */ 
public static File get_child (File folder, string file_name) {
	string f;
	string s;
	string n;

	// avoid drive letter problems on windows
	
	f = (!) folder.get_path ();
	s = (BirdFont.win32) ? "\\" : "/"; 
	
	n = file_name;
	if (unlikely (BirdFont.win32 && file_name.index_of ("\\") != -1)) {
		warning (@"File name contains path separator: $file_name, Directory: $f");
		n = n.substring (n.last_index_of ("\\")).replace ("\\", "");
	}

	if (!f.has_suffix (s)) {
		f += s;
	}
	
	printd (@"File: Directory: $f Name: $n\n");
	
	return File.new_for_path (f + n);
}

public static void set_drawing_callbacks (Drawing callbacks) {
	BirdFont.drawing = callbacks;
}

}
