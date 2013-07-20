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
	
	public static File find_file (string? dir, string name) {
		File f;
		string d = (dir == null) ? "" : (!) dir;

		f = get_file (BirdFont.exec_path + "/" + d + "/", name);
		if (likely (f.query_exists ())) return f;
		
		f = get_file (BirdFont.exec_path + "/", name + "/");
		if (likely (f.query_exists ())) return f;

		f = get_file (BirdFont.exec_path + "\\" + d + "\\", name);
		if (likely (f.query_exists ())) return f;
		
		f = get_file (BirdFont.exec_path + "\\", name + "\\");
		if (likely (f.query_exists ())) return f;
		
		f = get_file (BirdFont.exec_path + "/Contents/Resources/", d + "/" + name);
		if (likely (f.query_exists ())) return f;

		f = get_file (BirdFont.exec_path + "/Contents/Resources/", name + "/");
		if (likely (f.query_exists ())) return f;
		
		f = get_file ("./" + d + "/", name);
		if (likely (f.query_exists ())) return f;		

		f = get_file ("../" + d + "/", name);
		if (likely (f.query_exists ())) return f;

		f = get_file (".\\" + d + "\\", name);
		if (likely (f.query_exists ())) return f;

		f = get_file ("", name);
		if (likely (f.query_exists ())) return f;

		f = get_file (d + "\\", name);
		if (likely (f.query_exists ())) return f;

		f = get_file (@"$PREFIX/share/birdfont/" + d + "/", name);
		if (likely (f.query_exists ())) return f;

		f = get_file ("/usr/share/birdfont/" + d + "/", name);
		if (likely (f.query_exists ())) return f;
				
		warning (@"Did not find file $name in $d");
			
		return f;		
	}
		
	public static string get_locale_directory () {
		string f = "";
		
		f = BirdFont.exec_path + "/Contents/Resources/locale/sv/LC_MESSAGES/birdfont.mo";
		if (exists (f)) {
			return BirdFont.exec_path + "/Contents/Resources/locale";
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
			return f;
		}

		f = "/usr/share/locale/sv/LC_MESSAGES/birdfont.mo";
		if (exists (f)) {
			return "/usr/share/locale";
		}
		
		f = BirdFont.exec_path + "/Contents/Resources/locale";
		if (exists (f)) {
			return BirdFont.exec_path + "/Contents/Resources/locale";
		}
		
		warning ("translations not found");
		return "/usr/share/locale";
	}


	public static File get_char_database () {
		File f;
		
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
		
		f = (!) File.new_for_path ("/usr/share/unicode/ucd/NamesList.txt");
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
}

}
