/*
    Copyright (C) 2012 Johan Mattsson

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

using Gee;

public class Preferences {
		
	static Gee.HashMap<string, string> data;
	public static bool draw_boundaries = false;

	public Preferences () {
		data = new Gee.HashMap<string, string> ();
	}

	public static void set_last_file (string fn) {
		set ("last_file", fn);
	}

	public static string @get (string k) {
		string? s;

		if (is_null (data)) {
			data = new Gee.HashMap<string, string> ();
		}
		
		s = data.get (k);
		
		return (s != null) ? (!) s : "";
	}

	public static void @set (string k, string v) {
		if (is_null (data)) {
			data = new Gee.HashMap<string, string> ();
		}
		
		data.set (k, v);
		save ();
	}

	public static string[] get_recent_files () {
		string recent = get ("recent_files");
		string[] files = recent.split ("\t");
		
		for (uint i = 0; i < files.length; i++) {
			files[i] = files[i].replace ("\\t", "\t");
		}
		
		return files;
	}

	public static void add_recent_files (string file) {
		string escaped_string = file.replace ("\t", "\\t");
		StringBuilder recent = new StringBuilder ();

		foreach (string f in get_recent_files ()) {
			if (f != file) {
				recent.append (f.replace ("\t", "\\t"));
				recent.append ("\t");
			}
		}

		recent.append (escaped_string);

		set ("recent_files", @"$(recent.str)");
	}

	public static int get_window_width() {
		string wp = get ("window_width");
		int w = int.parse (wp);
		return (w == 0) ? 860 : w;
	}

	public static int get_window_height() {
		int h = int.parse (get ("window_height"));
		return (h == 0) ? 500 : h;
	}
	
	public static void load () {
		File app_dir;
		File settings;
		FileStream? settings_file;
		unowned FileStream b;
		string? l;
		
		printd ("get app");
		app_dir = BirdFont.get_settings_directory ();
		
		if (is_null (app_dir)) {
			warning ("No app directory.");
			return;
		}

		printd ("get settings file");
		settings = app_dir.get_child ("settings");

		if (is_null (settings)) {
			warning ("No setting directory.");
			return;
		}

		printd ("create map");
		data = new HashMap<string, string> ();

		printd ("look at settings");
		if (!settings.query_exists ()) {
			return;
		}
		
		printd ("open settings file");
		settings_file = FileStream.open ((!) settings.get_path (), "r");
		
		if (settings_file == null) {
			stderr.printf ("Failed to load settings from file %s.\n", (!) settings.get_path ());
			return;
		}
		
		printd ("parse settings file");
		b = (!) settings_file;
		l = b.read_line ();
		while ((l = b.read_line ())!= null) {
			string line;
			
			line = (!) l;
			
			if (line.get_char (0) == '#') {
				continue;
			}
			
			int i = 0;
			int s = 0;
			
			i = line.index_of_char(' ', s);
			string key = line.substring (s, i - s);

			s = i + 1;
			i = line.index_of_char('"', s);
			s = i + 1;
			i = line.index_of_char('"', s);
			string val = line.substring (s, i - s);
			
			data.set (key, val);
		}
	}
	
	public static void save () {
		try {
			File app_dir = BirdFont.get_settings_directory ();
			File settings = app_dir.get_child ("settings");

			return_if_fail (app_dir.query_exists ());
		
			if (settings.query_exists ()) {
				settings.delete ();
			}

			DataOutputStream os = new DataOutputStream(settings.create(FileCreateFlags.REPLACE_DESTINATION));
			uint8[] d;
			long written = 0;
			
			StringBuilder sb = new StringBuilder ();
			
			sb.append ("# BirdFont settings\n");
			sb.append ("# Version: 1.0\n");
			
			foreach (var k in data.keys) {
				sb.append (k);
				sb.append (" \"");
				sb.append (data.get (k));
				sb.append ("\"\n");
			}
			
			d = sb.str.data;
				
			while (written < d.length) { 
				written += os.write (d[written:d.length]);
			}
		} catch (Error e) {
			stderr.printf ("Can not save key settings. (%s)", e.message);	
		}	
	}
}

}
