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

/** Stand alone command line utility for exporting fonts. */
class BirdfontExport {
	
	public BirdfontExport () {
	}
	
	static void print_help (string[] arg) {
		stdout.printf ("Usage: ");
		stdout.printf (arg[0]);
		stdout.printf (" [INPUT FILE]\n");
	}
	
	public static int main(string[] arg) {
		ExportTool export;

		LogLevelFlags levels = LogLevelFlags.LEVEL_ERROR | LogLevelFlags.LEVEL_CRITICAL | LogLevelFlags.LEVEL_WARNING;
		Log.set_handler (null, levels, Supplement.fatal_warning);
				
		if (arg.length != 2) {
			print_help (arg);
			return 1;
		}

		Preferences preferences = new Preferences ();
		preferences.load ();
			
		Supplement.args = new Argument ("");
		Supplement.current_font = new Font ();

		// TODO: refactor and remove all gtk stuff from this program
		Gtk.init (ref arg);
		MainWindow window = new MainWindow ("Birdfont");
		window.show_all ();
		
		if (!Supplement.get_current_font ().load (arg[1])) {
			stderr.printf (@"Failed to load font $(arg[1]).\n");
		}

		ExportTool.export_svg_font_path (File.new_for_path ("."));
		ExportTool.export_ttf_font_path (File.new_for_path ("."), false);
		
		print ("Done\n");
						
		return 0;
	}
	
}

}
