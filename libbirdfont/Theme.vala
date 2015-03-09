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
using Cairo;

namespace BirdFont {

public class Theme : GLib.Object {

	static Gee.HashMap<string, Color> colors;
	public static Gee.ArrayList<string> color_list;

	public static void text_color (Text text, string name) {
		Color c;
		
		if (unlikely (!colors.has_key (name))) {
			warning (@"Theme does not have a color for $name");
			return;
		}
		
		c = colors.get (name);
		text.set_source_rgba (c.r, c.g, c.b, c.a);
	}

	public static void color (Context cr, string name) {
		Color c;
		
		if (unlikely (!colors.has_key (name))) {
			warning (@"Theme does not have a color for $name");
			return;
		}
		
		c = colors.get (name);
		cr.set_source_rgba (c.r, c.g, c.b, c.a);
	}

	public static void color_opacity (Context cr, string name, double opacity) {
		Color c;
		
		if (unlikely (!colors.has_key (name))) {
			warning (@"Theme does not have a color for $name");
			return;
		}
		
		c = colors.get (name);
		cr.set_source_rgba (c.r, c.g, c.b, opacity);
	}

	public static void text_color_opacity (Text text, string name, double opacity) {
		Color c;
		
		if (unlikely (!colors.has_key (name))) {
			warning (@"Theme does not have a color for $name");
			return;
		}
		
		c = colors.get (name);
		text.set_source_rgba (c.r, c.g, c.b, opacity);
	}
	public static Color get_color (string name) {
		Color c;
		
		if (unlikely (!colors.has_key (name))) {
			warning (@"Theme does not have a color for $name");
			return new Color (0, 0, 0, 1);
		}
		
		return colors.get (name);
	}
	
	public static void save_color (string name, double r, double g, double b, double a) {
		colors.set (name, new Color (r, g, b, a));
		write_theme ();
	}

	public static void load_theme () {
		File default_theme = SearchPaths.find_file (null, "theme.xml");
		File user_theme = get_child (BirdFont.get_settings_directory (), "theme.xml");

		colors = new Gee.HashMap<string, Color> ();
		color_list = new Gee.ArrayList<string> ();
		
		if (default_theme.query_exists ()) {
			parse_theme (default_theme);
		}

		if (user_theme.query_exists ()) {
			parse_theme (user_theme);
		}
		
		color_list.sort ();
	}

	public static void write_theme () {
		DataOutputStream os;
		File file;

		file = get_child (BirdFont.get_settings_directory (), "theme.xml");
		
		try {
			if (file.query_exists ()) {
				file.delete ();
			}
		} catch (GLib.Error e) {
			warning (e.message);
		}
		
		try {
			os = new DataOutputStream (file.create (FileCreateFlags.REPLACE_DESTINATION));
			os.put_string ("""<?xml version="1.0" encoding="utf-8" standalone="yes"?>""");
			os.put_string ("\n");
			
			os.put_string ("<theme>\n");
			foreach (string name in colors.keys) {
				Color color = colors.get (name);
				
				os.put_string ("\t<color ");
				
				os.put_string (@"name=\"$(Markup.escape_text (name))\" ");				
				os.put_string (@"red=\"$(color.r)\" ");
				os.put_string (@"green=\"$(color.g)\" ");
				os.put_string (@"blue=\"$(color.b)\" ");
				os.put_string (@"alpha=\"$(color.a)\"");
				
				os.put_string ("/>\n");
			}
			os.put_string ("</theme>\n");
			
			os.close ();
		} catch (GLib.Error e) {
			warning (e.message);
		}
	}

	static void parse_theme (File f) {
		string xml_data;
		XmlParser parser;
		
		try {
			FileUtils.get_contents((!) f.get_path (), out xml_data);
			parser = new XmlParser (xml_data);
			parse_colors (parser.get_root_tag ());
		} catch (GLib.Error e) {
			warning (e.message);
		}
	}
	
	static void parse_colors (Tag tag) {
		foreach (Tag t in tag) {
			if (t.get_name () == "color") {
				parse_color (t.get_attributes ());
			}
		}
	}
	
	static void parse_color (Attributes attributes) {
		string name = "";
		double r = 0;
		double g = 0;
		double b = 0;
		double a = 1;
		
		foreach (Attribute attr in attributes) {
			if (attr.get_name () == "name") {
				name = attr.get_content ();
			}
						
			if (attr.get_name () == "red") {
				r = double.parse (attr.get_content ());
			}
			
			if (attr.get_name () == "green") {
				g = double.parse (attr.get_content ());
			}
			
			if (attr.get_name () == "blue") {
				b = double.parse (attr.get_content ());
			}

			if (attr.get_name () == "alpha") {
				a = double.parse (attr.get_content ());
			}
		}
		
		color_list.add (name);
		colors.set (name, new Color (r, g, b, a));
	}
}

}
