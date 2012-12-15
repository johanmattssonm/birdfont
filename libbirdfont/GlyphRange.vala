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

public class GlyphRange {
	
	List<UniRange> ranges;
	
	public unowned List<string> unassigned = new List<string> ();
	
	uint32 len = 0;
	
	public GlyphRange () {
	}
		
	public unowned List<UniRange> get_ranges () {
		return ranges;
	}
	
	public void use_default_range () {
		/// All lower case letters in alphabetic order separated by space
		string lower_case = _("a b c d e f g h i j k l m n o p q r s t u v w x y z");
		
		/// All upper case letters in alphabetic order separated by space
		string upper_case = _("A B C D E F G H I J K L M N O P Q R S T U V W X Y Z");

		foreach (string c in lower_case.split (" ")) {
			add_single (c.get_char ());
		}

		foreach (string c in upper_case.split (" ")) {
			add_single (c.get_char ());
		}
				
		add_range ('0', '9');
		
		add_single (' '); // TODO: add all spaces here.
		
		add_single ('.');
		add_single ('?');
		
		add_single (',');
		
		add_single ('’');

		add_range ('“', '”');

		add_single ('&');
		
		add_range (':', ';');
		
		add_single ('/'); 
		
		add_range ('!', '/');
		
		add_single ('-');
		add_range ('‐', '—');
		add_range ('<', '@');
		add_range ('(', ')');
	}
	
	public void use_full_unicode_range () {
		add_range ('\0', (unichar) 0xFFF8);
	}
	
	// Todo: complete localized alphabetical sort åäö is the right order for example.
	public void sort () {
		ranges.sort ((a, b) => {
			bool r = a.start > b.start;
			
			return_if_fail (a.start != b.start);
			
			return (r) ? 1 : -1;
		});
	}
	
	public void add_single (unichar c) {
		add_range (c, c);
	}
	
	public uint32 get_length () {
		unichar l = len;
		l += unassigned.length ();
		return l;
	}
	
	public void add_range (unichar start, unichar stop) {
		unichar b, s;
		if (unique (start, stop)) {
			append_range (start, stop);
		} else {
			
			// make sure this range does not overlap existing ranges
			b = start;
			s = b;
			if (!unique (b, b)) {			
				while (b < stop) {
					if (!unique (b, b)) {
						b++;
					} else {
						if (s != b) {
							add_range (b, stop);
						}
						
						b++;
						s = b;
					}
				}
			} else {
				while (b < stop) {
					if (unique (b, b)) {
						b++;
					} else {
						if (s != b) {
							add_range (start, b - 1);
						}
						
						b++;
						s = b;
					}
				}				
			}
		}
	}
	
	private void append_range (unichar start, unichar stop) {
		UniRange r;
		
		StringBuilder s = new StringBuilder ();
		StringBuilder e = new StringBuilder ();
		s.append_unichar (start);
		e.append_unichar (stop);
		
		r = insert_range (start, stop); // insert a unique range
		merge_range (r); // join connecting ranges
	}
	
	private void merge_range (UniRange r) {
		foreach (UniRange u in ranges) {
			if (u == r) {
				continue;
			}			
			
			if (u.start == r.stop + 1) {
				u.start = r.start;
				ranges.remove_all (r);
				merge_range (u);
			}
			
			if (u.stop == r.start - 1) {
				u.stop = r.stop;
				ranges.remove_all (r);
				merge_range (u);
			}
		}
	}

	public string get_char (uint32 index) {
		int64 ti;
		string chr;
		UniRange r;
		StringBuilder sb;
		unichar c;
		
		if (index > len + unassigned.length ()) { 
			return "\0".dup();
		}
		
		if (index >= len) {
			
			if (index - len >= unassigned.length ()) {
				return "\0".dup();
			} 
			
			chr = ((!) unassigned.nth (index - len)).data;
			return chr;
		}

		r = ranges.first ().data;
		ti = index;

		foreach (UniRange u in ranges) {
			ti -= u.length ();
			
			if (ti < 0) {
				r = u;
				break;
			}
		}
				
		sb = new StringBuilder ();
		c = r.get_char ((unichar) (ti + r.length ()));
		sb.append_unichar (c);

		return sb.str;
	}
	
	public uint32 length () {
		return len;
	}

	private bool unique (unichar start, unichar stop) {
		foreach (UniRange u in ranges) {
			
			if (inside (start, u.start, u.stop)) return false;
			if (inside (stop, u.start, u.stop)) return false;
			if (inside (u.start, start, stop)) return false;
			if (inside (u.stop, start, stop)) return false;
			
		}

		return true;
	}

	private bool inside (unichar start, unichar u_start, unichar u_stop) {
		return (u_start <= start <= u_stop);
	}
	
	private UniRange insert_range (unichar start, unichar stop) {
		if (unlikely (start > stop)) {
			warning ("start > stop");
			stop = start;
		}
		
		UniRange ur = new UniRange (start, stop);
		len += ur.length ();
		ranges.append (ur);
		
		return ur;
	}

	public void print_all () {
		StringBuilder s;
		
		stdout.printf ("Ranges:\n");
		foreach (UniRange u in ranges) {
			s = new StringBuilder ();
			s.append_unichar (u.start);
			s.append (" - ");
			s.append_unichar (u.stop);
			s.append ("\n");
			stdout.printf (s.str);
		}
	}
}

}
