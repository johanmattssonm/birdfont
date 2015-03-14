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
	
	public static void set_default_colors () {
		color_list = new Gee.ArrayList<string> ();
		colors = new Gee.HashMap<string, Color> ();
		
		Theme.set_default_color ("Background 1", 1, 1, 1, 1);
		Theme.set_default_color ("Background 2", 101 / 255.0, 108 / 255.0, 116 / 255.0, 1);
		Theme.set_default_color ("Background 3", 38 / 255.0, 39 / 255.0, 43 / 255.0, 1);
		Theme.set_default_color ("Background 4", 51 / 255.0, 54 / 255.0, 59 / 255.0, 1);
		Theme.set_default_color ("Background 5", 0.3, 0.3, 0.3, 1);
		Theme.set_default_color ("Background 6", 224/255.0, 224/255.0, 224/255.0, 1);
		Theme.set_default_color ("Background 7", 56 / 255.0, 59 / 255.0, 65 / 255.0, 1);
		Theme.set_default_color ("Background 8", 55/255.0, 55/255.0, 55/255.0, 1);
		Theme.set_default_color ("Background 9", 72/255.0, 72/255.0, 72/255.0, 1);
		
		Theme.set_default_color ("Foreground 1", 0, 0, 0, 1);
		Theme.set_default_color ("Foreground 2", 101 / 255.0, 108 / 255.0, 116 / 255.0, 1);
		Theme.set_default_color ("Foreground 3", 26 / 255.0, 30 / 255.0, 32 / 255.0, 1);
		Theme.set_default_color ("Foreground 4", 40 / 255.0, 57 / 255.0, 65 / 255.0, 1);
		Theme.set_default_color ("Foreground 5", 70 / 255.0, 77 / 255.0, 83 / 255.0, 1);
		
		Theme.set_default_color ("Highlighted 1", 234 / 255.0, 77 / 255.0, 26 / 255.0, 1);
		
		Theme.set_default_color ("Highlighted Guide", 0, 0, 0.3, 1);
		Theme.set_default_color ("Guide 1", 0.7, 0.7, 0.8, 1);
		Theme.set_default_color ("Guide 2", 0.7, 0, 0, 0.5);
		Theme.set_default_color ("Guide 3", 120 / 255.0, 68 / 255.0, 120 / 255.0, 120 / 255.0);
		
		Theme.set_default_color ("Grid",0.2, 0.6, 0.2, 0.2);
		
		Theme.set_default_color ("Background Glyph", 0.2, 0.2, 0.2, 0.5);
		
		Theme.set_default_color ("Tool Border 1", 38 / 255.0, 39 / 255.0, 43 / 255.0, 1);
		Theme.set_default_color ("Tool Background 1", 14 / 255.0, 16 / 255.0, 17 / 255.0, 1);

		Theme.set_default_color ("Tool Border 2", 38 / 255.0, 39 / 255.0, 43 / 255.0, 1);
		Theme.set_default_color ("Tool Background 2", 26 / 255.0, 30 / 255.0, 32 / 255.0, 1);

		Theme.set_default_color ("Tool Border 3", 38 / 255.0, 39 / 255.0, 43 / 255.0, 1);
		Theme.set_default_color ("Tool Background 3", 44 / 255.0, 47 / 255.0, 51 / 255.0, 1);

		Theme.set_default_color ("Tool Border 4", 38 / 255.0, 39 / 255.0, 43 / 255.0, 1);
		Theme.set_default_color ("Tool Background 4", 33 / 255.0, 36 / 255.0, 39 / 255.0, 1);
		
		Theme.set_default_color ("Button Foreground", 101 / 255.0, 108 / 255.0, 116 / 255.0, 1);
		
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
		
		N_("Button Foreground");
	}
	
	public static void set_default_color (string name, double r, double g, double b, double a) {
		color_list.add (name);
		colors.set (name, new Color (r, g, b, a));
		write_theme (); // FIXME: don't overwrite color
	}
	
	public static void save_color (string name, double r, double g, double b, double a) {
		colors.set (name, new Color (r, g, b, a));
		write_theme ();
	}

	public static void load_theme () {
		File default_theme = SearchPaths.find_file (null, "theme.xml");
		File user_theme = get_child (BirdFont.get_settings_directory (), "theme.xml");

		if (default_theme.query_exists ()) {
			parse_theme (default_theme);
		}

		if (user_theme.query_exists ()) {
			parse_theme (user_theme);
		}
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

		colors.set (name, new Color (r, g, b, a));
	}
}

}
