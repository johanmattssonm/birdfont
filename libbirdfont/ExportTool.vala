/*
	Copyright (C) 2012 2014 2015 Johan Mattsson

	This library is free software; you can redistribute it and/or modify 
	it under the terms of the GNU Lesser General Public License as 
	published by the Free Software Foundation; either version 3 of the 
	License, or (at your option) any later version.

	This library is distributed in the hope that it will be useful, but 
	WITHOUT ANY WARRANTY; without even the implied warranty of 
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
	Lesser General Public License for more details.
*/

using B;

namespace BirdFont {

public class ExportTool : GLib.Object {

	public static string? error_message = null;
	
	public ExportTool (string n) {
	}

	public static void set_output_directory () {
#if MAC
		Font font = BirdFont.get_current_font ();
		string? path = font.get_export_directory ();
			
		FileChooser fc = new FileChooser ();
		fc.file_selected.connect ((p) => {
			 path = p;
		});
		
		if (path == null) {
			File export_path_handle = File.new_for_path (path);
		
			if (!can_write (export_path_handle)) {
				MainWindow.file_chooser (t_("Export"), fc, FileChooser.LOAD | FileChooser.DIRECTORY);
			}
		}
		
		font.export_directory = path;
#endif
	}

	public static string export_selected_paths_to_svg () {
		return export_current_glyph_to_string (true);		
	}
	
	public static string export_selected_paths_to_inkscape_clipboard () {
		return export_current_glyph_to_inkscape_clipboard (true);
	}

	public static string export_current_glyph_to_string (bool only_selected_paths = false) {
		return export_to_string (MainWindow.get_current_glyph (), only_selected_paths);
	}

	public static string export_to_string (Glyph glyph, bool only_selected_paths) {
		string name;
		StringBuilder s;

		name = XmlParser.encode (glyph.get_name ());
		s = new StringBuilder ();
		
		s.append ("""<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.0//EN" "http://www.w3.org/TR/2001/REC-SVG-20010904/DTD/svg10.dtd">
<svg version="1.0" 
	id="glyph_""" + name + """" 
	xmlns="http://www.w3.org/2000/svg" 
	xmlns:xlink="http://www.w3.org/1999/xlink"
	x="0px"
	y="0px"
	width=""" + "\"" + @"$(glyph.get_width ())" + """px" 
	height=""" + "\"" + @"$(glyph.get_height ())" + """px">
""");
		
		s.append (@"<g id=\"$(name)\">\n");

		s.append (get_svg_path_elements (glyph, only_selected_paths));
	
		s.append ("</g>\n");
		s.append ("</svg>");
	
		return s.str;
	}
	
	public static string export_current_glyph_to_inkscape_clipboard (bool only_selected_paths = false) {
		return export_to_inkscape_clipboard (MainWindow.get_current_glyph (), only_selected_paths);
	}
	
	public static string export_to_inkscape_clipboard (Glyph glyph, bool only_selected_paths = false) {
		StringBuilder s;
		
		s = new StringBuilder ();
		s.append ("""<?xml version="1.0" encoding="UTF-8" standalone="no"?>""");
		s.append ("\n");
		s.append ("<svg>\n");
				
		s.append ("""<inkscape:clipboard
			id="clipboard3009"
			style="color:#000000;fill:#000000;fill-opacity:1;fill-rule:nonzero;stroke:none;marker:none;visibility:visible;display:inline;overflow:visible;enable-background:accumulate"
			min="0,0"
			max="0,0" />
	 """);

		s.append (get_svg_path_elements (glyph, only_selected_paths));
		s.append ("</svg>");
		
		return s.str;
	}

