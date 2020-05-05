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

/** Look for files in default folders on different operating systems. */
public class SearchPaths {
	
	private static string resources_folder = "";
	
	public static File find_file (string? dir, string name) {
		File f = search_file (dir, name);

		if (!f.query_exists ()) {
			warning (@"Did not find file $name");
		}
		
		return f;
	}
	
	public static File search_file (string? dir, string name) {
		File f;
		string d = (dir == null) ? "" : (!) dir;
		string resources;
		string bundle_path = (BirdFont.bundle_path != null) ? (!) BirdFont.bundle_path : "";

		resources = (is_null (resources_folder)) ? "" : resources_folder; 

		string? current_program = GLib.FileUtils.read_link ("/proc/self/exe");		

		if (current_program != null)	{
			string program = (!) current_program;
			int separator = program.last_index_of ("/");
			
			if (separator > -1) {
				string folder = program.substring (0, separator);
				
				f = get_file (folder + "/../" + d + "/", name);
				if (f.query_exists ()) return f;	

				f = get_file (folder + "/../", name);
				if (f.query_exists ()) return f;	
			}
		}
		
		f = get_file (resources + "/" + d + "/", name);
		if (f.query_exists ()) return f;

		f = get_file (resources + "/", name);
		if (f.query_exists ()) return f;

		f = get_file ("resources/", name);
		if (f.query_exists ()) return f;
				
		f = get_file (resources + "/", name + "/");
		if (f.query_exists ()) return f;

		f = get_file (BirdFont.exec_path + "/" + d + "/", name);
		if (f.query_exists ()) return f;
		
		f = get_file (BirdFont.exec_path + "/", name + "/");
		if (f.query_exists ()) return f;

		f = get_file (BirdFont.exec_path + "\\" + d + "\\", name);
		if (f.query_exists ()) return f;
		
		f = get_file (BirdFont.exec_path + "\\", name + "\\");
		if (f.query_exists ()) return f;
		
		f = get_file (bundle_path + "/Contents/Resources/birdfont_resources/", d + "/" + name);
		if (f.query_exists ()) return f;
		
		f = get_file (bundle_path + "/Contents/Resources/birdfont_resources/", name + "/");
		if (f.query_exists ()) return f;
		
		f = get_file ("./" + d + "/", name);
		if (f.query_exists ()) return f;		

		f = get_file ("../" + d + "/", name);
		if (f.query_exists ()) return f;
		
		f = get_file (".\\" + d + "\\", name);
		if (f.query_exists ()) return f;

		f = get_file ("", name);
		if (f.query_exists ()) return f;

		f = get_file (d + "\\", name);
		if (f.query_exists ()) return f;

		f = get_file (@"$PREFIX/share/birdfont/" + d + "/", name);
		if (f.query_exists ()) return f;

		f = get_file (@"/usr/local/share/birdfont/" + d + "/", name);
		if (f.query_exists ()) return f;

		f = get_file (@"resources/linux/", name);
		if (f.query_exists ()) return f;

		f = get_file (@"/usr/share/birdfont/" + d + "/", name);
		if (f.query_exists ()) return f;

		return f;		
	}
		
	public static string get_locale_directory () {
		string f = "";
		string resources;
		string bundle_path = (BirdFont.bundle_path != null) ? (!) BirdFont.bundle_path : "";
		
		resources = (is_null (resources_folder)) ? "" : resources_folder; 

		f = resources + "\\locale\\sv\\LC_MESSAGES\\birdfont.mo";
		if (exists (f)) {
			return resources + "\\locale";
		}
		
		if (!is_null (BirdFont.exec_path)) {
			f = BirdFont.exec_path + "/Contents/Resources/birdfont_resources/locale/sv/LC_MESSAGES/birdfont.mo";
			if (exists (f)) {
				return BirdFont.exec_path + "/Contents/birdfont_resources/Resources/locale";
			}
			
			f = BirdFont.exec_path + "\\locale\\sv\\LC_MESSAGES\\birdfont.mo";
			if (exists (f)) {
				return BirdFont.exec_path + "\\locale";
			}			
		}
		
		f = "./build/locale/sv/LC_MESSAGES/birdfont.mo";
		if (exists (f)) {
			return  "./build/locale";
		}

		f = ".\\locale\\sv\\LC_MESSAGES\\birdfont.mo";
		if (exists (f)) {
			return ".\\locale";
		}

		f = PREFIX + "/share/locale/sv/LC_MESSAGES/birdfont.mo";
		if (exists (f)) {
			return PREFIX + "/share/locale/";
		}

		f = "/usr/share/locale/sv/LC_MESSAGES/birdfont.mo";
		if (exists (f)) {
			return "/usr/share/locale";
		}
		
		f = BirdFont.exec_path + "/Contents/Resources/birdfont_resources/locale";
		if (exists (f)) {
			return BirdFont.exec_path + "/Contents/Resources/birdfont_resources/locale";
		}

		f = bundle_path + "/Contents/Resources/birdfont_resources/locale";
		if (exists (f)) {
			return bundle_path + "/Contents/Resources/birdfont_resources/locale";
		}
				
		warning ("translations not found");
		return "/usr/share/locale";
	}

	public static File get_char_database () {
		File f;
		string bundle_path = (BirdFont.bundle_path != null) ? (!) BirdFont.bundle_path : "";
		
		f = (!) File.new_for_path ("./resources/NamesList.txt");
		if (f.query_exists ()) {
			return f;
		}
		
		f = (!) File.new_for_path (PREFIX + "/share/unicode/NamesList.txt");
		if (f.query_exists ()) {
			return f;
		}

		f = (!) File.new_for_path (PREFIX + "/share/unicode/ucd/NamesList.txt");
		if (f.query_exists ()) {
			return f;
		}
		
		f = (!) File.new_for_path (".\\NamesList.txt");
		if (f.query_exists ()) {
			return f;
		}

		f = (!) File.new_for_path ("/usr/share/unicode/NamesList.txt");
		if (f.query_exists ()) {
			return f;
		}

		f = (!) File.new_for_path (BirdFont.exec_path + "/Contents/Resources/NamesList.txt");
		if (f.query_exists ()) {
			return f;
		}

		f = (!) File.new_for_path (bundle_path + "/Contents/Resources/NamesList.txt");
		if (f.query_exists ()) {
			return f;
		}
		
		f = (!) File.new_for_path ("/usr/share/unicode/ucd/NamesList.txt");
		if (f.query_exists ()) {
			return f;
		}
		
		warning ("ucd not found");
		
		return f;
	}
		
	static File get_file (string? path, string name) {
		StringBuilder fn = new StringBuilder ();
		string p = (path == null) ? "" : (!) path;
		fn.append (p);
		fn.append ((!) name);

		return File.new_for_path (fn.str);
	}
	
	static bool exists (string file) {
		File f = File.new_for_path (file);
		return f.query_exists ();
	}

	public static void set_resources_folder (string res) {
		resources_folder = res;
	}
}

}
