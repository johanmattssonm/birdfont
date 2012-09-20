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

using Gtk;
using Supplement;

namespace Supplement {

internal class Supplement {
	internal static Argument args;
	internal static bool experimental = false;
	internal static bool show_coordinates = false;
	internal static bool fatal_wanings = false;
	internal static bool win32 = false;
	internal static string exec_path = "";

	internal static Font current_font;
	internal static Glyph current_glyph;
	
	internal static Font get_current_font () {
		return current_font;
	}

	internal static void fatal_warning (string? log_domain, LogLevelFlags log_levels, string message) {		
		bool fatal = true;
		
		if (log_domain != null) {
			stderr.printf ("%s: \n", (!) log_domain);
		}
		
		stderr.printf ("\n%s\n\n", message);
		assert (!fatal);
	}
	
	internal static void new_font () {
		current_font = new Font ();
	}

	internal static File get_thumbnail_directory () {
		File thumbnails = get_settings_directory ().get_child ("thumbnails");
		
		if (!thumbnails.query_exists ()) {
			DirUtils.create ((!) thumbnails.get_path (), 0xFFFFFF);
		}
		
		return thumbnails;
	}
		
	internal static File get_settings_directory () {
		File home = File.new_for_path (Environment.get_home_dir ());
		File settings = home.get_child (".birdfont");
		
		if (!settings.query_exists ()) {
			DirUtils.create ((!) settings.get_path (), 0xFFFFFF);
		}
			
		return settings;
	}

	internal static File get_backup_directory () {
		File settings = get_settings_directory ();
		File backup = settings.get_child ("backup");
		
		if (!backup.query_exists ()) {
			DirUtils.create ((!) backup.get_path (), 0xFFFFFF);
		}
			
		return backup;
	}

	internal static bool has_argument (string param) {
		return args.has_argument (param);
	}
	
	internal static string? get_argument (string param) {
		return args.get_argument (param);
	}	
}

internal bool is_null (void* n) {
	return n == null;
}

}
