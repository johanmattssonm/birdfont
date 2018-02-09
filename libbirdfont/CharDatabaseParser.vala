/*
	Copyright (C) 2013 2015 2018 Johan Mattsson

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
using Sqlite;

namespace BirdFont {

public class CharDatabaseParser : GLib.Object {
	static unowned Database db;
	static Database? database = null;

	GlyphRange utf8 = new GlyphRange ();
	
	public CharDatabaseParser () {	
	}

	public File get_database_file () {
		string? fn = BirdFont.get_argument ("--parse-ucd");
		
		if (fn != null && ((!) fn) != "") {
			return File.new_for_path ((!) fn);
		}
		
		return File.new_for_path ("ucd.sqlite");
	}
	
	public void regenerate_database () {
		File f = get_database_file ();
		
		stdout.printf ("Generating sqlite database in: %s\n", (!) f.get_path ());
		
		try {
			if (f.query_exists ()) {
				f.delete ();
			}
			
			bool open = open_database (OPEN_READWRITE | OPEN_CREATE);
			
			if (open) {
				create_tables ();
				parse_all_entries ();
			}
		} catch (GLib.Error e) {
			warning (e.message);
		}
	}
	
	public bool open_database (int access_mode) {
		File f = get_database_file ();
		int rc = Database.open_v2 ((!) f.get_path (), out database, access_mode);

		db = (!) database;

		if (rc != Sqlite.OK) {
			stderr.printf ("File: %s\n", (!) f.get_path ());
			stderr.printf ("Can't open database: %d, %s\n", rc, db.errmsg ());
			return false;
		}
		
		return true;
	}
	
	public void create_tables () {
		int ec;
		string? errmsg;
		string description_table = """
			CREATE TABLE Description (
				unicode         INTEGER     PRIMARY KEY    NOT NULL,
				description     TEXT                       NOT NULL
			);
		""";

		ec = db.exec (description_table, null, out errmsg);
		if (ec != Sqlite.OK) {
			warning ("Error: %s\n", (!) errmsg);
		}

		string index_table = """
			CREATE TABLE Words (
				unicode        INTEGER     NOT NULL,
				word           TEXT        NOT NULL
			);
		""";

		ec = db.exec (index_table, null, out errmsg);
		if (ec != Sqlite.OK) {
			warning ("Error: %s\n", (!) errmsg);
		}

		string create_index = "CREATE INDEX word_index ON Words (word);";

		ec = db.exec (create_index, null, out errmsg);
		if (ec != Sqlite.OK) {
			warning ("Error: %s\n", (!) errmsg);
		}
	}

	public void insert_lookup (int64 character, string word) {
		string? errmsg;
		string w = word.down ();
		string query = """
			INSERT INTO Words (unicode, word)
			VALUES (""" + @"$((int64) character)" + """, '""" + w.replace ("'", "''") + "');";
		int ec = db.exec (query, null, out errmsg);
		
		if (ec != Sqlite.OK) {
			stderr.printf (query);
			warning ("Error: %s\n", (!) errmsg);
		}
	}
	
	/** medial, isolated etc. */
	public string get_context_substitution (string description) {
		string[] lines = description.split ("\n");
		return_val_if_fail (lines.length > 0, "NONE");
		
		string first_line = lines[0];
		string type = "NONE";
		
		if (first_line.has_suffix ("INITIAL FORM")) {
			type = "INITIAL";
		} else if (first_line.has_suffix ("MEDIAL FORM")) {
			type = "MEDIAL";
		} else if (first_line.has_suffix ("FINAL FORM")) {
			type = "FINAL";
		} else if (first_line.has_suffix ("ISOLATED FORM")) {
			type = "ISOLATED";
		} 
		
		return type;
	}
	
	public string get_name (string description) {
		string[] lines = description.split ("\n");
		return_val_if_fail (lines.length > 0, "NONE");
		
		string first_line = lines[0];
		int separator = first_line.index_of ("\t");
		string name = first_line.substring (separator + "\t".length);
		return name.strip ();
	}
	

	public void insert_entry (int64 character, string description) {
		string? errmsg;
		
		string query = """
			INSERT INTO Description (unicode, description)
			VALUES (""" + @"$((int64) character)" + ", "
				+ "'" + description.replace ("'", "''") + "');";
		
		int ec = db.exec (query, null, out errmsg);
		
		if (ec != Sqlite.OK) {
			stderr.printf (query);
			warning ("Error: %s\n", (!) errmsg);
			warning (@"Can't insert description to: $(character)");
		}
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

		if (data.has_prefix (";")) {
			return;
		}
		
		index_values = data.down ();
		index_values = index_values.replace ("\n\tx", "");
		index_values = index_values.replace ("\n\t*", "");
		index_values = index_values.replace ("\n\t=", "");
		index_values = index_values.replace ("\n\t#", "");
		index_values = index_values.replace (",", " ");
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
		insert_entry ((int64) ch, data);
		utf8.add_single (ch);
		
		foreach (string s in e) {
			r = s.split ("\n");
			
			foreach (string t in r) {			
				if (!t.has_prefix ("\t~")) {
					d = t.split (" ");
					foreach (string token in d) {
						if (token != "") {
							insert_lookup ((int64) ch, token);
						}
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
		int ec;
		string? errmsg;
		uint64 transaction_number = 0;
		
		file = get_unicode_database ();

		ec = db.exec ("BEGIN TRANSACTION", null, out errmsg);
		if (ec != Sqlite.OK) {
			warning ("Error: %s\n", (!) errmsg);
		}
				
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
							transaction_number++;
							
							if (transaction_number >= 1000) {								
								ec = db.exec ("END TRANSACTION", null, out errmsg);
								if (ec != Sqlite.OK) {
									warning ("Error: %s\n", (!) errmsg);
								}								

								ec = db.exec ("BEGIN TRANSACTION", null, out errmsg);
								if (ec != Sqlite.OK) {
									warning ("Error: %s\n", (!) errmsg);
								}
								
								transaction_number = 0;	
							} 
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
		
		ec = db.exec ("END TRANSACTION", null, out errmsg);
		if (ec != Sqlite.OK) {
			warning ("Error: %s\n", (!) errmsg);
		}
				
		stdout.printf ("Done");
	}

	File get_unicode_database () {
		return SearchPaths.get_char_database ();
	}
}

}
