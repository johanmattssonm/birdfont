/*
    Copyright (C) 2012 2014 Johan Mattsson

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

public class ExportTool : GLib.Object {
	
	public ExportTool (string n) {
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

		name = glyph.get_name (); // FIXME: xml encode
		s = new StringBuilder ();
		
		s.append ("""<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.0//EN" "http://www.w3.org/TR/2001/REC-SVG-20010904/DTD/svg10.dtd">
<svg version="1.0" 
	id="glyph_""" + name + """" 
	mlns="http://www.w3.org/2000/svg" 
	xmlns:xlink="http://www.w3.org/1999/xlink"
	x="0px"
	y="0px"
	width="""" + @"$(glyph.get_width ())" + """px" 
	height="""" + @"$(glyph.get_height ())" + """px">
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
		name = glyph.get_name ();
								
		s = new StringBuilder ();
		glyph_svg = "";
		
		if (only_selected_paths) {
			foreach (Path p in glyph.active_paths) {
				glyph_svg += Svg.to_svg_path (p, glyph);
			}	
		} else {
			foreach (Path p in glyph.path_list) {
				glyph_svg += Svg.to_svg_path (p, glyph);
			}
		}

		s.append (@"<path ");
		s.append (@"style=\"fill:#000000;stroke-width:0px\" ");
		s.append (@"d=\"$(glyph_svg)\" id=\"path_$(name)\" />\n");
		
		return s.str;
	}
	
	public static void export_current_glyph () {
		FileChooser fc = new FileChooser ();
		fc.file_selected.connect ((f) => {
			Glyph glyph = MainWindow.get_current_glyph ();
			FontDisplay fd = MainWindow.get_current_display ();
			string glyph_svg;
			string svg_file;
			File file;
			DataOutputStream os;
			string name;
			string fn;
			int i;
			
			name = glyph.get_name ();
			
			if (f == null) {
				return;
			}
			
			svg_file = (!) f;

			if (!(fd is Glyph)) {
				return;
			}
			
			try {
				i = 1;
				fn = svg_file.replace (".svg", "");
				file = File.new_for_path (fn + ".svg");
				while (file.query_exists ()) {
					file = File.new_for_path (fn + @"$i.svg");
					i++;
				}
				
				glyph_svg = export_current_glyph_to_string ();
				os = new DataOutputStream (file.create(FileCreateFlags.REPLACE_DESTINATION));
				os.put_string (glyph_svg);
		
			} catch (Error e) {
				stderr.printf (@"Export \"$svg_file\" \n");
				critical (@"$(e.message)");
			}
		});
		
		MainWindow.file_chooser (t_("Save"), fc, FileChooser.SAVE);
	}

	/* Font must be saved before export in order to know where the
	 * generated files should be stored.
	 */
	internal static void export_all () {
		Font font = BirdFont.get_current_font ();
		
		printd ("Exporting all fonts.\n");
		
		if (font.font_file == null) {
			warning ("Font is not saved.");
		} else {
			do_export ();
		}
	}
		
	static void do_export () {
		bool f;
				
		f = export_ttf_font ();
		if (!f) {
			warning ("Failed to export ttf font");
		}

		f = export_svg_font ();
		if (!f) {
			warning ("Failed to export svg font");
		}
	}

	public static void generate_html_document (string html_file, Font font) {
		File file = File.new_for_path (html_file);
		DataOutputStream os;
		string name = font.get_full_name ();

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
	<h3 class="big">Handgloves & Mittoms</h3>
	<p class="big">Bibliography</p>
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

	public static bool export_ttf_font () {
		Font font = BirdFont.get_current_font ();
		File file = font.get_folder ();
		return export_ttf_font_path (file);
	}

	public static bool export_ttf_font_path (File folder) {
		Font current_font = BirdFont.get_current_font ();
		File ttf_file;
		File eot_file;
		bool done = true;
		
		try {
			ttf_file = get_child (folder, current_font.get_full_name () + ".ttf");
			eot_file = get_child (folder, current_font.get_full_name () + ".eot");

			printd (@"Writing TTF fonts to $((!) ttf_file.get_path ())\n");
			
			if (ttf_file.query_exists ()) {
				ttf_file.delete ();
			}

			if (eot_file.query_exists ()) {
				eot_file.delete ();
			}
			
			TooltipArea.show_text (t_("Writing TTF and EOT files."));
			
			write_ttf ((!) ttf_file.get_path ());
			write_eot ((!) ttf_file.get_path (), (!) eot_file.get_path ());
		} catch (Error e) {
			critical (@"$(e.message)");
			done = false;
		}

		return done;		
	}

	public static bool export_svg_font () {
		Font font = BirdFont.get_current_font ();
		TooltipArea.show_text (t_("Writing SVG file."));
		return export_svg_font_path (font.get_folder ());
	}
		
	public static bool export_svg_font_path (File folder) {
		Font font = BirdFont.get_current_font ();
		string file_name = @"$(font.get_full_name ()).svg";
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
			TooltipArea.show_text (e.message);
			return false;
		}
		
		return true;
	}

	static void write_ttf (string ttf) {
		OpenFontFormatWriter fo = new OpenFontFormatWriter ();
		Font f = BirdFont.get_current_font ();
		File file = (!) File.new_for_path (ttf);
		
		try {
			fo.open (file);
			fo.write_ttf_font (f);
			fo.close ();
		} catch (Error e) {
			warning (@"Can't write TTF font to $ttf");
			critical (@"$(e.message)");
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
