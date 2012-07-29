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

class GlyphRange {
	
	List<UniRange> ranges;

	GlyphTable unassigned = new GlyphTable ();
	
	uint32 len = 0;
	
	public GlyphRange () {
	}
	
	public void set_unassigned (GlyphTable unassigned) {
		this.unassigned = unassigned;
	}
	
	public unowned List<UniRange> get_ranges () {
		return ranges;
	}
	
	public void use_default_range () {
		add_range ('a', 'z');

		add_single ('å');
		add_single ('ä');
		add_single ('ö');

		add_range ('A', 'Z');

		add_single ('Å');
		add_single ('Ä');
		add_single ('Ö');
		
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
		add_range ('\0', (unichar) 0xA868FE00);
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
	
	public unichar get_length () {
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
		uint i = 0;
		uint next = 0;
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
			
			chr = ((!) unassigned.nth (index - len)).get_name ();
			return chr;
		}

		r = ranges.first ().data;

		ti = (index < r.length ()) ? index - 1: index;

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
	
	public unichar length () {
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
