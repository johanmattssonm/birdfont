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

class CharDatabaseParser : GLib.Object {
	
	MainContext? context;
	
	public CharDatabaseParser (MainContext? c) {	
		context = c;
		
		if (context == null) {
			warning ("No main context set.");
		}
	}

	public static void run () {
		CharDatabaseParser thread_data;
		thread_data = new CharDatabaseParser (MainContext.default ());
		
		if (!Thread.supported ()) {
			warning ("Threads not supported, this might take a while.");
			thread_data.load ();
		} else {
			try {
				//new Thread<int> ("database parser", thread_data.load);
				Thread<int>.create<int> (thread_data.load, false);
			} catch (GLib.Error e) {
				warning (e.message);
			}
		}
	}
	
	private void add_entry (string data) {
		string[] e;
		string[] r;
		string[] d;
		string index_values;
		unichar ch;
		string unicode_hex;
		Mutex mutex = new Mutex (); // wait for callback to finish
			
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
		
		mutex.lock ();
		Idle.add (() => {
			CharDatabase.full_unicode_range.add_single (ch);
			CharDatabase.entries.set (unicode_hex, data);
			mutex.unlock ();
			return false;
		});

		foreach (string s in e) {
			r = s.split ("\n");
			foreach (string t in r) {  
				d = t.split (" ");
				foreach (string token in d) {
					if (token != "") {
						mutex.lock ();
						Idle.add (() => {
							CharDatabase.index.set (token, unicode_hex);
							mutex.unlock ();
							return false;
						});
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
