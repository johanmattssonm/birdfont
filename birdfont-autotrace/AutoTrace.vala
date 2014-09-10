/*
    Copyright (C) 2014 Johan Mattsson

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

using Cairo;
using Gee;

namespace BirdFont {

class AutoTrace {
	
	ArrayList<string> files;

	bool help;
	bool quadratic_control_points;
	double cutoff;
	double details;
	double simplification;
	
	public AutoTrace (string[] arg) {
		files = new ArrayList<string> ();
		help = false;
		quadratic_control_points = false;
		cutoff = 1;
		details = 1;
		simplification = 0.5;
		
		for (int i = 1; i < arg.length; i++) {
			if (arg[i] == "-q" || arg[i] == "--quadratic") {
				quadratic_control_points = true;
			} else if (arg[i] == "-c" || arg[i] == "--cutoff" && i + 1 < arg.length) {
				cutoff = double.parse (arg[i + 1]);
				i++;
			} else if (arg[i] == "-d" || arg[i] == "--details" && i + 1 < arg.length) {
				details = double.parse (arg[i + 1]);
				i++;
			} else if (arg[i] == "-s" || arg[i] == "--simplification" && i + 1 < arg.length) {
				simplification = double.parse (arg[i + 1]);
				i++;
			} else if (arg[i] == "-h" || arg[i] == "--help") 	{
				help = true;
			} else {
				files.add (arg[i]);
			}
		}		
	}
	
	public bool has_help_flag () {
		return help;
	}
	
	public static void print_help (string[] arg) {
		stdout.printf (t_("Usage:"));
		stdout.printf (arg[0]);
		stdout.printf (" [" + t_("OPTION") + " ...] " + t_("FILE") + " ..."+"\n");
		stdout.printf ("-c, --cutoff                    " + t_("brighness cutoff, from 0.001 to 2, the default value is 1\n"));
		stdout.printf ("-d, --details                   " + t_("details, from 0.001 to 9.999, the default value is 1\n"));
		stdout.printf ("-h, --help                      " + t_("print this message\n"));
		stdout.printf ("-q, --quadratic                 " + t_("use quadratic control points\n"));
		stdout.printf ("-s, --simplification            " + t_("simplification, from 0.001 to 1, the default value is 0.5\n"));
		stdout.printf ("\n");
	}

	public int trace () {
		BackgroundImage bg;
		File file;
		PathList pl;
		Glyph g;
		double w, h;
		Font font;
		string svg;
		string file_name;
		DataOutputStream data_stream;
		
		foreach (string f in files) {
			file = File.new_for_path (f);
			if (!file.query_exists ()) {
				stdout.printf (@"$f\n");
				stdout.printf (t_("File does not exist.") + "\n");
				return 1;
			}
			
			if (((!) file.get_basename ()).index_of (".") == -1) {
				stdout.printf (@"$f\n");
				stdout.printf (t_("Unknown file format.") + "\n");
				return 2;
			}
		}
		
		if (quadratic_control_points) {
			DrawingTools.point_type = PointType.QUADRATIC;
		} else {
			DrawingTools.point_type = PointType.CUBIC;
		}
		
		foreach (string f in files) {
			file_name = f;
			file_name = file_name.substring (0, file_name.last_index_of ("."));
			file_name = @"$file_name.svg";
			
			stdout.printf (t_("Writing") + " " + file_name + "\n");
		
			font = BirdFont.new_font ();
			bg = new BackgroundImage (f);
			
			bg.set_trace_resolution (details);
			bg.set_threshold (cutoff);
			bg.set_trace_simplification (simplification);
			bg.set_high_contrast (true);

			g = new Glyph.no_lines ("");
			
			GlyphCanvas.current_display = g;
			BirdFont.current_glyph = g;

			h = bg.get_img ().get_height ();
			
			font.top_limit = h / 2;
			font.bottom_limit = -h / 2;
			font.top_position = h / 2;
			font.bottom_position = -h / 2;
						
			w = bg.get_img ().get_width ();
			g.left_limit = -w / 2.0;
			g.right_limit = w / 2.0;
			
			bg.center_in_glyph ();
						
			pl = bg.autotrace ();
			
			foreach (Path p in pl.paths) {
				g.add_path (p);
			}
			
			svg = ExportTool.export_to_string (g, false);
			
			file = File.new_for_path (file_name);
			
			if (file.query_exists ()) {
				file.delete ();
			}
				
			data_stream = new DataOutputStream (file.create (FileCreateFlags.REPLACE_DESTINATION));
			data_stream.put_string (svg);
		}
		
		return 0;
	}
}

public static int main (string[] arg) {
	AutoTrace autotrace;
	Preferences p;
	
	p = new Preferences ();
	
	BirdFont.init_gettext ();
	
	autotrace = new AutoTrace (arg);
	
	if (autotrace.has_help_flag () || arg.length <= 1) {
		AutoTrace.print_help (arg);
		return 0;
	}
	
	return autotrace.trace ();	
}

}
