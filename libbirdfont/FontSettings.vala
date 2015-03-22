/*
    Copyright (C) 2015 Johan Mattsson

    This library is free software; you can redistribute it and/or modify 
    it under the terms of the GNU Lesser General Public License as 
    published by the Free Software Foundation; either version 3 of the 
    License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful, but 
    WITHOUT ANY WARRANTY; without even the implied warranty of 
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
    Lesser General Public License for more details.
*/

using Bird;

namespace BirdFont {

/** Font specific settings file. */
public class FontSettings : GLib.Object {

	string font_name;
	Gee.HashMap<string, string> settings;

	public FontSettings () {
		settings = new Gee.HashMap<string, string> ();
		font_name = "";
	}
	
	public string get_setting (string key) {
		if (settings.has_key (key)) {
			return settings.get (key);
		}
		
		return "";
	}

	public void set_setting (string key, string v) {
		settings.set (key, v);
		save (font_name);
	}
	
	File get_settings_file () {
		File config_directory = BirdFont.get_settings_directory ();
		File settings = get_child (config_directory, "settings");
		return get_child (config_directory, font_name.replace (".bf", ".config"));
	}
	
	public void save (string font_file_name) {
		File f;
		StringBuilder sb;
		
		font_name = font_file_name;
	
		try {
			f = get_settings_file ();
		
			if (f.query_exists ()) {
				f.delete ();
			}
			
			sb = new StringBuilder ();
			
			sb.append ("<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"yes\"?>");
			sb.append ("<settings>");
			
			foreach (var k in settings.keys) {
				sb.append ("\t<setting key=\"");
				sb.append (k);
				sb.append (" \" ");
				sb.append ("value=\"");
				sb.append (XmlParser.encode (settings.get (k)));
				sb.append ("\" />");
			}
			
			sb.append ("</settings>");
			
			FileUtils.set_contents ((!) f.get_path (), sb.str);
			
		} catch (Error e) {
			stderr.printf ("Can not save settings. (%s)", e.message);	
		}
	}
	
	public void load (string font_file_name) {
		File f;
		string xml_data;
		XmlParser parser;
		
		settings.clear ();
		font_name = font_file_name;
		f = get_settings_file ();
		
		if (f.query_exists ()) {
			FileUtils.get_contents((!) f.get_path (), out xml_data);
			parser = new XmlParser (xml_data);
			parse_settings (parser.get_root_tag ());	
		}
	}
	
	void parse_settings (Tag tag) {
		foreach (Tag t in tag) {
			if (t.get_name () == "setting") {
				parse_setting (t);
			}
		}
	}

	void parse_setting (Tag tag) {
		string key = "";
		string v = "";
		foreach (Attribute a in tag.get_attributes ()) {
			if (a.get_name () == "key") {
				key = a.get_content ();
			}

			if (a.get_name () == "value") {
				v = XmlParser.decode (a.get_content ());
			}
		}
	}

}

}