	private static string get_svg_path_elements (Glyph glyph, bool only_selected_paths) {
		string glyph_svg;
		StringBuilder s;
		string name;
		int id = 0;
		
		name = glyph.get_name ();
		
		Gee.ArrayList<Path> pl;
		
		s = new StringBuilder ();
		glyph_svg = "";

		pl = only_selected_paths ? glyph.active_paths : glyph.get_visible_paths ();
		foreach (Path p in pl) {
			if (p.stroke > 0) {
				s.append (@"<path ");
				s.append (@"style=\"");
				s.append (@"fill:none;");
				s.append (@"stroke:#000000;");
				s.append (@"stroke-width:$(p.stroke)px;");
				
				if (p.line_cap == LineCap.ROUND) {
					s.append (@"stroke-linecap:round;");
				} else if (p.line_cap == LineCap.SQUARE) {
					s.append (@"stroke-linecap:square;");
				}
				
				s.append (@"\" ");
				
				s.append (@"d=\"$(Svg.to_svg_path (p, glyph))\" id=\"path_$(name)_$(id)\" />\n");
				id++;
			}
		}
		
		if (only_selected_paths) {
			foreach (Path p in glyph.active_paths) {
				if (p.stroke == 0) {
					glyph_svg += Svg.to_svg_path (p, glyph);
				}
			}	
		} else {
			foreach (Path p in glyph.get_visible_paths ()) {
				if (p.stroke == 0) {
					glyph_svg += Svg.to_svg_path (p, glyph);
				}
			}
		}

		if (glyph_svg != "") {
			s.append (@"<path ");
			s.append (@"style=\"fill:#000000;stroke-width:0px\" ");
			s.append (@"d=\"$(glyph_svg)\" id=\"path_$(name)_$(id)\" />\n");
			id++;
		}
		
		return s.str;
	}
	
	public static void export_current_glyph () {
		FileChooser fc = new FileChooser ();
		fc.file_selected.connect ((selected_file) => {
			Glyph glyph = MainWindow.get_current_glyph ();
			FontDisplay fd = MainWindow.get_current_display ();
			string glyph_svg;
			string svg_file;
			File file;
			DataOutputStream os;
			string name;
			string fn;
			int i;
			
			if (fd is GlyphTab || fd is Glyph) {
				glyph = MainWindow.get_current_glyph ();
			} else if (fd is OverView) {
				OverView overview = MainWindow.get_overview ();
				Glyph? g = overview.get_selected_glyph ();
				
				if (g == null) {
					warning("No glyph selected in overview.");
					return;
				}
				
				glyph = (!) g;
			} else {
				return;
			}
			
			name = glyph.get_name ();
			
			if (selected_file == null) {
				warning ("No selected file.");
				return;
			}
			
			svg_file = (!) selected_file;

			try {
#if MAC
				file = File.new_for_path (svg_file);
#else
				i = 1;
				fn = svg_file.replace (".svg", "");
				file = File.new_for_path (fn + ".svg");
				while (file.query_exists ()) {
					file = File.new_for_path (fn + @"$i.svg");
					i++;
				}
#endif				
				glyph_svg = export_to_string (glyph, false);
				os = new DataOutputStream (file.create(FileCreateFlags.REPLACE_DESTINATION));
				os.put_string (glyph_svg);
			} catch (Error e) {
				stderr.printf (@"Export \"$svg_file\" \n");
				critical (@"$(e.message)");
			}
		});
		
		fc.add_extension ("svg");
		MainWindow.file_chooser (t_("Save"), fc, FileChooser.SAVE);
	}
	
