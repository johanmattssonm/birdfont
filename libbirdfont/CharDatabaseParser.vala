/*
    Copyright (C) 2013 Johan Mattsson

    This library is free software; you can redistribute it and/or modify 
    it under the terms of the GNU Lesser General Public License as 
    published by the Free Software Foundation; either version 3 of the 
    License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful, but 
    WITHOUT ANY WARRANTY; without even the implied warranty of 
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
    Lesser General Public License for more details.
*/

using Gee;

namespace BirdFont {

public class CharDatabaseParser : GLib.Object {

	public signal void sync ();
	
	GlyphRange utf8 = new GlyphRange ();
	
	public CharDatabaseParser () {	
	}

	private void add_entry (string data) {
		string[] e;
		string[] r;
		string[] d;
		string index_values;
		unichar ch;
		string unicode_hex;

		if (data.has_prefix ("@")) { // ignore comments
			return;
		}
		
		index_values = data.down ();
		index_values = index_values.replace ("\n\tx", "");
		index_values = index_values.replace ("\n\t*", "");
		index_values = index_values.replace ("\n\t=", "");
		index_values = index_values.replace ("\n\t#", "");
		index_values = index_values.replace (" - ", " ");
		index_values = index_values.replace ("(", "");
		index_values = index_values.replace (")", "");
		index_values = index_values.replace ("<font>", "");
		index_values = index_values.replace (" a ", " ");
		index_values = index_values.replace (" is ", " ");
		index_values = index_values.replace (" the ", " ");
		
		e = index_values.split ("\t");

		return_if_fail (e.length > 0);
		
		unicode_hex = e[0].up ();
		
		ch = Font.to_unichar ("U+" + unicode_hex.down ());
		
		Idle.add (() => {
			CharDatabase.entries.set (unicode_hex, data);
			return false;
		});
		sync ();
		
		utf8.add_single (ch);
		
		foreach (string s in e) {
			r = s.split ("\n");
			foreach (string t in r) {  
				d = t.split (" ");
				foreach (string token in d) {
					if (token != "") {
						Idle.add (() => {
							CharDatabase.index.set (token, unicode_hex);
							return false;
						});
						sync ();
					}
				}
			}
		}
	}

	private void parse_all_entries () {
		FileInputStream fin;
		DataInputStream din;
		string? line;
		string data;
		string description = "";
		File file;

		file = get_unicode_database ();
		
		try {
			fin = file.read ();
			din = new DataInputStream (fin);
			
			line = din.read_line (null);
			while (true) {
				data = (!) line;
				description = data;
				
				while ((line = din.read_line (null)) != null) {
					data = (!) line;
					if (data.has_prefix ("\t")) {
						description += "\n";
						description += data;
					} else {
						if (description.index_of ("<not a character>") == -1) {
							add_entry (description);
						}
						break;
					}					
				}
				
				if (line == null) {
					break;
				}
			}
			
			if (description == "") {
				warning ("no description found");
			}
			
			fin.close ();
			din.close ();
		} catch (GLib.Error e) {
			warning (e.message);
			warning ("In %s", (!) get_unicode_database ().get_path ());
		}
	}
	
	public int load () {
		parse_all_entries ();
		
		IdleSource idle = new IdleSource ();
		idle.set_callback (() => {
			CharDatabase.full_unicode_range = utf8;
			CharDatabase.show_loading_message ();
			CharDatabase.database_is_loaded = true;
			ProgressBar.set_progress (0);
			return false;
		});
		idle.attach (null);
		
		return 0;
	}

	static File get_unicode_database () {
		return SearchPaths.get_char_database ();
	}
}

}
