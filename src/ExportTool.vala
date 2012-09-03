/*
    Copyright (C) 2012 Johan Mattsson

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

namespace Supplement {

class ExportTool : Tool {

	private static string? prefered_browser = null;
	private static ExportThread export_thread;

	public ExportTool (string n) {
		base (n, "Export glyph to svg file", 'e', CTRL);
	
		select_action.connect((self) => {
			export_svg_font ();
			// Fixa: add export_glyph_to_svg (); as tool in toolbox
		});
		
		press_action.connect((self, b, x, y) => {
		});

		release_action.connect((self, b, x, y) => {
		});
		
		move_action.connect ((self, x, y)	 => {
		});
	}

	public static bool export_all () {
		Font font = Supplement.get_current_font ();
		bool f;
		
		if (font.get_ttf_export ()) {
			f = export_ttf_font ();
			
			if (!f) {
				warning ("Failed to export font");
				return false;
			}
		}
		
		if (font.get_svg_export ()) {
			f = export_svg_font ();

			if (!f) {
				warning ("Failed to export font");
				return false;
			}
		}
		
		return true;
	}

	public void export_glyph_to_svg () {
		Glyph glyph = MainWindow.get_current_glyph ();
		Font font = Supplement.get_current_font ();
		FontDisplay fd = MainWindow.get_current_display ();
		string glyph_svg;
		string svg_file = @"$(glyph.get_name ()).svg";
		File file = font.get_folder ().get_child (svg_file);
		DataOutputStream os;
		string name = glyph.get_name ();
		int pid = 0;
		
		if (!(fd is Glyph)) {
			return;
		}
		
		try {
			
			if (file.query_exists ()) {
				file.delete ();
			}
			
			os = new DataOutputStream (file.create(FileCreateFlags.REPLACE_DESTINATION));	
			
			os.put_string (
"""<?xml version="1.0" standalone="no"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd" >
<svg """);

			os.put_string (@"xmlns=\"http://www.w3.org/2000/svg\"\n");
			os.put_string (@"\twidth=\"$(glyph.get_width () / Glyph.SCALE)\"\n");
			os.put_string (@"\theight=\"$(glyph.get_height () / Glyph.SCALE)\"\n");
			os.put_string (@"\tid=\"glyph_$(name)\"\n");
			os.put_string (@"\tversion=\"1.1\">\n");
			
			os.put_string (@"\n");
			
			os.put_string (@"<g id=\"$(name)\">\n");
			
			foreach (Path p in glyph.path_list) {
				
				glyph_svg = Svg.to_svg_path (p, glyph);
				
				os.put_string (@"<path ");
				os.put_string (@"style=\"fill:#000000;stroke-width:0px\" ");
				os.put_string (@"d=\"$(glyph_svg)\" id=\"path_$(name)$(pid++)\" />\n");
				
			}
			
			os.put_string ("""</g>
			
</svg>""");
	
		} catch (Error e) {
			stderr.printf (@"Export \"$svg_file\" \n");
			critical (@"$(e.message)");
			status ("Can't export $svg_file.");
		}
		
		status ("Wrote $svg_file.");
	}

	/** Export font and open html document */
	public void view_result () {
		Font font = Supplement.get_current_font ();
		string path = @"$(font.get_name ()).html";
		File dir = font.get_folder ();
		File file = dir.get_child (path);
		string browser = "";		
		
		if (!export_svg_font ()) {
			warning ("Failed to export svg font.");
			return;
		}
		
		if (!export_ttf_font ()) {
			warning ("Failed to export ttf font.");
			return;
		}
		
		try {			
			if (!file.query_exists ()) {
				generate_html_document ((!)file.get_path (), font);				
			}

			browser = find_browser ();
			Process.spawn_command_line_async (@"$browser $(file.get_uri ())");
		} catch (Error e) {
			stderr.printf (@"Failed to execute \"$browser $path\" \n");
			critical (@"$(e.message)");
		}
		
	}
		
	private string find_browser () {				
		File f;
		string b;
		if (prefered_browser != null) return (!) prefered_browser;
		
		b = @"C:\\Users\\$(Environment.get_user_name())\\AppData\\Local\\Google\\Chrome\\Application\\chrome.exe"; // mind the hyphen
		
		f = File.new_for_path (b);
		if (f.query_exists ()) {
			prefered_browser = @"'$b'"; // hyphen for windows command
			return (!) prefered_browser;
		}
		
		prefered_browser = "sensible-browser";
		return (!) prefered_browser;
	}
	
	public static void generate_html_document (string html_file, Font font) {
		File file = File.new_for_path (html_file);
		DataOutputStream os = new DataOutputStream (file.create(FileCreateFlags.REPLACE_DESTINATION));

		string name = font.get_name ();

		try {

os.put_string (
"""<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>

	<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
	<title>Lorem ipsum</title>
	
	<style type="text/css">

		@font-face {
			font-family: '"""); os.put_string (@"$(name)");              os.put_string ("""SVG';
			src: url('""");     os.put_string (@"$(name).svg#$(name)");  os.put_string ("""') format('svg');
		}
	""");

	os.put_string ("""
		@font-face {
			font-family: '"""); os.put_string (@"$(name)");              os.put_string ("""TTF';
			src: url('""");     os.put_string (@"$(name).ttf"); os.put_string ("""') format('truetype');
		} """);

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
			os.put_string ("SVG'");
			
			os.put_string (", '");
			os.put_string (@"$(name)");
			os.put_string ("TTF'");

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
	<p class="big">Inspirerande</p>
</div>

<div>
	<h3 class="small">Handgloves & Mittoms</h3>
	<p class="small">Wind blows in Hauges poetry.</p>
</p>
</div>

<div>
	<h4 class="smaller">Headline 16pt</h4>
	<p class="smaller">Ett litet stycke svalhjärta.</p>	
</div>

<div>
	<h4 class="smaller">Alphabet</h4>
	<p class="smaller">a b c d e f g h i j k l m n o p q r s t u v w x y z å ä ö</p>
	<p class="smaller">A B C D E F G H I J K L M N O P Q R S T U V W X Y Z Å Ä Ö</p>
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
		Font font = Supplement.get_current_font ();
		File file = font.get_folder ();
		return export_ttf_font_path (file);
	}
	
	public static bool export_ttf_font_path (File folder, bool async = true) 
		requires (Supplement.get_current_font ().font_file != null) {
		Font current_font = Supplement.get_current_font ();
		string path;
		OpenFontFormatWriter fo;
		Font temp_font = new Font ();
		unowned Thread<void*> th;
		File file;
		string temp_file;

		try {
			// create a copy of current font and use it in a separate 
			// export thread
			temp_file = current_font.save_backup ();
			file = folder.get_child (current_font.get_name () + ".ttf");

			if (file.query_exists ()) {
				file.delete ();
			}

			path = (!) file.get_path ();
			export_thread = new ExportThread (temp_file, path);

			try {
				th = Thread.create<void*> (export_thread.run, true);
			
				if (!async) {
					th.join ();
				}
			} catch (ThreadError e) {
				stderr.printf ("%s\n", e.message);
				return false;
			}			
		} catch (Error e) {
			critical (@"$(e.message)");
			return false;
		}
		
		return true;		
	}
	
	public static bool export_svg_font () {
		Font font = Supplement.get_current_font ();
		return export_svg_font_path (font.get_folder ());
	}
		
	public static bool export_svg_font_path (File folder) {
		Font font = Supplement.get_current_font ();
		string file_name = @"$(font.get_name ()).svg";
		File file;
		SvgFontFormatWriter fo;
		
		try {
			file = folder.get_child (file_name);
			
			if (file.query_exists ()) {
				file.delete ();
			}
			
			fo = new SvgFontFormatWriter ();
			fo.open (file);
			fo.write_font_file (font);
			fo.close ();
		} catch (Error e) {
			critical (@"$(e.message)");
			status (e.message);
			return false;
		}
		
		status (@"Wrote $file_name");
		return true;
	}


	class ExportThread {

		private string from;
		private string to;

		public ExportThread (string from, string to) {
			this.from = from;
			this.to = to;
		}

		public void* run () {
			OpenFontFormatWriter fo = new OpenFontFormatWriter ();
			Font f = new Font ();
			
			assert (!is_null (from));
			assert (!is_null (to));
			
			try {
				if (!f.load (from, false)) {
					warning (@"Can't read $from");
					return null;
				}
				
				fo.open ((!) File.new_for_path (to));
				fo.write_ttf_font (f);
				fo.close ();
			} catch (Error e) {
				critical (@"$(e.message)");
				return null;
			}	
			
			return null;
		}
	}
	
	private static void status (string s) {
		TooltipArea status = MainWindow.get_tool_tip ();
		
		if (is_null (status)) {
			return;
		}
		
		status.show_text (s);
	}
}

}
