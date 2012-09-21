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
using Gdk;
using Cairo;

namespace Supplement {

class FileSelection {
	
	public double x = 0;
	public double y = 0;
	
	public StringBuilder path;
	
	public bool show_marker = false;
	public bool input = false;
	
	public signal void redraw ();
	
	bool running;
	List<string> directory_listing = new List<string> ();
	int list_offset = 0;
	int list_n_rows = 0;
	
	string sep = "/";
	
	int has_modifier = 0;
	
	List<string> listing;
	
	public FileSelection () {
		path = new StringBuilder ();
		path.append (Supplement.get_current_font ().get_path ());
		running = true;
		
		sep = (path.str.index_of ("/") == 0) ? "/" : "\\"; // windows and unix sepparators
		
		var time = new TimeoutSource(600);
		
		time.set_callback (() => {
			
			if (input) show_marker = true;
			else show_marker = !show_marker;
			
			input = false;
			
			redraw ();
			return running;
    });

    time.attach (null);
	}
	
	public void draw (Allocation allocation, Context cr) {
		FontExtents fe;
		
		cr.save ();
		cr.move_to (x, y);
		
		cr.set_font_size (12);
		cr.select_font_face ("Cantarell", FontSlant.NORMAL, FontWeight.BOLD);
		
		path.append ((show_marker) ? "|" : " ");
		cr.font_extents (out fe);
		
		// Fixa: pango font metrix vore bra
		if (allocation.width / (1 * fe.max_x_advance) < path.len) {
			int t = path.str.last_index_of (sep) ;
			string s;
			
			return_if_fail (t != -1);
			s = path.str.substring (t + 1);
			cr.show_text (s);
		} else {
			cr.show_text (path.str);
		}
		path.truncate (path.len - 1);
		
		cr.stroke ();
		cr.restore ();
		
		draw_directory_listing (allocation, cr);
	}

	void draw_directory_listing (Allocation allocation, Context cr) {
		int lh = 90;
		int n = 0;
		int m = (int) ((allocation.height - lh) / 50.0);
		int skip = list_offset;
		int max_fn_len = 36;
		
		list_n_rows = m;

		cr.save ();

		cr.set_font_size (12);
		cr.select_font_face ("Cantarell", FontSlant.NORMAL, FontWeight.BOLD);
		
		cr.move_to (x, y);
		
		foreach (var f in directory_listing) {
			if (++n >= m + list_offset) continue;   // belowe
			if (--skip > 0) continue; // above
			
			lh += 25;
			cr.move_to (x, y + lh);
			
			if (f.char_count () > max_fn_len) {
				f = f.substring (0, max_fn_len);
				f += " ...";
			}
			
			cr.show_text (f);
		}

		if (n >= m && n != 0 && n - m > 0) {
			lh += 25;
			cr.move_to (x, y + lh);
			cr.show_text (@"and $(n - m) more files");
		}
		
		cr.stroke ();
		cr.restore ();
	}
		
	public void key_press (EventKey e) {
		unichar c;
		int max;
		
		show_marker = true;
		input = true;
		
		if (is_mod (e)) {
			has_modifier++;
		}
		
		if (e.keyval == Key.DOWN || e.keyval == Key.UP ) {
			list_offset += (e.keyval == Key.DOWN) ? +1 : -1;
			
			max = (int) directory_listing.length () - list_n_rows;
			if (list_offset > max) {
				list_offset = max;
			}

			if (list_offset < 0) {
				list_offset = 0;
			}
	
		} else if (e.keyval == Key.BACK_SPACE) {			
			path.truncate (path.len - 1);
			
			while (!path.str.validate ()) {
				path.truncate (path.len - 1);
				
				if (path.str.length == 0) {
					break;
				}
			}
			
		} else if (e.keyval == Key.TAB) {
			autocomplete ();
		} else {
			c = (unichar) e.keyval;
			
			// don't write .ffis instead of .ffi
			if (c == 's' && path.str.substring (-4) == ".ffi") {
				return;
			}
			
			if (has_modifier == 0 && !is_modifier_key (e.keyval) && c.validate ()) {
				path.append_unichar (c);
			}
		}
	}
	
	public void key_release (EventKey e) {
		if (is_mod (e)) {
			has_modifier--;
		}
	}
	
	public void autocomplete () {
		
		if (path.str.length == 0) {
			path.append (sep);
			return;
		}
		
		try {
			int p = path.str.last_index_of (sep);

			if (p == -1) return;

			bool list_all = false;
			File dd = File.new_for_path (path.str);
			bool matching = false;
			
			listing = new List<string> ();
			
			if (dd.query_file_type (0) == FileType.DIRECTORY) {
				if (path.str.substring (-1) != sep)
					path.append (sep);
				else
					list_all = true; // and print all files
			}

			string d = path.str.substring (0, p + 1);
			string f = path.str.substring (p + 1);
			File directory = File.new_for_path (d);
			FileEnumerator enumerator = directory.enumerate_children (FILE_ATTRIBUTE_STANDARD_NAME, 0);	
			FileInfo? file_info;
			FileInfo fi;
						
			while ((file_info = enumerator.next_file ()) != null) {
				fi = (!) file_info;
				
				if (fi.get_name ().index_of (".") == 0) continue;
				
				matching = (fi.get_name ().index_of (f) == 0);
				
				if (list_all || fi.get_name ().index_of (f) == 0) { // match
					StringBuilder nfn = new StringBuilder ();
					nfn.append (fi.get_name ());

					if (!nfn.str.validate ()) continue;

					if (fi.get_file_type () == FileType.DIRECTORY) { // Fixa: filetype is G_FILE_TYPE_UNKNOWN
						nfn.append (sep);
						listing.append (nfn.str);
					} else if (fi.get_name ().index_of (".ffi") != -1) {
						listing.append (nfn.str);
					} else {
						listing.append (nfn.str);
					}
				}
			}

			// as complete it can be do nothing
			if (listing.length () == 0) {
				return;
			}
					
			// clear previous listing
			while (directory_listing.length () > 0) {
				directory_listing.delete_link (directory_listing.first ());
			}

			// unique auto complete path
			if (listing.length () == 1) {
				path.erase ();
				path.append (d);
				path.append (listing.first ().data);
			}
	
			// matching but not unique
			partly_complete ();
	
			// show directory content
			list_offset = 0;
			if (listing.length () > 1) {
				foreach (var ldf in listing) {
					directory_listing.append (ldf);
				}
			}
						
    } catch (Error e) {
    }
    
	}
	
	private void partly_complete () {	
		int p, i;
		string dir;
		
		p = path.str.last_index_of (sep);
		dir = path.str.substring (0, p + 1);

		string new_file_name;
		bool variation;
		
		if (listing.length () == 0) {
			return;
		}
		
		new_file_name = listing.first ().data;
		
		while (new_file_name.length > 1) {
			
			variation = false;
			
			foreach (string listed in listing) {
				i = listed.index_of (new_file_name);

				if (i == -1) {
					variation = true;
				}
			}
			
			if (variation) {
				new_file_name = new_file_name.substring (0, new_file_name.length - 1);
			} else {
				
				path.erase ();
				path.append (dir);
				path.append (new_file_name);
				
				return;
			}
		}

		return;
	}
	
}

}
