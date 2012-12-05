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

public class ExportTool : Tool {
	private static string? prefered_browser = null;
	private static ExportThread export_thread;
	
	private static unowned Thread<void*> export_thread_handle;

	private static bool stop_export_thread = false;

	public ExportTool (string n) {
		base (n, _("Export glyph to svg file"), 'e', CTRL);
	
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

	public static void generate_html_document (string html_file, Font font) {
		File file = File.new_for_path (html_file);
		DataOutputStream os;
		string name = font.get_name ();

		try {
			os = new DataOutputStream (file.create(FileCreateFlags.REPLACE_DESTINATION));

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
	<p class="smaller">""" + _("a b c d e f g h i j k l m n o p q r s t u v w x y z") + """</p>
	<p class="smaller">""" + _("A B C D E F G H I J K L M N O P Q R S T U V W X Y Z") + """</p>
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
	
	/** Stop a running export thread.*/
	public static void stop_export () {
		lock (stop_export_thread) {
			stop_export_thread = true;
		}
	}
	
	public static bool should_stop () {
		bool r;
		lock (stop_export_thread) {
			r = stop_export_thread;
		}
		return r;
	} 
	
	public static string get_birdfont_export () {
		File f;
		
		f = File.new_for_path ("birdfont-export.sh");
		if (f.query_exists ()) {
			return "sh birdfont-export.sh";
		}

		f = File.new_for_path ("../birdfont-export.sh");	
		if (f.query_exists ()) {
			return "sh ../birdfont-export.sh";
		}

		f = File.new_for_path ("birdfont-export.exe");	
		if (f.query_exists ()) {
			return (!) f.get_path ();
		}

		f = File.new_for_path (@"$PREFIX/birdfont-export");
		if (f.query_exists ()) {
			return @"$PREFIX/bin/birdfont-export";
		}

		warning ("Can't find birdfont-export.");
		
		return "birdfont-export";
	}
	
	public static bool export_ttf_font_path (File folder, bool async = true) {
		Font current_font = Supplement.get_current_font ();
		File ttf_file;
		File eot_file;
		string temp_file;
		bool done = true;
		string export_command;
		
		if (Supplement.win32) {
			async = false;
		}

		try {
			// create a copy of current font and use it in a separate 
			// export thread
			temp_file = current_font.save_backup ();
			ttf_file = folder.get_child (current_font.get_name () + ".ttf");
			eot_file = folder.get_child (current_font.get_name () + ".eot");

			if (ttf_file.query_exists ()) {
				ttf_file.delete ();
			}

			if (eot_file.query_exists ()) {
				eot_file.delete ();
			}
			
			assert (!is_null (temp_file));
			assert (!is_null (ttf_file.get_path ()));
			assert (!is_null (eot_file.get_path ()));

			export_thread = new ExportThread (temp_file, (!) ttf_file.get_path (), (!) eot_file.get_path ());

			try {
				if (async) {
					export_command = @"$(get_birdfont_export ()) --ttf -o $((!) folder.get_path ()) $temp_file";
					
					try {
						Process.spawn_command_line_async (export_command);
					} catch (Error e) {
						stderr.printf (@"Failed to execute \"$export_command\" \n");
						critical (@"$(e.message)");
					}
				}
				
				if (!async) {
					export_thread.run ();
				}
			} catch (ThreadError e) {
				warning (e.message);
				done = false;
			}	
			
		} catch (Error e) {
			critical (@"$(e.message)");
			done = false;
		}
		
		return done;		
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
		
		status (@"Wrote font files");
		return true;
	}

	public class ExportThread : GLib.Object {
		private static string ffi;
		private static string ttf;
		private static string eot;

		public ExportThread (string ffi, string ttf, string eot) {
			this.ffi = ffi.dup ();
			this.ttf = ttf.dup ();
			this.eot = eot.dup ();
		}
		
		public void* run () {
			assert (!is_null (ffi));
			assert (!is_null (ttf));
			assert (!is_null (eot));
			
			if (!should_stop ()) { 
				write_ttf ();
			}
			
			if (!should_stop ()) { 
				write_eof ();
			}

			return null;
		}
		
		void write_ttf () {
			OpenFontFormatWriter fo = new OpenFontFormatWriter ();
			Font f = new Font ();
			File file = (!) File.new_for_path (ttf);

			return_if_fail (!is_null (ffi));			
			return_if_fail (!is_null (ttf));
			return_if_fail (!is_null (file));
			return_if_fail (!is_null (f));
			return_if_fail (!is_null (fo));
			
			try {
				if (!f.load (ffi, false)) {
					warning (@"Can't read $ffi");
				}
				
				fo.open (file);
				fo.write_ttf_font (f);
				fo.close ();
			} catch (Error e) {
				critical (@"$(e.message)");
			}
		}
		
		void write_eof () {
			EotWriter fo;

			return_if_fail (!is_null (this));
			return_if_fail (!is_null (ttf));
			return_if_fail (!is_null (eot));
			
			fo = new EotWriter (ttf, eot);

			return_if_fail (!is_null (fo));

			try {
				fo.write ();
			} catch (Error e) {
				warning ("EOF conversion falied.");
				critical (@"$(e.message)");
			}
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
