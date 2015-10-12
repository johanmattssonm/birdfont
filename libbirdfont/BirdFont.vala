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

internal static string build_absoulute_path (string file_name) {
	File f = File.new_for_path (file_name);
	return (!) f.get_path ();
}

public static string get_version () {
	return VERSION;
}

public static void set_logging (bool log) {
	BirdFont.logging = log;
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
	public static string? bundle_path = null;

	internal static bool logging = false;
	public static DataOutputStream? logstream = null;

	public static Font current_font;
	public static GlyphCollection current_glyph_collection;
	
	public static Drawing? drawing = null;
	
	public static string? settings_subdirectory = null;
	
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
	 * @param setting subdirectory
	 */
	public void init (string[] arg, string? program_path, string? settings_subdir) {
		int err_arg;
		int i;
		File font_file;
		string exec_path;
		string theme;
		int default_theme_version;
		string theme_version;
		CharDatabaseParser parser;
		CodePageBits codepage_bits;
		
		set_settings_subdir (settings_subdir);

		args = new Argument.command_line (arg);
		Font.empty = new Font ();

#if ANDROID
		BirdFont.logging = true;
		
		__android_log_print (ANDROID_LOG_WARN, "BirdFont", @"libbirdfont version $VERSION");
		LogLevelFlags log_levels = LogLevelFlags.LEVEL_ERROR | LogLevelFlags.LEVEL_CRITICAL | LogLevelFlags.LEVEL_WARNING;
		Log.set_handler (null, log_levels, android_warning);
		
		android = true;
#else
		stdout.printf ("birdfont version %s\n", VERSION);
		
		android = args.has_argument ("--android");
		
		if (!BirdFont.logging) {
			BirdFont.logging = args.has_argument ("--log");
		}
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
		
		// always load default theme when names in theme does change
		default_theme_version = 1;
		theme = Preferences.get ("theme");
		theme_version = Preferences.get ("theme_version");

		Theme.set_default_colors ();
		
		if (theme_version == "" || int.parse (theme_version) < default_theme_version) {
			
			Theme.load_theme ("dark.theme");
			Preferences.set ("theme", "dark.theme");
		} else {
			if (theme != "") {
				Theme.load_theme (theme);
			} else {
				Theme.load_theme ("dark.theme");
			}
		}

		Preferences.set ("theme_version", @"$default_theme_version");
		
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

		HeadTable.init (1024);

		if (TestBirdFont.get_singleton ().test_cases_to_run != "All") {
			TestBirdFont.run_tests ();
		}
		
		if (has_argument ("--parse-ucd")) {
			parser = new CharDatabaseParser ();
			parser.regenerate_database ();
		}

		if (has_argument ("--codepages")) {
			codepage_bits = new CodePageBits ();
			codepage_bits.generate_codepage_database ();
		}
	}

	public static bool has_logging () {
		bool log;
		
		lock (BirdFont.logging) {
			log = BirdFont.logging;
		}
		
		return log;
	}
	
	public static Argument get_arguments () {
		return args;
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
			RecentFiles.load_font (file);
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
			DrawingTools.add_new_grid (1, false);
			DrawingTools.add_new_grid (2, false);
			DrawingTools.add_new_grid (4, false);
		}
		
		if (!is_null (Toolbox.background_tools)) {
			Toolbox.background_tools.remove_images ();
		}
		
		KerningTools.update_kerning_classes ();
		
		return current_font;
	}

	public static void set_settings_directory (string directory) {
		settings_subdirectory = directory;
	}
	
	public static File get_preview_directory () {
		File settings = get_settings_directory ();
		File backup = get_child(settings, "preview");
		
		if (!backup.query_exists ()) {
			DirUtils.create ((!) backup.get_path (), 0755);
		}
			
		return backup;
	}

	public static void set_settings_subdir (string? subdir) {
		settings_subdirectory = subdir;
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

		if (settings_subdirectory != null) {
			settings = get_child(home, (!) settings_subdirectory);
		} else {
			settings = get_child(home, "birdfont");
		}
			
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
	
	public static void debug_message (string s) {
		if (unlikely (has_logging ())) {
			try {
				if (BirdFont.logstream != null) {
					((!)BirdFont.logstream).put_string (s);
					((!)BirdFont.logstream).flush ();
				} else {
					warning ("No logstream.");
				}
				
				stderr.printf (s);
			} catch (GLib.Error e) {
				warning (e.message);
			}
		}
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
public static void printd (string s) {
#if ANDROID
	__android_log_print (ANDROID_LOG_WARN, "BirdFont", s);
#else
	BirdFont.debug_message (s);
#endif
}

/** Translate string */
public string t_ (string t) {
#if ANDROID
	return t;
#else 
	return _(t);
#endif
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

#if LINUX
	s = "/"; 
#else
	s = (BirdFont.win32) ? "\\" : "/"; 
#endif
	
	n = file_name;
	if (unlikely (BirdFont.win32 && file_name.index_of ("\\") != -1)) {
		warning (@"File name contains path separator: $file_name, Directory: $f");
		n = n.substring (n.last_index_of ("\\")).replace ("\\", "");
	}

	if (!f.has_suffix (s)) {
		f += s;
	}
	
	printd (@"File in Directory: $f Name: $n\n");
	
	return File.new_for_path (f + n);
}

public static void set_drawing_callbacks (Drawing callbacks) {
	BirdFont.drawing = callbacks;
}

}