	public static void generate_html_document (string html_file, Font font) {
		File file = File.new_for_path (html_file);
		DataOutputStream os;
		string name;

#if MAC 
		name = ExportSettings.get_file_name_mac (font);
#else
		name = ExportSettings.get_file_name (font);
#endif
		try {
			os = new DataOutputStream (file.create(FileCreateFlags.REPLACE_DESTINATION));

os.put_string (
"""<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>

	<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
	<title>Lorem ipsum</title>
	
	<style type="text/css">

		body {
			text-rendering: optimizeLegibility;
			font-feature-settings: "kern";
			-moz-font-feature-settings: "kern=1";
			-ms-font-feature-settings: "kern";
			-webkit-font-feature-settings: "kern";
			-o-font-feature-settings: "kern";
		}

		@font-face {
			font-family: '"""); os.put_string (@"$(name)");              os.put_string ("""SVG';
			src: url('""");     os.put_string (@"$(name).svg#$(name)");  os.put_string ("""') format('svg');
		}
	""");

	os.put_string ("""
		@font-face {
			font-family: '"""); os.put_string (@"$(name)");              os.put_string ("""TTF';
			src: url('""");     os.put_string (@"$(name).ttf"); os.put_string ("""') format('truetype');
		} 
		""");

	os.put_string ("""
		@font-face {
			font-family: '"""); os.put_string (@"$(name)");              os.put_string ("""EOT';
			src: url('""");     os.put_string (@"$(name).eot"); os.put_string ("""');
		} 
		
		""");
		
	os.put_string ("""	
		h1 {
			font-weight:normal;
			margin: 0 0 5px 0;
			color: #afafaf;
		}

		h2 {
			font-weight:normal;
			margin: 0 0 5px 0;
			color: #afafaf;
		}
		
		h3 {
			font-weight:normal;
			margin: 0 0 5px 0;
			color: #afafaf;
		}
		
		h4 {
			font-weight:normal;
			margin: 0 0 5px 0;
			color: #afafaf;
		}
		
		p {
			margin: 0 0 5px 0;
			color: #000000;
		}
		
		body {
			margin: 30px 0 0 30px;
		}
		
		div {
			font-family: """);

			os.put_string ("'");
			os.put_string (@"$(name)");
			os.put_string ("EOT'");

			os.put_string (", '");
			os.put_string (@"$(name)");
			os.put_string ("TTF'");
			
			os.put_string (", '");
			os.put_string (@"$(name)");
			os.put_string ("SVG'");

			os.put_string (";");
			os.put_string ("""
			margin: 0 0 30px 0;
		}

		h1.bigger {
			font-size: 58pt;
		}

		h2.big {
			font-size: 40pt;
		}
		
		h3.small {
			font-size: 32pt;
		}

		h4.smaller {
			font-size: 18pt;
		}

		h1.percent {
			font-size: 100%;
		}		
		
		p.bigger {
			font-size: 32pt;
		}

		p.big {
			font-size: 24pt;
		}
		
		p.small {
			font-size: 18pt;
		}

		p.smaller {
			font-size: 12pt;
		}

		span.swashes {
			-moz-font-feature-settings: "swsh";
			-ms-font-feature-settings: "swsh";
			-webkit-font-feature-settings: "swsh";
			font-feature-settings: "swsh";	
		}
		
		span.alternates {	
			-moz-font-feature-settings: "salt" 1;
			-ms-font-feature-settings: "salt" 1;
			-webkit-font-feature-settings: "salt" 1;
			font-feature-settings: "salt" 1;
		}
		
		span.smallcaps {
			font-variant-caps: small-caps;
			-moz-font-feature-settings: "smcp";
			-ms-font-feature-settings: "smcp";
			-webkit-font-feature-settings: "smcp";
			font-feature-settings: "smcp";
		}

		span.capstosmallcaps {
			font-variant-caps: all-small-caps;
			-moz-font-feature-settings: "c2sc", "smcp";
			-ms-font-feature-settings: "c2sc", "smcp";
			-webkit-font-feature-settings: "c2sc", "smcp";
			font-feature-settings: "c2sc", "smcp";
		}
	</style>
""");
	
	os.put_string (
"""	
</head>
<body>

<div>
	<h1 class="bigger">Lorem ipsum</h1>
	<p class="bigger">Dolor sit amet!</p>
</div>

<div>
	<h2 class="big">Hamburgerfonstiv</h2>
	<p class="big">""" + name + """</p>
</div>

<div>
	<h3 class="big"></h3>
	<p class="big">OTF features, like swashes alternates &amp; </span> small caps, can be added 
		to the font.</span>
	</p>
</div>

<div>
	<h4 class="smaller">Headline 16pt</h4>
	<p class="smaller">Ett litet stycke svalhjärta.</p>	
</div>

<div>
	<h4 class="smaller">""" +  t_("Alphabet") + """</h4>
	<p class="smaller">""" + t_("a b c d e f g h i j k l m n o p q r s t u v w x y z") + """</p>
	<p class="smaller">""" + t_("A B C D E F G H I J K L M N O P Q R S T U V W X Y Z") + """</p>
	<p class="smaller">0 1 2 3 4 5 6 7 8 9</p>
</div>

</body>
</html>
""");

		} catch (GLib.Error e) {
			warning (e.message);
		}
	}

	public static string get_export_folder () {
		Font font = BirdFont.get_current_font ();
		string? d = font.get_export_directory ();
		
		if (d == null) {
			warning ("No export path is not set");
			return "";
		}
		
		return (!) d;
	}

	static bool can_write (File folder) {
		File test = get_child (folder, "text.tmp");
		bool writable = false;
		
		try {
			writable = FileUtils.set_contents ((!) test.get_path (), "test");
			
			if (writable) {
				FileUtils.remove ((!) test.get_path ());
			}
		} catch (GLib.Error e) {
			writable = false;
		}
		
		return writable;
	}

	public static File get_export_dir () {
		return File.new_for_path (get_export_folder ());
	}
	
	public static bool export_ttf_font () {
		File f = get_export_dir ();
		Font font = BirdFont.get_current_font ();
		
		try {
			if (!f.query_exists ()) {
				f.make_directory ();
			}
		} catch (GLib.Error e) {
			warning(e.message);
		}
			
		printd (@"export_ttf_font:\n");
		printd (@"get_export_folder (): $(get_export_folder ())\n");
		printd (@"font.get_path (): $(font.get_path ())\n");
		printd (@"font.get_folder_path (): $(font.get_folder_path ())\n");
		printd (@"font.get_folder (): $((!) f.get_path ())\n");
		
		return export_ttf_font_path (f);
	}

	public static bool export_ttf_font_path (File folder, bool use_export_settings = true) {
		Font current_font = BirdFont.get_current_font ();
		File ttf_file;
		File ttf_file_mac;
		File eot_file;
		bool done = true;
		string ttf_name;
		string ttf_name_mac;
		
		try {
			ttf_name = ExportSettings.get_file_name (current_font) + ".ttf";
			ttf_name_mac = ExportSettings.get_file_name_mac (current_font) + ".ttf";
			
			if (ttf_name == ttf_name_mac) {
				warning ("Same file name for the two ttf files.");
				ttf_name_mac = ExportSettings.get_file_name_mac (current_font) + " Mac.ttf";
			}
			
			ttf_file = get_child (folder, ttf_name);
			ttf_file_mac  = get_child (folder, ttf_name_mac);
			eot_file = get_child (folder, ExportSettings.get_file_name (current_font) + ".eot");

			printd (@"Writing TTF fonts to $((!) ttf_file.get_path ())\n");
			
			if (ttf_file.query_exists ()) {
				ttf_file.delete ();
			}

			if (ttf_file_mac.query_exists ()) {
				ttf_file_mac.delete ();
			}
			
			if (eot_file.query_exists ()) {
				eot_file.delete ();
			}
						
			write_ttf ((!) ttf_file.get_path (), (!) ttf_file_mac.get_path ());
			
			if (!use_export_settings || ExportSettings.export_eot_setting (current_font)) {
				write_eot ((!) ttf_file.get_path (), (!) eot_file.get_path ());
			}
			
			if (use_export_settings && !ExportSettings.export_ttf_setting (current_font)) {
				if (ttf_file.query_exists ()) {
					ttf_file.delete ();
				}
			}			
		} catch (Error e) {
			critical (@"$(e.message)");
			done = false;
		}

		return done;		
	}

	public static bool export_svg_font () {
		return export_svg_font_path (get_export_dir ());
	}
		
	public static bool export_svg_font_path (File folder) {
		Font font = BirdFont.get_current_font ();
		string file_name = @"$(ExportSettings.get_file_name (font)).svg";
		File file;
		SvgFontFormatWriter fo;
		
		try {
			file = get_child (folder, file_name);
			
			if (file.query_exists ()) {
				file.delete ();
			}
			
			fo = new SvgFontFormatWriter ();
			fo.open (file);
			fo.write_font_file (font);
			fo.close ();
		} catch (Error e) {
			critical (@"$(e.message)");
			return false;
		}
		
		return true;
	}

	static void write_ttf (string ttf, string ttf_mac) {
		Font f = BirdFont.get_current_font ();
		OpenFontFormatWriter fo = new OpenFontFormatWriter (f.units_per_em);
		
		File file = (!) File.new_for_path (ttf);
		File file_mac = (!) File.new_for_path (ttf_mac);		

		error_message = null;		
		
		try {
			fo.open (file, file_mac);
			fo.write_ttf_font (f);
			fo.close ();
		} catch (Error e) {
			warning (@"Can't create TTF font to $ttf");
			critical (@"$(e.message)");
			error_message = e.message;
			f.export_directory = null;
		}		
	}
	
	static void write_eot (string ttf, string eot) {
		EotWriter fo = new EotWriter (ttf, eot);

		try {
			fo.write ();
		} catch (Error e) {
			warning (@"EOF conversion falied, $ttf -> $eot");
			critical (@"$(e.message)");
		}
	}
}

}
